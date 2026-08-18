package entry

// AppEntry represents an enriched, indexed desktop application.
type AppEntry struct {
	ID          string   `json:"id"`                     // File name (e.g. "org.gimp.GIMP.desktop" or "gimp.desktop")
	Name        string   `json:"name"`                   // Display name ("GNU Image Manipulation Program")
	GenericName string   `json:"generic_name,omitempty"` // Generic description ("Image Editor")
	Exec        string   `json:"exec"`                   // Cleaned execution command ("gimp-2.10")
	ExecBinary  string   `json:"exec_binary,omitempty"`  // Base executable binary name ("gimp-2.10" or "gimp")
	Icon        string   `json:"icon,omitempty"`         // System icon name or absolute path ("gimp")
	Categories  []string `json:"categories,omitempty"`   // ["Graphics", "RasterEditor"]
	Keywords    []string `json:"keywords,omitempty"`     // ["photo", "paint", "edit"]
	Acronym     string   `json:"acronym,omitempty"`      // Derived acronym from Name ("gimp")
	SearchText  string   `json:"-"`                      // Pre-aggregated lowercase normalized search token pool
	LaunchCount int      `json:"launch_count"`           // Frecency / usage count
	Score       int      `json:"score,omitempty"`        // Transient search score (0-100+)
	Comment     string   `json:"comment,omitempty"`      // Tooltip / description comment
	Path        string   `json:"path,omitempty"`         // Absolute path to the .desktop file
	Terminal    bool     `json:"terminal,omitempty"`     // Whether the application runs in terminal
}

// SearchQueryPayload represents incoming IPC query parameters for searching applications.
type SearchQueryPayload struct {
	Query string `json:"query"`
	Limit int    `json:"limit,omitempty"`
}

// LaunchAppPayload represents incoming IPC command to launch an application.
type LaunchAppPayload struct {
	ID   string `json:"id"`
	Exec string `json:"exec,omitempty"`
}

// ListAppsPayload represents incoming IPC request to list indexed applications.
type ListAppsPayload struct {
	Limit int `json:"limit,omitempty"`
}

// AppSearchResultPayload represents outgoing search results over IPC.
type AppSearchResultPayload struct {
	Query   string     `json:"query"`
	Results []AppEntry `json:"results"`
	Total   int        `json:"total"`
}

// AppLaunchedPayload represents outgoing launch notification over IPC.
type AppLaunchedPayload struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Success bool   `json:"success"`
	Error   string `json:"error,omitempty"`
}
