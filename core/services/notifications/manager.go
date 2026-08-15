package notifications

import (
	"context"
	"fmt"
	"log/slog"
	"ogsShell/core/logger"
	"strings"
	"sync"
	"time"
)

const (
	// DefaultMaxHistoryCount limits total stored notifications to prevent unbounded memory/disk usage.
	DefaultMaxHistoryCount = 100
)

// NotificationManager defines the public contract for notification lifecycle, DND, and rule processing.
type NotificationManager interface {
	// ProcessIncoming handles an incoming alert, applies DND and app rules, persists to history if permitted,
	// and determines if a transient UI popup should be shown on Dynamic Island.
	ProcessIncoming(payload AddNotificationPayload) (*Notification, bool, string, error)

	// GetNotifications returns a slice of all stored notifications (newest first).
	GetNotifications() []Notification

	// DeleteNotification removes a specific notification from history by ID.
	DeleteNotification(id string) error

	// ClearAll removes all notifications from history.
	ClearAll() error

	// MarkAsRead marks a specific notification as read.
	MarkAsRead(id string) error

	// MarkAllAsRead marks all notifications in history as read.
	MarkAllAsRead() error

	// ToggleDND toggles or explicitly sets Do Not Disturb mode.
	ToggleDND(enabled *bool) bool

	// IsDND returns true if Do Not Disturb mode is active.
	IsDND() bool

	// SetRule adds or updates an application rule.
	SetRule(rule NotificationRule) error

	// DeleteRule removes an application rule.
	DeleteRule(appName string) error

	// GetRules returns all configured application rules.
	GetRules() []NotificationRule

	// Start initializes background tasks if needed.
	Start(ctx context.Context)

	// Close cleans up resources and flushes state.
	Close() error

	// Callbacks
	SetUpdateCallback(cb func(notifs []Notification))
	SetDNDCallback(cb func(dnd bool))
	SetRulesCallback(cb func(rules []NotificationRule))
}

// DefaultNotificationManager is the thread-safe implementation of NotificationManager.
type DefaultNotificationManager struct {
	notifsFilePath string
	rulesFilePath  string
	maxHistory     int
	log            *slog.Logger

	mu            sync.RWMutex
	notifications []Notification
	rules         map[string]NotificationRule // keyed by lower-case AppName
	dndEnabled    bool

	updateCb func(notifs []Notification)
	dndCb    func(dnd bool)
	rulesCb  func(rules []NotificationRule)

	closeOnce sync.Once
}

// NewDefaultNotificationManager creates a new NotificationManager with persistent storage.
func NewDefaultNotificationManager(notifsPath, rulesPath string, maxHistory ...int) (*DefaultNotificationManager, error) {
	if notifsPath == "" {
		notifsPath = GetNotificationsFilePath()
	}
	if rulesPath == "" {
		rulesPath = GetRulesFilePath()
	}

	limit := DefaultMaxHistoryCount
	if len(maxHistory) > 0 && maxHistory[0] > 0 {
		limit = maxHistory[0]
	}

	loadedNotifs, err := LoadNotifications(notifsPath)
	if err != nil {
		logger.Module("NOTIF").Warn("Bildirim geçmişi okunamadı, boş başlatılıyor", "err", err)
		loadedNotifs = []Notification{}
	}

	loadedRules, err := LoadRules(rulesPath)
	if err != nil {
		logger.Module("NOTIF").Warn("Bildirim kuralları okunamadı, boş başlatılıyor", "err", err)
		loadedRules = make(map[string]NotificationRule)
	}

	// Normalize rules map keys to lower case for case-insensitive matching
	normalizedRules := make(map[string]NotificationRule)
	for k, v := range loadedRules {
		normalizedRules[strings.ToLower(k)] = v
	}

	mgr := &DefaultNotificationManager{
		notifsFilePath: notifsPath,
		rulesFilePath:  rulesPath,
		maxHistory:     limit,
		log:            logger.Module("NOTIF"),
		notifications:  loadedNotifs,
		rules:          normalizedRules,
		dndEnabled:     false,
	}

	return mgr, nil
}

var notifIDSeq uint64
var notifIDSeqMu sync.Mutex

func generateNotificationID() string {
	notifIDSeqMu.Lock()
	notifIDSeq++
	seq := notifIDSeq
	notifIDSeqMu.Unlock()
	return fmt.Sprintf("notif_%d_%d", time.Now().UnixMilli(), seq)
}

