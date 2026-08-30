package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// AndroidStudioAdapter handles theme synchronization for Google Android Studio.
type AndroidStudioAdapter struct {
	sharedDir string
}

// NewAndroidStudioAdapter creates a new AndroidStudioAdapter.
func NewAndroidStudioAdapter() *AndroidStudioAdapter {
	return &AndroidStudioAdapter{}
}

func (a *AndroidStudioAdapter) ID() string   { return "android_studio" }
func (a *AndroidStudioAdapter) Name() string { return "Android Studio" }

func (a *AndroidStudioAdapter) getAndroidStudioConfigDirs() []string {
	var dirs []string
	homeDir, err := os.UserHomeDir()
	if err != nil || homeDir == "" {
		return dirs
	}

	// 1. Standard ~/.config/Google/AndroidStudio*
	googleBase := filepath.Join(homeDir, ".config", "Google")
	if entries, err := os.ReadDir(googleBase); err == nil {
		for _, entry := range entries {
			if entry.IsDir() && strings.HasPrefix(entry.Name(), "AndroidStudio") {
				dirs = append(dirs, filepath.Join(googleBase, entry.Name()))
			}
		}
	}

	// 2. Flatpak Android Studio directories
	flatpakBase := filepath.Join(homeDir, ".var", "app", "com.google.AndroidStudio", "config", "Google")
	if entries, err := os.ReadDir(flatpakBase); err == nil {
		for _, entry := range entries {
			if entry.IsDir() && strings.HasPrefix(entry.Name(), "AndroidStudio") {
				dirs = append(dirs, filepath.Join(flatpakBase, entry.Name()))
			}
		}
	}

	// 3. Snap Android Studio directories
	snapBases := []string{
		filepath.Join(homeDir, "snap", "android-studio", "current", ".config", "Google"),
		filepath.Join(homeDir, "snap", "android-studio", "common", ".config", "Google"),
	}
	for _, snapBase := range snapBases {
		if entries, err := os.ReadDir(snapBase); err == nil {
			for _, entry := range entries {
				if entry.IsDir() && strings.HasPrefix(entry.Name(), "AndroidStudio") {
					dirs = append(dirs, filepath.Join(snapBase, entry.Name()))
				}
			}
		}
	}

	// 4. Legacy ~/.AndroidStudio*
	if entries, err := os.ReadDir(homeDir); err == nil {
		for _, entry := range entries {
			if entry.IsDir() && strings.HasPrefix(entry.Name(), ".AndroidStudio") {
				configSub := filepath.Join(homeDir, entry.Name(), "config")
				if info, err := os.Stat(configSub); err == nil && info.IsDir() {
					dirs = append(dirs, configSub)
				} else {
					dirs = append(dirs, filepath.Join(homeDir, entry.Name()))
				}
			}
		}
	}

	return dirs
}

func (a *AndroidStudioAdapter) IsInstalled() bool {
	if len(a.getAndroidStudioConfigDirs()) > 0 {
		return true
	}
	for _, bin := range []string{"android-studio", "studio", "studio.sh"} {
		if _, err := exec.LookPath(bin); err == nil {
			return true
		}
	}
	return false
}

func (a *AndroidStudioAdapter) getSchemeName(themeID string) string {
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
	return "OgsNord"
}

func (a *AndroidStudioAdapter) Apply(palette *theme.ThemePalette) error {
	// First check shared/app_configs/android_studio/<theme>.icls, fallback to shared/app_configs/intellij/<theme>.icls
	srcFile, err := GetSharedAppConfigFile(a.sharedDir, "android_studio", palette.ID, "icls")
	if err != nil {
		srcFile, err = GetSharedAppConfigFile(a.sharedDir, "intellij", palette.ID, "icls")
		if err != nil {
			return err
		}
	}

	schemeName := a.getSchemeName(palette.ID)
	configDirs := a.getAndroidStudioConfigDirs()
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
