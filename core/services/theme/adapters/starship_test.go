package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestStarshipAdapter_Apply(t *testing.T) {
	tempDir := t.TempDir()
	sharedDir := filepath.Join(tempDir, "shared")
	starshipSharedDir := filepath.Join(sharedDir, "app_configs", "starship")
	palettesDir := filepath.Join(starshipSharedDir, "palettes")
	if err := os.MkdirAll(palettesDir, 0755); err != nil {
		t.Fatalf("failed to create palettes dir: %v", err)
	}

	baseContent := "# Starship Base Config\nformat = '$directory$character'\n"
	if err := os.WriteFile(filepath.Join(starshipSharedDir, "base.toml"), []byte(baseContent), 0644); err != nil {
		t.Fatalf("failed to write base.toml: %v", err)
	}

	nordContent := "[palettes.nord]\nbg = '#2e3440'\n"
	if err := os.WriteFile(filepath.Join(palettesDir, "nord.toml"), []byte(nordContent), 0644); err != nil {
		t.Fatalf("failed to write nord.toml: %v", err)
	}

	targetConfig := filepath.Join(tempDir, "starship.toml")
	adapter := NewStarshipAdapter(targetConfig)
	adapter.sharedDir = sharedDir

	if adapter.ID() != "starship" {
		t.Errorf("expected adapter ID 'starship', got '%s'", adapter.ID())
	}

	palette := &theme.ThemePalette{ID: "nord", Name: "Nord"}
	if err := adapter.Apply(palette); err != nil {
		t.Fatalf("adapter.Apply failed: %v", err)
	}

	data, err := os.ReadFile(targetConfig)
	if err != nil {
		t.Fatalf("failed to read generated starship.toml: %v", err)
	}

	content := string(data)
	if !strings.Contains(content, "format = '$directory$character'") {
		t.Errorf("expected generated starship.toml to contain base config")
	}
	if !strings.Contains(content, `palette = "nord"`) || !strings.Contains(content, "[palettes.nord]") {
		t.Errorf("expected generated starship.toml to contain palette definition")
	}
}
