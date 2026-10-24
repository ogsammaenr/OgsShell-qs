package hyprland

import (
	"bufio"
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
	"ogsShell/core/logger"
)

var (
	stateLineRegex = regexp.MustCompile(`^\s*([a-zA-Z0-9_]+)\s*=\s*"([^"]*)"`)
)

type StateChangeCallback func(state *HyprState)

type Manager struct {
	mu            sync.RWMutex
	hyprDir       string
	stateFile     string
	log           *slog.Logger
	onStateChange StateChangeCallback
}

// NewManager initializes the Hyprland profile manager.
func NewManager(customHyprDir ...string) *Manager {
	dir := ""
	if len(customHyprDir) > 0 && customHyprDir[0] != "" {
		dir = customHyprDir[0]
	} else {
		home, _ := os.UserHomeDir()
		dir = filepath.Join(home, ".config", "hypr")
	}

	return &Manager{
		hyprDir:   dir,
		stateFile: filepath.Join(dir, "lua", "active_state.lua"),
		log:       logger.Module("HYPRLAND"),
	}
}

// SetOnStateChange registers a callback triggered when active profiles change.
func (m *Manager) SetOnStateChange(cb StateChangeCallback) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.onStateChange = cb
}

// GetState reads the active profile state and scans available profiles.
func (m *Manager) GetState() (*HyprState, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	active, err := m.readActiveProfiles()
	if err != nil {
		m.log.Warn("Aktif profiller okunamadı, varsayılanlar kullanılıyor", "err", err)
	}

	available := m.scanAvailableProfiles()

	return &HyprState{
		Active:    active,
		Available: available,
	}, nil
}

func (m *Manager) readActiveProfiles() (HyprActiveProfiles, error) {
	active := HyprActiveProfiles{}
	f, err := os.Open(m.stateFile)
	if err != nil {
		return active, err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		matches := stateLineRegex.FindStringSubmatch(line)
		if len(matches) == 3 {
			key, val := matches[1], matches[2]
			switch key {
			case "monitor_profile":
				active.MonitorProfile = val
			case "enviroments_profile":
				active.EnvironmentsProfile = val
			case "theme_profile":
				active.ThemeProfile = val
			case "border_profile":
				active.BorderProfile = val
			case "animation_profile":
				active.AnimationProfile = val
			case "workspace_animation":
				active.WorkspaceAnimation = val
			case "window_animation":
				active.WindowAnimation = val
			case "layer_animation":
				active.LayerAnimation = val
			}
		}
	}

	return active, scanner.Err()
}

func (m *Manager) scanAvailableProfiles() HyprAvailableProfiles {
	return HyprAvailableProfiles{
		Borders:      m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "borders"), nil),
		Animations:   m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "animations"), map[string]bool{"curves": true, "custom_curves": true}),
		Workspaces:   m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "animations", "workspaces"), nil),
		Windows:      m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "animations", "windows"), nil),
		Layers:       m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "animations", "layers"), nil),
		Themes:       m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "themes"), nil),
		Monitors:     m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "monitors"), nil),
		Environments: m.listLuaFiles(filepath.Join(m.hyprDir, "lua", "profiles", "enviroments"), nil),
	}
}

func (m *Manager) listLuaFiles(dir string, exclude map[string]bool) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return []string{}
	}

	names := make([]string, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".lua") {
			continue
		}
		base := strings.TrimSuffix(entry.Name(), ".lua")
		if exclude != nil && exclude[base] {
			continue
		}
		names = append(names, base)
	}

	sort.Strings(names)
	return names
}

// SetProfile updates a profile key in active_state.lua and reloads Hyprland.
func (m *Manager) SetProfile(category, name string) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	key, targetDir, err := m.resolveCategory(category)
	if err != nil {
		return nil, err
	}

	// Validate target profile file exists
	targetFile := filepath.Join(targetDir, name+".lua")
	if _, err := os.Stat(targetFile); err != nil {
		return nil, fmt.Errorf("profil dosyası bulunamadı: %s (%s)", name, targetFile)
	}

	// Update active_state.lua atomically
	if err := m.updateStateFileKey(key, name); err != nil {
		return nil, fmt.Errorf("active_state.lua güncellenemedi: %w", err)
	}

	// Reload Hyprland
	_ = exec.Command("hyprctl", "reload").Run()
	m.log.Info("Hyprland profili güncellendi", "kategori", category, "profil", name)

	state := &HyprState{
		Active:    m.readActiveProfilesDirect(),
		Available: m.scanAvailableProfiles(),
	}

	if m.onStateChange != nil {
		m.onStateChange(state)
	}

	return state, nil
}

