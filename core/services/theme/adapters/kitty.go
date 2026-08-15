package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
)

type KittyAdapter struct {
	customThemePath string
	sharedDir       string
}

func NewKittyAdapter(customPath ...string) *KittyAdapter {
	p := ""
	if len(customPath) > 0 {
		p = customPath[0]
	}
	return &KittyAdapter{customThemePath: p}
}

func (a *KittyAdapter) ID() string   { return "kitty" }
func (a *KittyAdapter) Name() string { return "Kitty Terminal" }

func (a *KittyAdapter) getThemePath() string {
	if a.customThemePath != "" {
		return a.customThemePath
	}
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".config", "kitty", "current-theme.conf")
}

func (a *KittyAdapter) IsInstalled() bool {
	if _, err := exec.LookPath("kitty"); err == nil {
		return true
	}
	themePath := a.getThemePath()
	_, err := os.Stat(filepath.Dir(themePath))
	return err == nil
}

func (a *KittyAdapter) Apply(palette *theme.ThemePalette) error {
	destPath := a.getThemePath()
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "kitty", palette.ID, "conf")
	if err != nil {
		return err
	}

	if err := CopyFile(srcFile, destPath); err != nil {
		return err
	}

	// Live reload via POSIX SIGUSR1 signal (instant <1ms)
	_ = exec.Command("pkill", "-SIGUSR1", "kitty").Run()

	return nil
}
