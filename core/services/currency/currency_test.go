package currency

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDefaultRates(t *testing.T) {
	rates := DefaultRates()
	if rates == nil {
		t.Fatal("expected non-nil default rates")
	}
	if rates.Base != "USD" {
		t.Errorf("expected base USD, got %s", rates.Base)
	}
	if rates.Rates["TRY"] <= 0 {
		t.Errorf("expected positive TRY rate, got %f", rates.Rates["TRY"])
	}
	if rates.Rates["BTC"] <= 0 {
		t.Errorf("expected positive BTC rate, got %f", rates.Rates["BTC"])
	}
}

func TestStorageSaveAndLoad(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "ogs_currency_test_*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	storage := &Storage{
		ratesFilePath:  filepath.Join(tmpDir, "currency_rates.json"),
		configFilePath: filepath.Join(tmpDir, "config.json"),
	}

	// Initial load should create defaults
	rates, err := storage.LoadRates()
	if err != nil {
		t.Fatalf("unexpected load error: %v", err)
	}
	if rates.Rates["USD"] != 1.0 {
		t.Errorf("expected USD=1.0, got %f", rates.Rates["USD"])
	}

	// Modify and save
	rates.Rates["TEST"] = 123.45
	if err := storage.SaveRates(rates); err != nil {
		t.Fatalf("failed to save rates: %v", err)
	}

	// Reload
	reloaded, err := storage.LoadRates()
	if err != nil {
		t.Fatalf("failed to reload: %v", err)
	}
	if reloaded.Rates["TEST"] != 123.45 {
		t.Errorf("expected TEST=123.45, got %f", reloaded.Rates["TEST"])
	}
}

func TestLoadConfig(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "ogs_config_test_*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	cfgPath := filepath.Join(tmpDir, "config.json")
	jsonContent := `{
		"currency": {
			"enabled": true,
			"sync_interval_min": 15,
			"default_target": "EUR"
		}
	}`
	if err := os.WriteFile(cfgPath, []byte(jsonContent), 0644); err != nil {
		t.Fatal(err)
	}

	storage := &Storage{
		ratesFilePath:  filepath.Join(tmpDir, "currency_rates.json"),
		configFilePath: cfgPath,
	}

	cfg := storage.LoadConfig()
	if !cfg.Enabled {
		t.Errorf("expected enabled=true")
	}
	if cfg.SyncIntervalMin != 15 {
		t.Errorf("expected sync_interval_min=15, got %d", cfg.SyncIntervalMin)
	}
	if cfg.DefaultTarget != "EUR" {
		t.Errorf("expected default_target=EUR, got %s", cfg.DefaultTarget)
	}
}
