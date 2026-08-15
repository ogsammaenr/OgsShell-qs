package alarm

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// GetDefaultConfigPath resolves the JSON storage path ($XDG_CONFIG_HOME/ogsShell/alarms.json).
func GetDefaultConfigPath() string {
	configHome := os.Getenv("XDG_CONFIG_HOME")
	if configHome == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			homeDir = os.TempDir()
		}
		configHome = filepath.Join(homeDir, ".config")
	}
	return filepath.Join(configHome, "ogsShell", "alarms.json")
}

// LoadAlarms loads all alarms from the given JSON file.
func LoadAlarms(filePath string) ([]Alarm, error) {
	if filePath == "" {
		filePath = GetDefaultConfigPath()
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return []Alarm{}, nil
		}
		return nil, fmt.Errorf("failed to read alarms file %s: %w", filePath, err)
	}

	if len(data) == 0 {
		return []Alarm{}, nil
	}

	var alarms []Alarm
	if err := json.Unmarshal(data, &alarms); err != nil {
		return nil, fmt.Errorf("failed to parse alarms JSON: %w", err)
	}

	return alarms, nil
}

// SaveAlarms atomically saves alarms to the JSON file.
func SaveAlarms(filePath string, alarms []Alarm) error {
	if filePath == "" {
		filePath = GetDefaultConfigPath()
	}

	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(alarms, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize alarms: %w", err)
	}

	// Write to temporary file first for atomic persistence
	tmpPath := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary alarms file: %w", err)
	}

	if err := os.Rename(tmpPath, filePath); err != nil {
		return fmt.Errorf("failed to commit alarms file: %w", err)
	}

	return nil
}
