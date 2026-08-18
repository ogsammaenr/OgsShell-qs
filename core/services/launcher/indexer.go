package launcher

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"sync"

	"ogsShell/core/logger"
	"ogsShell/core/services/launcher/entry"
)

// Indexer manages thread-safe in-memory application caching, scoring queries, and persistent launch stats.
type Indexer struct {
	mu          sync.RWMutex
	entries     map[string]entry.AppEntry
	entryList   []entry.AppEntry
	statsFile   string
	launchStats map[string]int
	appDirs     []string
}

// NewIndexer creates a new Indexer with specified stats file and optional custom directories.
func NewIndexer(statsFile string, customDirs []string) *Indexer {
	if statsFile == "" {
		configHome := os.Getenv("XDG_CONFIG_HOME")
		if configHome == "" {
			home, _ := os.UserHomeDir()
			configHome = filepath.Join(home, ".config")
		}
		statsFile = filepath.Join(configHome, "ogsShell", "launcher_stats.json")
	}

	dirs := customDirs
	if len(dirs) == 0 {
		dirs = GetApplicationDirectories()
	}

	idx := &Indexer{
		entries:     make(map[string]entry.AppEntry),
		entryList:   make([]entry.AppEntry, 0, 128),
		statsFile:   statsFile,
		launchStats: make(map[string]int),
		appDirs:     dirs,
	}

	idx.loadStats()
	return idx
}

// Reindex scans all configured application directories and rebuilds the in-memory cache.
// Directories are processed such that user-level directories override system-level ones for duplicate IDs.
func (idx *Indexer) Reindex() {
	log := logger.Module("LAUNCHER-INDEXER")

	// We scan in reverse order so higher-priority (user local) directories overwrite lower-priority ones.
	scannedMap := make(map[string]entry.AppEntry)

	// Reverse iterate over dirs
	for i := len(idx.appDirs) - 1; i >= 0; i-- {
		dir := idx.appDirs[i]
		entries, err := os.ReadDir(dir)
		if err != nil {
			// Directory might not exist (e.g. flatpak not installed), skip silently
			continue
		}

		for _, file := range entries {
			if file.IsDir() || filepath.Ext(file.Name()) != ".desktop" {
				continue
			}

			fullPath := filepath.Join(dir, file.Name())
			app, err := ParseDesktopFile(fullPath)
			if err != nil || app == nil {
				continue
			}

			// Add or overwrite (higher priority directories come later in reverse iteration)
			scannedMap[app.ID] = *app
		}
	}

	idx.mu.Lock()
	defer idx.mu.Unlock()

	idx.entries = make(map[string]entry.AppEntry, len(scannedMap))
	idx.entryList = make([]entry.AppEntry, 0, len(scannedMap))

	for id, app := range scannedMap {
		// Attach persistent launch count
		if count, exists := idx.launchStats[id]; exists {
			app.LaunchCount = count
		}
		idx.entries[id] = app
		idx.entryList = append(idx.entryList, app)
	}

	log.Info("Uygulama indeksi yenilendi", "total_apps", len(idx.entryList))
}

// Search executes an in-memory weighted fuzzy search against all indexed applications.
func (idx *Indexer) Search(query string, limit int) []entry.AppEntry {
	if limit <= 0 {
		limit = 15
	}

	idx.mu.RLock()
	defer idx.mu.RUnlock()

	if len(idx.entryList) == 0 {
		return []entry.AppEntry{}
	}

	// Hot-path memory slice allocation
	matches := make([]entry.AppEntry, 0, len(idx.entryList))

	for _, app := range idx.entryList {
		score := ScoreApp(query, &app)
		if score > 0 {
			appCopy := app
			appCopy.Score = score
			matches = append(matches, appCopy)
		}
	}

	// Sort results: Score DESC, LaunchCount DESC, Name ASC
	sort.Slice(matches, func(i, j int) bool {
		if matches[i].Score != matches[j].Score {
			return matches[i].Score > matches[j].Score
		}
		if matches[i].LaunchCount != matches[j].LaunchCount {
			return matches[i].LaunchCount > matches[j].LaunchCount
		}
		return matches[i].Name < matches[j].Name
	})

	if len(matches) > limit {
		matches = matches[:limit]
	}

	return matches
}

// GetAll returns all indexed applications sorted by launch count and name.
func (idx *Indexer) GetAll(limit int) []entry.AppEntry {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	result := make([]entry.AppEntry, len(idx.entryList))
	copy(result, idx.entryList)

	sort.Slice(result, func(i, j int) bool {
		if result[i].LaunchCount != result[j].LaunchCount {
			return result[i].LaunchCount > result[j].LaunchCount
		}
		return result[i].Name < result[j].Name
	})

	if limit > 0 && len(result) > limit {
		result = result[:limit]
	}

	return result
}

// GetByID looks up an application entry by its desktop ID.
func (idx *Indexer) GetByID(appID string) (entry.AppEntry, bool) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	app, exists := idx.entries[appID]
	return app, exists
}

// RecordLaunch increments the launch counter for the given application ID and persists stats.
func (idx *Indexer) RecordLaunch(appID string) {
	idx.mu.Lock()
	idx.launchStats[appID]++
	count := idx.launchStats[appID]

	if app, exists := idx.entries[appID]; exists {
		app.LaunchCount = count
		idx.entries[appID] = app

		for i := range idx.entryList {
			if idx.entryList[i].ID == appID {
				idx.entryList[i].LaunchCount = count
				break
			}
		}
	}
	idx.mu.Unlock()

	// Asynchronously save stats to disk
	go idx.saveStats()
}

// Count returns the total number of indexed applications.
func (idx *Indexer) Count() int {
	idx.mu.RLock()
	defer idx.mu.RUnlock()
	return len(idx.entryList)
}

// loadStats loads launch history counts from disk.
func (idx *Indexer) loadStats() {
	data, err := os.ReadFile(idx.statsFile)
	if err != nil {
		return
	}

	var stats map[string]int
	if err := json.Unmarshal(data, &stats); err == nil {
		idx.launchStats = stats
	}
}

// saveStats atomically persists launch statistics to disk.
func (idx *Indexer) saveStats() {
	idx.mu.RLock()
	data, err := json.MarshalIndent(idx.launchStats, "", "  ")
	idx.mu.RUnlock()

	if err != nil {
		return
	}

	dir := filepath.Dir(idx.statsFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return
	}

	tmpFile := idx.statsFile + ".tmp"
	if err := os.WriteFile(tmpFile, data, 0644); err != nil {
		return
	}

	_ = os.Rename(tmpFile, idx.statsFile)
}
