package adapters

import (
	"encoding/json"
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

type WallpaperState struct {
	ActiveTheme     string            `json:"active_theme"`
	ThemeWallpapers map[string]string `json:"theme_wallpapers"`
}

type WallpaperAdapter struct {
	mu         sync.Mutex
	baseDir    string
	configPath string
	state      WallpaperState
}

func NewWallpaperAdapter(customBaseDir ...string) *WallpaperAdapter {
	homeDir, _ := os.UserHomeDir()
	baseDir := filepath.Join(homeDir, "Pictures", "Wallpapers")
	if len(customBaseDir) > 0 && customBaseDir[0] != "" {
		baseDir = customBaseDir[0]
	}

	configDir := filepath.Join(homeDir, ".config", "ogsshell")
	_ = os.MkdirAll(configDir, 0755)
	configPath := filepath.Join(configDir, "wallpaper_state.json")

	adapter := &WallpaperAdapter{
		baseDir:    baseDir,
		configPath: configPath,
		state: WallpaperState{
			ThemeWallpapers: make(map[string]string),
		},
	}

	adapter.loadState()
	return adapter
}

func (a *WallpaperAdapter) ID() string   { return "wallpaper" }
func (a *WallpaperAdapter) Name() string { return "Awww Wallpaper Engine" }

func (a *WallpaperAdapter) IsInstalled() bool {
	if _, err := exec.LookPath("awww"); err == nil {
		return true
	}
	return false
}

func (a *WallpaperAdapter) loadState() {
	a.mu.Lock()
	defer a.mu.Unlock()

	data, err := os.ReadFile(a.configPath)
	if err == nil {
		_ = json.Unmarshal(data, &a.state)
	}
	if a.state.ThemeWallpapers == nil {
		a.state.ThemeWallpapers = make(map[string]string)
	}
}

func (a *WallpaperAdapter) saveState() {
	data, err := json.MarshalIndent(a.state, "", "  ")
	if err == nil {
		_ = os.WriteFile(a.configPath, data, 0644)
	}
}

// EnsureAwwwDaemon starts awww-daemon if not already running.
func (a *WallpaperAdapter) EnsureAwwwDaemon() {
	if err := exec.Command("awww", "query").Run(); err != nil {
		// Start daemon in background
		cmd := exec.Command("awww-daemon")
		_ = cmd.Start()
	}
}

// GetThemeFolderName maps theme ID to folder name under ~/Pictures/Wallpapers/
func (a *WallpaperAdapter) GetThemeFolderName(themeID string) string {
	switch strings.ToLower(themeID) {
	case "catppuccin":
		return "Catppuccin"
	case "everforest":
		return "Everforest"
	case "gruvbox":
		return "Gruvbox"
	case "monochrome":
		return "Monochrome"
	case "nord":
		return "Nord"
	case "tokyonight":
		return "TokyoNight"
	default:
		return strings.Title(themeID)
	}
}

// GetThemeWallpapers lists all image files in the theme's folder and returns active one.
func (a *WallpaperAdapter) GetThemeWallpapers(themeID string) ([]string, string, error) {
	a.mu.Lock()
	defer a.mu.Unlock()

	folderName := a.GetThemeFolderName(themeID)
	dirPath := filepath.Join(a.baseDir, folderName)

	entries, err := os.ReadDir(dirPath)
	if err != nil {
		return nil, "", fmt.Errorf("duvar kağıdı klasörü okunamadı (%s): %w", dirPath, err)
	}

	validExts := map[string]bool{
		".png":  true,
		".jpg":  true,
		".jpeg": true,
		".webp": true,
	}

	var wallpapers []string
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		ext := strings.ToLower(filepath.Ext(entry.Name()))
		if validExts[ext] {
			wallpapers = append(wallpapers, filepath.Join(dirPath, entry.Name()))
		}
	}

	sort.Strings(wallpapers)

	active := a.state.ThemeWallpapers[themeID]
	// If active is not in folder, fallback to first
	if active == "" || !fileExists(active) {
		if len(wallpapers) > 0 {
			active = wallpapers[0]
		}
	}

	return wallpapers, active, nil
}

// SetSpecificWallpaper applies a wallpaper directly and updates state.
func (a *WallpaperAdapter) SetSpecificWallpaper(themeID, wallpaperPath string) error {
	a.mu.Lock()
	defer a.mu.Unlock()

	if !fileExists(wallpaperPath) {
		return fmt.Errorf("duvar kağıdı dosyası bulunamadı: %s", wallpaperPath)
	}

	a.EnsureAwwwDaemon()

	// Apply wallpaper with smooth wipe transition
	cmd := exec.Command("awww", "img", wallpaperPath,
		"--transition-type", "wipe",
		"--transition-angle", "45",
		"--transition-duration", "2",
		"--transition-fps", "60",
	)
	if err := cmd.Run(); err != nil {
		// Fallback without transition flags
		_ = exec.Command("awww", "img", wallpaperPath).Run()
	}

	a.state.ActiveTheme = themeID
	a.state.ThemeWallpapers[themeID] = wallpaperPath
	a.saveState()

	return nil
}

// NextWallpaper cycles to the next wallpaper in the theme folder.
func (a *WallpaperAdapter) NextWallpaper(themeID string) (string, error) {
	wallpapers, active, err := a.GetThemeWallpapers(themeID)
	if err != nil || len(wallpapers) == 0 {
		return "", fmt.Errorf("klasörde görsel bulunamadı: %w", err)
	}

	nextIdx := 0
	for i, w := range wallpapers {
		if w == active {
			nextIdx = (i + 1) % len(wallpapers)
			break
		}
	}

	nextPath := wallpapers[nextIdx]
	if err := a.SetSpecificWallpaper(themeID, nextPath); err != nil {
		return "", err
	}

	return nextPath, nil
}

// Apply is called automatically when ThemeManager switches themes.
func (a *WallpaperAdapter) Apply(palette *theme.ThemePalette) error {
	wallpapers, active, err := a.GetThemeWallpapers(palette.ID)
	if err != nil || len(wallpapers) == 0 {
		return nil // Graceful if theme folder is empty or not present
	}

	target := active
	if target == "" && len(wallpapers) > 0 {
		target = wallpapers[0]
	}

	if target != "" {
		return a.SetSpecificWallpaper(palette.ID, target)
	}

	return nil
}

func fileExists(path string) bool {
	if path == "" {
		return false
	}
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}
