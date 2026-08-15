package alarm

import (
	"context"
	"fmt"
	"log/slog"
	"ogsShell/core/logger"
	"os"
	"os/exec"
	"sort"
	"sync"
	"time"
)

// AlarmManager defines the standard interface for persistent alarm operations and scheduling.
type AlarmManager interface {
	// AddAlarm registers and persists a new alarm.
	AddAlarm(alarm Alarm) (*Alarm, error)

	// DeleteAlarm removes an alarm by ID.
	DeleteAlarm(id string) error

	// ToggleAlarm toggles or explicitly sets an alarm's enabled state.
	ToggleAlarm(id string, enabled *bool) (*Alarm, error)

	// SnoozeAlarm snoozes a ringing/active alarm for the specified number of minutes.
	SnoozeAlarm(id string, minutes int) (*Alarm, error)

	// DismissAlarm stops the ringing audio and resets snooze/one-shot state.
	DismissAlarm(id string) error

	// GetAlarms returns a snapshot list of all alarms.
	GetAlarms() []Alarm

	// Start begins the event-driven scheduling loop.
	Start(ctx context.Context)

	// Close terminates any active timers or audio processes.
	Close() error

	// SetTriggerCallback registers a callback invoked when an alarm matures.
	SetTriggerCallback(cb func(alarm Alarm))

	// SetUpdateCallback registers a callback invoked when the alarm list changes.
	SetUpdateCallback(cb func(alarms []Alarm))
}

// DefaultAlarmManager is the production implementation of AlarmManager.
type DefaultAlarmManager struct {
	filePath string
	log      *slog.Logger

	mu           sync.RWMutex
	alarms       map[string]*Alarm
	snoozedUntil map[string]time.Time

	wakeupCh chan struct{}

	triggerCb func(alarm Alarm)
	updateCb  func(alarms []Alarm)

	audioMu           sync.Mutex
	activeAudioCmd    *exec.Cmd
	activeAudioCancel context.CancelFunc
	activeAlarmID     string

	done      chan struct{}
	closeOnce sync.Once
}

// NewDefaultAlarmManager creates a new AlarmManager, loading alarms from disk.
func NewDefaultAlarmManager(filePath ...string) (*DefaultAlarmManager, error) {
	path := GetDefaultConfigPath()
	if len(filePath) > 0 && filePath[0] != "" {
		path = filePath[0]
	}

	loadedAlarms, err := LoadAlarms(path)
	if err != nil {
		logger.Module("ALARM").Warn("Alarms could not be read, starting with empty set", "err", err)
		loadedAlarms = []Alarm{}
	}

	alarmMap := make(map[string]*Alarm)
	for i := range loadedAlarms {
		a := loadedAlarms[i]
		alarmMap[a.ID] = &a
	}

	mgr := &DefaultAlarmManager{
		filePath:     path,
		log:          logger.Module("ALARM"),
		alarms:       alarmMap,
		snoozedUntil: make(map[string]time.Time),
		wakeupCh:     make(chan struct{}, 16),
		done:         make(chan struct{}),
	}

	return mgr, nil
}

// SetTriggerCallback sets the callback for alarm trigger events.
func (m *DefaultAlarmManager) SetTriggerCallback(cb func(alarm Alarm)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.triggerCb = cb
}

// SetUpdateCallback sets the callback for alarm list modifications.
func (m *DefaultAlarmManager) SetUpdateCallback(cb func(alarms []Alarm)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCb = cb
}

func (m *DefaultAlarmManager) notifyWakeup() {
	select {
	case m.wakeupCh <- struct{}{}:
	default:
	}
}

// Start launches the background scheduler loop.
func (m *DefaultAlarmManager) Start(ctx context.Context) {
	m.log.Info("Alarm scheduler engine started")

	go func() {
		var timer *time.Timer
		var timerC <-chan time.Time

		for {
			m.mu.Lock()
			earliest, found := m.findEarliestTriggerLocked(time.Now())
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
				m.log.Info("Next alarm scheduled", "at", earliest.Format("2006-01-02 15:04:05"), "in", dur.Round(time.Second))
			}
			m.mu.Unlock()

			select {
			case <-ctx.Done():
				if timer != nil {
					timer.Stop()
				}
				m.log.Info("Alarm scheduler stopped")
				m.stopAudio()
				return

			case <-m.done:
				if timer != nil {
					timer.Stop()
				}
				m.stopAudio()
				return

			case <-m.wakeupCh:
				// Alarms were added/removed/snoozed, restart loop to recalculate earliest timer
				continue

			case <-timerC:
				timer = nil
				timerC = nil
				m.handleTimerTrigger()
			}
		}
	}()
}