func (m *Manager) resolveCategory(category string) (key string, dir string, err error) {
	c := strings.ToLower(strings.TrimSpace(category))
	switch c {
	case "border", "borders", "decoration":
		return "border_profile", filepath.Join(m.hyprDir, "lua", "profiles", "borders"), nil
	case "animation", "animations", "preset":
		return "animation_profile", filepath.Join(m.hyprDir, "lua", "profiles", "animations"), nil
	case "workspace", "workspaces", "ws":
		return "workspace_animation", filepath.Join(m.hyprDir, "lua", "profiles", "animations", "workspaces"), nil
	case "window", "windows", "win":
		return "window_animation", filepath.Join(m.hyprDir, "lua", "profiles", "animations", "windows"), nil
	case "layer", "layers":
		return "layer_animation", filepath.Join(m.hyprDir, "lua", "profiles", "animations", "layers"), nil
	case "theme", "themes":
		return "theme_profile", filepath.Join(m.hyprDir, "lua", "profiles", "themes"), nil
	case "monitor", "monitors":
		return "monitor_profile", filepath.Join(m.hyprDir, "lua", "profiles", "monitors"), nil
	case "enviroment", "environment", "enviroments", "environments":
		return "enviroments_profile", filepath.Join(m.hyprDir, "lua", "profiles", "enviroments"), nil
	default:
		return "", "", fmt.Errorf("bilinmeyen profil kategorisi: %s", category)
	}
}

func (m *Manager) updateStateFileKey(key, value string) error {
	content, err := os.ReadFile(m.stateFile)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	found := false
	pattern := regexp.MustCompile(fmt.Sprintf(`^(\s*)%s\s*=\s*"[^"]*"`, regexp.QuoteMeta(key)))

	for i, line := range lines {
		if pattern.MatchString(line) {
			lines[i] = pattern.ReplaceAllString(line, fmt.Sprintf("${1}%s = \"%s\"", key, value))
			found = true
			break
		}
	}

	if !found {
		// Insert before the closing brace '}'
		inserted := false
		for i := len(lines) - 1; i >= 0; i-- {
			if strings.TrimSpace(lines[i]) == "}" {
				lines = append(lines[:i], append([]string{fmt.Sprintf("\t%s = \"%s\",", key, value)}, lines[i:]...)...)
				inserted = true
				break
			}
		}
		if !inserted {
			lines = append(lines, fmt.Sprintf("\t%s = \"%s\",", key, value))
		}
	}

	newContent := strings.Join(lines, "\n")
	tmpFile := fmt.Sprintf("%s.tmp", m.stateFile)
	if err := os.WriteFile(tmpFile, []byte(newContent), 0644); err != nil {
		return err
	}

	return os.Rename(tmpFile, m.stateFile)
}

func (m *Manager) readActiveProfilesDirect() HyprActiveProfiles {
	act, _ := m.readActiveProfiles()
	return act
}

// PreviewEval executes arbitrary Lua code via hyprctl eval for 0ms sub-millisecond preview.
func (m *Manager) PreviewEval(luaCode string) (string, error) {
	cmd := exec.Command("hyprctl", "eval", luaCode)
	out, err := cmd.CombinedOutput()
	outputStr := strings.TrimSpace(string(out))
	if err != nil {
		return outputStr, fmt.Errorf("hyprctl eval hatası: %s (%w)", outputStr, err)
	}
	return outputStr, nil
}

// SaveCustomCurve saves a cubic bezier curve to custom_curves.lua and loads it into runtime.
func (m *Manager) SaveCustomCurve(name string, points [][2]float64) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	name = strings.TrimSpace(name)
	if name == "" {
		return fmt.Errorf("eğri adı boş olamaz")
	}
	if len(points) < 2 {
		return fmt.Errorf("bezier eğrisi en az 2 kontrol noktası gerektirir")
	}

	p1, p2 := points[0], points[1]
	curveLine := fmt.Sprintf("hl.curve(\"%s\", { type = \"bezier\", points = { { %.3f, %.3f }, { %.3f, %.3f } } })",
		name, p1[0], p1[1], p2[0], p2[1])

	curvesFile := filepath.Join(m.hyprDir, "lua", "profiles", "animations", "custom_curves.lua")
	dir := filepath.Dir(curvesFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	// Read existing or create header
	var lines []string
	if data, err := os.ReadFile(curvesFile); err == nil {
		lines = strings.Split(string(data), "\n")
	} else {
		lines = []string{
			"-- ==========================================================",
			"-- Dinamik Kullanıcı Bezier Eğrileri (custom_curves.lua)",
			"-- ogsShell Ayarlar Uygulaması tarafından otomatik üretilir.",
			"-- ==========================================================",
			"",
		}
	}

	// Replace existing curve with same name or append
	curvePattern := regexp.MustCompile(fmt.Sprintf(`^hl\.curve\("%s",`, regexp.QuoteMeta(name)))
	found := false
	for i, l := range lines {
		if curvePattern.MatchString(strings.TrimSpace(l)) {
			lines[i] = curveLine
			found = true
			break
		}
	}
	if !found {
		lines = append(lines, curveLine)
	}

	// Write atomically
	tmpFile := fmt.Sprintf("%s.tmp", curvesFile)
	if err := os.WriteFile(tmpFile, []byte(strings.Join(lines, "\n")), 0644); err != nil {
		return err
	}
	if err := os.Rename(tmpFile, curvesFile); err != nil {
		return err
	}

	// Immediately register in running Hyprland session
	_, _ = m.PreviewEval(curveLine)
	m.log.Info("Özel Bezier eğrisi kaydedildi", "isim", name, "p1", p1, "p2", p2)

	return nil
}

