---
title: "Currency Exchange Service (Go Daemon)"
type: service
tags:
  - currency/converter
  - go/daemon
  - offline-first
status: active
---

# Currency Exchange Service (Go Daemon)

Go daemon subsystem responsible for periodic background synchronization, persistent atomic caching, and broadcast of global fiat and cryptocurrency exchange rates over Unix Domain Socket IPC.

## Purpose & Architecture

1. **Zero-Process Offline-First Design**:
   - Replaces external client scripts (Python/curl) with a low-footprint native Go HTTP client.
   - Synchronizes rates in the background without blocking the UI or introducing keystroke latency.
   - Persists exchange rates atomically to `$XDG_CONFIG_HOME/ogsShell/currency_rates.json`.
2. **Multi-Source Telemetry**:
   - **Fiat Currencies:** Frankfurter API (`https://api.frankfurter.dev/v1/latest?base=USD` / `api.frankfurter.app`) for TRY, EUR, GBP, CHF, JPY, CAD, AUD, RUB, CNY, SAR, AED, etc.
   - **Cryptocurrencies:** Binance Public Ticker API (`https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT` / `ETHUSDT` / `SOLUSDT`).
3. **Dynamic Configuration via `config.json`**:
   - Sync interval (`currency.sync_interval_min`, default: 30 minutes).
   - Default target currency (`currency.default_target`, default: `"TRY"`).
   - Enable/disable toggle (`currency.enabled`).

## Go Implementation Details

* **Source Directory:** `core/services/currency/`
* **Interfaces & Core Types:**
  - `CurrencyManager`: Background scheduler, memory cache, and network sync manager.
  - `Storage`: Inode-preserving atomic JSON disk commits to `currency_rates.json` and config loader.
  - `CurrencyRates`: Timestamped map of exchange rates relative to USD base.

### Socket Event Broadcast Schema

When exchange rates are updated, the service broadcasts the following NDJSON packet over `ogs_shell.sock`:

```json
{
  "type": "currency_rates_update",
  "payload": {
    "timestamp": 1789394849,
    "last_updated": "2026-09-14 17:42",
    "base": "USD",
    "rates": {
      "USD": 1.0,
      "TRY": 48.59,
      "EUR": 0.86,
      "GBP": 0.74,
      "BTC": 78322.01,
      "ETH": 2508.59,
      "SOL": 140.0
    }
  }
}
```

### Supported RPC Actions

1. `get_currency_rates`: Broadcasts current memory rates table.
2. `sync_currency_rates`: Forces an immediate asynchronous network fetch and updates disk cache.
3. `reload_currency_config`: Reloads `config.json` settings (interval and default target).

## Related Documentation

* QML Dynamic Island Widget: `[[App-Launcher-Widget]]`
* Configuration Specification: `[[Configuration-System-Spec]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* Master Architecture: `[[System-Architecture]]`
* Backend Endpoints: `[[Backend-Endpoints-Reference]]`
