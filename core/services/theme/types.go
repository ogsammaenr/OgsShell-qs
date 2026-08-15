package theme

// SharedThemeRaw represents the raw theme object structure in shared/themes/themes.json.
type SharedThemeRaw struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Accent string `json:"accent"`
	BG     string `json:"bg"`
	FG     string `json:"fg"`
	CardBG string `json:"card_bg"`
}

// ThemePalette represents a standardized complete color palette definition sent over IPC.
type ThemePalette struct {
	ID            string            `json:"id"`                        // e.g. "catppuccin", "tokyonight", "nord"
	Name          string            `json:"name"`                      // e.g. "Catppuccin Macchiato"
	Author        string            `json:"author,omitempty"`          // Author or source
	Colors        map[string]string `json:"colors"`                    // Hex colors: "bg", "surface", "fg", "accent", "border", "card_bg", etc.
	AppThemeNames map[string]string `json:"app_theme_names,omitempty"` // Mappings for apps if needed
}

// UserThemeConfig represents persistent user preferences for active theme and adapter toggles.
type UserThemeConfig struct {
	ActiveThemeID   string          `json:"active_theme_id"`
	EnabledAdapters map[string]bool `json:"enabled_adapters"`
}

// ThemeState represents the full synthesized theme state sent over IPC.
type ThemeState struct {
	ActiveTheme     *ThemePalette   `json:"active_theme"`
	AvailableThemes []ThemePalette  `json:"available_themes"`
	EnabledAdapters map[string]bool `json:"enabled_adapters"`
}

// RPC Request Payloads
type SetThemePayload struct {
	ThemeID string `json:"theme_id"`
}

type SaveThemePayload struct {
	Theme ThemePalette `json:"theme"`
}

type DeleteThemePayload struct {
	ThemeID string `json:"theme_id"`
}

type ToggleAdapterPayload struct {
	AdapterID string `json:"adapter_id"`
	Enabled   bool   `json:"enabled"`
}

// Wallpaper Payloads
type GetThemeWallpapersPayload struct {
	ThemeID string `json:"theme_id,omitempty"`
}

type ThemeWallpapersResponse struct {
	ThemeID         string   `json:"theme_id"`
	ActiveWallpaper string   `json:"active_wallpaper"`
	Wallpapers      []string `json:"wallpapers"`
}

type SetWallpaperPayload struct {
	ThemeID       string `json:"theme_id"`
	WallpaperPath string `json:"wallpaper_path"`
}

type NextWallpaperPayload struct {
	ThemeID string `json:"theme_id,omitempty"`
}