// ProcessIncoming evaluates rules, updates history, and returns whether to show a popup.
func (m *DefaultNotificationManager) ProcessIncoming(payload AddNotificationPayload) (*Notification, bool, string, error) {
	appName := strings.TrimSpace(payload.AppName)
	if appName == "" {
		appName = "System"
	}
	summary := strings.TrimSpace(payload.Summary)
	if summary == "" {
		summary = "Notification"
	}
	urgency := strings.ToLower(strings.TrimSpace(payload.Urgency))
	if urgency == "" {
		urgency = "normal"
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	ruleKey := strings.ToLower(appName)
	rule, hasRule := m.rules[ruleKey]

	// 1. Rule: Block (Completely discard alert)
	if hasRule && rule.Mode == RuleModeBlock {
		m.log.Info("Bildirim engellendi (Block Rule)", "app", appName, "summary", summary)
		return nil, false, "app_blocked", nil
	}

	now := time.Now().UnixMilli()
	notif := Notification{
		ID:        generateNotificationID(),
		AppName:   appName,
		Summary:   summary,
		Body:      payload.Body,
		Icon:      payload.Icon,
		Urgency:   urgency,
		Timestamp: now,
		Read:      false,
	}

	// Prepend to notifications slice (newest first)
	m.notifications = append([]Notification{notif}, m.notifications...)

	// Auto-prune if exceeding maximum history limit
	if len(m.notifications) > m.maxHistory {
		m.notifications = m.notifications[:m.maxHistory]
	}

	// Persist to disk
	if err := SaveNotifications(m.notifsFilePath, m.notifications); err != nil {
		m.log.Error("Bildirim geçmişi diske kaydedilemedi", "err", err)
	}

	// Notify history listeners
	if m.updateCb != nil {
		notifsCopy := make([]Notification, len(m.notifications))
		copy(notifsCopy, m.notifications)
		go m.updateCb(notifsCopy)
	}

	// 2. Critical urgency always overrides DND and mute rules
	if urgency == "critical" {
		m.log.Info("Kritik bildirim tetiklendi (DND ve Kural Baypas)", "app", appName, "summary", summary)
		return &notif, true, "critical_override", nil
	}

	// 3. Priority rule bypasses DND
	if hasRule && rule.Mode == RuleModePriority {
		m.log.Info("Öncelikli bildirim tetiklendi (Priority Rule)", "app", appName, "summary", summary)
		return &notif, true, "priority_override", nil
	}

	// 4. Do Not Disturb active
	if m.dndEnabled {
		m.log.Info("Bildirim DND modu nedeniyle sessize alındı", "app", appName, "summary", summary)
		return &notif, false, "dnd_suppressed", nil
	}

	// 5. Mute rule
	if hasRule && rule.Mode == RuleModeMute {
		m.log.Info("Bildirim uygulama kuralı nedeniyle sessize alındı", "app", appName, "summary", summary)
		return &notif, false, "app_muted", nil
	}

	// 6. Normal delivery
	return &notif, true, "normal", nil
}

// GetNotifications returns all stored notifications.
func (m *DefaultNotificationManager) GetNotifications() []Notification {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make([]Notification, len(m.notifications))
	copy(result, m.notifications)
	return result
}

// DeleteNotification removes a notification by ID.
func (m *DefaultNotificationManager) DeleteNotification(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	found := false
	var updated []Notification
	for _, n := range m.notifications {
		if n.ID == id {
			found = true
			continue
		}
		updated = append(updated, n)
	}

	if !found {
		return fmt.Errorf("bildirim bulunamadı: %s", id)
	}

	m.notifications = updated
	if err := SaveNotifications(m.notifsFilePath, m.notifications); err != nil {
		m.log.Error("Bildirim silinmesi diske işlenemedi", "err", err)
	}

	if m.updateCb != nil {
		notifsCopy := make([]Notification, len(m.notifications))
		copy(notifsCopy, m.notifications)
		go m.updateCb(notifsCopy)
	}

	return nil
}

// ClearAll removes all notifications.
func (m *DefaultNotificationManager) ClearAll() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.notifications = []Notification{}
	if err := SaveNotifications(m.notifsFilePath, m.notifications); err != nil {
		m.log.Error("Bildirim geçmişi temizlenmesi diske işlenemedi", "err", err)
	}

	if m.updateCb != nil {
		go m.updateCb([]Notification{})
	}

	return nil
}

