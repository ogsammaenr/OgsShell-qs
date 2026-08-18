package adapters

import (
	"encoding/json"
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

func (a *VesktopAdapter) getVesktopDirs() []string {
	var dirs []string
	if a.customThemePath != "" {
		dirs = append(dirs, filepath.Dir(filepath.Dir(a.customThemePath)))
		return dirs
	}

	homeDir, err := os.UserHomeDir()
	if err != nil || homeDir == "" {
		return dirs
	}

	// 1. Standard ~/.config/vesktop
	standardVesktop := filepath.Join(homeDir, ".config", "vesktop")
	if _, err := os.Stat(standardVesktop); err == nil {
		dirs = append(dirs, standardVesktop)
	}

	// 2. Standard ~/.config/Vencord
	standardVencord := filepath.Join(homeDir, ".config", "Vencord")
	if _, err := os.Stat(standardVencord); err == nil {
		dirs = append(dirs, standardVencord)
	}

	// 3. Flatpak Vesktop
	flatpakVesktop := filepath.Join(homeDir, ".var", "app", "dev.vencord.Vesktop", "config", "vesktop")
	if _, err := os.Stat(flatpakVesktop); err == nil {
		dirs = append(dirs, flatpakVesktop)
	}

	return dirs
}

func (a *VesktopAdapter) IsInstalled() bool {
	return len(a.getVesktopDirs()) > 0
}

func (a *VesktopAdapter) ensureSettings(baseDir string) {
	settingsDir := filepath.Join(baseDir, "settings")
	_ = os.MkdirAll(settingsDir, 0755)

	settingsFile := filepath.Join(settingsDir, "settings.json")
	var settings map[string]interface{}

	if data, err := os.ReadFile(settingsFile); err == nil {
		_ = json.Unmarshal(data, &settings)
	}
	if settings == nil {
		settings = make(map[string]interface{})
	}

	settings["useQuickCss"] = true

	// Ensure enabledThemes includes ogsshell.theme.css
	var themes []string
	if rawThemes, ok := settings["enabledThemes"].([]interface{}); ok {
		hasOgs := false
		for _, t := range rawThemes {
			if str, ok := t.(string); ok {
				themes = append(themes, str)
				if str == "ogsshell.theme.css" {
					hasOgs = true
				}
			}
		}
		if !hasOgs {
			themes = append(themes, "ogsshell.theme.css")
		}
	} else {
		themes = []string{"ogsshell.theme.css"}
	}
	settings["enabledThemes"] = themes

	if updatedData, err := json.MarshalIndent(settings, "", "    "); err == nil {
		_ = WriteFileInPlace(settingsFile, updatedData)
	}
}

func (a *VesktopAdapter) Apply(palette *theme.ThemePalette) error {
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "vesktop", palette.ID, "css")
	if err != nil {
		return err
	}

	dirs := a.getVesktopDirs()
	if len(dirs) == 0 {
		return nil
	}

	for _, dir := range dirs {
		// 1. Copy to themes/ogsshell.theme.css in-place preserving inode
		themesDir := filepath.Join(dir, "themes")
		_ = os.MkdirAll(themesDir, 0755)
		destTheme := filepath.Join(themesDir, "ogsshell.theme.css")
		_ = CopyFileInPlace(srcFile, destTheme)

		// 2. Copy to settings/quickCss.css in-place preserving inode (Vencord live hot-reloader watches this file!)
		settingsDir := filepath.Join(dir, "settings")
		_ = os.MkdirAll(settingsDir, 0755)
		destQuickCss := filepath.Join(settingsDir, "quickCss.css")
		_ = CopyFileInPlace(srcFile, destQuickCss)

		// 3. Ensure settings.json has useQuickCss and enabledThemes
		a.ensureSettings(dir)
	}

	return nil
}