// SaveCustomBorder writes a custom border profile and activates it.
func (m *Manager) SaveCustomBorder(p SaveCustomBorderPayload) (*HyprState, error) {
	name := strings.TrimSpace(p.Name)
	if name == "" {
		return nil, fmt.Errorf("profil adı boş olamaz")
	}

	safeName := regexp.MustCompile(`[^a-zA-Z0-9_-]`).ReplaceAllString(name, "_")
	if !strings.HasPrefix(safeName, "custom_") {
		safeName = "custom_" + safeName
	}

	borderDir := filepath.Join(m.hyprDir, "lua", "profiles", "borders")
	if err := os.MkdirAll(borderDir, 0755); err != nil {
		return nil, err
	}

	filePath := filepath.Join(borderDir, safeName+".lua")

	shadowColor := p.ShadowColor
	if shadowColor == "" {
		shadowColor = "rgba(00000077)"
	}

	roundingPower := p.RoundingPower
	if roundingPower <= 0 {
		roundingPower = 4.0
	}

	activeOpacity := p.ActiveOpacity
	if activeOpacity <= 0 {
		activeOpacity = 1.0
	}
	inactiveOpacity := p.InactiveOpacity
	if inactiveOpacity <= 0 {
		inactiveOpacity = 0.94
	}

	content := fmt.Sprintf(`-- ==========================================================
-- Özel Kenarlık Profili: %s
-- ogsShell Ayarlar Uygulaması tarafından üretildi.
-- ==========================================================

hl.config({
	general = {
		border_size = %d,
		gaps_in = %d,
		gaps_out = %d,
	},

	decoration = {
		rounding = %d,
		rounding_power = %.1f,

		active_opacity = %.2f,
		inactive_opacity = %.2f,

		shadow = {
			enabled = %t,
			range = %d,
			render_power = %d,
			offset = { %d, %d },
			color = "%s",
			color_inactive = "rgba(00000044)",
		},

		dim_inactive = %t,
		dim_strength = %.2f,
	},
})
`, safeName, p.BorderSize, p.GapsIn, p.GapsOut, p.Rounding, roundingPower,
		activeOpacity, inactiveOpacity, p.ShadowEnabled, p.ShadowRange,
		p.ShadowPower, p.ShadowOffset[0], p.ShadowOffset[1], shadowColor,
		p.DimInactive, p.DimStrength)

	tmpFile := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpFile, []byte(content), 0644); err != nil {
		return nil, err
	}
	if err := os.Rename(tmpFile, filePath); err != nil {
		return nil, err
	}

	return m.SetProfile("border", safeName)
}

// Watch continuously monitors active_state.lua for external changes and dispatches updates.
func (m *Manager) Watch(ctx context.Context) {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		m.log.Warn("fsnotify Hyprland watcher başlatılamadı", "err", err)
		return
	}
	defer watcher.Close()

	watchDir := filepath.Dir(m.stateFile)
	if err := watcher.Add(watchDir); err != nil {
		m.log.Warn("Hyprland lua dizini izlenemiyor", "dir", watchDir, "err", err)
		return
	}

	m.log.Info("Hyprland konfigürasyon izleyicisi devrede", "dizin", watchDir)

	var debounceTimer *time.Timer
	debounceDur := 150 * time.Millisecond

	for {
		select {
		case <-ctx.Done():
			return
		case event, ok := <-watcher.Events:
			if !ok {
				return
			}
			if filepath.Base(event.Name) == "active_state.lua" && (event.Has(fsnotify.Write) || event.Has(fsnotify.Create)) {
				if debounceTimer != nil {
					debounceTimer.Stop()
				}
				debounceTimer = time.AfterFunc(debounceDur, func() {
					state, err := m.GetState()
					if err == nil && m.onStateChange != nil {
						m.onStateChange(state)
					}
				})
			}
		case err, ok := <-watcher.Errors:
			if !ok {
				return
			}
			m.log.Warn("Hyprland watcher hatası", "err", err)
		}
	}
}
