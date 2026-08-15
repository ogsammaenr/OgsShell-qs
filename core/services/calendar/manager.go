package calendar

import (
	"context"
	"fmt"
	"log/slog"
	"ogsShell/core/logger"
	"os"
	"os/exec"
	"sort"
	"strings"
	"sync"
	"time"
)

// CalendarManager provides interface for calendar events, holidays, and reminder scheduling.
type CalendarManager interface {
	GetMonthData(year int, month int) MonthData
	GetHolidays(year int) []Holiday
	SyncHolidays(ctx context.Context, year int) ([]Holiday, error)
	GetEvents() []CalendarEvent
	AddEvent(event CalendarEvent) (*CalendarEvent, error)
	UpdateEvent(payload UpdateCalendarEventPayload) (*CalendarEvent, error)
	DeleteEvent(id string) error
	ToggleEventCompleted(id string, completed *bool) (*CalendarEvent, error)
	Start(ctx context.Context)
	Close() error
	SetEventsUpdateCallback(cb func(events []CalendarEvent))
	SetReminderCallback(cb func(payload CalendarReminderTriggeredPayload))
}

// DefaultCalendarManager implements CalendarManager.
type DefaultCalendarManager struct {
	filePath string
	log      *slog.Logger
	holidays *HolidayEngine

	mu       sync.RWMutex
	events   map[string]*CalendarEvent
	wakeupCh chan struct{}

	eventsUpdateCb func(events []CalendarEvent)
	reminderCb     func(payload CalendarReminderTriggeredPayload)

	done      chan struct{}
	closeOnce sync.Once
}

// NewDefaultCalendarManager creates a new DefaultCalendarManager.
func NewDefaultCalendarManager(filePath ...string) (*DefaultCalendarManager, error) {
	path := GetDefaultStoragePath()
	if len(filePath) > 0 && filePath[0] != "" {
		path = filePath[0]
	}

	loadedEvents, err := LoadEvents(path)
	if err != nil {
		logger.Module("CALENDAR").Warn("Could not load events, starting empty", "err", err)
		loadedEvents = []CalendarEvent{}
	}

	eventMap := make(map[string]*CalendarEvent)
	for i := range loadedEvents {
		e := loadedEvents[i]
		eventMap[e.ID] = &e
	}

	return &DefaultCalendarManager{
		filePath: path,
		log:      logger.Module("CALENDAR"),
		holidays: NewHolidayEngine(),
		events:   eventMap,
		wakeupCh: make(chan struct{}, 16),
		done:     make(chan struct{}),
	}, nil
}

// SetEventsUpdateCallback registers a callback for event list changes.
func (m *DefaultCalendarManager) SetEventsUpdateCallback(cb func(events []CalendarEvent)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.eventsUpdateCb = cb
}

// SetReminderCallback registers a callback for fired reminders.
func (m *DefaultCalendarManager) SetReminderCallback(cb func(payload CalendarReminderTriggeredPayload)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.reminderCb = cb
}

func (m *DefaultCalendarManager) notifyWakeup() {
	select {
	case m.wakeupCh <- struct{}{}:
	default:
	}
}

// Start runs the background reminder scheduler.
func (m *DefaultCalendarManager) Start(ctx context.Context) {
	m.log.Info("Calendar reminder engine started")

	// Background non-blocking sync for current year holidays
	go func() {
		select {
		case <-time.After(2 * time.Second):
			_, _ = m.SyncHolidays(ctx, time.Now().Year())
		case <-ctx.Done():
		case <-m.done:
		}
	}()

	go func() {
		var timer *time.Timer
		var timerC <-chan time.Time

		for {
			m.mu.Lock()
			earliest, found := m.findEarliestReminderLocked(time.Now())
			if timer != nil {
				timer.Stop()
				timer = nil
				timerC = nil
			}

			if found {
				dur := time.Until(earliest)
				if dur < 0 {
					dur = 0
				}
				timer = time.NewTimer(dur)
				timerC = timer.C
				m.log.Info("Next calendar reminder scheduled", "at", earliest.Format("2006-01-02 15:04:05"), "in", dur.Round(time.Second))
			}
			m.mu.Unlock()

			select {
			case <-ctx.Done():
				if timer != nil {
					timer.Stop()
				}
				m.log.Info("Calendar reminder engine stopped")
				return

			case <-m.done:
				if timer != nil {
					timer.Stop()
				}
				return

			case <-m.wakeupCh:
				continue

			case <-timerC:
				timer = nil
				timerC = nil
				m.handleReminderTrigger()
			}
		}
	}()
}

// SyncHolidays downloads live public holidays from online API and updates caches.
func (m *DefaultCalendarManager) SyncHolidays(ctx context.Context, year int) ([]Holiday, error) {
	if year <= 0 {
		year = time.Now().Year()
	}

	m.log.Info("Çevrim içi tatil senkronizasyonu başlatılıyor...", "year", year)
	holidays, err := m.holidays.SyncHolidaysOnline(ctx, year)
	if err != nil {
		m.log.Warn("Çevrim içi tatil senkronizasyonu başarısız (Yerel önbellek/algoritma devrede)", "err", err)
		return m.holidays.GetHolidaysForYear(year), err
	}

	m.log.Info("Çevrim içi tatiller başarıyla senkronize edildi", "count", len(holidays))
	return holidays, nil
}

