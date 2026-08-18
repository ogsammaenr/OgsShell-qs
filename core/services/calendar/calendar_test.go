package calendar

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestHolidayEngine_NationalHolidays(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", t.TempDir())
	engine := NewHolidayEngine()
	holidays2026 := engine.GetHolidaysForYear(2026)

	if len(holidays2026) == 0 {
		t.Fatalf("expected holidays to be generated for 2026")
	}

	// Verify 29 Ekim Cumhuriyet Bayramı exists
	var found29Oct bool
	for _, h := range holidays2026 {
		if h.Date == "2026-10-29" && h.Name == "Cumhuriyet Bayramı" {
			found29Oct = true
			break
		}
	}
	if !found29Oct {
		t.Errorf("expected 2026-10-29 Cumhuriyet Bayramı to be present")
	}

	// Verify Ramazan Bayramı in 2026 (March 19-22)
	var foundRamazan bool
	for _, h := range holidays2026 {
		if h.Date == "2026-03-20" && h.Type == "religious" {
			foundRamazan = true
			break
		}
	}
	if !foundRamazan {
		t.Errorf("expected Ramazan Bayramı 1. Gün (2026-03-20) to be present")
	}

	// Verify month filter
	octHolidays := engine.GetHolidaysForMonth(2026, 10)
	if len(octHolidays) < 2 { // 28 Oct (Arefe) + 29 Oct
		t.Errorf("expected at least 2 holidays in October 2026, got %d", len(octHolidays))
	}
}

func TestHolidayFetcher_MockServer(t *testing.T) {
	mockJSON := `[
		{
			"date": "2026-01-01",
			"localName": "Yılbaşı",
			"name": "New Year's Day",
			"countryCode": "TR",
			"fixed": true,
			"global": true,
			"types": ["Public"]
		},
		{
			"date": "2026-03-20",
			"localName": "Ramazan Bayramı",
			"name": "Ramadan Feast",
			"countryCode": "TR",
			"fixed": false,
			"global": true,
			"types": ["Public"]
		}
	]`

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(mockJSON))
	}))
	defer server.Close()

	fetcher := NewHolidayFetcher(server.URL)
	holidays, err := fetcher.FetchTurkeyHolidays(context.Background(), 2026)
	if err != nil {
		t.Fatalf("FetchTurkeyHolidays failed: %v", err)
	}

	if len(holidays) != 2 {
		t.Fatalf("expected 2 holidays, got %d", len(holidays))
	}

	if holidays[0].Name != "Yılbaşı" || holidays[1].Type != "religious" {
		t.Errorf("parsed holidays mismatch: %+v", holidays)
	}
}

func TestHolidayStorage_DiskCache(t *testing.T) {
	year := 2099
	cachePath := GetHolidaysCachePath(year)
	defer os.Remove(cachePath)

	testHolidays := []Holiday{
		{Date: "2099-01-01", Name: "Yılbaşı", IsHalfDay: false, Type: "national"},
		{Date: "2099-04-23", Name: "Ulusal Egemenlik", IsHalfDay: false, Type: "national"},
	}

	if err := SaveHolidaysCache(year, testHolidays); err != nil {
		t.Fatalf("SaveHolidaysCache failed: %v", err)
	}

	loaded, err := LoadHolidaysCache(year)
	if err != nil {
		t.Fatalf("LoadHolidaysCache failed: %v", err)
	}

	if len(loaded) != 2 || loaded[0].Name != "Yılbaşı" {
		t.Fatalf("loaded cache mismatch: %+v", loaded)
	}
}

func TestCalendarManager_CRUDAndMonthData(t *testing.T) {
	tmpDir := t.TempDir()
	jsonPath := filepath.Join(tmpDir, "test_events.json")

	mgr, err := NewDefaultCalendarManager(jsonPath)
	if err != nil {
		t.Fatalf("NewDefaultCalendarManager failed: %v", err)
	}
	defer mgr.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	mgr.Start(ctx)

	// Add Event
	event, err := mgr.AddEvent(CalendarEvent{
		Title:               "Sprint Review",
		Date:                "2026-08-15",
		Time:                "14:00",
		NotifyBeforeMinutes: 15,
	})
	if err != nil {
		t.Fatalf("AddEvent failed: %v", err)
	}
	if event.ID == "" {
		t.Errorf("expected event ID to be generated")
	}

	// Get Month Data
	monthData := mgr.GetMonthData(2026, 8)
	if len(monthData.Events) != 1 || monthData.Events[0].Title != "Sprint Review" {
		t.Fatalf("month data events mismatch: %+v", monthData.Events)
	}
	if len(monthData.Holidays) == 0 {
		t.Errorf("expected August holidays (Zafer Bayramı) to be present")
	}

	// Update Event
	newTitle := "Sprint Review & Demo"
	updated, err := mgr.UpdateEvent(UpdateCalendarEventPayload{
		ID:    event.ID,
		Title: &newTitle,
	})
	if err != nil {
		t.Fatalf("UpdateEvent failed: %v", err)
	}
	if updated.Title != newTitle {
		t.Errorf("expected title %s, got %s", newTitle, updated.Title)
	}

	// Toggle Completed
	completedVal := true
	toggled, err := mgr.ToggleEventCompleted(event.ID, &completedVal)
	if err != nil {
		t.Fatalf("ToggleEventCompleted failed: %v", err)
	}
	if !toggled.Completed {
		t.Errorf("expected event to be completed")
	}

	// Delete Event
	if err := mgr.DeleteEvent(event.ID); err != nil {
		t.Fatalf("DeleteEvent failed: %v", err)
	}

	if len(mgr.GetEvents()) != 0 {
		t.Errorf("expected 0 events after delete, got %d", len(mgr.GetEvents()))
	}
}

func TestCalendarManager_DynamicReminder(t *testing.T) {
	tmpDir := t.TempDir()
	jsonPath := filepath.Join(tmpDir, "test_reminder.json")

	mgr, err := NewDefaultCalendarManager(jsonPath)
	if err != nil {
		t.Fatalf("NewDefaultCalendarManager failed: %v", err)
	}
	defer mgr.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	reminderCh := make(chan CalendarReminderTriggeredPayload, 1)
	mgr.SetReminderCallback(func(payload CalendarReminderTriggeredPayload) {
		reminderCh <- payload
	})

	mgr.Start(ctx)

	// Add an event for today
	now := time.Now()
	event, err := mgr.AddEvent(CalendarEvent{
		Title:               "Urgent Standup",
		Date:                now.Format("2006-01-02"),
		Time:                now.Format("15:04"),
		NotifyBeforeMinutes: 0,
	})
	if err != nil {
		t.Fatalf("AddEvent failed: %v", err)
	}

	// Trigger check
	select {
	case p := <-reminderCh:
		if p.ID != event.ID {
			t.Errorf("expected reminder ID %s, got %s", event.ID, p.ID)
		}
	case <-time.After(2 * time.Second):
		t.Fatalf("timed out waiting for calendar reminder")
	}
}
