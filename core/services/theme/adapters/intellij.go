package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// IntelliJAdapter handles complete UI theme and editor color scheme synchronization for JetBrains IDEs.
type IntelliJAdapter struct {
	sharedDir string
}

// NewIntelliJAdapter creates a new IntelliJAdapter.
func NewIntelliJAdapter() *IntelliJAdapter {
	return &IntelliJAdapter{}
}

func (a *IntelliJAdapter) ID() string   { return "intellij" }
func (a *IntelliJAdapter) Name() string { return "IntelliJ IDEA / JetBrains IDEs" }

func (a *IntelliJAdapter) getJetBrainsConfigDirs() []string {
	var dirs []string
	homeDir, err := os.UserHomeDir()
	if err != nil || homeDir == "" {
		return dirs
	}

	// 1. Standard ~/.config/JetBrains/<Product><Version>
	standardBase := filepath.Join(homeDir, ".config", "JetBrains")
	if entries, err := os.ReadDir(standardBase); err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				dirs = append(dirs, filepath.Join(standardBase, entry.Name()))
			}
		}
	}

	// 2. Flatpak JetBrains directories
	flatpakBase := filepath.Join(homeDir, ".var", "app")
	if entries, err := os.ReadDir(flatpakBase); err == nil {
		for _, appEntry := range entries {
			if appEntry.IsDir() && strings.HasPrefix(appEntry.Name(), "com.jetbrains.") {
				appJetBrains := filepath.Join(flatpakBase, appEntry.Name(), "config", "JetBrains")
				if subEntries, err := os.ReadDir(appJetBrains); err == nil {
					for _, sub := range subEntries {
						if sub.IsDir() {
							dirs = append(dirs, filepath.Join(appJetBrains, sub.Name()))
						}
					}
				}
			}
		}
	}

	return dirs
}

func (a *IntelliJAdapter) getJetBrainsPluginDirs() []string {
	var dirs []string
	homeDir, err := os.UserHomeDir()
	if err != nil || homeDir == "" {
		return dirs
	}

	// 1. ~/.local/share/JetBrains/<Product><Version>
	localShareJB := filepath.Join(homeDir, ".local", "share", "JetBrains")
	if entries, err := os.ReadDir(localShareJB); err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				dirs = append(dirs, filepath.Join(localShareJB, entry.Name()))
			}
		}
	}

	// 2. ~/.config/JetBrains/<Product><Version>/plugins
	configJB := filepath.Join(homeDir, ".config", "JetBrains")
	if entries, err := os.ReadDir(configJB); err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				dirs = append(dirs, filepath.Join(configJB, entry.Name(), "plugins"))
			}
		}
	}

	// 3. Flatpak JetBrains data directories
	flatpakBase := filepath.Join(homeDir, ".var", "app")
	if entries, err := os.ReadDir(flatpakBase); err == nil {
		for _, appEntry := range entries {
			if appEntry.IsDir() && strings.HasPrefix(appEntry.Name(), "com.jetbrains.") {
				appJBData := filepath.Join(flatpakBase, appEntry.Name(), "data", "JetBrains")
				if subEntries, err := os.ReadDir(appJBData); err == nil {
					for _, sub := range subEntries {
						if sub.IsDir() {
							dirs = append(dirs, filepath.Join(appJBData, sub.Name()))
						}
					}
				}
			}
		}
	}

	return dirs
}

func (a *IntelliJAdapter) IsInstalled() bool {
	if len(a.getJetBrainsConfigDirs()) > 0 {
		return true
	}
	if _, err := exec.LookPath("idea"); err == nil {
		return true
	}
	if _, err := exec.LookPath("jetbrains-idea"); err == nil {
		return true
	}
	return false
}

func (a *IntelliJAdapter) getSchemeName(themeID string) string {
	schemeNames := map[string]string{
		"catppuccin": "OgsCatppuccin",
		"everforest": "OgsEverforest",
		"gruvbox":    "OgsGruvbox",
		"monochrome": "OgsMonochrome",
		"nord":       "OgsNord",
		"tokyonight": "OgsTokyoNight",
		"rosepine":   "OgsRosePine",
	}

	if name, ok := schemeNames[strings.ToLower(themeID)]; ok {
		return name
	}

	if len(themeID) > 0 {
		return fmt.Sprintf("Ogs%s%s", strings.ToUpper(themeID[:1]), themeID[1:])
	}
	return "OgsEverforest"
}

func (a *IntelliJAdapter) Apply(palette *theme.ThemePalette) error {
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "intellij", palette.ID, "icls")
	if err != nil {
		return err
	}

	// 1. Deploy ogsshell-themes.jar to all JetBrains plugin directories (direct jar & directory format)
	jarSrc, err := GetSharedAppConfigFile(a.sharedDir, "intellij", "ogsshell-themes", "jar")
	if err == nil {
		for _, pDir := range a.getJetBrainsPluginDirs() {
			_ = os.MkdirAll(pDir, 0755)
			_ = CopyFile(jarSrc, filepath.Join(pDir, "ogsshell-themes.jar"))

			libDir := filepath.Join(pDir, "ogsshell-themes", "lib")
			_ = os.MkdirAll(libDir, 0755)
			_ = CopyFile(jarSrc, filepath.Join(libDir, "ogsshell-themes.jar"))
		}
	}

	schemeName := a.getSchemeName(palette.ID)
	configDirs := a.getJetBrainsConfigDirs()
	if len(configDirs) == 0 {
		return nil
	}

	// Editor color scheme XML
	xmlContent := fmt.Sprintf(`<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="%s" />
  </component>
</application>
`, schemeName)

	// UI theme XML (LafManager)
	themeID := strings.ToLower(palette.ID)
	lafThemeID := fmt.Sprintf("com.ogsshell.theme.%s", themeID)
	lafXmlContent := fmt.Sprintf(`<application>
  <component name="LafManager">
    <laf themeId="%s" />
    <lafs-to-previous-schemes>
      <laf-to-scheme laf="%s" scheme="%s" />
      <laf-to-scheme laf="Islands Dark" scheme="%s" />
    </lafs-to-previous-schemes>
  </component>
</application>
`, lafThemeID, lafThemeID, schemeName, schemeName)

	for _, dir := range configDirs {
		// 1. Copy .icls color scheme file to colors/
		destIcls := filepath.Join(dir, "colors", fmt.Sprintf("%s.icls", schemeName))
		_ = CopyFile(srcFile, destIcls)

		optionsDir := filepath.Join(dir, "options")
		_ = os.MkdirAll(optionsDir, 0755)

		// 2. Atomically update options/colors.scheme.xml
		schemeXmlPath := filepath.Join(optionsDir, "colors.scheme.xml")
		tmpPath := fmt.Sprintf("%s.tmp", schemeXmlPath)
		if err := os.WriteFile(tmpPath, []byte(xmlContent), 0644); err == nil {
			_ = os.Rename(tmpPath, schemeXmlPath)
		}

		// 3. Atomically update options/laf.xml for complete IDE UI theme
		lafXmlPath := filepath.Join(optionsDir, "laf.xml")
		tmpLafPath := fmt.Sprintf("%s.tmp", lafXmlPath)
		if err := os.WriteFile(tmpLafPath, []byte(lafXmlContent), 0644); err == nil {
			_ = os.Rename(tmpLafPath, lafXmlPath)
		}
	}

	return nil
}