func (m *DefaultAlarmManager) handleTimerTrigger() {
	now := time.Now()
	var triggeredAlarms []Alarm

	m.mu.Lock()
	for id, a := range m.alarms {
		if isAlarmDue(*a, now, m.snoozedUntil[id]) {
			// Clear snooze entry
			delete(m.snoozedUntil, id)

			// If one-shot, disable after triggering
			if len(a.Days) == 0 {
				a.Enabled = false
				a.SnoozeCount = 0
				m.log.Info("Tek seferlik alarm pasife alındı (enabled=false)", "id", a.ID, "label", a.Label)
			}

			triggeredAlarms = append(triggeredAlarms, *a)
		}
	}

	if len(triggeredAlarms) > 0 {
		_ = SaveAlarms(m.filePath, m.getAlarmsSliceLocked())
	}

	alarmList := m.getAlarmsSliceLocked()
	updateCb := m.updateCb
	triggerCb := m.triggerCb
	m.mu.Unlock()

	// Notify listeners and play audio outside mutex
	for _, a := range triggeredAlarms {
		m.log.Info("⏰ ALARM ÇALIYOR!", "id", a.ID, "label", a.Label, "time", a.Time)
		m.playAudio(a)
		if triggerCb != nil {
			triggerCb(a)
		}
	}

	if len(triggeredAlarms) > 0 && updateCb != nil {
		updateCb(alarmList)
	}
}

// AddAlarm creates, persists, and schedules a new alarm.
func (m *DefaultAlarmManager) AddAlarm(alarm Alarm) (*Alarm, error) {
	if alarm.Time == "" {
		return nil, fmt.Errorf("alarm time is required (e.g. '07:30')")
	}

	var h, min int
	if _, err := fmt.Sscanf(alarm.Time, "%d:%d", &h, &min); err != nil || h < 0 || h > 23 || min < 0 || min > 59 {
		return nil, fmt.Errorf("invalid time format '%s', expected 'HH:MM'", alarm.Time)
	}
	alarm.Time = fmt.Sprintf("%02d:%02d", h, min)

	if alarm.ID == "" {
		alarm.ID = fmt.Sprintf("alarm_%d", time.Now().UnixNano())
	}

	m.mu.Lock()
	m.alarms[alarm.ID] = &alarm
	if err := SaveAlarms(m.filePath, m.getAlarmsSliceLocked()); err != nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("failed to save alarm: %w", err)
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	return &alarm, nil
}

