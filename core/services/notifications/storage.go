package notifications

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// GetDefaultConfigDir returns the base directory for ogsShell configuration ($XDG_CONFIG_HOME/ogsShell).
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

// GetNotificationsFilePath returns the path to notifications.json.
func GetNotificationsFilePath() string {
	return filepath.Join(GetDefaultConfigDir(), "notifications.json")
}

// GetRulesFilePath returns the path to notification_rules.json.
func GetRulesFilePath() string {
	return filepath.Join(GetDefaultConfigDir(), "notification_rules.json")
}

// LoadNotifications reads notification history from disk.
func LoadNotifications(filePath string) ([]Notification, error) {
	if filePath == "" {
		filePath = GetNotificationsFilePath()
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return []Notification{}, nil
		}
		return nil, fmt.Errorf("failed to read notifications file %s: %w", filePath, err)
	}

	if len(data) == 0 {
		return []Notification{}, nil
	}

	var notifs []Notification
	if err := json.Unmarshal(data, &notifs); err != nil {
		return nil, fmt.Errorf("failed to parse notifications JSON: %w", err)
	}

	return notifs, nil
}

// SaveNotifications atomically writes notification history to disk.
func SaveNotifications(filePath string, notifs []Notification) error {
	if filePath == "" {
		filePath = GetNotificationsFilePath()
	}

	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(notifs, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize notifications: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary notifications file: %w", err)
	}

	if err := os.Rename(tmpPath, filePath); err != nil {
		return fmt.Errorf("failed to commit notifications file: %w", err)
	}

	return nil
}

// LoadRules reads custom notification rules from disk.
func LoadRules(filePath string) (map[string]NotificationRule, error) {
	if filePath == "" {
		filePath = GetRulesFilePath()
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]NotificationRule), nil
		}
		return nil, fmt.Errorf("failed to read rules file %s: %w", filePath, err)
	}

	if len(data) == 0 {
		return make(map[string]NotificationRule), nil
	}

	var rules map[string]NotificationRule
	if err := json.Unmarshal(data, &rules); err != nil {
		return nil, fmt.Errorf("failed to parse notification rules JSON: %w", err)
	}

	return rules, nil
}

// SaveRules atomically writes custom notification rules to disk.
func SaveRules(filePath string, rules map[string]NotificationRule) error {
	if filePath == "" {
		filePath = GetRulesFilePath()
	}

	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(rules, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize notification rules: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary rules file: %w", err)
	}

	if err := os.Rename(tmpPath, filePath); err != nil {
		return fmt.Errorf("failed to commit rules file: %w", err)
	}

	return nil
}
