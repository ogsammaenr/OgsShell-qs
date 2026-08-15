package clipboard

import (
	"bytes"
	"context"
	"fmt"
	"log/slog"
	"ogsShell/core/logger"
	"os/exec"
	"strings"
	"sync"
	"time"
)

const (
	DefaultHistoryLimit = 50
)

// ClipboardManager defines the public contract for Wayland clipboard interactions and pinned snippets.
type ClipboardManager interface {
	// GetHistory returns clipboard history filtered by query and limited by count.
	GetHistory(limit int, query string) ([]ClipboardItem, error)

	// GetItemContent decodes and returns the full content of an item.
	GetItemContent(id string) (string, error)

	// CopyItem restores a history item by ID or copies custom text to the active Wayland clipboard.
	CopyItem(id string, customText string) error

	// DeleteItem removes an entry from cliphist and pinned items.
	DeleteItem(id string) error

	// ClearHistory wipes cliphist history while preserving pinned favorites.
	ClearHistory() error

	// PinItem bookmarks an item to persistent favorites.
	PinItem(id string, text string, label string) (*PinnedItem, error)

	// UnpinItem removes an item from persistent favorites.
	UnpinItem(id string) error

	// GetPinned returns all bookmarked snippets.
	GetPinned() []PinnedItem

	// Start initializes background watcher routines.
	Start(ctx context.Context)

	// Close terminates any active watchers or child processes.
	Close() error

	// Callbacks
	SetUpdateCallback(cb func(items []ClipboardItem))
	SetCopiedCallback(cb func(item ClipboardItem))
	SetPinnedCallback(cb func(items []PinnedItem))
}

// DefaultClipboardManager is the production implementation of ClipboardManager.
type DefaultClipboardManager struct {
	pinnedFilePath string
	log            *slog.Logger

	mu          sync.RWMutex
	pinnedItems []PinnedItem
	lastTopID   string

	updateCb func(items []ClipboardItem)
	copiedCb func(item ClipboardItem)
	pinnedCb func(items []PinnedItem)

	cancelWatcher context.CancelFunc
	closeOnce     sync.Once
}

// NewDefaultClipboardManager creates a new ClipboardManager instance.
func NewDefaultClipboardManager(pinnedPath ...string) (*DefaultClipboardManager, error) {
	path := GetPinnedFilePath()
	if len(pinnedPath) > 0 && pinnedPath[0] != "" {
		path = pinnedPath[0]
	}

	loadedPinned, err := LoadPinned(path)
	if err != nil {
		logger.Module("CLIPBOARD").Warn("Sabitlenmiş pano öğeleri okunamadı, boş başlatılıyor", "err", err)
		loadedPinned = []PinnedItem{}
	}

	mgr := &DefaultClipboardManager{
		pinnedFilePath: path,
		log:            logger.Module("CLIPBOARD"),
		pinnedItems:    loadedPinned,
	}

	return mgr, nil
}

// ParseCliphistListOutput parses raw tab-delimited output from `cliphist list`.
func ParseCliphistListOutput(raw string, pinnedMap map[string]PinnedItem, limit int, query string) []ClipboardItem {
	if limit <= 0 {
		limit = DefaultHistoryLimit
	}
	query = strings.ToLower(strings.TrimSpace(query))

	lines := strings.Split(raw, "\n")
	var items []ClipboardItem

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		parts := strings.SplitN(line, "\t", 2)
		if len(parts) < 2 {
			continue
		}

		id := strings.TrimSpace(parts[0])
		preview := strings.TrimSpace(parts[1])

		itemType := "text"
		if strings.HasPrefix(preview, "[[ binary data") {
			itemType = "image"
		}

		if query != "" {
			if !strings.Contains(strings.ToLower(preview), query) {
				continue
			}
		}

		_, isPinned := pinnedMap[id]

		items = append(items, ClipboardItem{
			ID:        id,
			Preview:   preview,
			Type:      itemType,
			IsPinned:  isPinned,
			Timestamp: time.Now().UnixMilli(),
		})

		if len(items) >= limit {
			break
		}
	}

	return items
}

