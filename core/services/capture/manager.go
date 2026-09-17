package capture

import (
	"bytes"
	"encoding/json"
	"fmt"
	"image"
	"image/png"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"
	"unicode/utf8"

	"ogsShell/core/logger"
)

// HyprlandMonitor represents monitor geometry and focus status from hyprctl monitors -j.
type HyprlandMonitor struct {
	ID      int     `json:"id"`
	Name    string  `json:"name"`
	Width   int     `json:"width"`
	Height  int     `json:"height"`
	X       int     `json:"x"`
	Y       int     `json:"y"`
	Focused bool    `json:"focused"`
	Scale   float64 `json:"scale"`
}

func getHyprlandMonitors() []HyprlandMonitor {
	cmd := exec.Command("hyprctl", "monitors", "-j")
	out, err := cmd.Output()
	if err != nil {
		return nil
	}
	var mons []HyprlandMonitor
	if err := json.Unmarshal(out, &mons); err != nil {
		return nil
	}
	return mons
}

func getFocusedMonitorName() string {
	mons := getHyprlandMonitors()
	for _, m := range mons {
		if m.Focused {
			return m.Name
		}
	}
	if len(mons) > 0 {
		return mons[0].Name
	}
	return ""
}

// CaptureManager defines the interface for screen capture, OCR, recording, and annotator tasks.
type CaptureManager interface {
	FreezeScreen(mode string) (*FreezeResult, error)
	CaptureScreenshot(p CaptureScreenshotPayload) (*CaptureResult, error)
	CaptureOCR(p CaptureOCRPayload) (*OCRResult, error)
	StartRecording(geometry string) (*RecordState, error)
	StopRecording() (*RecordFinishedPayload, error)
	GetRecordState() RecordState
	OpenAnnotator(filePath string) error
	SetRecordUpdateCallback(func(state RecordState))
	SetRecordFinishedCallback(func(result RecordFinishedPayload))
	Close() error
}

// Manager manages screenshot, OCR, screen recording, and external editing workflows.
type Manager struct {
	mu                     sync.RWMutex
	recordState            RecordState
	recordCmd              *exec.Cmd
	recordTicker           *time.Ticker
	recordStopChan         chan struct{}
	lastScreenshotPath     string
	recordUpdateCallback   func(state RecordState)
	recordFinishedCallback func(result RecordFinishedPayload)

	screenshotsDir string
	recordingsDir  string
	freezePath     string
	ocrTempPath    string
}

// NewDefaultCaptureManager initializes a new Manager with canonical user paths.
func NewDefaultCaptureManager() (*Manager, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		homeDir = "/tmp"
	}

	return &Manager{
		screenshotsDir: filepath.Join(homeDir, "Pictures", "Screenshots"),
		recordingsDir:  filepath.Join(homeDir, "Videos", "Recordings"),
		freezePath:     "/tmp/ogs_freeze.png",
		ocrTempPath:    "/tmp/ogs_ocr.png",
	}, nil
}

