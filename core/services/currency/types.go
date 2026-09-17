package currency

// CurrencyRates holds the exchange rate mapping, timestamp, and metadata.
type CurrencyRates struct {
	Timestamp   int64              `json:"timestamp"`
	LastUpdated string             `json:"last_updated"`
	Base        string             `json:"base"`
	Rates       map[string]float64 `json:"rates"`
}

// CurrencyConfig holds configuration options from config.json.
type CurrencyConfig struct {
	Enabled         bool   `json:"enabled"`
	SyncIntervalMin int    `json:"sync_interval_min"`
	DefaultTarget   string `json:"default_target"`
}
