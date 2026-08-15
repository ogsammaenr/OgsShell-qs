package notifications

import (
	"os"
	"path/filepath"
	"testing"
)

func setupTestManager(t *testing.T, maxLimit ...int) (*DefaultNotificationManager, func()) {
	tmpDir, err := os.MkdirTemp("", "notif_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}

	notifsPath := filepath.Join(tmpDir, "notifications.json")
	rulesPath := filepath.Join(tmpDir, "rules.json")

	limit := DefaultMaxHistoryCount
	if len(maxLimit) > 0 {
		limit = maxLimit[0]
	}

	mgr, err := NewDefaultNotificationManager(notifsPath, rulesPath, limit)
	if err != nil {
		t.Fatalf("failed to init NotificationManager: %v", err)
	}

	cleanup := func() {
		_ = mgr.Close()
		_ = os.RemoveAll(tmpDir)
	}

	return mgr, cleanup
}

func TestNotificationNormalFlow(t *testing.T) {
	mgr, cleanup := setupTestManager(t)
	defer cleanup()

	notif, shouldPopup, reason, err := mgr.ProcessIncoming(AddNotificationPayload{
		AppName: "Firefox",
		Summary: "Download complete",
		Body:    "file.iso downloaded",
		Urgency: "normal",
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if notif == nil {
		t.Fatal("expected notification object, got nil")
	}
	if !shouldPopup {
		t.Errorf("expected shouldPopup=true, got false")
	}
	if reason != "normal" {
		t.Errorf("expected reason='normal', got %s", reason)
	}

	list := mgr.GetNotifications()
	if len(list) != 1 {
		t.Fatalf("expected 1 notification in history, got %d", len(list))
	}
	if list[0].Summary != "Download complete" {
		t.Errorf("expected summary 'Download complete', got '%s'", list[0].Summary)
	}
}

func TestNotificationDNDMode(t *testing.T) {
	mgr, cleanup := setupTestManager(t)
	defer cleanup()

	// Turn DND on
	enabled := true
	mgr.ToggleDND(&enabled)

	if !mgr.IsDND() {
		t.Fatal("expected DND to be true")
	}

	// Normal alert during DND should not popup but must be saved in history
	notif, shouldPopup, reason, err := mgr.ProcessIncoming(AddNotificationPayload{
		AppName: "Discord",
		Summary: "New Message",
		Body:    "Hey there!",
		Urgency: "normal",
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if notif == nil {
		t.Fatal("expected notification to be created")
	}
	if shouldPopup {
		t.Errorf("expected shouldPopup=false during DND, got true")
	}
	if reason != "dnd_suppressed" {
		t.Errorf("expected reason='dnd_suppressed', got %s", reason)
	}

	// Critical alert during DND must popup
	critNotif, critPopup, critReason, err := mgr.ProcessIncoming(AddNotificationPayload{
		AppName: "System",
		Summary: "Battery Low",
		Body:    "10% remaining",
		Urgency: "critical",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if critNotif == nil {
		t.Fatal("expected critical notification to be created")
	}
	if !critPopup {
		t.Errorf("expected critical alert to popup during DND, got false")
	}
	if critReason != "critical_override" {
		t.Errorf("expected reason='critical_override', got %s", critReason)
	}

	// Total 2 saved in history
	if len(mgr.GetNotifications()) != 2 {
		t.Errorf("expected 2 notifications in history, got %d", len(mgr.GetNotifications()))
	}
}

func TestAppRulesMuteAndBlock(t *testing.T) {
	mgr, cleanup := setupTestManager(t)
	defer cleanup()

	// Configure rules
	_ = mgr.SetRule(NotificationRule{AppName: "Spotify", Mode: RuleModeMute})
	_ = mgr.SetRule(NotificationRule{AppName: "SpamApp", Mode: RuleModeBlock})

	// 1. Test Muted App (Spotify): saved to history, but no popup
	notif, popup, reason, err := mgr.ProcessIncoming(AddNotificationPayload{
		AppName: "spotify", // Case-insensitive test
		Summary: "Now Playing",
		Body:    "Song Name",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if notif == nil {
		t.Fatal("expected notification object")
	}
	if popup {
		t.Errorf("expected popup=false for muted Spotify, got true")
	}
	if reason != "app_muted" {
		t.Errorf("expected reason='app_muted', got %s", reason)
	}

	// 2. Test Blocked App (SpamApp): discarded, not saved, no popup
	blockedNotif, blockedPopup, blockedReason, err := mgr.ProcessIncoming(AddNotificationPayload{
		AppName: "SpamApp",
		Summary: "Buy now!",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if blockedNotif != nil {
		t.Errorf("expected nil notification for blocked app, got %+v", blockedNotif)
	}
	if blockedPopup {
		t.Errorf("expected popup=false for blocked app, got true")
	}
	if blockedReason != "app_blocked" {
		t.Errorf("expected reason='app_blocked', got %s", blockedReason)
	}

	// Only Spotify should be in history
	list := mgr.GetNotifications()
	if len(list) != 1 {
		t.Fatalf("expected 1 notification in history, got %d", len(list))
	}
	if list[0].AppName != "spotify" {
		t.Errorf("expected AppName 'spotify', got '%s'", list[0].AppName)
	}
}

func TestAppRulePriorityBypassesDND(t *testing.T) {
	mgr, cleanup := setupTestManager(t)
	defer cleanup()

	// Set Priority rule for EmergencyContact
	_ = mgr.SetRule(NotificationRule{AppName: "EmergencyContact", Mode: RuleModePriority})

	// Turn DND on
	enabled := true
	mgr.ToggleDND(&enabled)

	notif, popup, reason, err := mgr.ProcessIncoming(AddNotificationPayload{
		AppName: "EmergencyContact",
		Summary: "Important call",
		Urgency: "normal",
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if notif == nil {
		t.Fatal("expected notification object")
	}
	if !popup {
		t.Errorf("expected priority rule to bypass DND and popup, got false")
	}
	if reason != "priority_override" {
		t.Errorf("expected reason='priority_override', got %s", reason)
	}
}

func TestHistoryTrimming(t *testing.T) {
	mgr, cleanup := setupTestManager(t, 5) // Max 5 items
	defer cleanup()

	for i := 0; i < 10; i++ {
		_, _, _, _ = mgr.ProcessIncoming(AddNotificationPayload{
			AppName: "TestApp",
			Summary: "Message",
		})
	}

	list := mgr.GetNotifications()
	if len(list) != 5 {
		t.Errorf("expected history trimmed to 5 items, got %d", len(list))
	}
}

func TestNotificationCRUD(t *testing.T) {
	mgr, cleanup := setupTestManager(t)
	defer cleanup()

	n1, _, _, _ := mgr.ProcessIncoming(AddNotificationPayload{AppName: "App1", Summary: "S1"})
	n2, _, _, _ := mgr.ProcessIncoming(AddNotificationPayload{AppName: "App2", Summary: "S2"})

	if len(mgr.GetNotifications()) != 2 {
		t.Fatalf("expected 2 items, got %d", len(mgr.GetNotifications()))
	}

	// Mark Read
	_ = mgr.MarkAsRead(n1.ID)
	list := mgr.GetNotifications()
	var foundRead bool
	for _, item := range list {
		if item.ID == n1.ID && item.Read {
			foundRead = true
		}
	}
	if !foundRead {
		t.Errorf("expected n1 to be marked read")
	}

	// Mark All Read
	_ = mgr.MarkAllAsRead()
	for _, item := range mgr.GetNotifications() {
		if !item.Read {
			t.Errorf("expected item %s to be read", item.ID)
		}
	}

	// Delete n2
	_ = mgr.DeleteNotification(n2.ID)
	if len(mgr.GetNotifications()) != 1 {
		t.Errorf("expected 1 item after delete, got %d", len(mgr.GetNotifications()))
	}

	// Clear All
	_ = mgr.ClearAll()
	if len(mgr.GetNotifications()) != 0 {
		t.Errorf("expected 0 items after clear, got %d", len(mgr.GetNotifications()))
	}
}
