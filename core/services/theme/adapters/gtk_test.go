package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGtkAdapter_Apply(t *testing.T) {
	tempDir := t.TempDir()
	sharedDir := filepath.Join(tempDir, "shared")
	gtkSharedDir := filepath.Join(sharedDir, "app_configs", "gtk")
	if err := os.MkdirAll(gtkSharedDir, 0755); err != nil {
		t.Fatalf("failed to create gtk shared dir: %v", err)
	}

	cssContent := "@define-color accent_color #cba6f7;\n@define-color window_bg_color #1e1e2e;\n"
	if err := os.WriteFile(filepath.Join(gtkSharedDir, "catppuccin.css"), []byte(cssContent), 0644); err != nil {
		t.Fatalf("failed to write catppuccin.css: %v", err)
	}

	iniContent := "[Settings]\ngtk-theme-name=adw-gtk3-dark\ngtk-icon-theme-name=breeze\n"
	if err := os.WriteFile(filepath.Join(gtkSharedDir, "catppuccin.ini"), []byte(iniContent), 0644); err != nil {
		t.Fatalf("failed to write catppuccin.ini: %v", err)
	}

	adapter := NewGtkAdapter(sharedDir)
	if adapter.ID() != "gtk" {
		t.Errorf("expected adapter ID 'gtk', got '%s'", adapter.ID())
	}

	palette := &theme.ThemePalette{ID: "catppuccin", Name: "Catppuccin"}
	if err := adapter.Apply(palette); err != nil {
		t.Fatalf("adapter.Apply failed: %v", err)
	}

	homeDir, _ := os.UserHomeDir()
	gtk3Css := filepath.Join(homeDir, ".config", "gtk-3.0", "gtk.css")
	if data, err := os.ReadFile(gtk3Css); err == nil {
		if !strings.Contains(string(data), "ogsShell-catppuccin") {
			t.Errorf("expected gtk.css to contain ogsShell-catppuccin")
		}
	}

	theme3Css := filepath.Join(homeDir, ".local", "share", "themes", "ogsShell-catppuccin", "gtk-3.0", "gtk.css")
	if data, err := os.ReadFile(theme3Css); err == nil {
		if !strings.Contains(string(data), "@define-color accent_color #cba6f7") {
			t.Errorf("expected theme gtk.css to contain accent_color")
		}
	} else {
		t.Errorf("expected theme gtk.css to exist: %v", err)
	}

	gtk4Css := filepath.Join(homeDir, ".config", "gtk-4.0", "gtk.css")
	if data, err := os.ReadFile(gtk4Css); err == nil {
		if !strings.Contains(string(data), "@define-color accent_color #cba6f7") {
			t.Errorf("expected gtk-4.0/gtk.css to contain accent_color")
		}
	}

	xsettingsConf := filepath.Join(homeDir, ".config", "xsettingsd", "xsettingsd.conf")
	if data, err := os.ReadFile(xsettingsConf); err == nil {
		str := string(data)
		if !strings.Contains(str, `Net/ThemeName "ogsShell-catppuccin"`) {
			t.Errorf("expected xsettingsd.conf to contain Net/ThemeName ogsShell-catppuccin")
		}
		if !strings.Contains(str, `Net/IconThemeName "breeze"`) {
			t.Errorf("expected xsettingsd.conf to contain Net/IconThemeName")
		}
	} else {
		t.Errorf("expected xsettingsd.conf to be created: %v", err)
	}
}
