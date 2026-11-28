package hyprland

// HyprActiveProfiles represents the active profile names loaded from active_state.lua.
type HyprActiveProfiles struct {
	MonitorProfile      string `json:"monitor_profile"`
	EnvironmentsProfile string `json:"enviroments_profile"`
	ThemeProfile        string `json:"theme_profile"`
	BorderProfile       string `json:"border_profile"`
	AnimationProfile    string `json:"animation_profile"`
	WorkspaceAnimation  string `json:"workspace_animation"`
	WindowAnimation     string `json:"window_animation"`
	LayerAnimation      string `json:"layer_animation"`
}

// HyprAvailableProfiles contains lists of available profile choices in each category.
type HyprAvailableProfiles struct {
	Borders      []string `json:"borders"`
	Animations   []string `json:"animations"`
	Workspaces   []string `json:"workspaces"`
	Windows      []string `json:"windows"`
	Layers       []string `json:"layers"`
	Themes       []string `json:"themes"`
	Monitors     []string `json:"monitors"`
	Environments []string `json:"environments"`
}

// =========================================================================
// Hyprland 0.57.2 Unified Blur Configuration (11 Native Shader Variants)
// =========================================================================

type BlurGlassConfig struct {
	Refraction int     `json:"refraction"` // 0..20
	Size       int     `json:"size"`       // 4..512
	Roughness  float64 `json:"roughness"`  // 0..1
}

type BlurAcrylicConfig struct {
	Refraction int     `json:"refraction"` // 0..48
	Bulb       int     `json:"bulb"`       // 4..256
	Clarity    float64 `json:"clarity"`    // 0..1
	Aberration float64 `json:"aberration"` // 0..0.25
	Tint       string  `json:"tint"`       // RRGGBBAA hex (e.g. 14eef5ff)
}

type BlurDropsConfig struct {
	Speed float64 `json:"speed"` // 0..10
}

type BlurHeatShimmerConfig struct {
	Speed float64 `json:"speed"` // 0..10
}

type BlurAuroraConfig struct {
	Speed     float64 `json:"speed"`     // 0..10
	Intensity float64 `json:"intensity"` // 0..1
	Color1    string  `json:"color1"`    // RRGGBBAA hex
	Color2    string  `json:"color2"`    // RRGGBBAA hex
}

type BlurHazeConfig struct {
	Intensity   float64 `json:"intensity"`   // 0..1
	Iridescence float64 `json:"iridescence"` // 0..1
}

type BlurRippleConfig struct {
	Strength float64 `json:"strength"` // 0..32
	Radius   int     `json:"radius"`   // 1..1000
	Width    int     `json:"width"`    // 1..200
	Duration float64 `json:"duration"` // 0.05..5
}

type BlurWaterConfig struct {
	Strength float64 `json:"strength"` // 0..32
	Radius   int     `json:"radius"`   // 1..1000
	Speed    float64 `json:"speed"`    // 0..10
	Damping  float64 `json:"damping"`  // 0..1
	Duration float64 `json:"duration"` // 0.5..60
}

type BlurFluidJarConfig struct {
	Speed      float64 `json:"speed"`       // 0..10
	FillAmount float64 `json:"fill_amount"` // 0..1
	Mass       float64 `json:"mass"`        // 0.1..10
	Precision  float64 `json:"precision"`   // 0.5..8
	Turbulence float64 `json:"turbulence"`  // 0..5
	Distortion float64 `json:"distortion"`  // 0..10
	Color      string  `json:"color"`       // RRGGBBAA hex
}

type BlurConfig struct {
	Enabled          bool                  `json:"enabled"`
	Variant          string                `json:"variant"` // kawase, frost, ripple, drops, water, fluid_jar, prism, heat_shimmer, acrylic, aurora, haze
	Size             int                   `json:"size"`    // 0..100
	Passes           int                   `json:"passes"`  // 0..10
	IgnoreOpacity    bool                  `json:"ignore_opacity"`
	NewOptimizations bool                  `json:"new_optimizations"`
	Xray             bool                  `json:"xray"`
	Proportional     bool                  `json:"proportional"`
	Noise            float64               `json:"noise"`             // 0..1
	Contrast         float64               `json:"contrast"`          // 0..2
	Brightness       float64               `json:"brightness"`        // 0..2
	Vibrancy         float64               `json:"vibrancy"`          // 0..1
	VibrancyDarkness float64               `json:"vibrancy_darkness"` // 0..1
	Special          bool                  `json:"special"`
	Popups           bool                  `json:"popups"`
	Glass            BlurGlassConfig       `json:"glass"`
	Acrylic          BlurAcrylicConfig     `json:"acrylic"`
	Drops            BlurDropsConfig       `json:"drops"`
	HeatShimmer      BlurHeatShimmerConfig `json:"heat_shimmer"`
	Aurora           BlurAuroraConfig      `json:"aurora"`
	Haze             BlurHazeConfig        `json:"haze"`
	Ripple           BlurRippleConfig      `json:"ripple"`
	Water            BlurWaterConfig       `json:"water"`
	FluidJar         BlurFluidJarConfig    `json:"fluid_jar"`
}

// =========================================================================
// Unified Appearance & 7-Leaf Modular Animation State
// =========================================================================

