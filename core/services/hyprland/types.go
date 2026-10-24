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

// HyprState wraps active and available profiles into a single synchronized state object.
type HyprState struct {
	Active    HyprActiveProfiles    `json:"active"`
	Available HyprAvailableProfiles `json:"available"`
}

// SetProfilePayload defines the RPC request to activate a profile in a given category.
type SetProfilePayload struct {
	Category string `json:"category"`
	Name     string `json:"name"`
}

// PreviewEvalPayload defines the RPC request for 0ms live execution of a Lua snippet.
type PreviewEvalPayload struct {
	Lua string `json:"lua"`
}

// SaveCustomCurvePayload defines the payload for saving a user-defined cubic bezier curve.
type SaveCustomCurvePayload struct {
	Name   string       `json:"name"`
	Points [][2]float64 `json:"points"` // e.g. [[0.25, 0.1], [0.25, 1.0]]
}

// SaveCustomBorderPayload defines the payload for creating a custom border/decoration profile.
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
