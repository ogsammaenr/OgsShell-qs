package theme

import (
	"context"
	"fmt"
	"log/slog"
	"ogsShell/core/logger"
	"sync"
	"time"
)

// AppAdapterInterface defines the dependency to avoid circular imports.
type AppAdapterInterface interface {
	ID() string
	Name() string
	IsInstalled() bool
	Apply(palette *ThemePalette) error
}

// ThemeManager defines the public contract for theme management.
type ThemeManager interface {
	GetState() (*ThemeState, error)
	GetAvailableThemes() []ThemePalette
	SetActiveTheme(themeID string) (*ThemePalette, error)
	ToggleAdapter(adapterID string, enabled bool) error

	Start(ctx context.Context)
	Close() error
	SetUpdateCallback(cb func(state *ThemeState))
}

// DefaultThemeManager is the high-performance async implementation using shared/ directory.
type DefaultThemeManager struct {
	sharedDir  string
	configPath string
	log        *slog.Logger

	mu              sync.RWMutex
	availableThemes []ThemePalette
	activeTheme     *ThemePalette
	config          *UserThemeConfig
	adapters        []AppAdapterInterface

	applyChan chan *ThemePalette
	updateCb  func(state *ThemeState)

	ctx    context.Context
	cancel context.CancelFunc
}

// NewDefaultThemeManager creates a new ThemeManager loading strictly from shared/ themes.
func NewDefaultThemeManager(sharedDir string, configPath string, customAdapters ...AppAdapterInterface) (*DefaultThemeManager, error) {
	if sharedDir == "" {
		sharedDir = GetSharedDir()
	}
	if configPath == "" {
		configPath = GetThemeConfigPath()
	}

	cfg, err := LoadThemeConfig(configPath)
	if err != nil {
		cfg = &UserThemeConfig{
			ActiveThemeID:   "everforest",
			EnabledAdapters: make(map[string]bool),
		}
	}

	themes, err := LoadSharedThemes(GetSharedThemesPath(sharedDir))
	if err != nil || len(themes) == 0 {
		themes = DefaultSharedThemes
	}

	var active *ThemePalette
	for i := range themes {
		if themes[i].ID == cfg.ActiveThemeID {
			active = &themes[i]
			break
		}
	}
	if active == nil && len(themes) > 0 {
		active = &themes[0]
		cfg.ActiveThemeID = active.ID
	}

	mgr := &DefaultThemeManager{
		sharedDir:       sharedDir,
		configPath:      configPath,
		log:             logger.Module("THEME"),
		availableThemes: themes,
		activeTheme:     active,
		config:          cfg,
		adapters:        customAdapters,
		applyChan:       make(chan *ThemePalette, 32),
	}

	return mgr, nil
}

// RegisterAdapters adds adapters to the manager.
func (m *DefaultThemeManager) RegisterAdapters(adapters ...AppAdapterInterface) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.adapters = append(m.adapters, adapters...)

	// Default enable newly registered adapters if not in config
	for _, a := range adapters {
		if _, exists := m.config.EnabledAdapters[a.ID()]; !exists {
			m.config.EnabledAdapters[a.ID()] = true
		}
	}
}

// getStateUnsafe returns the synthesized theme state assuming lock is held.
func (m *DefaultThemeManager) getStateUnsafe() *ThemeState {
	enabledCopy := make(map[string]bool, len(m.config.EnabledAdapters))
	for k, v := range m.config.EnabledAdapters {
		enabledCopy[k] = v
	}

	themesCopy := make([]ThemePalette, len(m.availableThemes))
	copy(themesCopy, m.availableThemes)

	return &ThemeState{
		ActiveTheme:     m.activeTheme,
		AvailableThemes: themesCopy,
		EnabledAdapters: enabledCopy,
	}
}

// GetState returns the current synthesized theme state.
func (m *DefaultThemeManager) GetState() (*ThemeState, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.getStateUnsafe(), nil
}

// GetAvailableThemes returns the exact themes loaded from shared/themes/themes.json.
func (m *DefaultThemeManager) GetAvailableThemes() []ThemePalette {
	m.mu.RLock()
	defer m.mu.RUnlock()

	res := make([]ThemePalette, len(m.availableThemes))
	copy(res, m.availableThemes)
	return res
}

