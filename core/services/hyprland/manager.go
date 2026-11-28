package hyprland

import (
	"bufio"
	"context"
	"encoding/json"
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
	curveNameRegex = regexp.MustCompile(`(?:hl\.)?curve\(\s*"([^"]+)"`)
)

type StateChangeCallback func(state *HyprState)

type ThemeColorsProvider func() (accentHex string, surfaceHex string)

type Manager struct {
	mu            sync.RWMutex
	hyprDir       string
	stateFile     string
	configFile    string
	log           *slog.Logger
	onStateChange StateChangeCallback
	themeColorsFn ThemeColorsProvider
}

// NewManager initializes the Hyprland profile & unified config manager.
func NewManager(customHyprDir ...string) *Manager {
	dir := ""
	cfgFile := ""
	if len(customHyprDir) > 0 && customHyprDir[0] != "" {
		dir = customHyprDir[0]
		cfgFile = filepath.Join(dir, "hyprland_config.json")
	} else {
		home, _ := os.UserHomeDir()
		dir = filepath.Join(home, ".config", "hypr")
		xdg := strings.TrimSpace(os.Getenv("XDG_CONFIG_HOME"))
		if xdg == "" {
			xdg = filepath.Join(home, ".config")
		}
		cfgFile = filepath.Join(xdg, "ogsShell", "hyprland_config.json")
	}

	m := &Manager{
		hyprDir:    dir,
		stateFile:  filepath.Join(dir, "lua", "active_state.lua"),
		configFile: cfgFile,
		log:        logger.Module("HYPRLAND"),
	}

	// Ensure initial config & generated Lua files exist cleanly on disk
	m.ensureUnifiedFilesExist()
	return m
}

func (m *Manager) ensureUnifiedFilesExist() {
	cfg := m.loadUnifiedConfig()
	appPath := filepath.Join(m.hyprDir, "lua", "generated_appearance.lua")
	animPath := filepath.Join(m.hyprDir, "lua", "generated_animations.lua")
	if _, err := os.Stat(appPath); os.IsNotExist(err) {
		_ = m.writeGeneratedAppearanceLua(cfg)
	}
	if _, err := os.Stat(animPath); os.IsNotExist(err) {
		_ = m.writeGeneratedAnimationsLua(cfg)
	}
}

// SetOnStateChange registers a callback triggered when state changes.
func (m *Manager) SetOnStateChange(cb StateChangeCallback) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.onStateChange = cb
}

// SetThemeColorsProvider registers a callback returning active theme (accent, surface) hex colors.
func (m *Manager) SetThemeColorsProvider(fn ThemeColorsProvider) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.themeColorsFn = fn
}

// RefreshThemeBorderColors regenerates generated_appearance.lua when border_color_mode is "theme".
func (m *Manager) RefreshThemeBorderColors() {
	m.mu.Lock()
	defer m.mu.Unlock()
	cfg := m.loadUnifiedConfig()
	if strings.EqualFold(strings.TrimSpace(cfg.Appearance.BorderColorMode), "custom") {
		return
	}
	_ = m.writeGeneratedAppearanceLua(cfg)
}

// GetState returns the combined legacy profiles + unified config + presets + curves.
func (m *Manager) GetState() (*HyprState, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.buildStateLocked(), nil
}

func (m *Manager) buildStateLocked() *HyprState {
	active, err := m.readActiveProfiles()
	if err != nil {
		m.log.Warn("Aktif profiller okunamadı, varsayılanlar kullanılıyor", "err", err)
	}
	cfg := m.loadUnifiedConfig()

	appPresets := append(BuiltinAppearancePresets(), cfg.CustomAppearancePresets...)
	animPresets := append(BuiltinAnimationPresets(), cfg.CustomAnimationPresets...)

	return &HyprState{
		Active:            active,
		Available:         m.scanAvailableProfiles(),
		Config:            cfg,
		AppearancePresets: appPresets,
		AnimationPresets:  animPresets,
		AvailableCurves:   m.scanAvailableCurves(),
	}
}

