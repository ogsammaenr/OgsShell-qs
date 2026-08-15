package alarm

import (
	"context"
	"path/filepath"
	"testing"
	"time"
)

func TestCalculateNextTrigger_OneShot(t *testing.T) {
	loc := time.Local
	baseNow := time.Date(2026, 8, 10, 10, 0, 0, 0, loc) // 10:00

	// Alarm in future today (14:30)
	alarmFuture := Alarm{
		ID:      "a1",
		Time:    "14:30",
		Days:    []int{},
		Enabled: true,
	}
	next, ok := calculateNextTrigger(alarmFuture, baseNow, time.Time{})
	if !ok {
		t.Fatalf("expected next trigger to be found")
	}
	expectedFuture := time.Date(2026, 8, 10, 14, 30, 0, 0, loc)
	if !next.Equal(expectedFuture) {
		t.Errorf("got %v, want %v", next, expectedFuture)
	}

	// Alarm in past today (08:30) -> should trigger tomorrow
	alarmPast := Alarm{
		ID:      "a2",
		Time:    "08:30",
		Days:    []int{},
		Enabled: true,
	}
	nextPast, ok := calculateNextTrigger(alarmPast, baseNow, time.Time{})
	if !ok {
		t.Fatalf("expected next trigger to be found for tomorrow")
	}
	expectedTomorrow := time.Date(2026, 8, 11, 8, 30, 0, 0, loc)
	if !nextPast.Equal(expectedTomorrow) {
		t.Errorf("got %v, want %v", nextPast, expectedTomorrow)
	}

	// Disabled alarm -> should not trigger
	alarmDisabled := Alarm{
		ID:      "a3",
		Time:    "14:30",
		Days:    []int{},
		Enabled: false,
	}
	_, ok = calculateNextTrigger(alarmDisabled, baseNow, time.Time{})
	if ok {
		t.Errorf("expected disabled alarm to return false")
	}
}

func TestCalculateNextTrigger_Repeating(t *testing.T) {
	loc := time.Local
	// 2026-08-10 is Monday (Weekday = 1, ISO = 1)
	mondayNow := time.Date(2026, 8, 10, 10, 0, 0, 0, loc)

	// Wednesday (ISO 3) at 09:00
	alarmWed := Alarm{
		ID:      "a_wed",
		Time:    "09:00",
		Days:    []int{3},
		Enabled: true,
	}
	next, ok := calculateNextTrigger(alarmWed, mondayNow, time.Time{})
	if !ok {
		t.Fatalf("expected next trigger to be found for Wednesday")
	}
	expectedWed := time.Date(2026, 8, 12, 9, 0, 0, 0, loc) // Wednesday Aug 12
	if !next.Equal(expectedWed) {
		t.Errorf("got %v, want %v", next, expectedWed)
	}

	// Weekdays alarm [1,2,3,4,5] at 12:00 -> should be today (Monday) at 12:00
	alarmWeekdays := Alarm{
		ID:      "a_weekdays",
		Time:    "12:00",
		Days:    []int{1, 2, 3, 4, 5},
		Enabled: true,
	}
	nextToday, ok := calculateNextTrigger(alarmWeekdays, mondayNow, time.Time{})
	if !ok {
		t.Fatalf("expected next trigger today")
	}
	expectedToday := time.Date(2026, 8, 10, 12, 0, 0, 0, loc)
	if !nextToday.Equal(expectedToday) {
		t.Errorf("got %v, want %v", nextToday, expectedToday)
	}
}

func TestCalculateNextTrigger_Snoozed(t *testing.T) {
	loc := time.Local
	baseNow := time.Date(2026, 8, 10, 10, 0, 0, 0, loc)
	snoozeTime := baseNow.Add(10 * time.Minute)

	alarm := Alarm{
		ID:      "a_snooze",
		Time:    "08:00",
		Days:    []int{},
		Enabled: true,
	}

	next, ok := calculateNextTrigger(alarm, baseNow, snoozeTime)
	if !ok {
		t.Fatalf("expected snooze trigger to be found")
	}
	if !next.Equal(snoozeTime) {
		t.Errorf("got %v, want snooze time %v", next, snoozeTime)
	}
}

