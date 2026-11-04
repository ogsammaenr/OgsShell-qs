package keyring

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"time"

	"ogsShell/core/logger"
)

type PromptRequestedCallback func(payload PromptRequestedPayload)
type PromptDismissedCallback func(payload PromptDismissedPayload)

type Manager struct {
	mu                sync.RWMutex
	binaryPath        string
	cmd               *exec.Cmd
	stdin             io.WriteCloser
	isRunning         bool
	onPromptRequested PromptRequestedCallback
	onPromptDismissed PromptDismissedCallback
	logger            *slog.Logger
}

func NewManager() *Manager {
	return &Manager{
		logger: logger.Module("keyring"),
	}
}

func (m *Manager) SetOnPromptRequested(cb PromptRequestedCallback) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.onPromptRequested = cb
}

func (m *Manager) SetOnPromptDismissed(cb PromptDismissedCallback) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.onPromptDismissed = cb
}

func (m *Manager) resolveBinaryPath() string {
	candidates := []string{
		"bin/ogsshell-keyring-prompter",
		"../bin/ogsshell-keyring-prompter",
		"../../bin/ogsshell-keyring-prompter",
	}

	// Try relative to executable
	if exe, err := os.Executable(); err == nil {
		exeDir := filepath.Dir(exe)
		candidates = append(candidates,
			filepath.Join(exeDir, "ogsshell-keyring-prompter"),
			filepath.Join(exeDir, "..", "bin", "ogsshell-keyring-prompter"),
		)
	}

	// Try XDG config path
	if configHome := os.Getenv("XDG_CONFIG_HOME"); configHome != "" {
		candidates = append(candidates, filepath.Join(configHome, "ogsShell", "bin", "ogsshell-keyring-prompter"))
	}
	if home := os.Getenv("HOME"); home != "" {
		candidates = append(candidates, filepath.Join(home, ".config", "ogsShell", "bin", "ogsshell-keyring-prompter"))
	}

	for _, p := range candidates {
		if abs, err := filepath.Abs(p); err == nil {
			if info, err := os.Stat(abs); err == nil && !info.IsDir() && (info.Mode()&0111 != 0) {
				return abs
			}
		}
	}

	if lp, err := exec.LookPath("ogsshell-keyring-prompter"); err == nil {
		return lp
	}

	return ""
}

// Watch starts the prompter child process and monitors its lifecycle until ctx is cancelled.
func (m *Manager) Watch(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			m.Stop()
			return
		default:
		}

		binPath := m.resolveBinaryPath()
		if binPath == "" {
			m.logger.Warn("Keyring prompter binary bulunamadı, 10 saniye sonra tekrar denenecek (bin/ogsshell-keyring-prompter)")
			select {
			case <-ctx.Done():
				return
			case <-time.After(10 * time.Second):
				continue
			}
		}

		m.mu.Lock()
		m.binaryPath = binPath
		m.mu.Unlock()

		if err := m.runProcess(ctx, binPath); err != nil {
			m.logger.Warn("Keyring prompter süreci sonlandı", "err", err)
		}

		select {
		case <-ctx.Done():
			return
		case <-time.After(2 * time.Second):
			m.logger.Info("Keyring prompter süreci yeniden başlatılıyor...")
		}
	}
}

func (m *Manager) runProcess(ctx context.Context, binPath string) error {
	cmd := exec.CommandContext(ctx, binPath)
	cmd.Stderr = os.Stderr

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return fmt.Errorf("stdin pipe açılamadı: %w", err)
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		stdin.Close()
		return fmt.Errorf("stdout pipe açılamadı: %w", err)
	}

	if err := cmd.Start(); err != nil {
		stdin.Close()
		stdout.Close()
		return fmt.Errorf("prompter başlatılamadı: %w", err)
	}

	m.mu.Lock()
	m.cmd = cmd
	m.stdin = stdin
	m.isRunning = true
	m.mu.Unlock()

	m.logger.Info("Keyring prompter ajanı başlatıldı (D-Bus listener aktif)", "pid", cmd.Process.Pid, "path", binPath)

	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		line := scanner.Bytes()
		if len(line) == 0 {
			continue
		}

		var generic struct {
			Type    string          `json:"type"`
			Name    string          `json:"name,omitempty"`
			Payload json.RawMessage `json:"payload,omitempty"`
		}

		if err := json.Unmarshal(line, &generic); err != nil {
			continue
		}

		switch generic.Type {
		case "keyring_prompt_requested":
			var payload PromptRequestedPayload
			if err := json.Unmarshal(generic.Payload, &payload); err == nil {
				m.mu.RLock()
				cb := m.onPromptRequested
				m.mu.RUnlock()
				if cb != nil {
					cb(payload)
				}
			}

		case "keyring_prompt_dismissed":
			var payload PromptDismissedPayload
			if err := json.Unmarshal(generic.Payload, &payload); err == nil {
				m.mu.RLock()
				cb := m.onPromptDismissed
				m.mu.RUnlock()
				if cb != nil {
					cb(payload)
				}
			}

		case "keyring_name_acquired":
			m.logger.Info("D-Bus arayüzü başarıyla sahiplenildi", "name", generic.Name)

		case "keyring_bus_acquired":
			m.logger.Debug("D-Bus bağlantısı kuruldu", "name", generic.Name)
		}
	}

	waitErr := cmd.Wait()

	m.mu.Lock()
	m.isRunning = false
	m.stdin = nil
	m.cmd = nil
	m.mu.Unlock()

	return waitErr
}

// SubmitPassword sends the submitted password response to the C prompter.
func (m *Manager) SubmitPassword(id, password string, remember bool) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.isRunning || m.stdin == nil {
		return fmt.Errorf("keyring prompter ajanı çalışmıyor")
	}

	req := map[string]interface{}{
		"name": "keyring_submit_response",
		"args": map[string]interface{}{
			"id":       id,
			"password": password,
			"remember": remember,
		},
	}

	bytes, err := json.Marshal(req)
	if err != nil {
		return err
	}

	bytes = append(bytes, '\n')
	_, err = m.stdin.Write(bytes)
	return err
}

// ConfirmAction sends confirmation/cancellation response for confirm-type prompts.
func (m *Manager) ConfirmAction(id string, confirmed, remember bool) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.isRunning || m.stdin == nil {
		return fmt.Errorf("keyring prompter ajanı çalışmıyor")
	}

	req := map[string]interface{}{
		"name": "keyring_confirm_response",
		"args": map[string]interface{}{
			"id":        id,
			"confirmed": confirmed,
			"remember":  remember,
		},
	}

	bytes, err := json.Marshal(req)
	if err != nil {
		return err
	}

	bytes = append(bytes, '\n')
	_, err = m.stdin.Write(bytes)
	return err
}

// CancelPrompt cancels the active prompt.
func (m *Manager) CancelPrompt(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.isRunning || m.stdin == nil {
		return fmt.Errorf("keyring prompter ajanı çalışmıyor")
	}

	req := map[string]interface{}{
		"name": "keyring_cancel_response",
		"args": map[string]interface{}{
			"id": id,
		},
	}

	bytes, err := json.Marshal(req)
	if err != nil {
		return err
	}

	bytes = append(bytes, '\n')
	_, err = m.stdin.Write(bytes)
	return err
}

// Stop cleanly terminates the prompter process.
func (m *Manager) Stop() {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.stdin != nil {
		_ = m.stdin.Close()
		m.stdin = nil
	}

	if m.cmd != nil && m.cmd.Process != nil {
		_ = m.cmd.Process.Kill()
		m.cmd = nil
	}
	m.isRunning = false
}