// SetActiveTheme instantly switches active theme in memory & IPC, then dispatches adapters asynchronously.
func (m *DefaultThemeManager) SetActiveTheme(themeID string) (*ThemePalette, error) {
	m.mu.Lock()
	var selected *ThemePalette
	for i := range m.availableThemes {
		if m.availableThemes[i].ID == themeID {
			selected = &m.availableThemes[i]
			break
		}
	}

	if selected == nil {
		m.mu.Unlock()
		return nil, fmt.Errorf("tema bulunamadı: %s", themeID)
	}

	m.activeTheme = selected
	m.config.ActiveThemeID = selected.ID
	state := m.getStateUnsafe()
	cfgPath := m.configPath
	cfgCopy := *m.config
	m.mu.Unlock()

	m.log.Info("Aktif tema anında güncellendi", "id", selected.ID, "name", selected.Name)

	// 1. Asynchronously persist config to disk
	go func() {
		_ = SaveThemeConfig(cfgPath, &cfgCopy)
	}()

	// 2. Instantly broadcast state update to all UI / socket subscribers (<1ms)
	m.mu.RLock()
	cb := m.updateCb
	m.mu.RUnlock()
	if cb != nil {
		go cb(state)
	}

	// 3. Queue for debounced background adapter application
	select {
	case m.applyChan <- selected:
	default:
		// Drain older queued item if full and enqueue newest
		select {
		case <-m.applyChan:
		default:
		}
		m.applyChan <- selected
	}

	return selected, nil
}

// ToggleAdapter enables or disables an application adapter.
func (m *DefaultThemeManager) ToggleAdapter(adapterID string, enabled bool) error {
	m.mu.Lock()
	m.config.EnabledAdapters[adapterID] = enabled
	cfgPath := m.configPath
	cfgCopy := *m.config
	state := m.getStateUnsafe()
	active := m.activeTheme
	m.mu.Unlock()

	go func() {
		_ = SaveThemeConfig(cfgPath, &cfgCopy)
	}()

	m.log.Info("Adaptör durumu güncellendi", "adapter", adapterID, "enabled", enabled)

	m.mu.RLock()
	cb := m.updateCb
	m.mu.RUnlock()
	if cb != nil {
		go cb(state)
	}

	if enabled && active != nil {
		select {
		case m.applyChan <- active:
		default:
		}
	}

	return nil
}

// Start launches the background worker loops.
func (m *DefaultThemeManager) Start(ctx context.Context) {
	m.mu.Lock()
	m.ctx, m.cancel = context.WithCancel(ctx)
	m.mu.Unlock()

	m.log.Info("Tema yöneticisi başlatıldı", "active_theme", m.config.ActiveThemeID, "adapters_count", len(m.adapters), "shared_dir", m.sharedDir)
	go m.runAdapterDispatcher(m.ctx)
}

// Close gracefully stops background operations.
func (m *DefaultThemeManager) Close() error {
	m.mu.Lock()
	if m.cancel != nil {
		m.cancel()
	}
	m.mu.Unlock()
	m.log.Info("Tema yöneticisi kapatıldı")
	return nil
}

// SetUpdateCallback registers the IPC broadcast hook.
func (m *DefaultThemeManager) SetUpdateCallback(cb func(state *ThemeState)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCb = cb
}

// runAdapterDispatcher handles debounced, concurrent execution of external app adapters.
func (m *DefaultThemeManager) runAdapterDispatcher(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case target := <-m.applyChan:
			// Coalesce rapid clicks within 50ms window: drain intermediate updates
			drainTimer := time.NewTimer(50 * time.Millisecond)
		drainLoop:
			for {
				select {
				case newer := <-m.applyChan:
					target = newer
				case <-drainTimer.C:
					break drainLoop
				case <-ctx.Done():
					drainTimer.Stop()
					return
				}
			}

			if target == nil {
				continue
			}

			// Capture active adapters snapshot
			m.mu.RLock()
			adaptersCopy := make([]AppAdapterInterface, len(m.adapters))
			copy(adaptersCopy, m.adapters)
			enabledMap := make(map[string]bool, len(m.config.EnabledAdapters))
			for k, v := range m.config.EnabledAdapters {
				enabledMap[k] = v
			}
			m.mu.RUnlock()

			// Apply to all enabled adapters concurrently with isolated timeouts
			var wg sync.WaitGroup
			for _, adp := range adaptersCopy {
				if enabledMap[adp.ID()] && adp.IsInstalled() {
					wg.Add(1)
					go func(a AppAdapterInterface, p *ThemePalette) {
						defer wg.Done()
						done := make(chan error, 1)
						go func() {
							done <- a.Apply(p)
						}()

						select {
						case err := <-done:
							if err != nil {
								m.log.Warn("Adaptör temayı uygulayamadı", "adapter", a.ID(), "err", err)
							} else {
								m.log.Info("Adaptör temayı başarıyla uyguladı", "adapter", a.ID())
							}
						case <-time.After(1 * time.Second):
							m.log.Warn("Adaptör zaman aşımına uğradı (>1s)", "adapter", a.ID())
						case <-ctx.Done():
							return
						}
					}(adp, target)
				}
			}
			wg.Wait()
		}
	}
}
