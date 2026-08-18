package launcher

import (
	"context"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
	"ogsShell/core/logger"
)

// Watcher monitors application directories for desktop entry changes using fsnotify with 150ms debouncing.
type Watcher struct {
	fsWatcher     *fsnotify.Watcher
	dirs          []string
	indexer       *Indexer
	debounceDelay time.Duration
	onReindex     func()
	mu            sync.Mutex
	timer         *time.Timer
	stopCh        chan struct{}
}

// NewWatcher creates a new real-time filesystem watcher for application directories.
func NewWatcher(indexer *Indexer, dirs []string, onReindex func()) (*Watcher, error) {
	fsWatcher, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}

	if len(dirs) == 0 {
		dirs = GetApplicationDirectories()
	}

	w := &Watcher{
		fsWatcher:     fsWatcher,
		dirs:          dirs,
		indexer:       indexer,
		debounceDelay: 150 * time.Millisecond,
		onReindex:     onReindex,
		stopCh:        make(chan struct{}),
	}

	return w, nil
}

// Start begins monitoring the filesystem directories in a background goroutine.
func (w *Watcher) Start(ctx context.Context) {
	log := logger.Module("LAUNCHER-WATCHER")

	// Add existing application directories to fsnotify watcher
	for _, dir := range w.dirs {
		if fi, err := os.Stat(dir); err == nil && fi.IsDir() {
			if err := w.fsWatcher.Add(dir); err == nil {
				log.Debug("Uygulama dizini izlemeye alındı", "dir", dir)
			}
		}
	}

	go func() {
		defer w.fsWatcher.Close()

		for {
			select {
			case <-ctx.Done():
				return
			case <-w.stopCh:
				return
			case event, ok := <-w.fsWatcher.Events:
				if !ok {
					return
				}

				// Only react to .desktop file changes or directory creations/removals
				if filepath.Ext(event.Name) == ".desktop" || event.Has(fsnotify.Create) || event.Has(fsnotify.Remove) {
					w.triggerDebouncedReindex()
				}

			case err, ok := <-w.fsWatcher.Errors:
				if !ok {
					return
				}
				log.Warn("Dosya izleme hatası", "err", err)
			}
		}
	}()
}

// triggerDebouncedReindex resets or starts the 150ms debounce timer.
func (w *Watcher) triggerDebouncedReindex() {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.timer != nil {
		w.timer.Stop()
	}

	w.timer = time.AfterFunc(w.debounceDelay, func() {
		log := logger.Module("LAUNCHER-WATCHER")
		log.Info("Masaüstü dosyalarında değişiklik tespit edildi, indeks yenileniyor...")
		w.indexer.Reindex()
		if w.onReindex != nil {
			w.onReindex()
		}
	})
}

// Close stops the watcher.
func (w *Watcher) Close() error {
	w.mu.Lock()
	if w.timer != nil {
		w.timer.Stop()
	}
	w.mu.Unlock()

	select {
	case <-w.stopCh:
		// already closed
	default:
		close(w.stopCh)
	}

	return w.fsWatcher.Close()
}
