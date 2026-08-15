package calendar

// Holiday represents a national or religious holiday in Turkey.
type Holiday struct {
	Date      string `json:"date"`        // "YYYY-MM-DD"
	Name      string `json:"name"`        // e.g. "Cumhuriyet Bayramı"
	IsHalfDay bool   `json:"is_half_day"` // e.g. Arefe günleri
	Type      string `json:"type"`        // "national" | "religious" | "observance"
}

// CalendarEvent represents a user-created reminder or event.
type CalendarEvent struct {
	ID                  string `json:"id"`                              // Unique identifier
	Title               string `json:"title"`                           // Event title
	Description         string `json:"description,omitempty"`           // Optional description
	Date                string `json:"date"`                            // "YYYY-MM-DD"
	Time                string `json:"time,omitempty"`                  // "HH:MM" (optional for all-day)
	AllDay              bool   `json:"all_day"`                         // All-day flag
	Color               string `json:"color,omitempty"`                 // Hex color or style token
	Completed           bool   `json:"completed"`                       // Whether event is marked completed
	NotifyBeforeMinutes int    `json:"notify_before_minutes,omitempty"` // Reminder notice in minutes
	Notified            bool   `json:"notified"`                        // Whether reminder has already fired
}

// MonthData encapsulates all days, holidays, and events for a calendar month.
type MonthData struct {
	Year     int             `json:"year"`
	Month    int             `json:"month"` // 1-12
	Holidays []Holiday       `json:"holidays"`
	Events   []CalendarEvent `json:"events"`
}

// AddCalendarEventPayload defines the payload for adding an event.
type AddCalendarEventPayload struct {
	Title               string `json:"title"`
	Description         string `json:"description,omitempty"`
	Date                string `json:"date"`                            // "YYYY-MM-DD"
	Time                string `json:"time,omitempty"`                  // "HH:MM"
	AllDay              bool   `json:"all_day,omitempty"`
	Color               string `json:"color,omitempty"`
	NotifyBeforeMinutes int    `json:"notify_before_minutes,omitempty"`
}

// UpdateCalendarEventPayload defines the payload for modifying an event.
type UpdateCalendarEventPayload struct {
	ID                  string  `json:"id"`
	Title               *string `json:"title,omitempty"`
	Description         *string `json:"description,omitempty"`
	Date                *string `json:"date,omitempty"`
	Time                *string `json:"time,omitempty"`
	AllDay              *bool   `json:"all_day,omitempty"`
	Color               *string `json:"color,omitempty"`
	Completed           *bool   `json:"completed,omitempty"`
	NotifyBeforeMinutes *int    `json:"notify_before_minutes,omitempty"`
}

// DeleteCalendarEventPayload defines the payload for deleting an event.
type DeleteCalendarEventPayload struct {
	ID string `json:"id"`
}

// ToggleCalendarEventPayload defines the payload for toggling event completion.
type ToggleCalendarEventPayload struct {
	ID        string `json:"id"`
	Completed *bool  `json:"completed,omitempty"`
}

// GetCalendarMonthPayload defines the payload for querying month data.
type GetCalendarMonthPayload struct {
	Year  int `json:"year"`
	Month int `json:"month"`
}

// GetHolidaysPayload defines the payload for querying holidays of a year.
type GetHolidaysPayload struct {
	Year int `json:"year"`
}

// CalendarReminderTriggeredPayload defines the IPC broadcast event when a reminder fires.
type CalendarReminderTriggeredPayload struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Date         string `json:"date"`
	Time         string `json:"time"`
	MinutesUntil int    `json:"minutes_until"`
}