func (m *DefaultCalendarManager) handleReminderTrigger() {
	now := time.Now()
	var triggeredPayloads []CalendarReminderTriggeredPayload

	m.mu.Lock()
	for _, e := range m.events {
		if !e.Completed && !e.Notified {
			remTime, ok := calculateEventReminderTime(*e)
			if ok && (!remTime.After(now) && now.Sub(remTime) < 2*time.Minute) {
				e.Notified = true
				diffMins := int(time.Until(getEventDateTime(*e)).Minutes())
				if diffMins < 0 {
					diffMins = 0
				}

				triggeredPayloads = append(triggeredPayloads, CalendarReminderTriggeredPayload{
					ID:           e.ID,
					Title:        e.Title,
					Date:         e.Date,
					Time:         e.Time,
					MinutesUntil: diffMins,
				})
			}
		}
	}

	if len(triggeredPayloads) > 0 {
		_ = SaveEvents(m.filePath, m.getEventsSliceLocked())
	}

	eventList := m.getEventsSliceLocked()
	reminderCb := m.reminderCb
	updateCb := m.eventsUpdateCb
	m.mu.Unlock()

	for _, p := range triggeredPayloads {
		m.log.Info("📅 TAKVİM HATIRLATMASI!", "id", p.ID, "title", p.Title, "date", p.Date, "time", p.Time)
		m.playAlertSound()
		if reminderCb != nil {
			reminderCb(p)
		}
	}

	if len(triggeredPayloads) > 0 && updateCb != nil {
		updateCb(eventList)
	}
}

// GetMonthData returns the month grid data with holidays and events.
func (m *DefaultCalendarManager) GetMonthData(year int, month int) MonthData {
	if year <= 0 {
		year = time.Now().Year()
	}
	if month <= 0 || month > 12 {
		month = int(time.Now().Month())
	}

	holidays := m.holidays.GetHolidaysForMonth(year, month)

	m.mu.RLock()
	prefix := fmt.Sprintf("%04d-%02d-", year, month)
	var monthEvents []CalendarEvent
	for _, e := range m.events {
		if strings.HasPrefix(e.Date, prefix) {
			monthEvents = append(monthEvents, *e)
		}
	}
	m.mu.RUnlock()

	sort.Slice(monthEvents, func(i, j int) bool {
		if monthEvents[i].Date != monthEvents[j].Date {
			return monthEvents[i].Date < monthEvents[j].Date
		}
		return monthEvents[i].Time < monthEvents[j].Time
	})

	return MonthData{
		Year:     year,
		Month:    month,
		Holidays: holidays,
		Events:   monthEvents,
	}
}

// GetHolidays returns all holidays for a given year.
func (m *DefaultCalendarManager) GetHolidays(year int) []Holiday {
	if year <= 0 {
		year = time.Now().Year()
	}
	return m.holidays.GetHolidaysForYear(year)
}

// GetEvents returns all stored calendar events.
func (m *DefaultCalendarManager) GetEvents() []CalendarEvent {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.getEventsSliceLocked()
}

// AddEvent adds, persists, and schedules a new calendar event.
func (m *DefaultCalendarManager) AddEvent(event CalendarEvent) (*CalendarEvent, error) {
	if event.Title == "" {
		return nil, fmt.Errorf("event title is required")
	}
	if event.Date == "" {
		event.Date = time.Now().Format("2006-01-02")
	}
	if _, err := time.Parse("2006-01-02", event.Date); err != nil {
		return nil, fmt.Errorf("invalid date format '%s', expected 'YYYY-MM-DD'", event.Date)
	}

	if event.Time != "" {
		var h, min int
		if _, err := fmt.Sscanf(event.Time, "%d:%d", &h, &min); err != nil || h < 0 || h > 23 || min < 0 || min > 59 {
			return nil, fmt.Errorf("invalid time format '%s', expected 'HH:MM'", event.Time)
		}
		event.Time = fmt.Sprintf("%02d:%02d", h, min)
	}

	if event.ID == "" {
		event.ID = fmt.Sprintf("evt_%d", time.Now().UnixNano())
	}

	m.mu.Lock()
	m.events[event.ID] = &event
	if err := SaveEvents(m.filePath, m.getEventsSliceLocked()); err != nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("failed to save event: %w", err)
	}
	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	m.log.Info("Yeni takvim etkinliği eklendi", "id", event.ID, "title", event.Title, "date", event.Date, "time", event.Time)
	return &event, nil
}

