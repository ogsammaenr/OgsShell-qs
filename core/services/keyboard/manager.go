package keyboard

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"ogsShell/core/logger"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// KeyboardManager defines the contract for Hyprland keyboard layout management.
type KeyboardManager interface {
	// GetState returns the active synthesized keyboard layout state.
	GetState() (*KeyboardState, error)

	// SwitchLayout cycles or sets the active layout ("next", "prev", or index "0", "1").
	SwitchLayout(target string, device string) (*KeyboardState, error)

	// SetConfiguredLayouts updates active system layouts and persists preferences.
	SetConfiguredLayouts(layouts []string, variants []string) (*KeyboardState, error)

	// GetAvailableLayouts returns all available XKB layouts.
	GetAvailableLayouts() []AvailableLayout

	// Lifecycle
	Start(ctx context.Context)
	Close() error
	SetUpdateCallback(cb func(state *KeyboardState))
}

// DefaultKeyboardManager is the production implementation.
type DefaultKeyboardManager struct {
	configPath string
	log        *slog.Logger

	mu         sync.RWMutex
	lastState  *KeyboardState
	updateCb   func(state *KeyboardState)
	cancelLoop context.CancelFunc
	closeOnce  sync.Once
}

// NewDefaultKeyboardManager creates a new KeyboardManager instance.
func NewDefaultKeyboardManager(configPath ...string) (*DefaultKeyboardManager, error) {
	path := GetKeyboardConfigPath()
	if len(configPath) > 0 && configPath[0] != "" {
		path = configPath[0]
	}

	mgr := &DefaultKeyboardManager{
		configPath: path,
		log:        logger.Module("KEYBOARD"),
	}

	return mgr, nil
}

// DeduceShortCode calculates a 2-3 letter badge (e.g. "TR", "EN", "DE") from layout code or keymap name.
func DeduceShortCode(layoutCode string, keymapName string) string {
	code := strings.ToLower(strings.TrimSpace(layoutCode))
	keymap := strings.ToLower(strings.TrimSpace(keymapName))

	if code == "tr" || strings.Contains(keymap, "turkish") {
		return "TR"
	}
	if code == "us" || code == "gb" || strings.Contains(keymap, "english") {
		return "EN"
	}
	if code == "de" || strings.Contains(keymap, "german") {
		return "DE"
	}
	if code == "fr" || strings.Contains(keymap, "french") {
		return "FR"
	}
	if code == "es" || strings.Contains(keymap, "spanish") {
		return "ES"
	}
	if code == "it" || strings.Contains(keymap, "italian") {
		return "IT"
	}
	if code == "ru" || strings.Contains(keymap, "russian") {
		return "RU"
	}
	if code == "jp" || strings.Contains(keymap, "japanese") {
		return "JP"
	}
	if code == "az" || strings.Contains(keymap, "azerbaijani") {
		return "AZ"
	}

	if len(code) >= 2 {
		return strings.ToUpper(code[:2])
	}
	if len(keymap) >= 2 {
		return strings.ToUpper(keymap[:2])
	}
	return "KB"
}

// ParseHyprlandDevicesJSON parses `hyprctl devices -j` and produces a clean KeyboardState.
func ParseHyprlandDevicesJSON(data []byte) (*KeyboardState, error) {
	var devJSON HyprlandDeviceJSON
	if err := json.Unmarshal(data, &devJSON); err != nil {
		return nil, fmt.Errorf("hyprctl devices JSON parse hatası: %w", err)
	}

	if len(devJSON.Keyboards) == 0 {
		return &KeyboardState{
			DeviceName:         "default",
			CurrentLayoutIndex: 0,
			CurrentKeymap:      "Turkish",
			CurrentShortCode:   "TR",
			CurrentLayoutCode:  "tr",
			ConfiguredLayouts:  []string{"tr"},
		}, nil
	}

	// 1. Locate primary/main keyboard
	var mainKb *HyprlandKeyboardJSON
	for i := range devJSON.Keyboards {
		if devJSON.Keyboards[i].Main {
			mainKb = &devJSON.Keyboards[i]
			break
		}
	}

	// 2. If no device has main: true, find the first with non-empty keymap
	if mainKb == nil {
		for i := range devJSON.Keyboards {
			if devJSON.Keyboards[i].ActiveKeymap != "" {
				mainKb = &devJSON.Keyboards[i]
				break
			}
		}
	}

	if mainKb == nil {
		mainKb = &devJSON.Keyboards[0]
	}

	// Parse configured layouts and variants
	var layouts []string
	if mainKb.Layout != "" {
		parts := strings.Split(mainKb.Layout, ",")
		for _, p := range parts {
			trimmed := strings.TrimSpace(p)
			if trimmed != "" {
				layouts = append(layouts, trimmed)
			}
		}
	}
	if len(layouts) == 0 {
		layouts = []string{"tr"}
	}

	var variants []string
	if mainKb.Variant != "" {
		parts := strings.Split(mainKb.Variant, ",")
		for _, p := range parts {
			variants = append(variants, strings.TrimSpace(p))
		}
	}

	currentCode := layouts[0]
	if mainKb.ActiveLayoutIndex >= 0 && mainKb.ActiveLayoutIndex < len(layouts) {
		currentCode = layouts[mainKb.ActiveLayoutIndex]
	}

	shortCode := DeduceShortCode(currentCode, mainKb.ActiveKeymap)

	return &KeyboardState{
		DeviceName:         mainKb.Name,
		CurrentLayoutIndex: mainKb.ActiveLayoutIndex,
		CurrentKeymap:      mainKb.ActiveKeymap,
		CurrentShortCode:   shortCode,
		CurrentLayoutCode:  currentCode,
		ConfiguredLayouts:  layouts,
		ConfiguredVariants: variants,
	}, nil
}

