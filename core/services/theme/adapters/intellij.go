package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type IntelliJAdapter struct {
	sharedDir string
}

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

	schemeName := a.getSchemeName(palette.ID)
	configDirs := a.getJetBrainsConfigDirs()
	if len(configDirs) == 0 {
		return nil
	}

	xmlContent := fmt.Sprintf(`<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="%s" />
  </component>
</application>
`, schemeName)

	for _, dir := range configDirs {
		// 1. Copy .icls color scheme file to colors/
		destIcls := filepath.Join(dir, "colors", fmt.Sprintf("%s.icls", schemeName))
		_ = CopyFile(srcFile, destIcls)

		// 2. Atomically update options/colors.scheme.xml
		optionsDir := filepath.Join(dir, "options")
		_ = os.MkdirAll(optionsDir, 0755)

		schemeXmlPath := filepath.Join(optionsDir, "colors.scheme.xml")
		tmpPath := fmt.Sprintf("%s.tmp", schemeXmlPath)
		if err := os.WriteFile(tmpPath, []byte(xmlContent), 0644); err == nil {
			_ = os.Rename(tmpPath, schemeXmlPath)
		}
	}

	return nil
}
