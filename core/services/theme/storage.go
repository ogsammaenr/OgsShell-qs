package theme

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// DefaultSharedThemes provides the exact 6 core themes matching shared/themes/themes.json.
var DefaultSharedThemes = []ThemePalette{
	{
		ID:     "nord",
		Name:   "Nord",
		Author: "Arctic Ice Studio",
		Colors: map[string]string{
			"bg":               "#2e3440",
			"surface":          "#3b4252",
			"surface_variant":  "#3b4252",
			"card_bg":          "#3b4252",
			"fg":               "#eceff4",
			"accent":           "#88c0d0",
			"accent_secondary": "#81a1c1",
			"border":           "#88c0d0",
			"cyan":             "#88c0d0",
		},
	},
	{
		ID:     "catppuccin",
		Name:   "Catppuccin Macchiato",
		Author: "Catppuccin Org",
		Colors: map[string]string{
			"bg":               "#24273a",
			"surface":          "#363a4f",
			"surface_variant":  "#363a4f",
			"card_bg":          "#363a4f",
			"fg":               "#cad3f5",
			"accent":           "#c6a0f6",
			"accent_secondary": "#f5bde6",
			"border":           "#c6a0f6",
			"cyan":             "#8aadf4",
		},
	},
	{
		ID:     "everforest",
		Name:   "Everforest Dark",
		Author: "sainnhe",
		Colors: map[string]string{
			"bg":               "#2d353b",
			"surface":          "#343f44",
			"surface_variant":  "#343f44",
			"card_bg":          "#343f44",
			"fg":               "#d3c6aa",
			"accent":           "#a7c080",
			"accent_secondary": "#dbbc7f",
			"border":           "#a7c080",
			"cyan":             "#83c092",
		},
	},
	{
		ID:     "tokyonight",
		Name:   "Tokyo Night",
		Author: "folke",
		Colors: map[string]string{
			"bg":               "#1a1b26",
			"surface":          "#24283b",
			"surface_variant":  "#24283b",
			"card_bg":          "#24283b",
			"fg":               "#c0caf5",
			"accent":           "#7aa2f7",
			"accent_secondary": "#bb9af7",
			"border":           "#7aa2f7",
			"cyan":             "#7dcfff",
		},
	},
	{
		ID:     "gruvbox",
		Name:   "Gruvbox Dark",
		Author: "morhetz",
		Colors: map[string]string{
			"bg":               "#282828",
			"surface":          "#3c3836",
			"surface_variant":  "#3c3836",
			"card_bg":          "#3c3836",
			"fg":               "#ebdbb2",
			"accent":           "#fe8019",
			"accent_secondary": "#d79921",
			"border":           "#fe8019",
			"cyan":             "#689d6a",
		},
	},
	{
		ID:     "monochrome",
		Name:   "Monochrome Minimal",
		Author: "ogsShell",
		Colors: map[string]string{
			"bg":               "#121212",
			"surface":          "#1e1e1e",
			"surface_variant":  "#1e1e1e",
			"card_bg":          "#1e1e1e",
			"fg":               "#f0f0f0",
			"accent":           "#e0e0e0",
			"accent_secondary": "#888888",
			"border":           "#e0e0e0",
			"cyan":             "#ffffff",
		},
	},
}

// GetSharedDir locates the shared directory.
func GetSharedDir() string {
	// 1. Environment variable override
	if env := os.Getenv("OGSSHELL_SHARED_DIR"); env != "" {
		return env
	}

	// 2. Relative to current working directory
	candidates := []string{
		"shared",
		"../shared",
		"../../shared",
		"/usr/share/ogsshell/shared",
	}

	for _, cand := range candidates {
		if fi, err := os.Stat(cand); err == nil && fi.IsDir() {
			abs, err := filepath.Abs(cand)
			if err == nil {
				return abs
			}
			return cand
		}
	}

	return "shared"
}

// GetSharedThemesPath returns path to shared/themes/themes.json.
func GetSharedThemesPath(sharedDir string) string {
	if sharedDir == "" {
		sharedDir = GetSharedDir()
	}
	return filepath.Join(sharedDir, "themes", "themes.json")
}

// GetThemeConfigPath returns the persistent user theme config file path.
func GetThemeConfigPath() string {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		homeDir, _ := os.UserHomeDir()
		configDir = filepath.Join(homeDir, ".config")
	}
	return filepath.Join(configDir, "ogsShell", "theme_config.json")
}

// LoadSharedThemes loads themes directly from shared/themes/themes.json.
func LoadSharedThemes(themesJsonPath string) ([]ThemePalette, error) {
	if themesJsonPath == "" {
		themesJsonPath = GetSharedThemesPath("")
	}

	data, err := os.ReadFile(themesJsonPath)
	if err != nil {
		return DefaultSharedThemes, fmt.Errorf("shared/themes/themes.json okunamadı, varsayılanlar yükleniyor: %w", err)
	}

	var rawList []SharedThemeRaw
	if err := json.Unmarshal(data, &rawList); err != nil {
		return DefaultSharedThemes, fmt.Errorf("shared/themes/themes.json çözülemedi: %w", err)
	}

	var palettes []ThemePalette
	for _, raw := range rawList {
		author := "ogsShell"
		for _, def := range DefaultSharedThemes {
			if def.ID == raw.ID && def.Author != "" {
				author = def.Author
				break
			}
		}

		palettes = append(palettes, ThemePalette{
			ID:     raw.ID,
			Name:   raw.Name,
			Author: author,
			Colors: map[string]string{
				"bg":               raw.BG,
				"surface":          raw.CardBG,
				"surface_variant":  raw.CardBG,
				"card_bg":          raw.CardBG,
				"fg":               raw.FG,
				"accent":           raw.Accent,
				"accent_secondary": raw.Accent,
				"border":           raw.Accent,
				"cyan":             raw.Accent,
			},
		})
	}

	if len(palettes) == 0 {
		return DefaultSharedThemes, nil
	}

	return palettes, nil
}

// LoadThemeConfig loads user configuration.
func LoadThemeConfig(path string) (*UserThemeConfig, error) {
	if path == "" {
		path = GetThemeConfigPath()
	}

	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg UserThemeConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	if cfg.EnabledAdapters == nil {
		cfg.EnabledAdapters = make(map[string]bool)
	}

	return &cfg, nil
}

// SaveThemeConfig persists user configuration.
func SaveThemeConfig(path string, cfg *UserThemeConfig) error {
	if path == "" {
		path = GetThemeConfigPath()
	}

	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}

	tmpPath := fmt.Sprintf("%s.tmp", path)
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		return err
	}

	return os.Rename(tmpPath, path)
}
