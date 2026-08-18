package launcher

import (
	"os"
	"path/filepath"
	"strings"
	"sync"
)

var (
	iconCacheOnce sync.Once
	iconCacheMu   sync.RWMutex
	systemIcons   map[string]string
)

// InitSystemIconCache scans standard Linux XDG icon directories and populates the in-memory icon map.
func InitSystemIconCache() {
	iconCacheOnce.Do(func() {
		RebuildIconCache()
	})
}

// RebuildIconCache rescans icon directories.
func RebuildIconCache() {
	home, _ := os.UserHomeDir()
	iconDirs := []string{
		filepath.Join(home, ".local/share/icons"),
		filepath.Join(home, ".icons"),
		"/usr/share/pixmaps",
		"/usr/share/icons",
		"/var/lib/flatpak/exports/share/icons",
	}

	newMap := make(map[string]string, 4096)

	// Scan in reverse order so user directories take priority over system ones
	for i := len(iconDirs) - 1; i >= 0; i-- {
		dir := iconDirs[i]
		if _, err := os.Stat(dir); err != nil {
			continue
		}

		_ = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil || info == nil || info.IsDir() {
				return nil
			}

			ext := strings.ToLower(filepath.Ext(info.Name()))
			if ext != ".svg" && ext != ".png" && ext != ".xpm" {
				return nil
			}

			baseName := strings.ToLower(strings.TrimSuffix(info.Name(), ext))

			// Preference: SVGs or scalable/apps paths override small PNGs
			existing, exists := newMap[baseName]
			if !exists {
				newMap[baseName] = path
			} else {
				// If new is SVG and old is not, upgrade
				if ext == ".svg" && !strings.HasSuffix(existing, ".svg") {
					newMap[baseName] = path
				} else if strings.Contains(path, "scalable") || strings.Contains(path, "apps") {
					newMap[baseName] = path
				}
			}

			return nil
		})
	}

	iconCacheMu.Lock()
	systemIcons = newMap
	iconCacheMu.Unlock()
}

// ResolveIcon returns the absolute path to a matching icon file on disk, or empty string if not found.
func ResolveIcon(rawIcon, execBinary, desktopID string) string {
	InitSystemIconCache()

	raw := strings.TrimSpace(rawIcon)

	// 1. If already an absolute path
	if strings.HasPrefix(raw, "/") {
		if _, err := os.Stat(raw); err == nil {
			return raw
		}
	}

	// 2. Strip standard file extension if present
	cleanRaw := raw
	ext := filepath.Ext(cleanRaw)
	if ext == ".png" || ext == ".svg" || ext == ".xpm" || ext == ".ico" {
		cleanRaw = strings.TrimSuffix(cleanRaw, ext)
	}
	cleanRaw = strings.ToLower(cleanRaw)

	iconCacheMu.RLock()
	defer iconCacheMu.RUnlock()

	// 3. Exact lookup in system icon cache
	if cleanRaw != "" {
		if path, found := systemIcons[cleanRaw]; found {
			return path
		}
	}

	// 4. Try execBinary lookup
	if execBinary != "" {
		execClean := strings.ToLower(strings.TrimSpace(execBinary))
		if path, found := systemIcons[execClean]; found {
			return path
		}
	}

	// 5. Try desktop ID lookup (e.g. "org.kde.konsole" -> "konsole" or "org.kde.konsole")
	if desktopID != "" {
		baseID := strings.ToLower(strings.TrimSuffix(desktopID, ".desktop"))
		if path, found := systemIcons[baseID]; found {
			return path
		}
		// If reverse-domain (e.g. "org.kde.dolphin"), try last component ("dolphin")
		parts := strings.Split(baseID, ".")
		if len(parts) > 1 {
			lastPart := parts[len(parts)-1]
			if path, found := systemIcons[lastPart]; found {
				return path
			}
		}
	}

	// Not found on disk -> return empty string (QML will use Hyprland default SVG fallback)
	return ""
}
