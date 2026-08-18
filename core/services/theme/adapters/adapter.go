package adapters

import (
	"fmt"
	"ogsShell/core/services/theme"
	"os"
	"path/filepath"
)

// AppAdapter defines the contract for an application theme adapter.
type AppAdapter interface {
	ID() string
	Name() string
	IsInstalled() bool
	Apply(palette *theme.ThemePalette) error
}

// CopyFile atomically copies a file from src to dst.
func CopyFile(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return fmt.Errorf("kaynak dosya okunamadı (%s): %w", src, err)
	}

	if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
		return fmt.Errorf("hedef dizin oluşturulamadı (%s): %w", filepath.Dir(dst), err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", dst)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("geçici dosya yazılamadı (%s): %w", tmpPath, err)
	}

	return os.Rename(tmpPath, dst)
}

// WriteFileInPlace writes data directly to dst preserving the file inode so file watchers (like inotify) remain attached.
func WriteFileInPlace(dst string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
		return fmt.Errorf("hedef dizin oluşturulamadı (%s): %w", filepath.Dir(dst), err)
	}
	f, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("dosya açılamadı (%s): %w", dst, err)
	}
	defer f.Close()

	if _, err := f.Write(data); err != nil {
		return fmt.Errorf("dosya yazılamadı (%s): %w", dst, err)
	}
	return f.Sync()
}

// CopyFileInPlace copies file content directly into dst preserving the destination file's inode.
func CopyFileInPlace(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return fmt.Errorf("kaynak dosya okunamadı (%s): %w", src, err)
	}
	return WriteFileInPlace(dst, data)
}

// GetSharedAppConfigFile locates the theme configuration file in shared/app_configs/<app>/<theme>.<ext>.
func GetSharedAppConfigFile(sharedDir, appName, themeID, ext string) (string, error) {
	if sharedDir == "" {
		sharedDir = theme.GetSharedDir()
	}

	candidate := filepath.Join(sharedDir, "app_configs", appName, fmt.Sprintf("%s.%s", themeID, ext))
	if _, err := os.Stat(candidate); err == nil {
		return candidate, nil
	}

	// Fallback to searching without leading prefix/dash if any
	return candidate, fmt.Errorf("tema yapılandırma dosyası bulunamadı: %s", candidate)
}
