package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"time"
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

	// 1. Touch main kitty.conf so kitten __watch_conf__ triggers instant config reload (<1ms)
	mainConfig := filepath.Join(filepath.Dir(destPath), "kitty.conf")
	if _, err := os.Stat(mainConfig); err == nil {
		now := time.Now()
		_ = os.Chtimes(mainConfig, now, now)
		_ = exec.Command("touch", mainConfig).Run()
	}

	// 2. POSIX signal reload across all kitty instances
	_ = exec.Command("pkill", "-USR1", "-x", "kitty").Run()
	_ = exec.Command("pkill", "-SIGUSR1", "-x", "kitty").Run()

	return nil
}
