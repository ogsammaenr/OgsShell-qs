package currency

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"ogsShell/core/logger"
	"strconv"
	"sync"
	"time"
)

// CurrencyManager defines operations for exchange rates management.
type CurrencyManager interface {
	Start(ctx context.Context)
	Close() error
	GetRates() *CurrencyRates
	GetConfig() CurrencyConfig
	SyncRates(ctx context.Context) error
	ReloadConfig() error
	SetUpdateCallback(cb func(rates *CurrencyRates))
}

// DefaultCurrencyManager is the standard implementation.
type DefaultCurrencyManager struct {
	storage    *Storage
	httpClient *http.Client
	rates      *CurrencyRates
	config     CurrencyConfig
	mu         sync.RWMutex
	updateCb   func(rates *CurrencyRates)
	stopChan   chan struct{}
	log        *slog.Logger
}

// NewDefaultCurrencyManager initializes the manager and loads cached rates.
func NewDefaultCurrencyManager() (*DefaultCurrencyManager, error) {
	storage := NewStorage()
	rates, err := storage.LoadRates()
	if err != nil {
		rates = DefaultRates()
	}

	cfg := storage.LoadConfig()

	return &DefaultCurrencyManager{
		storage: storage,
		httpClient: &http.Client{
			Timeout: 8 * time.Second,
		},
		rates:    rates,
		config:   cfg,
		stopChan: make(chan struct{}),
		log:      logger.Module("CURRENCY"),
	}, nil
}

// SetUpdateCallback assigns the callback invoked when rates are updated.
func (m *DefaultCurrencyManager) SetUpdateCallback(cb func(rates *CurrencyRates)) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.updateCb = cb
}

// GetRates returns a copy of current exchange rates.
func (m *DefaultCurrencyManager) GetRates() *CurrencyRates {
	m.mu.RLock()
	defer m.mu.RUnlock()

	copied := &CurrencyRates{
		Timestamp:   m.rates.Timestamp,
		LastUpdated: m.rates.LastUpdated,
		Base:        m.rates.Base,
		Rates:       make(map[string]float64, len(m.rates.Rates)),
	}
	for k, v := range m.rates.Rates {
		copied.Rates[k] = v
	}
	return copied
}

// GetConfig returns the current configuration.
func (m *DefaultCurrencyManager) GetConfig() CurrencyConfig {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.config
}

// ReloadConfig re-reads config.json and updates ticker interval.
func (m *DefaultCurrencyManager) ReloadConfig() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.config = m.storage.LoadConfig()
	m.log.Info("Kur konfigürasyonu yenilendi",
		"interval_min", m.config.SyncIntervalMin,
		"default_target", m.config.DefaultTarget,
		"enabled", m.config.Enabled)
	return nil
}

// Start launches the background scheduler and initial sync.
func (m *DefaultCurrencyManager) Start(ctx context.Context) {
	m.mu.RLock()
	cb := m.updateCb
	currentRates := m.GetRates()
	cfg := m.config
	m.mu.RUnlock()

	// Initial broadcast with cached rates
	if cb != nil {
		cb(currentRates)
	}

	// Determine if immediate sync is needed
	now := time.Now().Unix()
	intervalSec := int64(cfg.SyncIntervalMin * 60)
	if intervalSec <= 0 {
		intervalSec = 1800 // 30 mins
	}

	if now-currentRates.Timestamp > intervalSec {
		go func() {
			syncCtx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
			defer cancel()
			_ = m.SyncRates(syncCtx)
		}()
	}

	// Background periodic refresh loop
	go func() {
		ticker := time.NewTicker(time.Duration(intervalSec) * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-m.stopChan:
				return
			case <-ticker.C:
				m.mu.RLock()
				enabled := m.config.Enabled
				m.mu.RUnlock()

				if enabled {
					syncCtx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
					if err := m.SyncRates(syncCtx); err != nil {
						m.log.Warn("Periyodik kur senkronizasyonunda hata", "err", err)
					}
					cancel()
				}
			}
		}
	}()

	m.log.Info("Kur çevirici arka plan servisi başlatıldı", "sync_interval_min", cfg.SyncIntervalMin)
}

// Close terminates background goroutines.
func (m *DefaultCurrencyManager) Close() error {
	select {
	case <-m.stopChan:
	default:
		close(m.stopChan)
	}
	return nil
}

