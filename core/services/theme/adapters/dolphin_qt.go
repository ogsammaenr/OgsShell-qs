package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type DolphinQtAdapter struct {
	sharedDir string
}

func NewDolphinQtAdapter() *DolphinQtAdapter {
	return &DolphinQtAdapter{}
}

func (a *DolphinQtAdapter) ID() string   { return "qt_dolphin" }
func (a *DolphinQtAdapter) Name() string { return "Qt & KDE Applications" }

func (a *DolphinQtAdapter) IsInstalled() bool {
	homeDir, _ := os.UserHomeDir()
	kdeglobals := filepath.Join(homeDir, ".config", "kdeglobals")
	if _, err := os.Stat(kdeglobals); err == nil {
		return true
	}
	if _, err := exec.LookPath("dolphin"); err == nil {
		return true
	}
	if _, err := exec.LookPath("qt6ct"); err == nil {
		return true
	}
	if _, err := exec.LookPath("qt5ct"); err == nil {
		return true
	}
	return false
}

// getKdeSchemeName maps theme IDs to KDE scheme names.
func (a *DolphinQtAdapter) getKdeSchemeName(themeID string) string {
	switch themeID {
	case "catppuccin":
		return "OgsCatppuccin"
	case "everforest":
		return "OgsEverforest"
	case "gruvbox":
		return "OgsGruvbox"
	case "monochrome":
		return "OgsMonochrome"
	case "nord":
		return "OgsNord"
	case "tokyonight":
		return "OgsTokyoNight"
	default:
		return fmt.Sprintf("Ogs%s", themeID)
	}
}

func (a *DolphinQtAdapter) updateQtCtColorScheme(confPath string, colorsFilePath string) {
	_ = os.MkdirAll(filepath.Dir(confPath), 0755)

	data, err := os.ReadFile(confPath)
	if err != nil {
		// Create default clean configuration if not present
		defaultConf := fmt.Sprintf(`[Appearance]
color_scheme_path=%s
custom_palette=2
standard_dialogs=default
style=Fusion

[Fonts]
fixed="Monospace,10,-1,5,50,0,0,0,0,0"
general="Sans Serif,10,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
`, colorsFilePath)
		_ = os.WriteFile(confPath, []byte(defaultConf), 0644)
		return
	}

	// Preserve existing fonts and interface settings, updating only color_scheme_path and custom_palette
	content := string(data)
	lines := strings.Split(content, "\n")
	var newLines []string
	inAppearance := false
	hasColorScheme := false

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		if strings.HasPrefix(trimmed, "[") && strings.HasSuffix(trimmed, "]") {
			if inAppearance && !hasColorScheme {
				newLines = append(newLines, fmt.Sprintf("color_scheme_path=%s", colorsFilePath))
				hasColorScheme = true
			}
			inAppearance = (trimmed == "[Appearance]")
		}

		if inAppearance {
			if strings.HasPrefix(trimmed, "color_scheme_path=") {
				newLines = append(newLines, fmt.Sprintf("color_scheme_path=%s", colorsFilePath))
				hasColorScheme = true
				continue
			}
			if strings.HasPrefix(trimmed, "custom_palette=") {
				newLines = append(newLines, "custom_palette=2")
				continue
			}
		}

		newLines = append(newLines, line)
	}

	if !strings.Contains(content, "[Appearance]") {
		newLines = append([]string{
			"[Appearance]",
			fmt.Sprintf("color_scheme_path=%s", colorsFilePath),
			"custom_palette=2",
			"",
		}, newLines...)
	} else if inAppearance && !hasColorScheme {
		newLines = append(newLines, fmt.Sprintf("color_scheme_path=%s", colorsFilePath))
	}

	_ = os.WriteFile(confPath, []byte(strings.Join(newLines, "\n")), 0644)
}

