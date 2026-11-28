package hyprland

import (
	"os"
	"path/filepath"
	"testing"
)

func setupTestHyprDir(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()

	luaDir := filepath.Join(dir, "lua")
	_ = os.MkdirAll(filepath.Join(luaDir, "profiles", "borders"), 0755)
	_ = os.MkdirAll(filepath.Join(luaDir, "profiles", "animations"), 0755)
	_ = os.MkdirAll(filepath.Join(luaDir, "profiles", "themes"), 0755)

	// Sample active_state.lua
	initialState := `return {
	monitor_profile = "two_monitor_setup",
	enviroments_profile = "nvidia",
	theme_profile = "ogs_theme",
	border_profile = "minimal",
	animation_profile = "bouncy",
	workspace_animation = "slide_horizontal",
	window_animation = "popin_smooth",
	layer_animation = "popin_layers",
}
`
	_ = os.WriteFile(filepath.Join(luaDir, "active_state.lua"), []byte(initialState), 0644)

	// Create dummy profile files
	_ = os.WriteFile(filepath.Join(luaDir, "profiles", "borders", "minimal.lua"), []byte("-- minimal"), 0644)
	_ = os.WriteFile(filepath.Join(luaDir, "profiles", "borders", "rounded.lua"), []byte("-- rounded"), 0644)
	_ = os.WriteFile(filepath.Join(luaDir, "profiles", "animations", "bouncy.lua"), []byte("-- bouncy"), 0644)
	_ = os.WriteFile(filepath.Join(luaDir, "profiles", "animations", "curves.lua"), []byte("-- curves"), 0644)
	_ = os.WriteFile(filepath.Join(luaDir, "profiles", "themes", "ogs_theme.lua"), []byte("-- ogs"), 0644)

	return dir
}

func TestManager_GetState(t *testing.T) {
	dir := setupTestHyprDir(t)
	mgr := NewManager(dir)

	state, err := mgr.GetState()
	if err != nil {
		t.Fatalf("GetState failed: %v", err)
	}

	if state.Active.BorderProfile != "minimal" {
		t.Errorf("expected border_profile minimal, got %s", state.Active.BorderProfile)
	}
	if state.Active.AnimationProfile != "bouncy" {
		t.Errorf("expected animation_profile bouncy, got %s", state.Active.AnimationProfile)
	}

	if len(state.Available.Borders) != 2 {
		t.Errorf("expected 2 borders, got %d", len(state.Available.Borders))
	}
	// curves.lua should be excluded from animations
	if len(state.Available.Animations) != 1 {
		t.Errorf("expected 1 animation (curves excluded), got %d", len(state.Available.Animations))
	}
}

func TestManager_UpdateStateFileKey(t *testing.T) {
	dir := setupTestHyprDir(t)
	mgr := NewManager(dir)

	err := mgr.updateStateFileKey("border_profile", "rounded")
	if err != nil {
		t.Fatalf("updateStateFileKey failed: %v", err)
	}

	state, err := mgr.GetState()
	if err != nil {
		t.Fatalf("GetState failed: %v", err)
	}

	if state.Active.BorderProfile != "rounded" {
		t.Errorf("expected border_profile rounded, got %s", state.Active.BorderProfile)
	}
}

func TestManager_SaveCustomCurve(t *testing.T) {
	dir := setupTestHyprDir(t)
	mgr := NewManager(dir)

	points := [][2]float64{
		{0.25, 0.1},
		{0.25, 1.0},
	}

	err := mgr.SaveCustomCurve("test_ease", points)
	if err != nil {
		t.Fatalf("SaveCustomCurve failed: %v", err)
	}

	curvesPath := filepath.Join(dir, "lua", "profiles", "animations", "custom_curves.lua")
	content, err := os.ReadFile(curvesPath)
	if err != nil {
		t.Fatalf("failed to read custom_curves.lua: %v", err)
	}

	if !stringsContains(string(content), `hl.curve("test_ease"`) {
		t.Errorf("custom_curves.lua missing curve definition: %s", string(content))
	}
}

func TestManager_SaveCustomBorder(t *testing.T) {
	dir := setupTestHyprDir(t)
	mgr := NewManager(dir)

	payload := SaveCustomBorderPayload{
		Name:            "glass",
		BorderSize:      3,
		GapsIn:          8,
		GapsOut:         16,
		Rounding:        18,
		RoundingPower:   4.0,
		ActiveOpacity:   0.98,
		InactiveOpacity: 0.90,
		ShadowEnabled:   true,
		ShadowRange:     25,
		ShadowPower:     3,
		ShadowOffset:    [2]int{0, 5},
		ShadowColor:     "rgba(00000088)",
		DimInactive:     true,
		DimStrength:     0.10,
	}

	state, err := mgr.SaveCustomBorder(payload)
	if err != nil {
		t.Fatalf("SaveCustomBorder failed: %v", err)
	}

	if state.Active.BorderProfile != "custom_glass" {
		t.Errorf("expected active border custom_glass, got %s", state.Active.BorderProfile)
	}

	borderFile := filepath.Join(dir, "lua", "profiles", "borders", "custom_glass.lua")
	content, err := os.ReadFile(borderFile)
	if err != nil {
		t.Fatalf("failed to read custom_glass.lua: %v", err)
	}

	if !stringsContains(string(content), "border_size = 3") {
		t.Errorf("missing border_size in custom_glass.lua: %s", string(content))
	}
}

