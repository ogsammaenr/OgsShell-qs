package adapters

import (
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
)

type NvimAdapter struct {
	customPluginPath string
	sharedDir        string
}

func NewNvimAdapter(customPath ...string) *NvimAdapter {
	p := ""
	if len(customPath) > 0 {
		p = customPath[0]
	}
	return &NvimAdapter{customPluginPath: p}
}

func (a *NvimAdapter) ID() string   { return "nvim" }
func (a *NvimAdapter) Name() string { return "Neovim (LazyVim/Lua)" }

func (a *NvimAdapter) getPluginPath() string {
	if a.customPluginPath != "" {
		return a.customPluginPath
	}
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".config", "nvim", "lua", "plugins", "theme.lua")
}

func (a *NvimAdapter) IsInstalled() bool {
	p := a.getPluginPath()
	_, err := os.Stat(filepath.Dir(filepath.Dir(p)))
	return err == nil
}

func (a *NvimAdapter) Apply(palette *theme.ThemePalette) error {
	destPath := a.getPluginPath()
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "nvim", palette.ID, "lua")
	if err != nil {
		return err
	}

	return CopyFile(srcFile, destPath)
}
