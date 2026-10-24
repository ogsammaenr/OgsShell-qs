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
