package adapters

import (
	"context"
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

// FindKittySockets discovers active Unix domain control sockets for running Kitty instances.
func FindKittySockets() []string {
	var sockets []string
	seen := make(map[string]bool)

	patterns := []string{
		"/tmp/kitty*",
		"/tmp/mykitty*",
	}

	if runtimeDir := os.Getenv("XDG_RUNTIME_DIR"); runtimeDir != "" {
		patterns = append(patterns, filepath.Join(runtimeDir, "kitty*"))
	}

	for _, pattern := range patterns {
		matches, err := filepath.Glob(pattern)
		if err != nil {
			continue
		}
		for _, m := range matches {
			if seen[m] {
				continue
			}
			fi, err := os.Stat(m)
			if err == nil && (fi.Mode()&os.ModeSocket != 0) {
				seen[m] = true
				sockets = append(sockets, m)
			}
		}
	}

	return sockets
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

	// 1. Send remote control command to all active Kitty sockets to preserve runtime font size
	sockets := FindKittySockets()
	socketApplied := false

	bin := "kitten"
	if _, err := exec.LookPath("kitten"); err != nil {
		bin = "kitty"
	}

	for _, sock := range sockets {
		ctx, cancel := context.WithTimeout(context.Background(), 250*time.Millisecond)
		cmd := exec.CommandContext(ctx, bin, "@", "--to", "unix:"+sock, "set-colors", "--all", "--configured", srcFile)
		if err := cmd.Run(); err == nil {
			socketApplied = true
		}
		cancel()
	}

	// 2. Fallback: If no sockets were found or succeeded, send SIGUSR1 (without touching kitty.conf)
	if !socketApplied {
		_ = exec.Command("pkill", "-SIGUSR1", "-x", "kitty").Run()
	}

	return nil
}
