package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
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
	if _, err := exec.LookPath("nvim"); err == nil {
		return true
	}
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

	if err := CopyFile(srcFile, destPath); err != nil {
		return err
	}

	// Live reload all running Neovim instances via remote sockets
	a.reloadRunningInstances(destPath)

	return nil
}

func (a *NvimAdapter) reloadRunningInstances(destPath string) {
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		runtimeDir = fmt.Sprintf("/run/user/%d", os.Getuid())
	}

	var socketPaths []string

	if entries, err := filepath.Glob(filepath.Join(runtimeDir, "nvim.*")); err == nil {
		socketPaths = append(socketPaths, entries...)
	}
	if entries, err := filepath.Glob(filepath.Join(os.TempDir(), "nvim.*", "*")); err == nil {
		socketPaths = append(socketPaths, entries...)
	}

	for _, sock := range socketPaths {
		fi, err := os.Stat(sock)
		if err != nil || fi.Mode()&os.ModeSocket == 0 {
			continue
		}

		_ = exec.Command("nvim", "--server", sock, "--remote-send", fmt.Sprintf("<Cmd>luafile %s<CR>", destPath)).Run()
	}
}