func (m *Manager) emitStateLocked(state *HyprState) {
	if m.onStateChange != nil && state != nil {
		m.onStateChange(state)
	}
}

// =========================================================================
// Unified JSON Config Persistence ($XDG_CONFIG_HOME/ogsShell/hyprland_config.json)
// =========================================================================

func (m *Manager) loadUnifiedConfig() HyprUnifiedConfig {
	cfg := DefaultUnifiedConfig()
	data, err := os.ReadFile(m.configFile)
	if err != nil {
		return cfg
	}
	if err := json.Unmarshal(data, &cfg); err != nil {
		m.log.Warn("hyprland_config.json ayrıştırılamadı, varsayılan kullanılıyor", "err", err)
		return DefaultUnifiedConfig()
	}
	// Backfill zero-value border color & nested blur fields safely if older JSON loaded
	if cfg.Appearance.BorderColorMode == "" {
		cfg.Appearance.BorderColorMode = "theme"
	}
	if cfg.Appearance.ActiveBorderColor == "" {
		cfg.Appearance.ActiveBorderColor = "89b4faff"
	}
	if cfg.Appearance.InactiveBorderColor == "" {
		cfg.Appearance.InactiveBorderColor = "313244cc"
	}
	if cfg.Appearance.BorderGradientAngle < 0 || cfg.Appearance.BorderGradientAngle > 360 {
		cfg.Appearance.BorderGradientAngle = 45
	}
	if cfg.Appearance.Blur.Variant == "" {
		cfg.Appearance.Blur.Variant = "kawase"
	}
	if cfg.Appearance.Blur.Glass.Size <= 0 {
		cfg.Appearance.Blur.Glass = DefaultBlurConfig().Glass
	}
	if cfg.Appearance.Blur.Acrylic.Bulb <= 0 {
		cfg.Appearance.Blur.Acrylic = DefaultBlurConfig().Acrylic
	}
	if cfg.Appearance.Blur.Aurora.Color1 == "" {
		cfg.Appearance.Blur.Aurora = DefaultBlurConfig().Aurora
	}
	if cfg.Appearance.Blur.Ripple.Radius <= 0 {
		cfg.Appearance.Blur.Ripple = DefaultBlurConfig().Ripple
	}
	if cfg.Appearance.Blur.Water.Radius <= 0 {
		cfg.Appearance.Blur.Water = DefaultBlurConfig().Water
	}
	if cfg.Appearance.Blur.FluidJar.Color == "" {
		cfg.Appearance.Blur.FluidJar = DefaultBlurConfig().FluidJar
	}
	if cfg.CustomAppearancePresets == nil {
		cfg.CustomAppearancePresets = []AppearancePreset{}
	}
	if cfg.CustomAnimationPresets == nil {
		cfg.CustomAnimationPresets = []AnimationPreset{}
	}
	return cfg
}