// FreezeScreen executes grim to capture an instant frozen frame for snipping overlays.
// In multi-monitor setups, captures each monitor individually with zero compression (-l 0)
// into /tmp/ogs_freeze_<mon>.png in parallel to eliminate distortion and squishing.
func (m *Manager) FreezeScreen(mode string) (*FreezeResult, error) {
	log := logger.Module("CAPTURE")
	log.Info("Ekran dondurma işlemi başlatılıyor...", "target", m.freezePath, "mode", mode)

	mons := getHyprlandMonitors()
	var wg sync.WaitGroup
	var freezeErr error
	var errMu sync.Mutex

	now := time.Now().UnixMilli()

	if len(mons) > 0 {
		focusedName := ""
		for _, mon := range mons {
			if mon.Focused {
				focusedName = mon.Name
			}
			wg.Add(1)
			go func(name string) {
				defer wg.Done()
				dest := fmt.Sprintf("/tmp/ogs_freeze_%s.png", name)
				cmd := exec.Command("grim", "-l", "0", "-o", name, dest)
				if out, err := cmd.CombinedOutput(); err != nil {
					errMu.Lock()
					freezeErr = err
					errMu.Unlock()
					log.Warn("Monitor freeze failed", "mon", name, "err", err, "out", strings.TrimSpace(string(out)))
				}
			}(mon.Name)
		}
		wg.Wait()

		// Also copy the focused monitor's capture to m.freezePath as universal fallback
		if focusedName != "" {
			src := fmt.Sprintf("/tmp/ogs_freeze_%s.png", focusedName)
			if data, err := os.ReadFile(src); err == nil {
				_ = os.WriteFile(m.freezePath, data, 0644)
			}
		}
	} else {
		// Single monitor or non-Hyprland fallback
		cmd := exec.Command("grim", "-l", "0", m.freezePath)
		if out, err := cmd.CombinedOutput(); err != nil {
			errMsg := fmt.Sprintf("grim ekran dondurma hatası: %v (output: %s)", err, strings.TrimSpace(string(out)))
			log.Error(errMsg)
			return &FreezeResult{
				FilePath:  m.freezePath,
				Timestamp: now,
				Success:   false,
				Error:     errMsg,
				Mode:      mode,
				Monitors:  mons,
			}, err
		}
	}

	res := &FreezeResult{
		FilePath:  m.freezePath,
		Timestamp: now,
		Success:   freezeErr == nil,
		Mode:      mode,
		Monitors:  mons,
	}
	log.Info("Ekran donduruldu", "monitors", len(mons), "timestamp", now)
	return res, nil
}

// CaptureScreenshot captures a given geometry or the focused screen, saves it to disk, and copies to clipboard.
// If a monitor and local coordinates are provided, crops directly from the pristine frozen PNG to avoid overlay artifacts.
func (m *Manager) CaptureScreenshot(p CaptureScreenshotPayload) (*CaptureResult, error) {
	log := logger.Module("CAPTURE")

	if err := os.MkdirAll(m.screenshotsDir, 0755); err != nil {
		log.Error("Ekran görüntüsü dizini oluşturulamadı", "dir", m.screenshotsDir, "err", err)
	}

	fileName := fmt.Sprintf("screenshot_%s.png", time.Now().Format("2006-01-02_15-04-05"))
	filePath := filepath.Join(m.screenshotsDir, fileName)

	// Step 1: Clean cropping from frozen frame (eliminates overlay superpositions & unmapping races)
	cropped := false
	if p.Monitor != "" && p.Width > 0 && p.Height > 0 {
		srcPath := fmt.Sprintf("/tmp/ogs_freeze_%s.png", p.Monitor)
		if _, err := os.Stat(srcPath); os.IsNotExist(err) {
			srcPath = m.freezePath
		}
		if f, err := os.Open(srcPath); err == nil {
			img, err := png.Decode(f)
			f.Close()
			if err == nil {
				if sub, ok := img.(interface {
					SubImage(r image.Rectangle) image.Image
				}); ok {
					cropRect := image.Rect(p.LocalX, p.LocalY, p.LocalX+p.Width, p.LocalY+p.Height)
					cropRect = cropRect.Intersect(img.Bounds())
					subImg := sub.SubImage(cropRect)
					outF, err := os.Create(filePath)
					if err == nil {
						if err := png.Encode(outF, subImg); err == nil {
							cropped = true
							log.Info("Ekran görüntüsü donmuş kareden kırpıldı", "mon", p.Monitor, "rect", cropRect, "file", filePath)
						}
						outF.Close()
					}
				}
			}
		}
	}

	// Step 2: Fallback to grim (full-screen or CLI captures)
	if !cropped {
		var cmd *exec.Cmd
		geomTrimmed := strings.TrimSpace(p.Geometry)
		if geomTrimmed != "" && geomTrimmed != "all" {
			time.Sleep(40 * time.Millisecond) // Ensure layer overlay has unmapped
			cmd = exec.Command("grim", "-g", geomTrimmed, filePath)
		} else if geomTrimmed == "all" {
			cmd = exec.Command("grim", filePath)
		} else {
			// Full screenshot: capture the focused monitor to prevent multi-monitor squishing
			focusedMon := getFocusedMonitorName()
			if focusedMon != "" {
				cmd = exec.Command("grim", "-o", focusedMon, filePath)
			} else {
				cmd = exec.Command("grim", filePath)
			}
		}

		if out, err := cmd.CombinedOutput(); err != nil {
			errMsg := fmt.Sprintf("grim ekran görüntüsü alma hatası: %v (output: %s)", err, strings.TrimSpace(string(out)))
			log.Error(errMsg)
			return &CaptureResult{
				FilePath:  filePath,
				Geometry:  p.Geometry,
				Timestamp: time.Now().UnixMilli(),
				Copied:    false,
				Success:   false,
				Error:     errMsg,
			}, err
		}
	}

	// Step 3: Copy to system clipboard: wl-copy --type image/png < file
	copied := false
	if imgData, err := os.ReadFile(filePath); err == nil {
		copyCmd := exec.Command("wl-copy", "--type", "image/png")
		copyCmd.Stdin = bytes.NewReader(imgData)
		if err := copyCmd.Run(); err == nil {
			copied = true
		} else {
			log.Warn("Ekran görüntüsü panoya kopyalanamadı", "err", err)
		}
	} else {
		log.Warn("Ekran görüntüsü dosyası okunamadı", "file", filePath, "err", err)
	}

	m.mu.Lock()
	m.lastScreenshotPath = filePath
	m.mu.Unlock()

	log.Info("Ekran görüntüsü alındı", "path", filePath, "geometry", p.Geometry, "copied", copied)

	return &CaptureResult{
		FilePath:  filePath,
		Geometry:  p.Geometry,
		Timestamp: time.Now().UnixMilli(),
		Copied:    copied,
		Success:   true,
	}, nil
}

