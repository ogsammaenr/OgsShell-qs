package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
)

type VesktopAdapter struct {
	customThemePath string
	sharedDir       string
}

func NewVesktopAdapter(customPath ...string) *VesktopAdapter {
	p := ""
	if len(customPath) > 0 {
		p = customPath[0]
	}
	return &VesktopAdapter{customThemePath: p}
}

func (a *VesktopAdapter) ID() string   { return "vesktop" }
func (a *VesktopAdapter) Name() string { return "Vesktop Discord Client" }

func (a *VesktopAdapter) getThemePath() string {
	if a.customThemePath != "" {
		return a.customThemePath
	}
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".config", "vesktop", "themes", "ogsshell.theme.css")
}

func (a *VesktopAdapter) IsInstalled() bool {
	themePath := a.getThemePath()
	_, err := os.Stat(filepath.Dir(filepath.Dir(themePath)))
	return err == nil
}

func (a *VesktopAdapter) Apply(palette *theme.ThemePalette) error {
	destPath := a.getThemePath()
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "vesktop", palette.ID, "css")
	if err != nil {
		return err
	}

	return CopyFile(srcFile, destPath)
}