func TestAlarmManager_Lifecycle(t *testing.T) {
	tmpDir := t.TempDir()
	jsonPath := filepath.Join(tmpDir, "test_alarms.json")

	mgr, err := NewDefaultAlarmManager(jsonPath)
	if err != nil {
		t.Fatalf("NewDefaultAlarmManager failed: %v", err)
	}
	defer mgr.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	mgr.Start(ctx)

	// Add Alarm
	newAlarm, err := mgr.AddAlarm(Alarm{
		Time:    "07:30",
		Days:    []int{1, 2, 3, 4, 5},
		Label:   "Work Wakeup",
		Enabled: true,
	})
	if err != nil {
		t.Fatalf("AddAlarm failed: %v", err)
	}
	if newAlarm.ID == "" {
		t.Errorf("expected ID to be generated")
	}

	// Verify persistence
	loaded, err := LoadAlarms(jsonPath)
	if err != nil {
		t.Fatalf("LoadAlarms failed: %v", err)
	}
	if len(loaded) != 1 || loaded[0].Label != "Work Wakeup" {
		t.Fatalf("persisted alarms mismatch: %+v", loaded)
	}

	// Toggle Alarm
	disabledVal := false
	toggled, err := mgr.ToggleAlarm(newAlarm.ID, &disabledVal)
	if err != nil {
		t.Fatalf("ToggleAlarm failed: %v", err)
	}
	if toggled.Enabled {
		t.Errorf("expected alarm to be disabled")
	}

	// Snooze Alarm
	snoozed, err := mgr.SnoozeAlarm(newAlarm.ID, 10)
	if err != nil {
		t.Fatalf("SnoozeAlarm failed: %v", err)
	}
	if snoozed.SnoozeCount != 1 {
		t.Errorf("expected SnoozeCount to be 1, got %d", snoozed.SnoozeCount)
	}

	// Dismiss Alarm
	if err := mgr.DismissAlarm(newAlarm.ID); err != nil {
		t.Fatalf("DismissAlarm failed: %v", err)
	}

	// Delete Alarm
	if err := mgr.DeleteAlarm(newAlarm.ID); err != nil {
		t.Fatalf("DeleteAlarm failed: %v", err)
	}

	alarms := mgr.GetAlarms()
	if len(alarms) != 0 {
		t.Errorf("expected 0 alarms after delete, got %d", len(alarms))
	}
}

func TestAlarmManager_DynamicTrigger(t *testing.T) {
	tmpDir := t.TempDir()
	jsonPath := filepath.Join(tmpDir, "test_dynamic.json")

	mgr, err := NewDefaultAlarmManager(jsonPath)
	if err != nil {
		t.Fatalf("NewDefaultAlarmManager failed: %v", err)
	}
	defer mgr.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	triggeredCh := make(chan Alarm, 1)
	mgr.SetTriggerCallback(func(a Alarm) {
		triggeredCh <- a
	})

	mgr.Start(ctx)

	// Wait 20ms to ensure Start loop is running and waiting on select
	time.Sleep(20 * time.Millisecond)

	// Add an alarm
	alarm, err := mgr.AddAlarm(Alarm{
		Time:    "07:30",
		Label:   "Dynamic Test",
		Enabled: true,
	})
	if err != nil {
		t.Fatalf("AddAlarm failed: %v", err)
	}

	// Snooze alarm to trigger in 100ms
	mgr.mu.Lock()
	mgr.snoozedUntil[alarm.ID] = time.Now().Add(100 * time.Millisecond)
	mgr.mu.Unlock()
	mgr.notifyWakeup()

	// It should trigger within 500ms
	select {
	case triggered := <-triggeredCh:
		if triggered.ID != alarm.ID {
			t.Errorf("triggered ID %s, want %s", triggered.ID, alarm.ID)
		}
		if triggered.Enabled {
			t.Errorf("expected triggered one-shot alarm to have Enabled: false")
		}
	case <-time.After(2 * time.Second):
		t.Fatalf("timed out waiting for dynamic alarm trigger")
	}

	// Verify that in-memory alarm became Enabled: false
	alarms := mgr.GetAlarms()
	if len(alarms) != 1 || alarms[0].Enabled {
		t.Errorf("expected in-memory one-shot alarm to be disabled (Enabled: false), got %+v", alarms)
	}

	// Verify that on-disk JSON persisted Enabled: false
	loaded, err := LoadAlarms(jsonPath)
	if err != nil || len(loaded) != 1 || loaded[0].Enabled {
		t.Errorf("expected persisted alarm to have Enabled: false, got %+v", loaded)
	}
}