// CaptureOCR captures target geometry to a temporary image, executes Tesseract OCR, and copies text to clipboard.
func (m *Manager) CaptureOCR(p CaptureOCRPayload) (*OCRResult, error) {
	log := logger.Module("CAPTURE-OCR")

	// 1. Capture cropped region into temporary file
	cropped := false
	if p.Monitor != "" && p.Width > 0 && p.Height > 0 {
		srcPath := fmt.Sprintf("/tmp/ogs_freeze_%s.png", p.Monitor)
		if _, err := os.Stat(srcPath); os.IsNotExist(err) {
			srcPath = m.freezePath
		}
		if f, err := os.Open(srcPath); err == nil {
			img, err := png.Decode(f)
			f.Close()
			if err == nil {
				if sub, ok := img.(interface {
					SubImage(r image.Rectangle) image.Image
				}); ok {
					cropRect := image.Rect(p.LocalX, p.LocalY, p.LocalX+p.Width, p.LocalY+p.Height)
					cropRect = cropRect.Intersect(img.Bounds())
					subImg := sub.SubImage(cropRect)
					outF, err := os.Create(m.ocrTempPath)
					if err == nil {
						if err := png.Encode(outF, subImg); err == nil {
							cropped = true
						}
						outF.Close()
					}
				}
			}
		}
	}

	if !cropped {
		var grimCmd *exec.Cmd
		geomTrimmed := strings.TrimSpace(p.Geometry)
		if geomTrimmed != "" && geomTrimmed != "all" {
			time.Sleep(40 * time.Millisecond)
			grimCmd = exec.Command("grim", "-g", geomTrimmed, m.ocrTempPath)
		} else if geomTrimmed == "all" {
			grimCmd = exec.Command("grim", m.ocrTempPath)
		} else {
			focusedMon := getFocusedMonitorName()
			if focusedMon != "" {
				grimCmd = exec.Command("grim", "-o", focusedMon, m.ocrTempPath)
			} else {
				grimCmd = exec.Command("grim", m.ocrTempPath)
			}
		}

		if out, err := grimCmd.CombinedOutput(); err != nil {
			errMsg := fmt.Sprintf("grim OCR görüntü yakalama hatası: %v (output: %s)", err, strings.TrimSpace(string(out)))
			log.Error(errMsg)
			return &OCRResult{
				Success: false,
				Error:   errMsg,
			}, err
		}
	}

	// 2. Run tesseract /tmp/ogs_ocr.png stdout -l tur+eng
	tessCmd := exec.Command("tesseract", m.ocrTempPath, "stdout", "-l", "tur+eng")
	outBytes, err := tessCmd.Output()
	if err != nil {
		// Fallback: try default language configuration if tur+eng fails
		log.Warn("Tesseract tur+eng hatası, varsayılan sistem dili ile tekrar deneniyor", "err", err)
		tessCmd = exec.Command("tesseract", m.ocrTempPath, "stdout")
		outBytes, err = tessCmd.Output()
		if err != nil {
			errMsg := fmt.Sprintf("tesseract OCR metin tanıma hatası: %v", err)
			log.Error(errMsg)
			return &OCRResult{
				Success: false,
				Error:   errMsg,
			}, err
		}
	}

	rawText := strings.TrimSpace(string(outBytes))
	charCount := utf8.RuneCountInString(rawText)

	// Clean single-line truncated preview for the Dynamic Island HUD
	preview := rawText
	preview = strings.ReplaceAll(preview, "\r\n", " ")
	preview = strings.ReplaceAll(preview, "\n", " ")
	preview = strings.Join(strings.Fields(preview), " ")
	if utf8.RuneCountInString(preview) > 80 {
		runes := []rune(preview)
		preview = string(runes[:77]) + "..."
	}

	// 3. Copy extracted text to clipboard
	copied := false
	if rawText != "" {
		copyCmd := exec.Command("wl-copy")
		copyCmd.Stdin = strings.NewReader(rawText)
		if err := copyCmd.Run(); err == nil {
			copied = true
		} else {
			log.Warn("OCR metni panoya kopyalanamadı", "err", err)
		}
	}

	log.Info("OCR işlemi başarıyla tamamlandı", "charCount", charCount, "preview", preview, "copied", copied)

	return &OCRResult{
		Text:      rawText,
		Preview:   preview,
		CharCount: charCount,
		Copied:    copied,
		Success:   true,
	}, nil
}

