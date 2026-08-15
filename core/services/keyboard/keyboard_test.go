package keyboard

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDeduceShortCode(t *testing.T) {
	tests := []struct {
		code     string
		keymap   string
		expected string
	}{
		{"tr", "Turkish (Alt-Q)", "TR"},
		{"us", "English (US)", "EN"},
		{"gb", "English (UK)", "EN"},
		{"de", "German (nodeadkeys)", "DE"},
		{"fr", "French (AZERTY)", "FR"},
		{"es", "Spanish", "ES"},
		{"ru", "Russian", "RU"},
		{"jp", "Japanese", "JP"},
		{"az", "Azerbaijani", "AZ"},
	}

	for _, tt := range tests {
		got := DeduceShortCode(tt.code, tt.keymap)
		if got != tt.expected {
			t.Errorf("DeduceShortCode(%q, %q) = %q; want %q", tt.code, tt.keymap, got, tt.expected)
		}
	}
}

func TestParseHyprlandDevicesJSON(t *testing.T) {
	rawJSON := []byte(`{
		"keyboards": [
			{
				"address": "0x5624b74a6d60",
				"name": "video-bus",
				"layout": "tr,us",
				"variant": "alt,",
				"active_layout_index": 0,
				"active_keymap": "Turkish (Alt-Q)",
				"main": false
			},
			{
				"address": "0x5624b7bbf220",
				"name": "keyd-virtual-keyboard",
				"layout": "tr,us",
				"variant": "alt,",
				"active_layout_index": 1,
				"active_keymap": "English (US)",
				"main": true
			}
		]
	}`)

	state, err := ParseHyprlandDevicesJSON(rawJSON)
	if err != nil {
		t.Fatalf("unexpected error parsing JSON: %v", err)
	}

	if state.DeviceName != "keyd-virtual-keyboard" {
		t.Errorf("expected main keyboard 'keyd-virtual-keyboard', got %q", state.DeviceName)
	}
	if state.CurrentLayoutIndex != 1 {
		t.Errorf("expected layout index 1, got %d", state.CurrentLayoutIndex)
	}
	if state.CurrentKeymap != "English (US)" {
		t.Errorf("expected keymap 'English (US)', got %q", state.CurrentKeymap)
	}
	if state.CurrentShortCode != "EN" {
		t.Errorf("expected shortcode 'EN', got %q", state.CurrentShortCode)
	}
	if len(state.ConfiguredLayouts) != 2 || state.ConfiguredLayouts[0] != "tr" || state.ConfiguredLayouts[1] != "us" {
		t.Errorf("unexpected configured layouts: %+v", state.ConfiguredLayouts)
	}
}

func TestXKBLayoutsParser(t *testing.T) {
	layouts := ParseXKBLayouts()
	if len(layouts) == 0 {
		t.Fatalf("expected at least some XKB layouts, got 0")
	}

	// Verify that common layouts like 'tr' and 'us' exist
	foundTR := false
	foundUS := false
	for _, l := range layouts {
		if l.Code == "tr" {
			foundTR = true
		}
		if l.Code == "us" {
			foundUS = true
		}
	}

	if !foundTR {
		t.Errorf("expected to find 'tr' in XKB layouts")
	}
	if !foundUS {
		t.Errorf("expected to find 'us' in XKB layouts")
	}
}

func TestKeyboardConfigStorage(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "kb_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cfgPath := filepath.Join(tmpDir, "keyboard_config.json")

	cfg := &UserKeyboardConfig{
		Layouts:  []string{"tr", "us", "de"},
		Variants: []string{"alt", "", ""},
	}

	if err := SaveConfig(cfgPath, cfg); err != nil {
		t.Fatalf("failed to save config: %v", err)
	}

	loaded, err := LoadConfig(cfgPath)
	if err != nil {
		t.Fatalf("failed to load config: %v", err)
	}

	if len(loaded.Layouts) != 3 || loaded.Layouts[0] != "tr" || loaded.Layouts[2] != "de" {
		t.Errorf("unexpected loaded layouts: %+v", loaded.Layouts)
	}
}
