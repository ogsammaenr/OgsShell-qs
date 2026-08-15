package alarm

// Alarm represents a scheduled, persistent user alarm.
type Alarm struct {
	ID          string `json:"id"`           // Unique identifier (UUID or timestamp)
	Time        string `json:"time"`         // "HH:MM" format (e.g. "07:30")
	Days        []int  `json:"days"`         // Days of week: 1=Mon..7=Sun (empty for one-shot)
	Label       string `json:"label"`        // Alarm label / title
	Enabled     bool   `json:"enabled"`      // Whether alarm is active
	SoundPath   string `json:"sound_path"`   // Custom audio file (.wav/.ogg) path
	SnoozeCount int    `json:"snooze_count"` // Number of times currently snoozed
}

// AddAlarmPayload defines the RPC request for creating a new alarm.
type AddAlarmPayload struct {
	Time      string `json:"time"`
	Days      []int  `json:"days,omitempty"`
	Label     string `json:"label,omitempty"`
	Enabled   *bool  `json:"enabled,omitempty"`
	SoundPath string `json:"sound_path,omitempty"`
}

// DeleteAlarmPayload defines the RPC request for deleting an alarm.
type DeleteAlarmPayload struct {
	ID string `json:"id"`
}

// ToggleAlarmPayload defines the RPC request for toggling/setting alarm enabled state.
type ToggleAlarmPayload struct {
	ID      string `json:"id"`
	Enabled *bool  `json:"enabled,omitempty"`
}

// SnoozeAlarmPayload defines the RPC request for snoozing an alarm.
type SnoozeAlarmPayload struct {
	ID      string `json:"id,omitempty"`
	Minutes int    `json:"minutes,omitempty"` // Default 5 minutes if <= 0
}

// DismissAlarmPayload defines the RPC request for dismissing a ringing alarm.
type DismissAlarmPayload struct {
	ID string `json:"id,omitempty"`
}

// AlarmTriggeredPayload defines the IPC event broadcast when an alarm fires.
type AlarmTriggeredPayload struct {
	ID    string `json:"id"`
	Label string `json:"label"`
	Time  string `json:"time"`
}