// GetState queries Hyprland and returns the current KeyboardState.
func (m *DefaultKeyboardManager) GetState() (*KeyboardState, error) {
	cmd := exec.Command("hyprctl", "devices", "-j")
	var out bytes.Buffer
	cmd.Stdout = &out

	if err := cmd.Run(); err != nil {
		m.log.Warn("hyprctl devices -j başarısız, son bilinen durum dönülüyor", "err", err)
		m.mu.RLock()
		defer m.mu.RUnlock()
		if m.lastState != nil {
			return m.lastState, nil
		}
		return &KeyboardState{
			DeviceName:        "default",
			CurrentKeymap:     "Turkish",
			CurrentShortCode:  "TR",
			CurrentLayoutCode: "tr",
			ConfiguredLayouts: []string{"tr"},
		}, nil
	}

	state, err := ParseHyprlandDevicesJSON(out.Bytes())
	if err != nil {
		return nil, err
	}

	m.mu.Lock()
	m.lastState = state
	m.mu.Unlock()

	return state, nil
}

// SwitchLayout cycles or selects a layout in Hyprland.
func (m *DefaultKeyboardManager) SwitchLayout(target string, device string) (*KeyboardState, error) {
	if target == "" {
		target = "next"
	}
	if device == "" {
		device = "all"
	}

	cmd := exec.Command("hyprctl", "switchxkblayout", device, target)
	var errOut bytes.Buffer
	cmd.Stderr = &errOut

	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("hyprctl switchxkblayout hatası: %s: %w", errOut.String(), err)
	}

	m.log.Info("Klavye düzeni değiştirildi", "target", target, "device", device)

	// Fetch updated state
	state, err := m.GetState()
	if err == nil && m.updateCb != nil {
		go m.updateCb(state)
	}

	return state, err
}

// SetConfiguredLayouts configures active layouts at runtime and saves them to disk.
func (m *DefaultKeyboardManager) SetConfiguredLayouts(layouts []string, variants []string) (*KeyboardState, error) {
	if len(layouts) == 0 {
		return nil, fmt.Errorf("en az bir klavye düzeni belirtilmelidir")
	}

	layoutStr := strings.Join(layouts, ",")
	variantStr := strings.Join(variants, ",")

	// 1. Apply to running Hyprland session
	cmdLayout := exec.Command("hyprctl", "keyword", "input:kb_layout", layoutStr)
	if err := cmdLayout.Run(); err != nil {
		m.log.Warn("hyprctl keyword input:kb_layout başarısız", "err", err)
	}

	if variantStr != "" {
		cmdVariant := exec.Command("hyprctl", "keyword", "input:kb_variant", variantStr)
		_ = cmdVariant.Run()
	}

	// 2. Persist to disk
	cfg := &UserKeyboardConfig{
		Layouts:  layouts,
		Variants: variants,
	}
	if err := SaveConfig(m.configPath, cfg); err != nil {
		m.log.Error("Klavye konfigürasyonu diske kaydedilemedi", "err", err)
	}

	m.log.Info("Klavye düzenleri yapılandırıldı", "layouts", layoutStr, "variants", variantStr)

	// 3. Fetch and broadcast updated state
	state, err := m.GetState()
	if err == nil && m.updateCb != nil {
		go m.updateCb(state)
	}

	return state, err
}

// GetAvailableLayouts returns all XKB layout definitions.
func (m *DefaultKeyboardManager) GetAvailableLayouts() []AvailableLayout {
	return ParseXKBLayouts()
}

// Start begins listening to Hyprland's .socket2.sock for layout change events.
func (m *DefaultKeyboardManager) Start(parentCtx context.Context) {
	ctx, cancel := context.WithCancel(parentCtx)
	m.cancelLoop = cancel

	sig := os.Getenv("HYPRLAND_INSTANCE_SIGNATURE")
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		runtimeDir = "/run/user/1000"
	}

	socketPath := filepath.Join(runtimeDir, "hypr", sig, ".socket2.sock")

	m.log.Info("Hyprland klavye olay dinleyicisi başlatılıyor", "socket", socketPath)

	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			default:
			}

			conn, err := net.Dial("unix", socketPath)
			if err != nil {
				// Hyprland socket not ready or not running, retry after 3s
				select {
				case <-ctx.Done():
					return
				case <-time.After(3 * time.Second):
					continue
				}
			}

			scanner := bufio.NewScanner(conn)
			for scanner.Scan() {
				select {
				case <-ctx.Done():
					_ = conn.Close()
					return
				default:
				}

				line := scanner.Text()
				if strings.HasPrefix(line, "activelayout>>") {
					m.log.Info("Hyprland activelayout olayı alındı", "event", line)
					state, err := m.GetState()
					if err == nil && m.updateCb != nil {
						m.updateCb(state)
					}
				}
			}

			_ = conn.Close()
			time.Sleep(1 * time.Second)
		}
	}()
}

// Close terminates active socket connections.
func (m *DefaultKeyboardManager) Close() error {
	m.closeOnce.Do(func() {
		if m.cancelLoop != nil {
			m.cancelLoop()
		}
		m.log.Info("Klavye yöneticisi kapatıldı")
	})
	return nil
}

func (m *DefaultKeyboardManager) SetUpdateCallback(cb func(state *KeyboardState)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCb = cb
}