// UpdateEvent modifies an existing event.
func (m *DefaultCalendarManager) UpdateEvent(payload UpdateCalendarEventPayload) (*CalendarEvent, error) {
	m.mu.Lock()
	e, exists := m.events[payload.ID]
	if !exists {
		m.mu.Unlock()
		return nil, fmt.Errorf("event '%s' not found", payload.ID)
	}

	if payload.Title != nil {
		e.Title = *payload.Title
	}
	if payload.Description != nil {
		e.Description = *payload.Description
	}
	if payload.Date != nil {
		if _, err := time.Parse("2006-01-02", *payload.Date); err == nil {
			e.Date = *payload.Date
		}
	}
	if payload.Time != nil {
		e.Time = *payload.Time
	}
	if payload.AllDay != nil {
		e.AllDay = *payload.AllDay
	}
	if payload.Color != nil {
		e.Color = *payload.Color
	}
	if payload.Completed != nil {
		e.Completed = *payload.Completed
	}
	if payload.NotifyBeforeMinutes != nil {
		e.NotifyBeforeMinutes = *payload.NotifyBeforeMinutes
		e.Notified = false // Reset notified flag on reminder update
	}

	if err := SaveEvents(m.filePath, m.getEventsSliceLocked()); err != nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("failed to save updated event: %w", err)
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	m.log.Info("Takvim etkinliği güncellendi", "id", e.ID, "title", e.Title)
	return e, nil
}

// DeleteEvent removes an event by ID.
func (m *DefaultCalendarManager) DeleteEvent(id string) error {
	m.mu.Lock()
	if _, exists := m.events[id]; !exists {
		m.mu.Unlock()
		return fmt.Errorf("event '%s' not found", id)
	}

	delete(m.events, id)
	if err := SaveEvents(m.filePath, m.getEventsSliceLocked()); err != nil {
		m.mu.Unlock()
		return fmt.Errorf("failed to save events after deletion: %w", err)
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	m.log.Info("Takvim etkinliği silindi", "id", id)
	return nil
}

// ToggleEventCompleted marks an event as completed/pending.
func (m *DefaultCalendarManager) ToggleEventCompleted(id string, completed *bool) (*CalendarEvent, error) {
	m.mu.Lock()
	e, exists := m.events[id]
	if !exists {
		m.mu.Unlock()
		return nil, fmt.Errorf("event '%s' not found", id)
	}

	if completed != nil {
		e.Completed = *completed
	} else {
		e.Completed = !e.Completed
	}

	if err := SaveEvents(m.filePath, m.getEventsSliceLocked()); err != nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("failed to save toggle event state: %w", err)
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	return e, nil
}

func (m *DefaultCalendarManager) getEventsSliceLocked() []CalendarEvent {
	list := make([]CalendarEvent, 0, len(m.events))
	for _, e := range m.events {
		list = append(list, *e)
	}

	sort.Slice(list, func(i, j int) bool {
		if list[i].Date != list[j].Date {
			return list[i].Date < list[j].Date
		}
		return list[i].Time < list[j].Time
	})

	return list
}

func (m *DefaultCalendarManager) notifyUpdateLocked() {
	if m.eventsUpdateCb != nil {
		list := m.getEventsSliceLocked()
		go m.eventsUpdateCb(list)
	}
}

func (m *DefaultCalendarManager) findEarliestReminderLocked(now time.Time) (time.Time, bool) {
	var earliest time.Time
	var found bool

	for _, e := range m.events {
		if !e.Completed && !e.Notified {
			remTime, ok := calculateEventReminderTime(*e)
			if ok {
				if !remTime.After(now) {
					if now.Sub(remTime) < 2*time.Minute {
						return now, true
					}
				} else {
					if !found || remTime.Before(earliest) {
						earliest = remTime
						found = true
					}
				}
			}
		}
	}
	return earliest, found
}

func (m *DefaultCalendarManager) playAlertSound() {
	go func() {
		candidates := []string{
			"/usr/share/sounds/freedesktop/stereo/complete.oga",
			"/usr/share/sounds/freedesktop/stereo/bell.oga",
			"/usr/share/sounds/freedesktop/stereo/message.oga",
		}
		player := "pw-play"
		if _, err := exec.LookPath("pw-play"); err != nil {
			player = "paplay"
		}

		for _, sound := range candidates {
			if _, err := os.Stat(sound); err == nil {
				_ = exec.Command(player, sound).Run()
				return
			}
		}
	}()
}

// Close cleans up background channels.
func (m *DefaultCalendarManager) Close() error {
	m.closeOnce.Do(func() {
		close(m.done)
	})
	return nil
}

func calculateEventReminderTime(e CalendarEvent) (time.Time, bool) {
	eventDateTime := getEventDateTime(e)
	if eventDateTime.IsZero() {
		return time.Time{}, false
	}

	remTime := eventDateTime.Add(-time.Duration(e.NotifyBeforeMinutes) * time.Minute)
	return remTime, true
}

func getEventDateTime(e CalendarEvent) time.Time {
	timeStr := e.Time
	if timeStr == "" || e.AllDay {
		timeStr = "09:00"
	}

	fullStr := fmt.Sprintf("%s %s", e.Date, timeStr)
	t, err := time.ParseInLocation("2006-01-02 15:04", fullStr, time.Local)
	if err != nil {
		return time.Time{}
	}
	return t
}
