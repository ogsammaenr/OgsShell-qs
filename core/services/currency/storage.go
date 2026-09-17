package currency

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// Storage handles atomic persistence for currency rates and config reading.
type Storage struct {
	ratesFilePath  string
	configFilePath string
}

// NewStorage creates a new storage instance targeting $XDG_CONFIG_HOME/ogsShell/.
func NewStorage() *Storage {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			home = "/home/excalibur"
		}
		configDir = filepath.Join(home, ".config")
	}

	ogsDir := filepath.Join(configDir, "ogsShell")
	_ = os.MkdirAll(ogsDir, 0755)

	return &Storage{
		ratesFilePath:  filepath.Join(ogsDir, "currency_rates.json"),
		configFilePath: filepath.Join(ogsDir, "config.json"),
	}
}

// DefaultRates returns realistic fallback rates when no cache or network is available.
func DefaultRates() *CurrencyRates {
	return &CurrencyRates{
		Timestamp:   time.Now().Unix(),
		LastUpdated: time.Now().Format("2006-01-02 15:04"),
		Base:        "USD",
		Rates: map[string]float64{
			"USD": 1.0,
			"TRY": 48.59,
			"EUR": 0.86,
			"GBP": 0.74,
			"CHF": 0.81,
			"JPY": 154.0,
			"CAD": 1.38,
			"AUD": 1.39,
			"RUB": 90.0,
			"CNY": 6.70,
			"SAR": 3.75,
			"AED": 3.67,
			"BTC": 78000.0,
			"ETH": 2500.0,
			"SOL": 140.0,
		},
	}
}

// LoadRates loads currency rates from disk, falling back to defaults if not found or corrupted.
func (s *Storage) LoadRates() (*CurrencyRates, error) {
	data, err := os.ReadFile(s.ratesFilePath)
	if err != nil {
		if os.IsNotExist(err) {
			def := DefaultRates()
			_ = s.SaveRates(def)
			return def, nil
		}
		return DefaultRates(), err
	}

	var rates CurrencyRates
	if err := json.Unmarshal(data, &rates); err != nil {
		return DefaultRates(), err
	}

	if rates.Rates == nil || len(rates.Rates) == 0 {
		return DefaultRates(), fmt.Errorf("empty rates table in cache")
	}

	return &rates, nil
}

// SaveRates atomically writes currency rates to disk.
func (s *Storage) SaveRates(rates *CurrencyRates) error {
	if rates == nil {
		return fmt.Errorf("cannot save nil rates")
	}

	data, err := json.MarshalIndent(rates, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal currency rates: %w", err)
	}

	tmpFile := s.ratesFilePath + ".tmp"
	if err := os.WriteFile(tmpFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write temp currency rates: %w", err)
	}

	if err := os.Rename(tmpFile, s.ratesFilePath); err != nil {
		return fmt.Errorf("failed to rename temp currency rates: %w", err)
	}

	return nil
}

// ConfigRoot represents the top-level structure of config.json.
type ConfigRoot struct {
	Currency *CurrencyConfig `json:"currency,omitempty"`
}

// LoadConfig reads the currency configuration from $XDG_CONFIG_HOME/ogsShell/config.json.
func (s *Storage) LoadConfig() CurrencyConfig {
	def := CurrencyConfig{
		Enabled:         true,
		SyncIntervalMin: 30,
		DefaultTarget:   "TRY",
	}

	data, err := os.ReadFile(s.configFilePath)
	if err != nil {
		return def
	}

	var root ConfigRoot
	if err := json.Unmarshal(data, &root); err != nil || root.Currency == nil {
		return def
	}

	cfg := *root.Currency
	if cfg.SyncIntervalMin <= 0 {
		cfg.SyncIntervalMin = 30
	}
	if cfg.DefaultTarget == "" {
		cfg.DefaultTarget = "TRY"
	}

	return cfg
}