// StartRecording starts wf-recorder in a separate process group and initiates 1s interval progress updates.
func (m *Manager) StartRecording(geometry string) (*RecordState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	log := logger.Module("CAPTURE-RECORD")

	if m.recordState.IsRecording {
		log.Warn("Ekran kaydı zaten devam ediyor", "file", m.recordState.FilePath)
		stateCopy := m.recordState
		return &stateCopy, nil
	}

	if err := os.MkdirAll(m.recordingsDir, 0755); err != nil {
		log.Error("Ekran kaydı dizini oluşturulamadı", "dir", m.recordingsDir, "err", err)
	}

	fileName := fmt.Sprintf("recording_%s.mp4", time.Now().Format("2006-01-02_15-04-05"))
	filePath := filepath.Join(m.recordingsDir, fileName)

	var args []string
	geomTrimmed := strings.TrimSpace(geometry)
	if geomTrimmed != "" && geomTrimmed != "all" {
		args = append(args, "-g", geomTrimmed)
	} else if geomTrimmed != "all" {
		focusedMon := getFocusedMonitorName()
		if focusedMon != "" {
			args = append(args, "-o", focusedMon)
		}
	}
	args = append(args, "-f", filePath)

	cmd := exec.Command("wf-recorder", args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setpgid: true,
	}

	if err := cmd.Start(); err != nil {
		log.Error("wf-recorder başlatılamadı", "err", err)
		return nil, fmt.Errorf("wf-recorder başlatılamadı: %w", err)
	}

	m.recordCmd = cmd
	m.recordState = RecordState{
		IsRecording:     true,
		DurationSeconds: 0,
		FilePath:        filePath,
		Geometry:        geometry,
	}
	m.recordStopChan = make(chan struct{})
	m.recordTicker = time.NewTicker(1 * time.Second)

	log.Info("Ekran kaydı başlatıldı", "pid", cmd.Process.Pid, "file", filePath, "geometry", geometry)

	// Launch periodic ticker
	go m.runRecordTicker(m.recordTicker, m.recordStopChan)

	// Watch process in background
	go m.watchRecordProcess(cmd, filePath)

	stateCopy := m.recordState
	return &stateCopy, nil
}