// SyncRates fetches latest rates from Frankfurter and Binance APIs, updates memory and disk.
func (m *DefaultCurrencyManager) SyncRates(ctx context.Context) error {
	m.log.Info("Canlı kur senkronizasyonu başlatılıyor...")

	newRates := make(map[string]float64)

	// Keep existing rates as base
	m.mu.RLock()
	for k, v := range m.rates.Rates {
		newRates[k] = v
	}
	m.mu.RUnlock()

	// 1. Fetch Fiat Rates from Frankfurter
	if err := m.fetchFrankfurter(ctx, newRates); err != nil {
		m.log.Warn("Frankfurter API kur çekme uyarısı", "err", err)
	}

	// 2. Fetch Crypto Rates from Binance (BTC & ETH)
	if err := m.fetchBinance(ctx, "BTCUSDT", "BTC", newRates); err != nil {
		m.log.Warn("Binance BTC fiyat çekme uyarısı", "err", err)
	}
	if err := m.fetchBinance(ctx, "ETHUSDT", "ETH", newRates); err != nil {
		m.log.Warn("Binance ETH fiyat çekme uyarısı", "err", err)
	}
	if err := m.fetchBinance(ctx, "SOLUSDT", "SOL", newRates); err != nil {
		m.log.Warn("Binance SOL fiyat çekme uyarısı", "err", err)
	}

	now := time.Now()
	ratesObj := &CurrencyRates{
		Timestamp:   now.Unix(),
		LastUpdated: now.Format("2006-01-02 15:04"),
		Base:        "USD",
		Rates:       newRates,
	}

	// Persist to disk
	if err := m.storage.SaveRates(ratesObj); err != nil {
		m.log.Error("Kur tablosu diske kaydedilemedi", "err", err)
	}

	// Update memory
	m.mu.Lock()
	m.rates = ratesObj
	cb := m.updateCb
	m.mu.Unlock()

	// Trigger broadcast
	if cb != nil {
		cb(ratesObj)
	}

	m.log.Info("Canlı kurlar başarıyla güncellendi",
		"TRY", newRates["TRY"],
		"EUR", newRates["EUR"],
		"BTC", newRates["BTC"])

	return nil
}

type frankfurterResponse struct {
	Base  string             `json:"base"`
	Rates map[string]float64 `json:"rates"`
}

func (m *DefaultCurrencyManager) fetchFrankfurter(ctx context.Context, target map[string]float64) error {
	urls := []string{
		"https://api.frankfurter.dev/v1/latest?base=USD",
		"https://api.frankfurter.app/latest?from=USD",
	}

	var lastErr error
	for _, u := range urls {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
		if err != nil {
			lastErr = err
			continue
		}
		req.Header.Set("User-Agent", "OgsShell/1.0 (Linux x86_64)")

		resp, err := m.httpClient.Do(req)
		if err != nil {
			lastErr = err
			continue
		}

		body, err := io.ReadAll(resp.Body)
		_ = resp.Body.Close()
		if err != nil {
			lastErr = err
			continue
		}

		if resp.StatusCode != http.StatusOK {
			lastErr = fmt.Errorf("status %d from %s", resp.StatusCode, u)
			continue
		}

		var fResp frankfurterResponse
		if err := json.Unmarshal(body, &fResp); err != nil {
			lastErr = err
			continue
		}

		target["USD"] = 1.0
		for k, v := range fResp.Rates {
			target[k] = v
		}
		return nil
	}

	return lastErr
}

type binanceTickerResponse struct {
	Symbol string `json:"symbol"`
	Price  string `json:"price"`
}

func (m *DefaultCurrencyManager) fetchBinance(ctx context.Context, symbol, code string, target map[string]float64) error {
	url := fmt.Sprintf("https://api.binance.com/api/v3/ticker/price?symbol=%s", symbol)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", "OgsShell/1.0 (Linux x86_64)")

	resp, err := m.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("binance status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	var bResp binanceTickerResponse
	if err := json.Unmarshal(body, &bResp); err != nil {
		return err
	}

	price, err := strconv.ParseFloat(bResp.Price, 64)
	if err != nil {
		return err
	}

	target[code] = price
	return nil
}