// GetHistory queries cliphist and returns the history list.
func (m *DefaultClipboardManager) GetHistory(limit int, query string) ([]ClipboardItem, error) {
	cmd := exec.Command("cliphist", "list")
	var out bytes.Buffer
	cmd.Stdout = &out

	if err := cmd.Run(); err != nil {
		m.log.Warn("cliphist list komutu başarısız", "err", err)
		// Return pinned items if cliphist fails
		return m.getPinnedAsClipboardItems(query), nil
	}

	m.mu.RLock()
	pinnedMap := make(map[string]PinnedItem, len(m.pinnedItems))
	for _, p := range m.pinnedItems {
		pinnedMap[p.ID] = p
	}
	m.mu.RUnlock()

	items := ParseCliphistListOutput(out.String(), pinnedMap, limit, query)
	return items, nil
}

func (m *DefaultClipboardManager) getPinnedAsClipboardItems(query string) []ClipboardItem {
	m.mu.RLock()
	defer m.mu.RUnlock()

	query = strings.ToLower(strings.TrimSpace(query))
	var items []ClipboardItem
	for _, p := range m.pinnedItems {
		if query != "" && !strings.Contains(strings.ToLower(p.Content), query) && !strings.Contains(strings.ToLower(p.Label), query) {
			continue
		}
		preview := p.Content
		if len(preview) > 100 {
			preview = preview[:100] + "..."
		}
		items = append(items, ClipboardItem{
			ID:        p.ID,
			Preview:   preview,
			Type:      "text",
			IsPinned:  true,
			Label:     p.Label,
			Timestamp: p.Timestamp,
		})
	}
	return items
}

// GetItemContent decodes full text from cliphist or pinned storage.
func (m *DefaultClipboardManager) GetItemContent(id string) (string, error) {
	// 1. Check pinned storage first
	m.mu.RLock()
	for _, p := range m.pinnedItems {
		if p.ID == id {
			m.mu.RUnlock()
			return p.Content, nil
		}
	}
	m.mu.RUnlock()

	// 2. Decode from cliphist
	cmd := exec.Command("cliphist", "decode", id)
	var out bytes.Buffer
	var errOut bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &errOut

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("cliphist decode hatası (%s): %s", id, errOut.String())
	}

	return out.String(), nil
}

// CopyItem restores or writes text to the active Wayland clipboard using `wl-copy`.
func (m *DefaultClipboardManager) CopyItem(id string, customText string) error {
	var textToCopy string
	if customText != "" {
		textToCopy = customText
	} else if id != "" {
		content, err := m.GetItemContent(id)
		if err != nil {
			return err
		}
		textToCopy = content
	} else {
		return fmt.Errorf("kopyalanacak metin veya ID belirtilmedi")
	}

	cmd := exec.Command("wl-copy")
	cmd.Stdin = strings.NewReader(textToCopy)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("wl-copy çalıştırma hatası: %w", err)
	}

	m.log.Info("Pano içeriği başarıyla güncellendi (wl-copy)", "len", len(textToCopy))
	return nil
}

// DeleteItem removes an entry from cliphist and pinned items.
func (m *DefaultClipboardManager) DeleteItem(id string) error {
	// Remove from pinned if present
	_ = m.UnpinItem(id)

	// Run cliphist delete
	cmd := exec.Command("cliphist", "delete")
	cmd.Stdin = strings.NewReader(fmt.Sprintf("%s\t\n", id))
	_ = cmd.Run()

	m.log.Info("Pano öğesi silindi", "id", id)

	// Refresh and broadcast
	if m.updateCb != nil {
		items, _ := m.GetHistory(DefaultHistoryLimit, "")
		go m.updateCb(items)
	}

	return nil
}

// ClearHistory wipes cliphist while keeping pinned items.
func (m *DefaultClipboardManager) ClearHistory() error {
	cmd := exec.Command("cliphist", "wipe")
	if err := cmd.Run(); err != nil {
		m.log.Warn("cliphist wipe başarısız", "err", err)
	}

	m.log.Info("Pano geçmişi temizlendi (Sabitlenen öğeler korundu)")

	if m.updateCb != nil {
		items, _ := m.GetHistory(DefaultHistoryLimit, "")
		go m.updateCb(items)
	}

	return nil
}