func TestManager_UnifiedAppearanceBlurAnimationsAndGameMode(t *testing.T) {
	dir := setupTestHyprDir(t)
	mgr := NewManager(dir)

	// 1. Apply acrylic_glass preset
	state, err := mgr.ApplyPreset("appearance", "acrylic_glass")
	if err != nil {
		t.Fatalf("ApplyPreset appearance failed: %v", err)
	}
	if state.Config.ActiveAppearancePreset != "acrylic_glass" || state.Config.Appearance.Blur.Variant != "acrylic" {
		t.Fatalf("expected acrylic_glass preset with acrylic blur variant, got %+v", state.Config)
	}

	// Verify generated_appearance.lua contains acrylic variant
	appLua, err := os.ReadFile(filepath.Join(dir, "lua", "generated_appearance.lua"))
	if err != nil {
		t.Fatalf("failed reading generated_appearance.lua: %v", err)
	}
	if !stringsContains(string(appLua), `variant = "acrylic"`) {
		t.Errorf("expected acrylic variant in generated_appearance.lua: %s", string(appLua))
	}

	// 2. Apply bouncy animation preset, then tweak only workspaces leaf
	state, err = mgr.ApplyPreset("animation", "bouncy")
	if err != nil {
		t.Fatalf("ApplyPreset animation failed: %v", err)
	}
	animCfg := state.Config.Animations
	animCfg.Workspaces.Speed = 7.5
	animCfg.Workspaces.Style = "slidefadevert 20%"
	state, err = mgr.ApplyAnimations(ApplyAnimationsPayload{Animations: animCfg, PresetID: ""})
	if err != nil {
		t.Fatalf("ApplyAnimations failed: %v", err)
	}
	animLua, err := os.ReadFile(filepath.Join(dir, "lua", "generated_animations.lua"))
	if err != nil {
		t.Fatalf("failed reading generated_animations.lua: %v", err)
	}
	if !stringsContains(string(animLua), `leaf = "workspaces", enabled = true, speed = 7.5`) {
		t.Errorf("expected updated workspaces leaf in generated_animations.lua: %s", string(animLua))
	}

	// 3. Save custom preset & delete it
	state, err = mgr.SavePreset(SavePresetPayload{Kind: "animation", Name: "Benim Hizim"})
	if err != nil {
		t.Fatalf("SavePreset failed: %v", err)
	}
	if len(state.Config.CustomAnimationPresets) != 1 {
		t.Fatalf("expected 1 custom animation preset, got %d", len(state.Config.CustomAnimationPresets))
	}
	customID := state.Config.CustomAnimationPresets[0].ID
	state, err = mgr.DeletePreset("animation", customID)
	if err != nil {
		t.Fatalf("DeletePreset failed: %v", err)
	}
	if len(state.Config.CustomAnimationPresets) != 0 {
		t.Fatalf("expected 0 custom animation presets after delete")
	}

	// 4. Toggle Game Mode ON then OFF (must preserve saved appearance!)
	state, err = mgr.SetGameMode(true)
	if err != nil || !state.Config.GameMode {
		t.Fatalf("SetGameMode(true) failed: %v", err)
	}
	gmLua, _ := os.ReadFile(filepath.Join(dir, "lua", "generated_appearance.lua"))
	if !stringsContains(string(gmLua), "gaps_in = 0") || !stringsContains(string(gmLua), "enabled = false") {
		t.Errorf("expected gamemode Lua overrides, got: %s", string(gmLua))
	}
	state, err = mgr.SetGameMode(false)
	if err != nil || state.Config.GameMode {
		t.Fatalf("SetGameMode(false) failed: %v", err)
	}
	restoredLua, _ := os.ReadFile(filepath.Join(dir, "lua", "generated_appearance.lua"))
	if !stringsContains(string(restoredLua), `variant = "acrylic"`) {
		t.Errorf("expected saved acrylic blur restored after exiting gamemode")
	}
}