type AppearanceConfig struct {
	BorderSize          int        `json:"border_size"`
	BorderColorMode     string     `json:"border_color_mode"`     // "theme" | "custom"
	ActiveBorderColor   string     `json:"active_border_color"`   // hex RRGGBB or RRGGBBAA
	ActiveBorderColor2  string     `json:"active_border_color_2"` // optional gradient 2nd color (empty = solid)
	BorderGradientAngle int        `json:"border_gradient_angle"` // 0..360 deg
	InactiveBorderColor string     `json:"inactive_border_color"` // hex RRGGBB or RRGGBBAA
	GapsIn              int        `json:"gaps_in"`
	GapsOut             int        `json:"gaps_out"`
	Rounding            int        `json:"rounding"`
	RoundingPower       float64    `json:"rounding_power"`
	ActiveOpacity       float64    `json:"active_opacity"`
	InactiveOpacity     float64    `json:"inactive_opacity"`
	ShadowEnabled       bool       `json:"shadow_enabled"`
	ShadowRange         int        `json:"shadow_range"`
	ShadowPower         int        `json:"shadow_render_power"`
	DimInactive         bool       `json:"dim_inactive"`
	DimStrength         float64    `json:"dim_strength"`
	Blur                BlurConfig `json:"blur"`
}

type AnimationLeaf struct {
	Enabled bool    `json:"enabled"`
	Speed   float64 `json:"speed"`
	Bezier  string  `json:"bezier"`
	Style   string  `json:"style"`
}

type AnimationsConfig struct {
	Enabled     bool          `json:"enabled"`
	WindowsIn   AnimationLeaf `json:"windows_in"`
	WindowsOut  AnimationLeaf `json:"windows_out"`
	WindowsMove AnimationLeaf `json:"windows_move"`
	Workspaces  AnimationLeaf `json:"workspaces"`
	Layers      AnimationLeaf `json:"layers"`
	Fade        AnimationLeaf `json:"fade"`
	Border      AnimationLeaf `json:"border"`
}

type AppearancePreset struct {
	ID          string           `json:"id"`
	Name        string           `json:"name"`
	Description string           `json:"description"`
	Builtin     bool             `json:"builtin"`
	Config      AppearanceConfig `json:"config"`
}

type AnimationPreset struct {
	ID          string           `json:"id"`
	Name        string           `json:"name"`
	Description string           `json:"description"`
	Builtin     bool             `json:"builtin"`
	Config      AnimationsConfig `json:"config"`
}

// HyprUnifiedConfig is persisted in ~/.config/ogsShell/hyprland_config.json.
type HyprUnifiedConfig struct {
	ActiveAppearancePreset  string             `json:"active_appearance_preset"`
	ActiveAnimationPreset   string             `json:"active_animation_preset"`
	GameMode                bool               `json:"game_mode"`
	Appearance              AppearanceConfig   `json:"appearance"`
	Animations              AnimationsConfig   `json:"animations"`
	CustomAppearancePresets []AppearancePreset `json:"custom_appearance_presets"`
	CustomAnimationPresets  []AnimationPreset  `json:"custom_animation_presets"`
}

// HyprState wraps legacy profiles + unified config + presets + curves into one synchronized broadcast.
type HyprState struct {
	Active            HyprActiveProfiles    `json:"active"`
	Available         HyprAvailableProfiles `json:"available"`
	Config            HyprUnifiedConfig     `json:"config"`
	AppearancePresets []AppearancePreset    `json:"appearance_presets"`
	AnimationPresets  []AnimationPreset     `json:"animation_presets"`
	AvailableCurves   []string              `json:"available_curves"`
}

// =========================================================================
// RPC Action Payloads
// =========================================================================

type SetProfilePayload struct {
	Category string `json:"category"`
	Name     string `json:"name"`
}

type PreviewEvalPayload struct {
	Lua string `json:"lua"`
}

type SaveCustomCurvePayload struct {
	Name   string       `json:"name"`
	Points [][2]float64 `json:"points"`
}

type SaveCustomBorderPayload struct {
	Name            string  `json:"name"`
	BorderSize      int     `json:"border_size"`
	GapsIn          int     `json:"gaps_in"`
	GapsOut         int     `json:"gaps_out"`
	Rounding        int     `json:"rounding"`
	RoundingPower   float64 `json:"rounding_power"`
	ActiveOpacity   float64 `json:"active_opacity"`
	InactiveOpacity float64 `json:"inactive_opacity"`
	ShadowEnabled   bool    `json:"shadow_enabled"`
	ShadowRange     int     `json:"shadow_range"`
	ShadowPower     int     `json:"shadow_render_power"`
	ShadowOffset    [2]int  `json:"shadow_offset"`
	ShadowColor     string  `json:"shadow_color"`
	DimInactive     bool    `json:"dim_inactive"`
	DimStrength     float64 `json:"dim_strength"`
}

type ApplyAppearancePayload struct {
	Appearance AppearanceConfig `json:"appearance"`
	PresetID   string           `json:"preset_id"`
}

type ApplyAnimationsPayload struct {
	Animations AnimationsConfig `json:"animations"`
	PresetID   string           `json:"preset_id"`
}

type ApplyPresetPayload struct {
	Kind     string `json:"kind"` // "appearance" | "animation"
	PresetID string `json:"preset_id"`
}

type SavePresetPayload struct {
	Kind        string `json:"kind"` // "appearance" | "animation"
	Name        string `json:"name"`
	Description string `json:"description"`
}

type DeletePresetPayload struct {
	Kind     string `json:"kind"` // "appearance" | "animation"
	PresetID string `json:"preset_id"`
}

type SetGameModePayload struct {
	Enabled bool `json:"enabled"`
}
