package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
)

type StarshipAdapter struct {
	customConfigPath string
	sharedDir        string
}

func NewStarshipAdapter(customPath ...string) *StarshipAdapter {
	p := ""
	if len(customPath) > 0 {
		p = customPath[0]
	}
	return &StarshipAdapter{customConfigPath: p}
}

func (a *StarshipAdapter) ID() string   { return "starship" }
func (a *StarshipAdapter) Name() string { return "Starship Prompt" }

func (a *StarshipAdapter) getConfigPath() string {
	if a.customConfigPath != "" {
		return a.customConfigPath
	}
	if envPath := os.Getenv("STARSHIP_CONFIG"); envPath != "" {
		return envPath
	}
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".config", "starship.toml")
}

func (a *StarshipAdapter) IsInstalled() bool {
	if _, err := exec.LookPath("starship"); err == nil {
		return true
	}
	destPath := a.getConfigPath()
	_, err := os.Stat(destPath)
	return err == nil
}

func (a *StarshipAdapter) Apply(palette *theme.ThemePalette) error {
	sharedDir := a.sharedDir
	if sharedDir == "" {
		sharedDir = theme.GetSharedDir()
	}

	basePath := filepath.Join(sharedDir, "app_configs", "starship", "base.toml")
	baseData, err := os.ReadFile(basePath)
	if err != nil {
		return fmt.Errorf("starship temel konfigürasyonu okunamadı (%s): %w", basePath, err)
	}

	palettePath := filepath.Join(sharedDir, "app_configs", "starship", "palettes", fmt.Sprintf("%s.toml", palette.ID))
	paletteData, err := os.ReadFile(palettePath)
	if err != nil {
		return fmt.Errorf("starship tema paleti okunamadı (%s): %w", palettePath, err)
	}

	combined := fmt.Sprintf("palette = \"%s\"\n\n%s\n\n%s\n", palette.ID, string(baseData), string(paletteData))
	destPath := a.getConfigPath()

	return WriteFileInPlace(destPath, []byte(combined))
}
