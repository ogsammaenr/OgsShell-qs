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
	tmuxConf := filepath.Join(homeDir, ".config", "tmux")
	_, err := os.Stat(tmuxConf)
	return err == nil
}

func (a *TmuxAdapter) Apply(palette *theme.ThemePalette) error {
	homeDir, _ := os.UserHomeDir()
	destPath := filepath.Join(homeDir, ".config", "tmux", "theme.conf")
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "tmux", palette.ID, "conf")
	if err != nil {
		return err
	}

	if err := CopyFile(srcFile, destPath); err != nil {
		return err
	}

	// Reload tmux sessions
	_ = exec.Command("tmux", "source-file", filepath.Join(homeDir, ".config", "tmux", "tmux.conf")).Run()
	return nil
}