func (a *DolphinQtAdapter) Apply(palette *theme.ThemePalette) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("user home dir error: %w", err)
	}

	kdeSchemeName := a.getKdeSchemeName(palette.ID)

	// =========================================================================
	// 1. KDE Global & Color Scheme Files
	// =========================================================================
	if srcDolphin, err := GetSharedAppConfigFile(a.sharedDir, "dolphin", palette.ID, "kdeglobals"); err == nil {
		destKde := filepath.Join(homeDir, ".config", "kdeglobals")
		_ = os.MkdirAll(filepath.Dir(destKde), 0755)
		_ = CopyFile(srcDolphin, destKde)

		schemePath := filepath.Join(homeDir, ".local", "share", "color-schemes", fmt.Sprintf("%s.colors", kdeSchemeName))
		_ = os.MkdirAll(filepath.Dir(schemePath), 0755)
		_ = CopyFile(srcDolphin, schemePath)
	}

	// Persist global KDE color scheme
	if _, err := exec.LookPath("kwriteconfig6"); err == nil {
		_ = exec.Command("kwriteconfig6", "--file", "kdeglobals", "--group", "General", "--key", "ColorScheme", kdeSchemeName).Run()
		_ = exec.Command("kwriteconfig6", "--file", "kdeglobals", "--group", "KDE", "--key", "colorScheme", kdeSchemeName).Run()
	}
	if _, err := exec.LookPath("kwriteconfig5"); err == nil {
		_ = exec.Command("kwriteconfig5", "--file", "kdeglobals", "--group", "General", "--key", "ColorScheme", kdeSchemeName).Run()
		_ = exec.Command("kwriteconfig5", "--file", "kdeglobals", "--group", "KDE", "--key", "colorScheme", kdeSchemeName).Run()
	}

	// =========================================================================
	// 2. Synchronize All KDE Applications Configurations
	// =========================================================================
	kdeAppConfigs := []string{
		"dolphinrc",
		"katerc",
		"kwriterc",
		"okularrc",
		"arkrc",
		"konsolerc",
		"spectaclerc",
		"kdenliverc",
		"systemmonitorrc",
		"gwenviewrc",
	}

	for _, cfg := range kdeAppConfigs {
		if _, err := exec.LookPath("kwriteconfig6"); err == nil {
			_ = exec.Command("kwriteconfig6", "--file", cfg, "--group", "UiSettings", "--key", "ColorScheme", kdeSchemeName).Run()
		}
		if _, err := exec.LookPath("kwriteconfig5"); err == nil {
			_ = exec.Command("kwriteconfig5", "--file", cfg, "--group", "UiSettings", "--key", "ColorScheme", kdeSchemeName).Run()
		}
	}

	// =========================================================================
	// 3. Qt5ct & Qt6ct Palettes
	// =========================================================================
	if srcQt, err := GetSharedAppConfigFile(a.sharedDir, "qt", palette.ID, "conf"); err == nil {
		qt6ColorsDir := filepath.Join(homeDir, ".config", "qt6ct", "colors")
		qt5ColorsDir := filepath.Join(homeDir, ".config", "qt5ct", "colors")

		_ = os.MkdirAll(qt6ColorsDir, 0755)
		_ = os.MkdirAll(qt5ColorsDir, 0755)

		qt6ColorsFile := filepath.Join(qt6ColorsDir, fmt.Sprintf("%s.conf", palette.ID))
		qt5ColorsFile := filepath.Join(qt5ColorsDir, fmt.Sprintf("%s.conf", palette.ID))

		_ = CopyFile(srcQt, qt6ColorsFile)
		_ = CopyFile(srcQt, qt5ColorsFile)

		// Update color_scheme_path preserving user font/interface preferences
		a.updateQtCtColorScheme(filepath.Join(homeDir, ".config", "qt6ct", "qt6ct.conf"), qt6ColorsFile)
		a.updateQtCtColorScheme(filepath.Join(homeDir, ".config", "qt5ct", "qt5ct.conf"), qt5ColorsFile)
	}

	// =========================================================================
	// 4. Broadcast Live Updates
	// =========================================================================
	a.broadcastKdeDbusChanges(kdeSchemeName)

	return nil
}

func (a *DolphinQtAdapter) broadcastKdeDbusChanges(schemeName string) {
	// 1. Plasma colorscheme utility
	if _, err := exec.LookPath("plasma-apply-colorscheme"); err == nil {
		_ = exec.Command("plasma-apply-colorscheme", schemeName).Run()
	}

	// 2. KGlobalSettings signals:
	//    int32:0 -> PaletteChanged
	//    int32:2 -> StyleChanged
	//    int32:3 -> SettingsChanged
	_ = exec.Command("dbus-send", "--session", "--type=signal", "/KGlobalSettings", "org.kde.KGlobalSettings.notifyChange", "int32:0", "int32:0").Run()
	_ = exec.Command("dbus-send", "--session", "--type=signal", "/KGlobalSettings", "org.kde.KGlobalSettings.notifyChange", "int32:2", "int32:0").Run()
	_ = exec.Command("dbus-send", "--session", "--type=signal", "/KGlobalSettings", "org.kde.KGlobalSettings.notifyChange", "int32:3", "int32:0").Run()
}