func (m *Manager) saveUnifiedConfig(cfg HyprUnifiedConfig) error {
	if err := os.MkdirAll(filepath.Dir(m.configFile), 0755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	tmp := m.configFile + ".tmp"
	if err := os.WriteFile(tmp, data, 0644); err != nil {
		return err
	}
	return os.Rename(tmp, m.configFile)
}

// =========================================================================
// Lua Code Generators (generated_appearance.lua & generated_animations.lua)
// =========================================================================

func sanitizeHex8(v, fallback string) string {
	clean := strings.TrimPrefix(strings.TrimSpace(v), "#")
	clean = strings.TrimPrefix(clean, "0x")
	if len(clean) == 6 {
		clean = clean + "ff"
	}
	if len(clean) != 8 {
		return fallback
	}
	for _, r := range clean {
		if !((r >= '0' && r <= '9') || (r >= 'a' && r <= 'f') || (r >= 'A' && r <= 'F')) {
			return fallback
		}
	}
	return strings.ToLower(clean)
}

func (m *Manager) buildBorderColLua(a AppearanceConfig) string {
	mode := strings.ToLower(strings.TrimSpace(a.BorderColorMode))
	if mode == "custom" {
		c1 := sanitizeHex8(a.ActiveBorderColor, "89b4faff")
		inact := sanitizeHex8(a.InactiveBorderColor, "313244cc")
		c2Raw := strings.TrimSpace(a.ActiveBorderColor2)
		if c2Raw != "" {
			c2 := sanitizeHex8(c2Raw, "")
			if c2 != "" && c2 != c1 {
				angle := a.BorderGradientAngle
				if angle < 0 || angle > 360 {
					angle = 45
				}
				return fmt.Sprintf(`col = {
			active_border = { colors = { "rgba(%s)", "rgba(%s)" }, angle = %d },
			inactive_border = "rgba(%s)",
		},`, c1, c2, angle, inact)
			}
		}
		return fmt.Sprintf(`col = {
			active_border = "rgba(%s)",
			inactive_border = "rgba(%s)",
		},`, c1, inact)
	}

	// Theme-synced mode: resolve active theme accent & surface colors
	accent, surface := "", ""
	if m.themeColorsFn != nil {
		accent, surface = m.themeColorsFn()
	}
	if accent == "" || surface == "" {
		return ""
	}
	ac := sanitizeHex8(accent, "89b4faff")
	sf := sanitizeHex8(surface, "313244ff")
	return fmt.Sprintf(`col = {
			active_border = { colors = { "rgba(%s)", "rgba(%s)" }, angle = 45 },
			inactive_border = "rgba(%s)",
		},`, ac, sf, sf)
}

func (m *Manager) buildAppearanceLuaSnippet(cfg HyprUnifiedConfig) string {
	if cfg.GameMode {
		return `hl.config({
	general = {
		border_size = 1,
		gaps_in = 0,
		gaps_out = 0,
	},
	decoration = {
		rounding = 0,
		active_opacity = 1.00,
		inactive_opacity = 1.00,
		dim_inactive = false,
		shadow = {
			enabled = false,
		},
		blur = {
			enabled = false,
		},
	},
})`
	}

	a := cfg.Appearance
	b := a.Blur
	variant := b.Variant
	if variant == "" {
		variant = "kawase"
	}
	rp := a.RoundingPower
	if rp < 1.0 {
		rp = 4.0
	}
	sp := a.ShadowPower
	if sp < 1 {
		sp = 2
	}
	actOp := a.ActiveOpacity
	if actOp <= 0 {
		actOp = 1.0
	}
	inactOp := a.InactiveOpacity
	if inactOp <= 0 {
		inactOp = 0.95
	}

	acrylicTint := sanitizeHex8(b.Acrylic.Tint, "14eef5ff")
	auroraC1 := sanitizeHex8(b.Aurora.Color1, "29f0a0ff")
	auroraC2 := sanitizeHex8(b.Aurora.Color2, "7a4dffff")
	fluidColor := sanitizeHex8(b.FluidJar.Color, "cc3399ff")
	borderColBlock := m.buildBorderColLua(a)
	if borderColBlock != "" {
		borderColBlock = "\n\t\t" + borderColBlock
	}

	return fmt.Sprintf(`hl.config({
	general = {
		border_size = %d,
		gaps_in = %d,
		gaps_out = %d,%s
	},
	decoration = {
		rounding = %d,
		rounding_power = %.1f,
		active_opacity = %.2f,
		inactive_opacity = %.2f,
		dim_inactive = %t,
		dim_strength = %.2f,
		shadow = {
			enabled = %t,
			range = %d,
			render_power = %d,
			offset = { 0, 4 },
			color = "rgba(00000055)",
			color_inactive = "rgba(00000028)",
		},
		blur = {
			enabled = %t,
			variant = "%s",
			size = %d,
			passes = %d,
			ignore_opacity = %t,
			new_optimizations = %t,
			xray = %t,
			proportional = %t,
			noise = %.4f,
			contrast = %.3f,
			brightness = %.3f,
			vibrancy = %.3f,
			vibrancy_darkness = %.3f,
			special = %t,
			popups = %t,
			glass = {
				refraction = %d,
				size = %d,
				roughness = %.2f,
			},
			acrylic = {
				refraction = %d,
				bulb = %d,
				clarity = %.2f,
				aberration = %.3f,
				tint = "0x%s",
			},
			drops = {
				speed = %.2f,
			},
			heat_shimmer = {
				speed = %.2f,
			},
			aurora = {
				speed = %.2f,
				intensity = %.2f,
				color1 = "0x%s",
				color2 = "0x%s",
			},
			haze = {
				intensity = %.2f,
				iridescence = %.2f,
			},
			ripple = {
				strength = %.1f,
				radius = %d,
				width = %d,
				duration = %.2f,
			},
			water = {
				strength = %.1f,
				radius = %d,
				speed = %.2f,
				damping = %.2f,
				duration = %.1f,
			},
			fluid_jar = {
				speed = %.2f,
				fill_amount = %.2f,
				mass = %.2f,
				precision = %.1f,
				turbulence = %.2f,
				distortion = %.1f,
				color = "0x%s",
			},
		},
	},
})`,
		a.BorderSize, a.GapsIn, a.GapsOut, borderColBlock,
		a.Rounding, rp, actOp, inactOp, a.DimInactive, a.DimStrength,
		a.ShadowEnabled, a.ShadowRange, sp,
		b.Enabled, variant, b.Size, b.Passes, b.IgnoreOpacity, b.NewOptimizations,
		b.Xray, b.Proportional, b.Noise, b.Contrast, b.Brightness, b.Vibrancy, b.VibrancyDarkness,
		b.Special, b.Popups,
		b.Glass.Refraction, b.Glass.Size, b.Glass.Roughness,
		b.Acrylic.Refraction, b.Acrylic.Bulb, b.Acrylic.Clarity, b.Acrylic.Aberration, acrylicTint,
		b.Drops.Speed,
		b.HeatShimmer.Speed,
		b.Aurora.Speed, b.Aurora.Intensity, auroraC1, auroraC2,
		b.Haze.Intensity, b.Haze.Iridescence,
		b.Ripple.Strength, b.Ripple.Radius, b.Ripple.Width, b.Ripple.Duration,
		b.Water.Strength, b.Water.Radius, b.Water.Speed, b.Water.Damping, b.Water.Duration,
		b.FluidJar.Speed, b.FluidJar.FillAmount, b.FluidJar.Mass, b.FluidJar.Precision, b.FluidJar.Turbulence, b.FluidJar.Distortion, fluidColor,
	)
}

func formatAnimLeaf(leafName string, l AnimationLeaf, springCurves map[string]bool) string {
	curveName := strings.TrimSpace(l.Bezier)
	if curveName == "" {
		curveName = "easeOutQuint"
	}
	speed := l.Speed
	if speed <= 0 {
		speed = 4.0
	}
	fieldKey := "bezier"
	if (springCurves != nil && springCurves[curveName]) || strings.HasPrefix(strings.ToLower(curveName), "spring") {
		fieldKey = "spring"
	}
	style := strings.TrimSpace(l.Style)
	if style != "" {
		return fmt.Sprintf(`hl.animation({ leaf = "%s", enabled = %t, speed = %.1f, %s = "%s", style = "%s" })`,
			leafName, l.Enabled, speed, fieldKey, curveName, style)
	}
	return fmt.Sprintf(`hl.animation({ leaf = "%s", enabled = %t, speed = %.1f, %s = "%s" })`,
		leafName, l.Enabled, speed, fieldKey, curveName)
}

func (m *Manager) buildAnimationsLuaSnippet(cfg HyprUnifiedConfig) string {
	enabled := cfg.Animations.Enabled && !cfg.GameMode
	an := cfg.Animations
	_, springCurves := m.scanCurvesMetadata()

	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("hl.config({ animations = { enabled = %t, workspace_wraparound = true } })\n", enabled))
	sb.WriteString(formatAnimLeaf("global", AnimationLeaf{Enabled: enabled, Speed: 4.5, Bezier: "easeOutQuint"}, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("windows", an.WindowsIn, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("windowsIn", an.WindowsIn, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("windowsOut", an.WindowsOut, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("windowsMove", an.WindowsMove, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("workspaces", an.Workspaces, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("layers", an.Layers, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("layersIn", an.Layers, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("layersOut", an.Layers, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("fade", an.Fade, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("fadeIn", an.Fade, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("fadeOut", an.Fade, springCurves) + "\n")
	sb.WriteString(formatAnimLeaf("border", an.Border, springCurves) + "\n")
	return sb.String()
}

func (m *Manager) writeGeneratedAppearanceLua(cfg HyprUnifiedConfig) error {
	filePath := filepath.Join(m.hyprDir, "lua", "generated_appearance.lua")
	if err := os.MkdirAll(filepath.Dir(filePath), 0755); err != nil {
		return err
	}
	header := "-- ==========================================================\n" +
		"-- ogsShell Otomatik Üretilen Hyprland Görünüm & Blur Ayarları\n" +
		"-- Bu dosya Ayarlar uygulaması tarafından otomatik güncellenir.\n" +
		"-- ==========================================================\n\n"
	content := header + m.buildAppearanceLuaSnippet(cfg) + "\n"
	tmp := filePath + ".tmp"
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		return err
	}
	return os.Rename(tmp, filePath)
}

func (m *Manager) writeGeneratedAnimationsLua(cfg HyprUnifiedConfig) error {
	filePath := filepath.Join(m.hyprDir, "lua", "generated_animations.lua")
	if err := os.MkdirAll(filepath.Dir(filePath), 0755); err != nil {
		return err
	}
	header := "-- ==========================================================\n" +
		"-- ogsShell Otomatik Üretilen Hyprland 7'li Animasyon Ayarları\n" +
		"-- Bu dosya Ayarlar uygulaması tarafından otomatik güncellenir.\n" +
		"-- ==========================================================\n\n"
	content := header + m.buildAnimationsLuaSnippet(cfg)
	tmp := filePath + ".tmp"
	if err := os.WriteFile(tmp, []byte(content), 0644); err != nil {
		return err
	}
	return os.Rename(tmp, filePath)
}

// =========================================================================
// Unified Apply / Preset / GameMode Operations (0ms Live + Atomic Persist)
// =========================================================================

// ApplyAppearance saves new appearance+blur values and pushes them live via hyprctl eval.
func (m *Manager) ApplyAppearance(p ApplyAppearancePayload) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	cfg := m.loadUnifiedConfig()
	cfg.Appearance = p.Appearance
	cfg.ActiveAppearancePreset = p.PresetID

	if err := m.saveUnifiedConfig(cfg); err != nil {
		return nil, err
	}
	if err := m.writeGeneratedAppearanceLua(cfg); err != nil {
		return nil, err
	}

	if out, err := m.PreviewEval(m.buildAppearanceLuaSnippet(cfg)); err != nil {
		m.log.Warn("Görünüm canlı uygulanamadı", "out", out, "err", err)
	}
	state := m.buildStateLocked()
	m.emitStateLocked(state)
	return state, nil
}

// ApplyAnimations saves new 7-leaf animation settings and pushes them live via hyprctl eval.
func (m *Manager) ApplyAnimations(p ApplyAnimationsPayload) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	cfg := m.loadUnifiedConfig()
	cfg.Animations = p.Animations
	cfg.ActiveAnimationPreset = p.PresetID

	if err := m.saveUnifiedConfig(cfg); err != nil {
		return nil, err
	}
	if err := m.writeGeneratedAnimationsLua(cfg); err != nil {
		return nil, err
	}

	if out, err := m.PreviewEval(m.buildAnimationsLuaSnippet(cfg)); err != nil {
		m.log.Warn("Animasyonlar canlı uygulanamadı", "out", out, "err", err)
	}
	state := m.buildStateLocked()
	m.emitStateLocked(state)
	return state, nil
}

// ApplyPreset loads a builtin or custom preset into the live unified config and applies it immediately.
func (m *Manager) ApplyPreset(kind, presetID string) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	cfg := m.loadUnifiedConfig()
	k := strings.ToLower(strings.TrimSpace(kind))

	switch k {
	case "appearance", "border":
		all := append(BuiltinAppearancePresets(), cfg.CustomAppearancePresets...)
		found := false
		for _, pr := range all {
			if pr.ID == presetID {
				prevMode := cfg.Appearance.BorderColorMode
				prevC1 := cfg.Appearance.ActiveBorderColor
				prevC2 := cfg.Appearance.ActiveBorderColor2
				prevAngle := cfg.Appearance.BorderGradientAngle
				prevInact := cfg.Appearance.InactiveBorderColor
				cfg.Appearance = pr.Config
				// Preserve user's border color preferences when switching builtin geometry presets
				if pr.Builtin {
					cfg.Appearance.BorderColorMode = prevMode
					cfg.Appearance.ActiveBorderColor = prevC1
					cfg.Appearance.ActiveBorderColor2 = prevC2
					cfg.Appearance.BorderGradientAngle = prevAngle
					cfg.Appearance.InactiveBorderColor = prevInact
				}
				cfg.ActiveAppearancePreset = pr.ID
				found = true
				break
			}
		}
		if !found {
			return nil, fmt.Errorf("görünüm preseti bulunamadı: %s", presetID)
		}
		if err := m.saveUnifiedConfig(cfg); err != nil {
			return nil, err
		}
		if err := m.writeGeneratedAppearanceLua(cfg); err != nil {
			return nil, err
		}
		if out, err := m.PreviewEval(m.buildAppearanceLuaSnippet(cfg)); err != nil {
			m.log.Warn("Görünüm preseti canlı uygulanamadı", "out", out, "err", err)
		}

	case "animation", "animations":
		all := append(BuiltinAnimationPresets(), cfg.CustomAnimationPresets...)
		found := false
		for _, pr := range all {
			if pr.ID == presetID {
				cfg.Animations = pr.Config
				cfg.ActiveAnimationPreset = pr.ID
				found = true
				break
			}
		}
		if !found {
			return nil, fmt.Errorf("animasyon preseti bulunamadı: %s", presetID)
		}
		if err := m.saveUnifiedConfig(cfg); err != nil {
			return nil, err
		}
		if err := m.writeGeneratedAnimationsLua(cfg); err != nil {
			return nil, err
		}
		_, _ = m.PreviewEval(m.buildAnimationsLuaSnippet(cfg))

	default:
		return nil, fmt.Errorf("geçersiz preset türü: %s", kind)
	}

	m.log.Info("Hyprland preseti uygulandı", "tür", k, "preset", presetID)
	state := m.buildStateLocked()
	m.emitStateLocked(state)
	return state, nil
}

// SavePreset snapshots the current active Appearance or Animations config into a named custom preset.
func (m *Manager) SavePreset(p SavePresetPayload) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	name := strings.TrimSpace(p.Name)
	if name == "" {
		return nil, fmt.Errorf("preset adı boş olamaz")
	}
	id := "custom_" + strings.ToLower(regexp.MustCompile(`[^a-zA-Z0-9_-]+`).ReplaceAllString(name, "_"))
	desc := strings.TrimSpace(p.Description)
	if desc == "" {
		desc = "Özel kullanıcı preseti"
	}

	cfg := m.loadUnifiedConfig()
	k := strings.ToLower(strings.TrimSpace(p.Kind))

	switch k {
	case "appearance", "border":
		pr := AppearancePreset{
			ID:          id,
			Name:        name,
			Description: desc,
			Builtin:     false,
			Config:      cfg.Appearance,
		}
		updated := false
		for i := range cfg.CustomAppearancePresets {
			if cfg.CustomAppearancePresets[i].ID == id {
				cfg.CustomAppearancePresets[i] = pr
				updated = true
				break
			}
		}
		if !updated {
			cfg.CustomAppearancePresets = append(cfg.CustomAppearancePresets, pr)
		}
		cfg.ActiveAppearancePreset = id

	case "animation", "animations":
		pr := AnimationPreset{
			ID:          id,
			Name:        name,
			Description: desc,
			Builtin:     false,
			Config:      cfg.Animations,
		}
		updated := false
		for i := range cfg.CustomAnimationPresets {
			if cfg.CustomAnimationPresets[i].ID == id {
				cfg.CustomAnimationPresets[i] = pr
				updated = true
				break
			}
		}
		if !updated {
			cfg.CustomAnimationPresets = append(cfg.CustomAnimationPresets, pr)
		}
		cfg.ActiveAnimationPreset = id

	default:
		return nil, fmt.Errorf("geçersiz preset türü: %s", p.Kind)
	}

	if err := m.saveUnifiedConfig(cfg); err != nil {
		return nil, err
	}

	m.log.Info("Özel Hyprland preseti kaydedildi", "tür", k, "id", id)
	state := m.buildStateLocked()
	m.emitStateLocked(state)
	return state, nil
}

// DeletePreset removes a custom preset by ID (builtin presets are protected).
func (m *Manager) DeletePreset(kind, presetID string) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	cfg := m.loadUnifiedConfig()
	k := strings.ToLower(strings.TrimSpace(kind))

	switch k {
	case "appearance", "border":
		next := make([]AppearancePreset, 0, len(cfg.CustomAppearancePresets))
		for _, pr := range cfg.CustomAppearancePresets {
			if pr.ID != presetID {
				next = append(next, pr)
			}
		}
		cfg.CustomAppearancePresets = next
		if cfg.ActiveAppearancePreset == presetID {
			cfg.ActiveAppearancePreset = ""
		}

	case "animation", "animations":
		next := make([]AnimationPreset, 0, len(cfg.CustomAnimationPresets))
		for _, pr := range cfg.CustomAnimationPresets {
			if pr.ID != presetID {
				next = append(next, pr)
			}
		}
		cfg.CustomAnimationPresets = next
		if cfg.ActiveAnimationPreset == presetID {
			cfg.ActiveAnimationPreset = ""
		}

	default:
		return nil, fmt.Errorf("geçersiz preset türü: %s", kind)
	}

	if err := m.saveUnifiedConfig(cfg); err != nil {
		return nil, err
	}

	state := m.buildStateLocked()
	m.emitStateLocked(state)
	return state, nil
}

// SetGameMode toggles performance Game Mode without losing saved appearance/animation settings.
func (m *Manager) SetGameMode(enabled bool) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	cfg := m.loadUnifiedConfig()
	cfg.GameMode = enabled

	if err := m.saveUnifiedConfig(cfg); err != nil {
		return nil, err
	}
	if err := m.writeGeneratedAppearanceLua(cfg); err != nil {
		return nil, err
	}
	if err := m.writeGeneratedAnimationsLua(cfg); err != nil {
		return nil, err
	}

	if out, err := m.PreviewEval(m.buildAppearanceLuaSnippet(cfg) + "\n" + m.buildAnimationsLuaSnippet(cfg)); err != nil {
		m.log.Warn("Oyun modu canlı uygulanamadı", "out", out, "err", err)
	}
	m.log.Info("Hyprland Oyun Modu güncellendi", "aktif", enabled)

	state := m.buildStateLocked()
	m.emitStateLocked(state)
	return state, nil
}

// =========================================================================
// Curve Discovery (curves.lua + custom_curves.lua)
// =========================================================================

func (m *Manager) scanCurvesMetadata() ([]string, map[string]bool) {
	seen := map[string]bool{}
	springs := map[string]bool{}
	curves := make([]string, 0, 24)
	files := []string{
		filepath.Join(m.hyprDir, "lua", "profiles", "animations", "curves.lua"),
		filepath.Join(m.hyprDir, "lua", "profiles", "animations", "custom_curves.lua"),
	}
	for _, fpath := range files {
		data, err := os.ReadFile(fpath)
		if err != nil {
			continue
		}
		for _, line := range strings.Split(string(data), "\n") {
			trimmed := strings.TrimSpace(line)
			if trimmed == "" || strings.HasPrefix(trimmed, "--") {
				continue
			}
			// Strip inline comments before matching
			if idx := strings.Index(trimmed, "--"); idx != -1 {
				trimmed = strings.TrimSpace(trimmed[:idx])
			}
			if matches := curveNameRegex.FindStringSubmatch(trimmed); len(matches) == 2 {
				name := strings.TrimSpace(matches[1])
				if name != "" {
					if strings.Contains(trimmed, `type = "spring"`) || strings.Contains(trimmed, `type="spring"`) {
						springs[name] = true
					}
					if !seen[name] {
						seen[name] = true
						curves = append(curves, name)
					}
				}
			}
		}
	}
	if len(curves) == 0 {
		defaults := []string{"easeOutQuint", "easeOutExpo", "easeInOutCubic", "quick", "snappyQuick", "overshoot", "easeOutBack", "gentle", "smoothSlide", "linear", "springSoft", "springBouncy", "springStiff", "springWobbly", "springGentle"}
		for _, c := range defaults {
			if strings.HasPrefix(c, "spring") {
				springs[c] = true
			}
		}
		return defaults, springs
	}
	return curves, springs
}

func (m *Manager) scanAvailableCurves() []string {
	curves, _ := m.scanCurvesMetadata()
	return curves
}

// =========================================================================
// Legacy Profile Operations (Monitors, Environments, Themes, Backwards Compat)
// =========================================================================

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

// SetProfile updates a profile key in active_state.lua and reloads Hyprland (used for monitors, themes, etc.).
func (m *Manager) SetProfile(category, name string) (*HyprState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	key, targetDir, err := m.resolveCategory(category)
	if err != nil {
		return nil, err
	}

	targetFile := filepath.Join(targetDir, name+".lua")
	if _, err := os.Stat(targetFile); err != nil {
		return nil, fmt.Errorf("profil dosyası bulunamadı: %s (%s)", name, targetFile)
	}

	if err := m.updateStateFileKey(key, name); err != nil {
		return nil, fmt.Errorf("active_state.lua güncellenemedi: %w", err)
	}

	_ = exec.Command("hyprctl", "reload").Run()
	m.log.Info("Hyprland profili güncellendi", "kategori", category, "profil", name)

	state := m.buildStateLocked()
	m.emitStateLocked(state)
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
	if err := os.MkdirAll(filepath.Dir(curvesFile), 0755); err != nil {
		return err
	}

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

	tmpFile := fmt.Sprintf("%s.tmp", curvesFile)
	if err := os.WriteFile(tmpFile, []byte(strings.Join(lines, "\n")), 0644); err != nil {
		return err
	}
	if err := os.Rename(tmpFile, curvesFile); err != nil {
		return err
	}

	_, _ = m.PreviewEval(curveLine)
	m.log.Info("Özel Bezier eğrisi kaydedildi", "isim", name, "p1", p1, "p2", p2)
	return nil
}

// SaveCustomBorder writes a legacy custom border profile (preserved for backwards compatibility).
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

	content := fmt.Sprintf(`hl.config({
	general = { border_size = %d, gaps_in = %d, gaps_out = %d },
	decoration = {
		rounding = %d, rounding_power = %.1f,
		active_opacity = %.2f, inactive_opacity = %.2f,
		shadow = { enabled = %t, range = %d, render_power = %d, offset = { %d, %d }, color = "%s" },
		dim_inactive = %t, dim_strength = %.2f,
	},
})
`, p.BorderSize, p.GapsIn, p.GapsOut, p.Rounding, roundingPower,
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

// Watch monitors active_state.lua for external changes and dispatches updates.
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
