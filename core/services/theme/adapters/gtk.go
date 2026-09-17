package adapters

import (
	"bufio"
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

type GtkAdapter struct {
	sharedDir string
}

func NewGtkAdapter(sharedDir ...string) *GtkAdapter {
	dir := ""
	if len(sharedDir) > 0 {
		dir = sharedDir[0]
	}
	return &GtkAdapter{sharedDir: dir}
}

func (a *GtkAdapter) ID() string   { return "gtk" }
func (a *GtkAdapter) Name() string { return "GTK 3.0 & GTK 4.0 Theme" }

func (a *GtkAdapter) IsInstalled() bool {
	homeDir, _ := os.UserHomeDir()
	gtk3 := filepath.Join(homeDir, ".config", "gtk-3.0")
	if _, err := os.Stat(gtk3); err == nil {
		return true
	}
	gtk4 := filepath.Join(homeDir, ".config", "gtk-4.0")
	if _, err := os.Stat(gtk4); err == nil {
		return true
	}
	if _, err := exec.LookPath("gsettings"); err == nil {
		return true
	}
	if _, err := exec.LookPath("xsettingsd"); err == nil {
		return true
	}
	return false
}

func (a *GtkAdapter) ensureThemeTemplates() {
	homeDir, _ := os.UserHomeDir()
	themesBaseDir := filepath.Join(homeDir, ".local", "share", "themes")
	_ = os.MkdirAll(themesBaseDir, 0755)

	importBase := `@import url("/usr/share/themes/adw-gtk3-dark/gtk-3.0/gtk.css");`
	if _, err := os.Stat("/usr/share/themes/adw-gtk3-dark/gtk-3.0/gtk.css"); err != nil {
		importBase = `@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");`
	}

	themeIDs := []string{"catppuccin", "everforest", "gruvbox", "monochrome", "nord", "tokyonight", "rosepine"}
	for _, id := range themeIDs {
		themeDir := filepath.Join(themesBaseDir, "ogsShell-"+id)
		gtk3Dir := filepath.Join(themeDir, "gtk-3.0")
		gtk4Dir := filepath.Join(themeDir, "gtk-4.0")
		_ = os.MkdirAll(gtk3Dir, 0755)
		_ = os.MkdirAll(gtk4Dir, 0755)

		indexTheme := filepath.Join(themeDir, "index.theme")
		indexContent := fmt.Sprintf("[Desktop Entry]\nType=X-GNOME-Metatheme\nName=ogsShell-%s\nComment=ogsShell dynamic theme\nEncoding=UTF-8\n\n[X-GNOME-Metatheme]\nGtkTheme=ogsShell-%s\nMetacityTheme=ogsShell-%s\nButtonLayout=:close\n", id, id, id)
		_ = os.WriteFile(indexTheme, []byte(indexContent), 0644)

		if srcCss, err := GetSharedAppConfigFile(a.sharedDir, "gtk", id, "css"); err == nil {
			cssBytes, _ := os.ReadFile(srcCss)
			combined3 := importBase + "\n\n" + string(cssBytes)
			_ = os.WriteFile(filepath.Join(gtk3Dir, "gtk.css"), []byte(combined3), 0644)
			_ = os.WriteFile(filepath.Join(gtk4Dir, "gtk.css"), cssBytes, 0644)
		}
	}
}

func (a *GtkAdapter) Apply(palette *theme.ThemePalette) error {
	homeDir, _ := os.UserHomeDir()

	// 1. Pre-deploy all ogsShell GTK themes into ~/.local/share/themes/
	a.ensureThemeTemplates()

	gtk3Dir := filepath.Join(homeDir, ".config", "gtk-3.0")
	gtk4Dir := filepath.Join(homeDir, ".config", "gtk-4.0")
	_ = os.MkdirAll(gtk3Dir, 0755)
	_ = os.MkdirAll(gtk4Dir, 0755)

	themeName := "ogsShell-" + palette.ID

	// 2. GTK 3.0 User CSS:
	// In GTK 3, ~/.config/gtk-3.0/gtk.css has Priority 800 (USER), overriding the theme provider (Priority 600).
	// Crucially, GTK 3 caches ~/.config/gtk-3.0/gtk.css in memory and NEVER re-reads it on theme change.
	// We write a minimal comment into gtk.css so Priority 800 does not block live theme provider switching.
	gtk3Css := filepath.Join(gtk3Dir, "gtk.css")
	_ = os.WriteFile(gtk3Css, []byte("/* ogsShell dynamic theme mode - Active: "+themeName+" */\n"), 0644)

	// 3. GTK 4.0 CSS (for Libadwaita applications which read ~/.config/gtk-4.0/gtk.css directly)
	if srcCss, err := GetSharedAppConfigFile(a.sharedDir, "gtk", palette.ID, "css"); err == nil {
		gtk4Css := filepath.Join(gtk4Dir, "gtk.css")
		_ = CopyFile(srcCss, gtk4Css)
	}

	// 4. Parse settings from INI template
	var iconName, fontName, cursorName string
	preferDark := "prefer-dark"

	if srcIni, err := GetSharedAppConfigFile(a.sharedDir, "gtk", palette.ID, "ini"); err == nil {
		if f, err := os.Open(srcIni); err == nil {
			scanner := bufio.NewScanner(f)
			for scanner.Scan() {
				line := strings.TrimSpace(scanner.Text())
				if strings.HasPrefix(line, "gtk-icon-theme-name=") {
					iconName = strings.TrimPrefix(line, "gtk-icon-theme-name=")
				} else if strings.HasPrefix(line, "gtk-font-name=") {
					fontName = strings.TrimPrefix(line, "gtk-font-name=")
				} else if strings.HasPrefix(line, "gtk-cursor-theme-name=") {
					cursorName = strings.TrimPrefix(line, "gtk-cursor-theme-name=")
				}
			}
			_ = f.Close()
		}
	}

	// 5. Generate settings.ini with dynamic themeName
	var iniLines []string
	iniLines = append(iniLines, "[Settings]")
	iniLines = append(iniLines, "gtk-theme-name="+themeName)
	if iconName != "" {
		iniLines = append(iniLines, "gtk-icon-theme-name="+iconName)
	}
	if fontName != "" {
		iniLines = append(iniLines, "gtk-font-name="+fontName)
	}
	if cursorName != "" {
		iniLines = append(iniLines, "gtk-cursor-theme-name="+cursorName)
	}
	iniLines = append(iniLines, "gtk-application-prefer-dark-theme=true")
	iniLines = append(iniLines, "")
	iniContent := []byte(strings.Join(iniLines, "\n"))

	_ = os.WriteFile(filepath.Join(gtk3Dir, "settings.ini"), iniContent, 0644)
	_ = os.WriteFile(filepath.Join(gtk4Dir, "settings.ini"), iniContent, 0644)

	// 6. Dispatch to GSettings so running Wayland apps and xdg-desktop-portal reload styles in real-time
	if gsettings, err := exec.LookPath("gsettings"); err == nil {
		_ = exec.Command(gsettings, "set", "org.gnome.desktop.interface", "gtk-theme", themeName).Run()
		_ = exec.Command(gsettings, "set", "org.gnome.desktop.interface", "color-scheme", preferDark).Run()

		if iconName != "" {
			_ = exec.Command(gsettings, "set", "org.gnome.desktop.interface", "icon-theme", iconName).Run()
		}
		if fontName != "" {
			_ = exec.Command(gsettings, "set", "org.gnome.desktop.interface", "font-name", fontName).Run()
		}
		if cursorName != "" {
			_ = exec.Command(gsettings, "set", "org.gnome.desktop.interface", "cursor-theme", cursorName).Run()
		}
	}

	// 7. Dispatch to xfconf if available (for XFCE/Thunar components)
	if xfconfQuery, err := exec.LookPath("xfconf-query"); err == nil {
		_ = exec.Command(xfconfQuery, "-c", "xsettings", "-p", "/Net/ThemeName", "-s", themeName, "--create", "-t", "string").Run()
		if iconName != "" {
			_ = exec.Command(xfconfQuery, "-c", "xsettings", "-p", "/Net/IconThemeName", "-s", iconName, "--create", "-t", "string").Run()
		}
	}

	// 8. xsettingsd for XWayland and non-portal GTK apps
	xsettingsDir := filepath.Join(homeDir, ".config", "xsettingsd")
	_ = os.MkdirAll(xsettingsDir, 0755)
	xsettingsConf := filepath.Join(xsettingsDir, "xsettingsd.conf")

	var xsettingsLines []string
	xsettingsLines = append(xsettingsLines, `Net/ThemeName "`+themeName+`"`)
	if iconName != "" {
		xsettingsLines = append(xsettingsLines, `Net/IconThemeName "`+iconName+`"`)
	}
	if fontName != "" {
		xsettingsLines = append(xsettingsLines, `Gtk/FontName "`+fontName+`"`)
	}
	if cursorName != "" {
		xsettingsLines = append(xsettingsLines, `Gtk/CursorThemeName "`+cursorName+`"`)
	}
	xsettingsLines = append(xsettingsLines, `Net/EnableEventSounds 1`)
	xsettingsLines = append(xsettingsLines, `EnableInputFeedbackSounds 0`)
	xsettingsLines = append(xsettingsLines, `Xft/Antialias 1`)
	xsettingsLines = append(xsettingsLines, `Xft/Hinting 1`)
	xsettingsLines = append(xsettingsLines, `Xft/HintStyle "hintslight"`)
	xsettingsLines = append(xsettingsLines, `Xft/RGBA "rgb"`)
	xsettingsLines = append(xsettingsLines, "")

	_ = os.WriteFile(xsettingsConf, []byte(strings.Join(xsettingsLines, "\n")), 0644)

	// If xsettingsd binary is present: notify running process or spawn it
	if xsettingsBin, err := exec.LookPath("xsettingsd"); err == nil {
		if pgrep, err := exec.LookPath("pgrep"); err == nil && exec.Command(pgrep, "xsettingsd").Run() == nil {
			if pkill, err := exec.LookPath("pkill"); err == nil {
				_ = exec.Command(pkill, "-HUP", "xsettingsd").Run()
			}
		} else {
			cmd := exec.Command(xsettingsBin, "-c", xsettingsConf)
			cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
			_ = cmd.Start()
		}
	}

	return nil
}
