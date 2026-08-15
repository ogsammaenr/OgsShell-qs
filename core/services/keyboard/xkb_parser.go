package keyboard

import (
	"bufio"
	"os"
	"strings"
	"sync"
)

var (
	evdevPaths = []string{
		"/usr/share/X11/xkb/rules/evdev.lst",
		"/usr/share/X11/xkb/rules/base.lst",
	}
	cachedLayouts []AvailableLayout
	cacheMu       sync.RWMutex
)

// FallbackCommonLayouts provides a built-in list if system files are unavailable.
var FallbackCommonLayouts = []AvailableLayout{
	{Code: "tr", Description: "Turkish"},
	{Code: "us", Description: "English (US)"},
	{Code: "gb", Description: "English (UK)"},
	{Code: "de", Description: "German"},
	{Code: "fr", Description: "French"},
	{Code: "es", Description: "Spanish"},
	{Code: "it", Description: "Italian"},
	{Code: "pt", Description: "Portuguese"},
	{Code: "ru", Description: "Russian"},
	{Code: "jp", Description: "Japanese"},
	{Code: "kr", Description: "Korean"},
	{Code: "cn", Description: "Chinese"},
	{Code: "ar", Description: "Arabic"},
	{Code: "az", Description: "Azerbaijani"},
	{Code: "gr", Description: "Greek"},
	{Code: "nl", Description: "Dutch"},
	{Code: "se", Description: "Swedish"},
	{Code: "no", Description: "Norwegian"},
	{Code: "fi", Description: "Finnish"},
	{Code: "pl", Description: "Polish"},
	{Code: "cz", Description: "Czech"},
	{Code: "ua", Description: "Ukrainian"},
}

// ParseXKBLayouts parses available layouts from system XKB rules.
func ParseXKBLayouts(customPath ...string) []AvailableLayout {
	cacheMu.RLock()
	if len(cachedLayouts) > 0 && len(customPath) == 0 {
		defer cacheMu.RUnlock()
		res := make([]AvailableLayout, len(cachedLayouts))
		copy(res, cachedLayouts)
		return res
	}
	cacheMu.RUnlock()

	paths := evdevPaths
	if len(customPath) > 0 && customPath[0] != "" {
		paths = []string{customPath[0]}
	}

	for _, p := range paths {
		layouts, err := parseEvdevFile(p)
		if err == nil && len(layouts) > 0 {
			cacheMu.Lock()
			cachedLayouts = layouts
			cacheMu.Unlock()

			res := make([]AvailableLayout, len(layouts))
			copy(res, layouts)
			return res
		}
	}

	// Return fallback
	return FallbackCommonLayouts
}

func parseEvdevFile(path string) ([]AvailableLayout, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	inLayoutSection := false
	var layouts []AvailableLayout

	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)

		if strings.HasPrefix(trimmed, "!") {
			if strings.HasPrefix(trimmed, "! layout") {
				inLayoutSection = true
			} else {
				inLayoutSection = false
			}
			continue
		}

		if inLayoutSection && trimmed != "" {
			// Format: "  code            Description Text"
			parts := strings.Fields(trimmed)
			if len(parts) >= 2 {
				code := parts[0]
				desc := strings.TrimSpace(trimmed[len(code):])
				desc = strings.TrimSpace(desc)
				layouts = append(layouts, AvailableLayout{
					Code:        code,
					Description: desc,
				})
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return layouts, nil
}
