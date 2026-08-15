package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
)

type GtkAdapter struct {
	sharedDir string
}

func NewGtkAdapter() *GtkAdapter {
	return &GtkAdapter{}
}

func (a *GtkAdapter) ID() string   { return "gtk" }
func (a *GtkAdapter) Name() string { return "GTK 3.0 & GTK 4.0 Theme" }

func (a *GtkAdapter) IsInstalled() bool {
	homeDir, _ := os.UserHomeDir()
	gtk3 := filepath.Join(homeDir, ".config", "gtk-3.0")
	_, err := os.Stat(gtk3)
	return err == nil
}

func (a *GtkAdapter) Apply(palette *theme.ThemePalette) error {
	homeDir, _ := os.UserHomeDir()

	// 1. GTK CSS
	if srcCss, err := GetSharedAppConfigFile(a.sharedDir, "gtk", palette.ID, "css"); err == nil {
		gtk3Css := filepath.Join(homeDir, ".config", "gtk-3.0", "gtk.css")
		gtk4Css := filepath.Join(homeDir, ".config", "gtk-4.0", "gtk.css")
		_ = CopyFile(srcCss, gtk3Css)
		_ = CopyFile(srcCss, gtk4Css)
	}

	// 2. GTK Settings INI
	if srcIni, err := GetSharedAppConfigFile(a.sharedDir, "gtk", palette.ID, "ini"); err == nil {
		gtk3Ini := filepath.Join(homeDir, ".config", "gtk-3.0", "settings.ini")
		_ = CopyFile(srcIni, gtk3Ini)
	}

	return nil
}