// runRecordTicker periodically increments recording duration and calls update callbacks.
func (m *Manager) runRecordTicker(ticker *time.Ticker, stopChan chan struct{}) {
	for {
		select {
		case <-stopChan:
			return
		case <-ticker.C:
			m.mu.Lock()
			if !m.recordState.IsRecording {
				m.mu.Unlock()
				return
			}
			m.recordState.DurationSeconds++
			currentState := m.recordState
			cb := m.recordUpdateCallback
			m.mu.Unlock()

			if cb != nil {
				cb(currentState)
			}
		}
	}
}

// watchRecordProcess observes the recording process in case of unexpected termination.
func (m *Manager) watchRecordProcess(cmd *exec.Cmd, filePath string) {
	err := cmd.Wait()

	m.mu.Lock()
	if !m.recordState.IsRecording || m.recordCmd != cmd {
		m.mu.Unlock()
		return
	}

	log := logger.Module("CAPTURE-RECORD")
	log.Warn("wf-recorder beklenmedik şekilde sonlandı", "err", err)

	if m.recordTicker != nil {
		m.recordTicker.Stop()
	}
	if m.recordStopChan != nil {
		close(m.recordStopChan)
		m.recordStopChan = nil
	}

	duration := m.recordState.DurationSeconds
	m.recordState = RecordState{
		IsRecording:     false,
		DurationSeconds: 0,
	}
	m.recordCmd = nil

	updateCb := m.recordUpdateCallback
	finishCb := m.recordFinishedCallback
	m.mu.Unlock()

	if updateCb != nil {
		updateCb(RecordState{IsRecording: false, DurationSeconds: 0})
	}
	if finishCb != nil {
		finishCb(RecordFinishedPayload{
			FilePath:        filePath,
			DurationSeconds: duration,
			Success:         err == nil,
			Error: func() string {
				if err != nil {
					return err.Error()
				}
				return ""
			}(),
		})
	}
}