// MarkAsRead marks a specific notification as read.
func (m *DefaultNotificationManager) MarkAsRead(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	found := false
	for i := range m.notifications {
		if m.notifications[i].ID == id {
			m.notifications[i].Read = true
			found = true
			break
		}
	}

	if !found {
		return fmt.Errorf("bildirim bulunamadı: %s", id)
	}

	if err := SaveNotifications(m.notifsFilePath, m.notifications); err != nil {
		m.log.Error("Okundu durumu diske işlenemedi", "err", err)
	}

	if m.updateCb != nil {
		notifsCopy := make([]Notification, len(m.notifications))
		copy(notifsCopy, m.notifications)
		go m.updateCb(notifsCopy)
	}

	return nil
}

// MarkAllAsRead marks all notifications as read.
func (m *DefaultNotificationManager) MarkAllAsRead() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for i := range m.notifications {
		m.notifications[i].Read = true
	}

	if err := SaveNotifications(m.notifsFilePath, m.notifications); err != nil {
		m.log.Error("Tümünü okundu işaretleme diske işlenemedi", "err", err)
	}

	if m.updateCb != nil {
		notifsCopy := make([]Notification, len(m.notifications))
		copy(notifsCopy, m.notifications)
		go m.updateCb(notifsCopy)
	}

	return nil
}

// ToggleDND toggles or explicitly sets DND state.
func (m *DefaultNotificationManager) ToggleDND(enabled *bool) bool {
	m.mu.Lock()
	defer m.mu.Unlock()

	if enabled != nil {
		m.dndEnabled = *enabled
	} else {
		m.dndEnabled = !m.dndEnabled
	}

	m.log.Info("DND durumu güncellendi", "dnd_enabled", m.dndEnabled)

	if m.dndCb != nil {
		val := m.dndEnabled
		go m.dndCb(val)
	}

	return m.dndEnabled
}

// IsDND returns current DND state.
func (m *DefaultNotificationManager) IsDND() bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.dndEnabled
}

// SetRule sets or updates a custom rule for an application.
func (m *DefaultNotificationManager) SetRule(rule NotificationRule) error {
	if strings.TrimSpace(rule.AppName) == "" {
		return fmt.Errorf("uygulama adı boş olamaz")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	key := strings.ToLower(rule.AppName)
	m.rules[key] = rule

	if err := SaveRules(m.rulesFilePath, m.rules); err != nil {
		m.log.Error("Bildirim kuralları diske kaydedilemedi", "err", err)
		return err
	}

	if m.rulesCb != nil {
		rulesList := m.getRulesSliceLocked()
		go m.rulesCb(rulesList)
	}

	return nil
}

// DeleteRule removes a custom rule for an application.
func (m *DefaultNotificationManager) DeleteRule(appName string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	key := strings.ToLower(appName)
	if _, exists := m.rules[key]; !exists {
		return fmt.Errorf("kural bulunamadı: %s", appName)
	}

	delete(m.rules, key)

	if err := SaveRules(m.rulesFilePath, m.rules); err != nil {
		m.log.Error("Kural silinmesi diske kaydedilemedi", "err", err)
		return err
	}

	if m.rulesCb != nil {
		rulesList := m.getRulesSliceLocked()
		go m.rulesCb(rulesList)
	}

	return nil
}

// GetRules returns all custom application rules.
func (m *DefaultNotificationManager) GetRules() []NotificationRule {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.getRulesSliceLocked()
}

func (m *DefaultNotificationManager) getRulesSliceLocked() []NotificationRule {
	rulesList := make([]NotificationRule, 0, len(m.rules))
	for _, r := range m.rules {
		rulesList = append(rulesList, r)
	}
	return rulesList
}

func (m *DefaultNotificationManager) Start(ctx context.Context) {
	m.log.Info("Bildirim yöneticisi hazır", "stored_count", len(m.notifications), "rules_count", len(m.rules))
}

func (m *DefaultNotificationManager) Close() error {
	m.closeOnce.Do(func() {
		m.log.Info("Bildirim yöneticisi kapatıldı")
	})
	return nil
}

func (m *DefaultNotificationManager) SetUpdateCallback(cb func(notifs []Notification)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCb = cb
}

func (m *DefaultNotificationManager) SetDNDCallback(cb func(dnd bool)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.dndCb = cb
}

func (m *DefaultNotificationManager) SetRulesCallback(cb func(rules []NotificationRule)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.rulesCb = cb
}
