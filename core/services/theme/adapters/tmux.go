package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
)

type TmuxAdapter struct {
	sharedDir string
}

func NewTmuxAdapter() *TmuxAdapter {
	return &TmuxAdapter{}
}

func (a *TmuxAdapter) ID() string   { return "tmux" }
func (a *TmuxAdapter) Name() string { return "Tmux Terminal Multiplexer" }

func (a *TmuxAdapter) IsInstalled() bool {
	if _, err := exec.LookPath("tmux"); err == nil {
		return true
	}
	homeDir, _ := os.UserHomeDir()
	if _, err := os.Stat(filepath.Join(homeDir, ".tmux.conf")); err == nil {
		return true
	}
	if _, err := os.Stat(filepath.Join(homeDir, ".tmux")); err == nil {
		return true
	}
	if _, err := os.Stat(filepath.Join(homeDir, ".config", "tmux")); err == nil {
		return true
	}
	return false
}

func (a *TmuxAdapter) Apply(palette *theme.ThemePalette) error {
	homeDir, _ := os.UserHomeDir()
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "tmux", palette.ID, "conf")
	if err != nil {
		return err
	}

	// 1. Write theme to all standard tmux theme file locations
	destPaths := []string{
		filepath.Join(homeDir, ".tmux", "current-theme.conf"),
		filepath.Join(homeDir, ".tmux", "theme.conf"),
		filepath.Join(homeDir, ".config", "tmux", "current-theme.conf"),
		filepath.Join(homeDir, ".config", "tmux", "theme.conf"),
	}

	for _, dest := range destPaths {
		_ = CopyFile(srcFile, dest)
	}

	// 2. If tmux is installed / running, live reload configuration & status bar
	if _, err := exec.LookPath("tmux"); err == nil {
		// Source the theme file directly into active tmux server
		_ = exec.Command("tmux", "source-file", srcFile).Run()

		// Re-source main tmux config if it exists
		mainConfigs := []string{
			filepath.Join(homeDir, ".tmux.conf"),
			filepath.Join(homeDir, ".config", "tmux", "tmux.conf"),
		}
		for _, cfg := range mainConfigs {
			if _, err := os.Stat(cfg); err == nil {
				_ = exec.Command("tmux", "source-file", cfg).Run()
				break
			}
		}

		// Re-trigger minimal-tmux-status plugin if present
		minimalPlugins := []string{
			filepath.Join(homeDir, ".tmux", "plugins", "minimal-tmux-status", "minimal.tmux"),
			filepath.Join(homeDir, ".config", "tmux", "plugins", "minimal-tmux-status", "minimal.tmux"),
		}
		for _, plug := range minimalPlugins {
			if _, err := os.Stat(plug); err == nil {
				_ = exec.Command("tmux", "run-shell", plug).Run()
				break
			}
		}

		// Instant redraw of status line and client panes
		_ = exec.Command("tmux", "refresh-client", "-S").Run()
		_ = exec.Command("tmux", "refresh-client").Run()
	}

	return nil
}