// DeleteAlarm removes an alarm by ID.
func (m *DefaultAlarmManager) DeleteAlarm(id string) error {
	m.mu.Lock()
	if _, exists := m.alarms[id]; !exists {
		m.mu.Unlock()
		return fmt.Errorf("alarm '%s' not found", id)
	}

	delete(m.alarms, id)
	delete(m.snoozedUntil, id)

	m.audioMu.Lock()
	if m.activeAlarmID == id {
		m.stopAudioLocked()
	}
	m.audioMu.Unlock()

	if err := SaveAlarms(m.filePath, m.getAlarmsSliceLocked()); err != nil {
		m.mu.Unlock()
		return fmt.Errorf("failed to save alarms after delete: %w", err)
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	return nil
}

// ToggleAlarm flips or explicitly sets the enabled flag of an alarm.
func (m *DefaultAlarmManager) ToggleAlarm(id string, enabled *bool) (*Alarm, error) {
	m.mu.Lock()
	alarm, exists := m.alarms[id]
	if !exists {
		m.mu.Unlock()
		return nil, fmt.Errorf("alarm '%s' not found", id)
	}

	if enabled != nil {
		alarm.Enabled = *enabled
	} else {
		alarm.Enabled = !alarm.Enabled
	}

	if !alarm.Enabled {
		delete(m.snoozedUntil, id)
		m.audioMu.Lock()
		if m.activeAlarmID == id {
			m.stopAudioLocked()
		}
		m.audioMu.Unlock()
	}

	if err := SaveAlarms(m.filePath, m.getAlarmsSliceLocked()); err != nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("failed to save alarms: %w", err)
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	return alarm, nil
}

// SnoozeAlarm delays the alarm for the specified duration (default 5m) and halts ringing.
func (m *DefaultAlarmManager) SnoozeAlarm(id string, minutes int) (*Alarm, error) {
	if minutes <= 0 {
		minutes = 5
	}

	m.mu.Lock()
	if id == "" {
		m.audioMu.Lock()
		id = m.activeAlarmID
		m.audioMu.Unlock()
	}

	alarm, exists := m.alarms[id]
	if !exists {
		m.mu.Unlock()
		return nil, fmt.Errorf("alarm '%s' not found to snooze", id)
	}

	m.audioMu.Lock()
	m.stopAudioLocked()
	m.audioMu.Unlock()

	alarm.SnoozeCount++
	snoozeTarget := time.Now().Add(time.Duration(minutes) * time.Minute)
	m.snoozedUntil[id] = snoozeTarget

	_ = SaveAlarms(m.filePath, m.getAlarmsSliceLocked())
	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.log.Info("Alarm snoozed", "id", id, "minutes", minutes, "next", snoozeTarget.Format("15:04:05"))
	m.notifyWakeup()
	return alarm, nil
}

// DismissAlarm halts the audio playback and resets snooze/one-shot state.
func (m *DefaultAlarmManager) DismissAlarm(id string) error {
	m.mu.Lock()
	if id == "" {
		m.audioMu.Lock()
		id = m.activeAlarmID
		m.audioMu.Unlock()
	}

	m.audioMu.Lock()
	m.stopAudioLocked()
	m.audioMu.Unlock()

	if id != "" {
		if alarm, exists := m.alarms[id]; exists {
			delete(m.snoozedUntil, id)
			alarm.SnoozeCount = 0
			if len(alarm.Days) == 0 {
				alarm.Enabled = false
			}
			_ = SaveAlarms(m.filePath, m.getAlarmsSliceLocked())
		}
	}

	m.notifyUpdateLocked()
	m.mu.Unlock()

	m.notifyWakeup()
	return nil
}

// GetAlarms returns a sorted copy of all stored alarms.
func (m *DefaultAlarmManager) GetAlarms() []Alarm {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.getAlarmsSliceLocked()
}

func (m *DefaultAlarmManager) getAlarmsSliceLocked() []Alarm {
	list := make([]Alarm, 0, len(m.alarms))
	for _, a := range m.alarms {
		list = append(list, *a)
	}

	sort.Slice(list, func(i, j int) bool {
		if list[i].Time != list[j].Time {
			return list[i].Time < list[j].Time
		}
		return list[i].Label < list[j].Label
	})

	return list
}

func (m *DefaultAlarmManager) notifyUpdateLocked() {
	if m.updateCb != nil {
		list := m.getAlarmsSliceLocked()
		go m.updateCb(list)
	}
}

// findEarliestTriggerLocked finds the earliest trigger timestamp among all configured alarms.
func (m *DefaultAlarmManager) findEarliestTriggerLocked(now time.Time) (time.Time, bool) {
	var earliest time.Time
	var found bool

	for id, a := range m.alarms {
		next, ok := calculateNextTrigger(*a, now, m.snoozedUntil[id])
		if ok {
			if !found || next.Before(earliest) {
				earliest = next
				found = true
			}
		}
	}
	return earliest, found
}

func (m *DefaultAlarmManager) playAudio(alarm Alarm) {
	m.audioMu.Lock()
	defer m.audioMu.Unlock()

	m.stopAudioLocked()

	ctx, cancel := context.WithCancel(context.Background())
	m.activeAudioCancel = cancel
	m.activeAlarmID = alarm.ID

	soundPath := alarm.SoundPath
	if soundPath == "" || !fileExists(soundPath) {
		soundPath = findFallbackSound()
	}

	player := findAudioPlayer()
	if player == "" || soundPath == "" {
		m.log.Warn("No audio player or fallback sound available to play alarm")
		return
	}

	cmd := exec.CommandContext(ctx, player, soundPath)
	m.activeAudioCmd = cmd

	m.log.Info("Alarm sesi çalınıyor 🔔", "player", player, "sound", soundPath, "label", alarm.Label)

	go func(alarmID string) {
		err := cmd.Run()
		if err != nil && ctx.Err() == nil {
			m.log.Warn("Alarm ses çalma hatası", "err", err)
		} else {
			m.log.Info("Alarm ses çalma süreci tamamlandı", "id", alarmID)
		}
	}(alarm.ID)
}

func (m *DefaultAlarmManager) stopAudio() {
	m.audioMu.Lock()
	defer m.audioMu.Unlock()
	m.stopAudioLocked()
}

func (m *DefaultAlarmManager) stopAudioLocked() {
	if m.activeAudioCancel != nil {
		m.activeAudioCancel()
		m.activeAudioCancel = nil
	}
	if m.activeAudioCmd != nil && m.activeAudioCmd.Process != nil {
		m.log.Info("Alarm sesi susturuldu / kapatıldı", "id", m.activeAlarmID)
		_ = m.activeAudioCmd.Process.Kill()
		m.activeAudioCmd = nil
	}
	m.activeAlarmID = ""
}

// Close terminates the manager and cleans up background timers and processes.
func (m *DefaultAlarmManager) Close() error {
	m.closeOnce.Do(func() {
		close(m.done)
		m.stopAudio()
	})
	return nil
}

// calculateNextTrigger calculates the next execution time for an alarm.
func calculateNextTrigger(alarm Alarm, now time.Time, snoozedUntil time.Time) (time.Time, bool) {
	// If snoozed, the snooze timestamp takes precedence
	if !snoozedUntil.IsZero() && snoozedUntil.After(now) {
		return snoozedUntil, true
	}

	if !alarm.Enabled {
		return time.Time{}, false
	}

	var hour, min int
	if _, err := fmt.Sscanf(alarm.Time, "%d:%d", &hour, &min); err != nil {
		return time.Time{}, false
	}

	todayTarget := time.Date(now.Year(), now.Month(), now.Day(), hour, min, 0, 0, now.Location())

	// 1. One-shot alarm (Days is empty)
	if len(alarm.Days) == 0 {
		if todayTarget.After(now) {
			return todayTarget, true
		}
		return todayTarget.AddDate(0, 0, 1), true
	}

	// 2. Repeating alarm (Days specified)
	for offset := 0; offset < 8; offset++ {
		candidate := todayTarget.AddDate(0, 0, offset)
		if isDayMatch(candidate.Weekday(), alarm.Days) {
			if candidate.After(now) {
				return candidate, true
			}
		}
	}

	return time.Time{}, false
}

// isAlarmDue checks if an alarm is currently scheduled to fire.
func isAlarmDue(a Alarm, now time.Time, snoozedUntil time.Time) bool {
	if !snoozedUntil.IsZero() {
		diff := now.Sub(snoozedUntil)
		return diff >= 0 && diff < 90*time.Second
	}

	if !a.Enabled {
		return false
	}

	var hour, min int
	if _, err := fmt.Sscanf(a.Time, "%d:%d", &hour, &min); err != nil {
		return false
	}

	todayTarget := time.Date(now.Year(), now.Month(), now.Day(), hour, min, 0, 0, now.Location())

	if len(a.Days) > 0 && !isDayMatch(now.Weekday(), a.Days) {
		return false
	}

	diff := now.Sub(todayTarget)
	return diff >= 0 && diff < 90*time.Second
}

// isDayMatch checks if the given weekday matches any integer in days (supports 1=Mon..7=Sun or 0=Sun).
func isDayMatch(w time.Weekday, days []int) bool {
	isoDay := int(w)
	if w == time.Sunday {
		isoDay = 7
	}

	for _, d := range days {
		if d == int(w) || d == isoDay {
			return true
		}
	}
	return false
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func findAudioPlayer() string {
	candidates := []string{"pw-play", "paplay", "aplay", "mpv", "ffplay"}
	for _, c := range candidates {
		if path, err := exec.LookPath(c); err == nil {
			return path
		}
	}
	return ""
}

func findFallbackSound() string {
	candidates := []string{
		"/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga",
		"/usr/share/sounds/freedesktop/stereo/complete.oga",
		"/usr/share/sounds/freedesktop/stereo/bell.oga",
		"/usr/share/sounds/gnome/default/alerts/glass.ogg",
	}
	for _, c := range candidates {
		if fileExists(c) {
			return c
		}
	}
	return ""
}
