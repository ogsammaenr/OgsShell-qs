package keyboard

// KeyboardState represents the active keyboard state synthesized from Hyprland devices.
type KeyboardState struct {
	DeviceName         string   `json:"device_name"`          // Main keyboard identifier
	CurrentLayoutIndex int      `json:"current_layout_index"` // Active layout index (0, 1, ...)
	CurrentKeymap      string   `json:"current_keymap"`       // e.g. "Turkish (Alt-Q)"
	CurrentShortCode   string   `json:"current_short_code"`   // e.g. "TR", "EN", "DE"
	CurrentLayoutCode  string   `json:"current_layout_code"`  // e.g. "tr", "us"
	ConfiguredLayouts  []string `json:"configured_layouts"`   // e.g. ["tr", "us"]
	ConfiguredVariants []string `json:"configured_variants"`  // e.g. ["alt", ""]
}

// AvailableLayout represents a system layout from the XKB database.
type AvailableLayout struct {
	Code        string `json:"code"`        // e.g. "tr"
	Description string `json:"description"` // e.g. "Turkish"
}

// SwitchLayoutPayload defines the RPC request for cycling or picking a layout.
type SwitchLayoutPayload struct {
	Target string `json:"target,omitempty"` // "next", "prev", or index "0", "1"
	Device string `json:"device,omitempty"` // Default: "all"
}

// SetConfiguredLayoutsPayload defines the RPC request for configuring active layout list.
type SetConfiguredLayoutsPayload struct {
	Layouts  []string `json:"layouts"`            // e.g. ["tr", "us"]
	Variants []string `json:"variants,omitempty"` // e.g. ["alt", ""]
}

// HyprlandDeviceJSON represents the raw keyboard structure returned by `hyprctl devices -j`.
type HyprlandDeviceJSON struct {
	Keyboards []HyprlandKeyboardJSON `json:"keyboards"`
}

type HyprlandKeyboardJSON struct {
	Address           string `json:"address"`
	Name              string `json:"name"`
	Rules             string `json:"rules"`
	Model             string `json:"model"`
	Layout            string `json:"layout"`
	Variant           string `json:"variant"`
	Options           string `json:"options"`
	ActiveLayoutIndex int    `json:"active_layout_index"`
	ActiveKeymap      string `json:"active_keymap"`
	CapsLock          bool   `json:"capsLock"`
	NumLock           bool   `json:"numLock"`
	Main              bool   `json:"main"`
}
