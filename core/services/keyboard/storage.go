package keyboard

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// UserKeyboardConfig represents persistent user keyboard layout settings.
type UserKeyboardConfig struct {
	Layouts  []string `json:"layouts"`
	Variants []string `json:"variants,omitempty"`
}

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

// GetKeyboardConfigPath returns the path to keyboard_config.json.
func GetKeyboardConfigPath() string {
	return filepath.Join(GetDefaultConfigDir(), "keyboard_config.json")
}

// LoadConfig reads user keyboard layout preferences from disk.
func LoadConfig(filePath string) (*UserKeyboardConfig, error) {
	if filePath == "" {
		filePath = GetKeyboardConfigPath()
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return &UserKeyboardConfig{
				Layouts:  []string{"tr"},
				Variants: []string{"alt"},
			}, nil
		}
		return nil, fmt.Errorf("failed to read keyboard config %s: %w", filePath, err)
	}

	if len(data) == 0 {
		return &UserKeyboardConfig{
			Layouts:  []string{"tr"},
			Variants: []string{"alt"},
		}, nil
	}

	var cfg UserKeyboardConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse keyboard config JSON: %w", err)
	}

	return &cfg, nil
}

// SaveConfig atomically writes user keyboard layout preferences to disk.
func SaveConfig(filePath string, cfg *UserKeyboardConfig) error {
	if filePath == "" {
		filePath = GetKeyboardConfigPath()
	}

	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize keyboard config: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary keyboard config file: %w", err)
	}

	if err := os.Rename(tmpPath, filePath); err != nil {
		return fmt.Errorf("failed to commit keyboard config file: %w", err)
	}

	return nil
}