// PinItem bookmarks an item into persistent storage.
func (m *DefaultClipboardManager) PinItem(id string, text string, label string) (*PinnedItem, error) {
	content := text
	if content == "" && id != "" {
		decoded, err := m.GetItemContent(id)
		if err != nil {
			return nil, fmt.Errorf("öğe çözülemedi: %w", err)
		}
		content = decoded
	}

	if content == "" {
		return nil, fmt.Errorf("sabitlenecek içerik boş olamaz")
	}

	if label == "" {
		if len(content) > 30 {
			label = content[:30] + "..."
		} else {
			label = content
		}
	}

	pinnedID := id
	if pinnedID == "" {
		pinnedID = fmt.Sprintf("pin_%d", time.Now().UnixMilli())
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	// Check if already pinned
	for i := range m.pinnedItems {
		if m.pinnedItems[i].ID == pinnedID {
			m.pinnedItems[i].Label = label
			m.pinnedItems[i].Content = content
			_ = SavePinned(m.pinnedFilePath, m.pinnedItems)
			return &m.pinnedItems[i], nil
		}
	}

	item := PinnedItem{
		ID:        pinnedID,
		Content:   content,
		Label:     label,
		Timestamp: time.Now().UnixMilli(),
	}

	m.pinnedItems = append([]PinnedItem{item}, m.pinnedItems...)
	if err := SavePinned(m.pinnedFilePath, m.pinnedItems); err != nil {
		m.log.Error("Sabitlenen öğe kaydedilemedi", "err", err)
		return nil, err
	}

	m.log.Info("Pano öğesi sabitlendi", "id", item.ID, "label", item.Label)

	if m.pinnedCb != nil {
		pinnedCopy := make([]PinnedItem, len(m.pinnedItems))
		copy(pinnedCopy, m.pinnedItems)
		go m.pinnedCb(pinnedCopy)
	}

	return &item, nil
}

// UnpinItem removes an item from pinned storage.
func (m *DefaultClipboardManager) UnpinItem(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	found := false
	var updated []PinnedItem
	for _, p := range m.pinnedItems {
		if p.ID == id {
			found = true
			continue
		}
		updated = append(updated, p)
	}

	if !found {
		return nil
	}

	m.pinnedItems = updated
	if err := SavePinned(m.pinnedFilePath, m.pinnedItems); err != nil {
		m.log.Error("Sabitleme kaldırma diske kaydedilemedi", "err", err)
		return err
	}

	m.log.Info("Pano sabitlemesi kaldırıldı", "id", id)

	if m.pinnedCb != nil {
		pinnedCopy := make([]PinnedItem, len(m.pinnedItems))
		copy(pinnedCopy, m.pinnedItems)
		go m.pinnedCb(pinnedCopy)
	}

	return nil
}

// GetPinned returns all pinned items.
func (m *DefaultClipboardManager) GetPinned() []PinnedItem {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make([]PinnedItem, len(m.pinnedItems))
	copy(result, m.pinnedItems)
	return result
}

// Start begins periodic and event-driven clipboard monitoring.
func (m *DefaultClipboardManager) Start(parentCtx context.Context) {
	ctx, cancel := context.WithCancel(parentCtx)
	m.cancelWatcher = cancel

	m.log.Info("Pano yöneticisi başlatıldı", "pinned_count", len(m.pinnedItems))

	// Run lightweight 1.5s polling loop to detect clipboard changes reliably across Wayland apps
	go func() {
		ticker := time.NewTicker(1500 * time.Millisecond)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				m.log.Info("Pano izleyici durduruldu")
				return
			case <-ticker.C:
				items, err := m.GetHistory(1, "")
				if err != nil || len(items) == 0 {
					continue
				}

				topItem := items[0]
				m.mu.Lock()
				isNew := m.lastTopID != "" && m.lastTopID != topItem.ID
				m.lastTopID = topItem.ID
				m.mu.Unlock()

				if isNew {
					m.log.Info("Yeni pano öğesi yakalandı", "id", topItem.ID, "preview", topItem.Preview)
					if m.copiedCb != nil {
						go m.copiedCb(topItem)
					}
					if m.updateCb != nil {
						fullList, _ := m.GetHistory(DefaultHistoryLimit, "")
						go m.updateCb(fullList)
					}
				}
			}
		}
	}()
}

// Close terminates watcher routines.
func (m *DefaultClipboardManager) Close() error {
	m.closeOnce.Do(func() {
		if m.cancelWatcher != nil {
			m.cancelWatcher()
		}
		m.log.Info("Pano yöneticisi kapatıldı")
	})
	return nil
}

func (m *DefaultClipboardManager) SetUpdateCallback(cb func(items []ClipboardItem)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCb = cb
}

func (m *DefaultClipboardManager) SetCopiedCallback(cb func(item ClipboardItem)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.copiedCb = cb
}

func (m *DefaultClipboardManager) SetPinnedCallback(cb func(items []PinnedItem)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.pinnedCb = cb
}