// StopRecording sends SIGINT to wf-recorder to ensure atomic moov atom finalization.
func (m *Manager) StopRecording() (*RecordFinishedPayload, error) {
	m.mu.Lock()
	if !m.recordState.IsRecording || m.recordCmd == nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("aktif bir ekran kaydı bulunmuyor")
	}

	log := logger.Module("CAPTURE-RECORD")
	log.Info("Ekran kaydı durduruluyor (SIGINT gönderiliyor)...", "file", m.recordState.FilePath)

	// Stop progress ticker
	if m.recordTicker != nil {
		m.recordTicker.Stop()
	}
	if m.recordStopChan != nil {
		close(m.recordStopChan)
		m.recordStopChan = nil
	}

	cmd := m.recordCmd
	filePath := m.recordState.FilePath
	duration := m.recordState.DurationSeconds

	// Reset state
	m.recordState = RecordState{
		IsRecording:     false,
		DurationSeconds: 0,
	}
	m.recordCmd = nil
	updateCb := m.recordUpdateCallback
	finishCb := m.recordFinishedCallback
	m.mu.Unlock()

	if updateCb != nil {
		updateCb(RecordState{IsRecording: false, DurationSeconds: 0})
	}

	// Send SIGINT to process group for graceful moov atom write
	var waitErr error
	if cmd != nil && cmd.Process != nil {
		if err := syscall.Kill(-cmd.Process.Pid, syscall.SIGINT); err != nil {
			_ = cmd.Process.Signal(syscall.SIGINT)
		}

		done := make(chan error, 1)
		go func() {
			done <- cmd.Wait()
		}()

		select {
		case err := <-done:
			waitErr = err
		case <-time.After(5 * time.Second):
			log.Warn("wf-recorder SIGINT sonrası 5sn içinde kapanmadı, SIGKILL gönderiliyor")
			_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
			waitErr = <-done
		}
	}

	result := &RecordFinishedPayload{
		FilePath:        filePath,
		DurationSeconds: duration,
		Success:         true,
	}
	if waitErr != nil {
		log.Info("wf-recorder tamamlandı", "waitInfo", waitErr)
	}

	if finishCb != nil {
		finishCb(*result)
	}

	log.Info("Ekran kaydı başarıyla tamamlandı", "path", filePath, "duration", duration)
	return result, nil
}

// GetRecordState returns a snapshot of the current recording state.
func (m *Manager) GetRecordState() RecordState {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.recordState
}

// OpenAnnotator launches Gradia editor with the target file or the last taken screenshot.
func (m *Manager) OpenAnnotator(filePath string) error {
	log := logger.Module("CAPTURE-ANNOTATOR")

	targetFile := strings.TrimSpace(filePath)
	if targetFile == "" {
		m.mu.RLock()
		targetFile = m.lastScreenshotPath
		m.mu.RUnlock()
	}

	if targetFile == "" {
		return fmt.Errorf("düzenlenecek görsel dosyası belirtilmedi ve kayıtlı son ekran görüntüsü yok")
	}

	if _, err := os.Stat(targetFile); err != nil {
		return fmt.Errorf("görsel dosyası bulunamadı (%s): %w", targetFile, err)
	}

	log.Info("Gradia görsel düzenleyici başlatılıyor", "file", targetFile)

	// 1. Try systemd-run --user --scope
	if systemdPath, err := exec.LookPath("systemd-run"); err == nil && systemdPath != "" {
		cmd := exec.Command(systemdPath, "--user", "--scope", "gradia", targetFile)
		cmd.Env = os.Environ()
		if err := cmd.Start(); err == nil {
			log.Info("Gradia systemd-run ile bağımsız başlatıldı", "file", targetFile)
			return nil
		}
	}

	// 2. Fallback: Detached process with Setsid
	cmd := exec.Command("gradia", targetFile)
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setsid: true,
	}
	cmd.Env = os.Environ()
	if err := cmd.Start(); err != nil {
		log.Error("Gradia başlatılamadı", "err", err)
		return fmt.Errorf("gradia başlatılamadı: %w", err)
	}

	log.Info("Gradia detached süreç olarak başlatıldı", "pid", cmd.Process.Pid)
	return nil
}

// SetRecordUpdateCallback registers a listener for ongoing recording state updates.
func (m *Manager) SetRecordUpdateCallback(cb func(state RecordState)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.recordUpdateCallback = cb
}

// SetRecordFinishedCallback registers a listener for recording completion events.
func (m *Manager) SetRecordFinishedCallback(cb func(result RecordFinishedPayload)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.recordFinishedCallback = cb
}

// Close ensures any running recording is stopped cleanly upon daemon shutdown.
func (m *Manager) Close() error {
	m.mu.Lock()
	isRec := m.recordState.IsRecording
	m.mu.Unlock()

	if isRec {
		_, _ = m.StopRecording()
	}
	return nil
}
