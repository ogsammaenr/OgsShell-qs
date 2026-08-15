package clipboard

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// GetDefaultConfigDir returns the ogsShell base config directory ($XDG_CONFIG_HOME/ogsShell).
func GetDefaultConfigDir() string {
	configHome := os.Getenv("XDG_CONFIG_HOME")
	if configHome == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			homeDir = os.TempDir()
		}
		configHome = filepath.Join(homeDir, ".config")
	}
	return filepath.Join(configHome, "ogsShell")
}

// GetPinnedFilePath returns the path to clipboard_pinned.json.
func GetPinnedFilePath() string {
	return filepath.Join(GetDefaultConfigDir(), "clipboard_pinned.json")
}

// LoadPinned reads all pinned/favorite clipboard items from disk.
func LoadPinned(filePath string) ([]PinnedItem, error) {
	if filePath == "" {
		filePath = GetPinnedFilePath()
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return []PinnedItem{}, nil
		}
		return nil, fmt.Errorf("failed to read pinned clipboard file %s: %w", filePath, err)
	}

	if len(data) == 0 {
		return []PinnedItem{}, nil
	}

	var items []PinnedItem
	if err := json.Unmarshal(data, &items); err != nil {
		return nil, fmt.Errorf("failed to parse pinned clipboard JSON: %w", err)
	}

	return items, nil
}

// SavePinned atomically writes pinned/favorite clipboard items to disk.
func SavePinned(filePath string, items []PinnedItem) error {
	if filePath == "" {
		filePath = GetPinnedFilePath()
	}

	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(items, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize pinned clipboard items: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary pinned clipboard file: %w", err)
	}

	if err := os.Rename(tmpPath, filePath); err != nil {
		return fmt.Errorf("failed to commit pinned clipboard file: %w", err)
	}

	return nil
}
