package theme

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"
)

type MockAdapter struct {
	id          string
	name        string
	appliedWith *ThemePalette
}

func (m *MockAdapter) ID() string   { return m.id }
func (m *MockAdapter) Name() string { return m.name }
func (m *MockAdapter) IsInstalled() bool { return true }
func (m *MockAdapter) Apply(palette *ThemePalette) error {
	m.appliedWith = palette
	return nil
}

func TestSharedThemeDiscoveryAndApply(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "shared_theme_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	sharedDir := filepath.Join(tmpDir, "shared")
	themesDir := filepath.Join(sharedDir, "themes")
	if err := os.MkdirAll(themesDir, 0755); err != nil {
		t.Fatalf("failed to create themes dir: %v", err)
	}

	themesJsonContent := `[
  {
    "id": "nord",
    "name": "Nord",
    "accent": "#88c0d0",
    "bg": "#2e3440",
    "fg": "#eceff4",
    "card_bg": "#3b4252"
  },
  {
    "id": "catppuccin",
    "name": "Catppuccin Macchiato",
    "accent": "#c6a0f6",
    "bg": "#24273a",
    "fg": "#cad3f5",
    "card_bg": "#363a4f"
  },
  {
    "id": "everforest",
    "name": "Everforest Dark",
    "accent": "#a7c080",
    "bg": "#2d353b",
    "fg": "#d3c6aa",
    "card_bg": "#343f44"
  },
  {
    "id": "tokyonight",
    "name": "Tokyo Night",
    "accent": "#7aa2f7",
    "bg": "#1a1b26",
    "fg": "#c0caf5",
    "card_bg": "#24283b"
  },
  {
    "id": "gruvbox",
    "name": "Gruvbox Dark",
    "accent": "#fe8019",
    "bg": "#282828",
    "fg": "#ebdbb2",
    "card_bg": "#3c3836"
  },
  {
    "id": "monochrome",
    "name": "Monochrome Minimal",
    "accent": "#e0e0e0",
    "bg": "#121212",
    "fg": "#f0f0f0",
    "card_bg": "#1e1e1e"
  }
]`
	if err := os.WriteFile(filepath.Join(themesDir, "themes.json"), []byte(themesJsonContent), 0644); err != nil {
		t.Fatalf("failed to write themes.json: %v", err)
	}

	configPath := filepath.Join(tmpDir, "theme_config.json")

	mgr, err := NewDefaultThemeManager(sharedDir, configPath)
	if err != nil {
		t.Fatalf("failed to create theme manager: %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	mgr.Start(ctx)
	defer mgr.Close()

	themes := mgr.GetAvailableThemes()
	if len(themes) != 6 {
		t.Fatalf("expected exactly 6 shared themes, got %d", len(themes))
	}

	// Verify exact theme IDs
	expectedIDs := []string{"nord", "catppuccin", "everforest", "tokyonight", "gruvbox", "monochrome"}
	for i, expID := range expectedIDs {
		if themes[i].ID != expID {
			t.Errorf("expected theme[%d] to be %s, got %s", i, expID, themes[i].ID)
		}
	}

	// Register adapter and test SetActiveTheme
	mockAdp := &MockAdapter{id: "mock_app", name: "Mock App"}
	mgr.RegisterAdapters(mockAdp)

	applied, err := mgr.SetActiveTheme("tokyonight")
	if err != nil {
		t.Fatalf("failed to set active theme tokyonight: %v", err)
	}
	if applied.ID != "tokyonight" {
		t.Errorf("expected active theme tokyonight, got %s", applied.ID)
	}

	// Wait for async dispatcher
	time.Sleep(120 * time.Millisecond)

	if mockAdp.appliedWith == nil || mockAdp.appliedWith.ID != "tokyonight" {
		t.Errorf("expected mock adapter to receive tokyonight, got %+v", mockAdp.appliedWith)
	}
}

func TestThemeConfigPersistence(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "theme_cfg_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cfgPath := filepath.Join(tmpDir, "theme_config.json")
	cfg := &UserThemeConfig{
		ActiveThemeID: "tokyonight",
		EnabledAdapters: map[string]bool{
			"kitty": true,
			"zed":   false,
		},
	}

	if err := SaveThemeConfig(cfgPath, cfg); err != nil {
		t.Fatalf("failed to save config: %v", err)
	}

	loaded, err := LoadThemeConfig(cfgPath)
	if err != nil {
		t.Fatalf("failed to load config: %v", err)
	}

	if loaded.ActiveThemeID != "tokyonight" {
		t.Errorf("expected tokyonight, got %s", loaded.ActiveThemeID)
	}
	if loaded.EnabledAdapters["zed"] != false || loaded.EnabledAdapters["kitty"] != true {
		t.Errorf("unexpected adapter states: %+v", loaded.EnabledAdapters)
	}
}
