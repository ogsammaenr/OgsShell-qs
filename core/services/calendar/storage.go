package calendar

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// GetDefaultStoragePath returns the path to calendar_events.json.
func GetDefaultStoragePath() string {
	configHome := os.Getenv("XDG_CONFIG_HOME")
	if configHome == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			homeDir = os.TempDir()
		}
		configHome = filepath.Join(homeDir, ".config")
	}
	return filepath.Join(configHome, "ogsShell", "calendar_events.json")
}

// LoadEvents reads calendar events from the JSON file.
func LoadEvents(filePath string) ([]CalendarEvent, error) {
	if filePath == "" {
		filePath = GetDefaultStoragePath()
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return []CalendarEvent{}, nil
		}
		return nil, fmt.Errorf("failed to read calendar events file: %w", err)
	}

	if len(data) == 0 {
		return []CalendarEvent{}, nil
	}

	var events []CalendarEvent
	if err := json.Unmarshal(data, &events); err != nil {
		return nil, fmt.Errorf("failed to parse calendar events JSON: %w", err)
	}

	return events, nil
}

// SaveEvents writes calendar events atomically to the JSON file.
func SaveEvents(filePath string, events []CalendarEvent) error {
	if filePath == "" {
		filePath = GetDefaultStoragePath()
	}

	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(events, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize calendar events: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", filePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary calendar events file: %w", err)
	}

	if err := os.Rename(tmpPath, filePath); err != nil {
		return fmt.Errorf("failed to commit calendar events file: %w", err)
	}

	return nil
}

// GetHolidaysCachePath returns the path to cached holidays for a given year.
func GetHolidaysCachePath(year int) string {
	cacheHome := os.Getenv("XDG_CACHE_HOME")
	if cacheHome == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			homeDir = os.TempDir()
		}
		cacheHome = filepath.Join(homeDir, ".cache")
	}
	return filepath.Join(cacheHome, "ogsShell", fmt.Sprintf("holidays_%d.json", year))
}

// LoadHolidaysCache loads cached holidays from disk.
func LoadHolidaysCache(year int) ([]Holiday, error) {
	cachePath := GetHolidaysCachePath(year)
	data, err := os.ReadFile(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to read holiday cache: %w", err)
	}

	if len(data) == 0 {
		return nil, nil
	}

	var holidays []Holiday
	if err := json.Unmarshal(data, &holidays); err != nil {
		return nil, fmt.Errorf("failed to parse holiday cache json: %w", err)
	}

	return holidays, nil
}

// SaveHolidaysCache writes verified holidays atomically to the cache directory.
func SaveHolidaysCache(year int, holidays []Holiday) error {
	cachePath := GetHolidaysCachePath(year)
	dir := filepath.Dir(cachePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create cache directory: %w", err)
	}

	data, err := json.MarshalIndent(holidays, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to serialize holiday cache: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp", cachePath)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary holiday cache file: %w", err)
	}

	if err := os.Rename(tmpPath, cachePath); err != nil {
		return fmt.Errorf("failed to commit holiday cache file: %w", err)
	}

	return nil
}