func TestManager_SpringCurvesAndIgnoreCommentedCurves(t *testing.T) {
	dir := setupTestHyprDir(t)
	curvesContent := `
curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1.0 }, { 0.32, 1.0 } } })
curve("springSoft", { type = "spring", mass = 1.0, stiffness = 190, dampening = 20 })
curve("springBouncy", { type = "spring", mass = 0.85, stiffness = 210, dampening = 13 })
`
	customContent := `
-- Örnek format:
-- hl.curve("custom_bounce", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1.0 } } })
hl.curve("my_real_curve", { type = "bezier", points = { { 0.2, 0.8 }, { 0.2, 1.0 } } })
`
	_ = os.WriteFile(filepath.Join(dir, "lua", "profiles", "animations", "curves.lua"), []byte(curvesContent), 0644)
	_ = os.WriteFile(filepath.Join(dir, "lua", "profiles", "animations", "custom_curves.lua"), []byte(customContent), 0644)

	mgr := NewManager(dir)
	state, err := mgr.GetState()
	if err != nil {
		t.Fatalf("GetState failed: %v", err)
	}
	for _, c := range state.AvailableCurves {
		if c == "custom_bounce" {
			t.Errorf("commented-out curve 'custom_bounce' must not appear in AvailableCurves")
		}
	}

	// Apply 'gentle' preset which uses springSoft & springGentle
	_, err = mgr.ApplyPreset("animation", "gentle")
	if err != nil {
		t.Fatalf("ApplyPreset gentle failed: %v", err)
	}
	animLua, _ := os.ReadFile(filepath.Join(dir, "lua", "generated_animations.lua"))
	luaStr := string(animLua)
	if !stringsContains(luaStr, `spring = "springSoft"`) {
		t.Errorf("expected spring = \"springSoft\" in generated_animations.lua, got:\n%s", luaStr)
	}
	if stringsContains(luaStr, `bezier = "springSoft"`) || stringsContains(luaStr, `bezier = "springGentle"`) {
		t.Errorf("spring curves must NOT use bezier field, got:\n%s", luaStr)
	}
}

func TestManager_BorderColorsSolidGradientAndThemeSync(t *testing.T) {
	dir := setupTestHyprDir(t)
	mgr := NewManager(dir)
	mgr.SetThemeColorsProvider(func() (string, string) {
		return "#ebbcba", "#1f1d2e"
	})

	// 1. Custom 2-color gradient
	cfg := DefaultUnifiedConfig().Appearance
	cfg.BorderSize = 2
	cfg.BorderColorMode = "custom"
	cfg.ActiveBorderColor = "#7aa2f7ff"
	cfg.ActiveBorderColor2 = "#bb9af7ff"
	cfg.BorderGradientAngle = 135
	cfg.InactiveBorderColor = "#1a1b26aa"

	_, err := mgr.ApplyAppearance(ApplyAppearancePayload{Appearance: cfg})
	if err != nil {
		t.Fatalf("ApplyAppearance gradient failed: %v", err)
	}
	luaBytes, _ := os.ReadFile(filepath.Join(dir, "lua", "generated_appearance.lua"))
	luaStr := string(luaBytes)
	if !stringsContains(luaStr, `active_border = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)" }, angle = 135 }`) {
		t.Errorf("expected gradient active_border in generated_appearance.lua, got:\n%s", luaStr)
	}
	if !stringsContains(luaStr, `inactive_border = "rgba(1a1b26aa)"`) {
		t.Errorf("expected inactive_border in generated_appearance.lua, got:\n%s", luaStr)
	}

	// 2. Custom solid color (ActiveBorderColor2 empty)
	cfg.ActiveBorderColor2 = ""
	_, err = mgr.ApplyAppearance(ApplyAppearancePayload{Appearance: cfg})
	if err != nil {
		t.Fatalf("ApplyAppearance solid failed: %v", err)
	}
	luaBytes, _ = os.ReadFile(filepath.Join(dir, "lua", "generated_appearance.lua"))
	if !stringsContains(string(luaBytes), `active_border = "rgba(7aa2f7ff)"`) {
		t.Errorf("expected solid active_border in generated_appearance.lua, got:\n%s", string(luaBytes))
	}

	// 3. Theme-synced mode
	cfg.BorderColorMode = "theme"
	_, err = mgr.ApplyAppearance(ApplyAppearancePayload{Appearance: cfg})
	if err != nil {
		t.Fatalf("ApplyAppearance theme mode failed: %v", err)
	}
	luaBytes, _ = os.ReadFile(filepath.Join(dir, "lua", "generated_appearance.lua"))
	if !stringsContains(string(luaBytes), `active_border = { colors = { "rgba(ebbbbaff)", "rgba(1f1d2eff)" }, angle = 45 }`) &&
		!stringsContains(string(luaBytes), `active_border = { colors = { "rgba(ebbcbbff)", "rgba(1f1d2eff)" }, angle = 45 }`) &&
		!stringsContains(string(luaBytes), `active_border = { colors = { "rgba(ebbcbaff)", "rgba(1f1d2eff)" }, angle = 45 }`) {
		t.Errorf("expected theme-synced active_border in generated_appearance.lua, got:\n%s", string(luaBytes))
	}
}

func stringsContains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 || (len(s) > 0 && len(substr) > 0 && searchSubstr(s, substr)))
}

func searchSubstr(s, substr string) bool {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
