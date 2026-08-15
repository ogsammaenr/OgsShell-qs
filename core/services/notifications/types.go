package notifications

// RuleMode represents how notifications from a specific application are handled.
type RuleMode string

const (
	// RuleModeNormal allows both transient popup on Dynamic Island and saving to history.
	RuleModeNormal RuleMode = "normal"
	// RuleModeMute silences transient popups on Dynamic Island but saves to history.
	RuleModeMute RuleMode = "mute"
	// RuleModeBlock discards notifications completely (no popup, not saved to history).
	RuleModeBlock RuleMode = "block"
	// RuleModePriority allows transient popups even when Do Not Disturb (DND) is active.
	RuleModePriority RuleMode = "priority"
)

// Notification represents a single stored or incoming desktop alert.
type Notification struct {
	ID        string `json:"id"`
	AppName   string `json:"app_name"`
	Summary   string `json:"summary"`
	Body      string `json:"body"`
	Icon      string `json:"icon,omitempty"`
	Urgency   string `json:"urgency"` // "low" | "normal" | "critical"
	Timestamp int64  `json:"timestamp"`
	Read      bool   `json:"read"`
}

// NotificationRule defines customized filtering/muting behavior for a specific app.
type NotificationRule struct {
	AppName      string   `json:"app_name"`
	Mode         RuleMode `json:"mode"`
	SoundEnabled bool     `json:"sound_enabled"`
}

// NotificationState encapsulates the full state of the notification subsystem.
type NotificationState struct {
	DNDEnabled    bool                        `json:"dnd_enabled"`
	Notifications []Notification              `json:"notifications"`
	Rules         map[string]NotificationRule `json:"rules"`
}

// AddNotificationPayload defines the request parameters when submitting a new notification.
type AddNotificationPayload struct {
	AppName string `json:"app_name"`
	Summary string `json:"summary"`
	Body    string `json:"body"`
	Icon    string `json:"icon,omitempty"`
	Urgency string `json:"urgency,omitempty"`
}

// NotificationReceivedPayload defines the event broadcast when an alert is processed.
type NotificationReceivedPayload struct {
	Notification Notification `json:"notification"`
	ShouldPopup  bool         `json:"should_popup"`
	Reason       string       `json:"reason"` // "normal" | "dnd_suppressed" | "app_muted" | "priority_override" | "critical_override"
}

// ToggleDNDPayload defines the RPC request for toggling or explicitly setting DND mode.
type ToggleDNDPayload struct {
	Enabled *bool `json:"enabled,omitempty"`
}

// SetRulePayload defines the RPC request for configuring an application rule.
type SetRulePayload struct {
	AppName      string   `json:"app_name"`
	Mode         RuleMode `json:"mode"`
	SoundEnabled *bool    `json:"sound_enabled,omitempty"`
}

// DeleteRulePayload defines the RPC request for removing an application rule.
type DeleteRulePayload struct {
	AppName string `json:"app_name"`
}

// DeleteNotificationPayload defines the RPC request for removing a single notification from history.
type DeleteNotificationPayload struct {
	ID string `json:"id"`
}

// MarkReadPayload defines the RPC request for marking one or all notifications as read.
type MarkReadPayload struct {
	ID  string `json:"id,omitempty"`
	All bool   `json:"all,omitempty"`
}
