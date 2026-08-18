package adapters

import (
	"encoding/json"
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
	"strings"
)

type ZedAdapter struct {
	customSettingsPath string
	sharedDir          string
}

func NewZedAdapter(customPath ...string) *ZedAdapter {
	p := ""
	if len(customPath) > 0 {
		p = customPath[0]
	}
	return &ZedAdapter{customSettingsPath: p}
}

func (a *ZedAdapter) ID() string   { return "zed" }
func (a *ZedAdapter) Name() string { return "Zed Editor" }

func (a *ZedAdapter) getSettingsPath() string {
	if a.customSettingsPath != "" {
		return a.customSettingsPath
	}
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".config", "zed", "settings.json")
}

func (a *ZedAdapter) getThemesDir() string {
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".config", "zed", "themes")
}

func (a *ZedAdapter) IsInstalled() bool {
	settingsPath := a.getSettingsPath()
	_, err := os.Stat(filepath.Dir(settingsPath))
	return err == nil
}

func (a *ZedAdapter) ensureThemeTemplates() {
	themesDir := a.getThemesDir()
	_ = os.MkdirAll(themesDir, 0755)

	themeIDs := []string{"catppuccin", "everforest", "gruvbox", "monochrome", "nord", "tokyonight"}
	for _, id := range themeIDs {
		if srcFile, err := GetSharedAppConfigFile(a.sharedDir, "zed", id, "json"); err == nil {
			destFile := filepath.Join(themesDir, fmt.Sprintf("%s.json", id))
			_ = CopyFileInPlace(srcFile, destFile)
		}
	}
}

func (a *ZedAdapter) Apply(palette *theme.ThemePalette) error {
	// 1. Ensure all theme definitions exist in ~/.config/zed/themes/
	a.ensureThemeTemplates()

	// 2. Copy current theme JSON in-place to ~/.config/zed/themes/ogsshell.json preserving inode
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "zed", palette.ID, "json")
	if err == nil {
		destThemeFile := filepath.Join(a.getThemesDir(), "ogsshell.json")
		_ = CopyFileInPlace(srcFile, destThemeFile)
	}

	// 3. Patch theme name in ~/.config/zed/settings.json IN-PLACE preserving inode
	settingsPath := a.getSettingsPath()
	if _, err := os.Stat(settingsPath); err != nil {
		return nil
	}

	data, err := os.ReadFile(settingsPath)
	if err != nil {
		return err
	}

	var root map[string]interface{}
	if err := json.Unmarshal(data, &root); err != nil {
		return fmt.Errorf("zed settings.json çözülemedi: %w", err)
	}

	themeName := palette.Name
	if srcFile != "" {
		// Read theme name from the json if present
		if tData, tErr := os.ReadFile(srcFile); tErr == nil {
			var tObj map[string]interface{}
			if jErr := json.Unmarshal(tData, &tObj); jErr == nil {
				if n, ok := tObj["name"].(string); ok && n != "" {
					themeName = n
				}
			}
		}
	}

	root["theme"] = themeName

	newData, err := json.MarshalIndent(root, "", "  ")
	if err != nil {
		return err
	}

	// Preserve trailing newline and write directly in-place preserving inode
	content := strings.TrimSpace(string(newData)) + "\n"
	return WriteFileInPlace(settingsPath, []byte(content))
}
