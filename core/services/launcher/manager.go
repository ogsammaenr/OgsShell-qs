package launcher

import (
	"context"
	"fmt"
	"sync"

	"ogsShell/core/logger"
	"ogsShell/core/services/launcher/entry"
)

// LauncherManager defines the interface for application discovery, indexing, search, and execution.
type LauncherManager interface {
	Start(ctx context.Context)
	Close() error
	Search(query string, limit int) []entry.AppEntry
	List(limit int) []entry.AppEntry
	Launch(appID string, customExec string) error
	Reindex()
	SetUpdateCallback(func(apps []entry.AppEntry))
	GetAppByID(appID string) (entry.AppEntry, bool)
	GetAppCount() int
}

// Manager is the main coordinator for the App Launcher subsystem.
type Manager struct {
	indexer        *Indexer
	watcher        *Watcher
	runner         *AppRunner
	updateCallback func(apps []entry.AppEntry)
	mu             sync.RWMutex
}

// NewDefaultLauncherManager initializes a new LauncherManager with standard system paths.
func NewDefaultLauncherManager(customStatsPath string, customDirs []string) (*Manager, error) {
	indexer := NewIndexer(customStatsPath, customDirs)
	runner := NewAppRunner()

	m := &Manager{
		indexer: indexer,
		runner:  runner,
	}

	watcher, err := NewWatcher(indexer, customDirs, func() {
		m.notifyUpdate()
	})
	if err != nil {
		logger.Module("LAUNCHER").Warn("fsnotify watcher başlatılamadı, statik modda devam ediliyor", "err", err)
	}
	m.watcher = watcher

	return m, nil
}

// Start begins background indexing and directory watching.
func (m *Manager) Start(ctx context.Context) {
	log := logger.Module("LAUNCHER")
	log.Info("Masaüstü uygulamaları taranıyor...")

	// Initial scan
	m.indexer.Reindex()
	log.Info("Uygulama indeksi hazırlandı", "count", m.indexer.Count())

	// Start real-time file watcher
	if m.watcher != nil {
		m.watcher.Start(ctx)
		log.Info("Gerçek zamanlı .desktop dosya izleyicisi aktif")
	}
}

// Close gracefully stops the watcher and frees resources.
func (m *Manager) Close() error {
	if m.watcher != nil {
		return m.watcher.Close()
	}
	return nil
}

// Search performs a weighted fuzzy in-memory search for applications matching the query.
func (m *Manager) Search(query string, limit int) []entry.AppEntry {
	return m.indexer.Search(query, limit)
}

// List returns all indexed applications sorted by launch count and name.
func (m *Manager) List(limit int) []entry.AppEntry {
	return m.indexer.GetAll(limit)
}

// Launch starts an application given its ID or a direct exec string.
func (m *Manager) Launch(appID string, customExec string) error {
	log := logger.Module("LAUNCHER")
	execCmd := customExec

	if execCmd == "" && appID != "" {
		app, exists := m.indexer.GetByID(appID)
		if !exists {
			return fmt.Errorf("uygulama bulunamadı: %s", appID)
		}
		execCmd = app.Exec
	}

	if execCmd == "" {
		return fmt.Errorf("çalıştırılacak geçerli bir komut bulunamadı")
	}

	err := m.runner.Launch(execCmd)
	if err != nil {
		return err
	}

	// Record launch frequency
	if appID != "" {
		m.indexer.RecordLaunch(appID)
	}

	log.Info("Uygulama başarıyla başlatıldı", "id", appID, "exec", execCmd)
	return nil
}

// Reindex forces a manual scan of all application directories.
func (m *Manager) Reindex() {
	m.indexer.Reindex()
	m.notifyUpdate()
}

// SetUpdateCallback registers a handler to be invoked whenever the app index is updated.
func (m *Manager) SetUpdateCallback(cb func(apps []entry.AppEntry)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCallback = cb
}

// GetAppByID looks up an indexed application by its desktop entry file name.
func (m *Manager) GetAppByID(appID string) (entry.AppEntry, bool) {
	return m.indexer.GetByID(appID)
}

// GetAppCount returns the number of currently indexed applications.
func (m *Manager) GetAppCount() int {
	return m.indexer.Count()
}

// notifyUpdate broadcasts the updated application list to the registered callback.
func (m *Manager) notifyUpdate() {
	m.mu.RLock()
	cb := m.updateCallback
	m.mu.RUnlock()

	if cb != nil {
		cb(m.indexer.GetAll(0))
	}
}
