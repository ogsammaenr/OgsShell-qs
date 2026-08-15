---
title: "Proposal: Dynamic Online Holiday Sync Engine with Resilient Offline Fallback"
type: agent-thought
tags:
  - proposal/holidays
  - service/calendar
  - api/nager-date
  - cache/json
  - go/daemon
created: 2026-08-11
updated: 2026-08-11
status: implemented
related_notes:
  - "[[Calendar-Service]]"
  - "[[System-Architecture]]"
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Socket-Schema]]"
---

# Proposal: Dynamic Online Holiday Sync Engine with Resilient Offline Fallback

> [!IDEA]
> Extending the Holiday Engine in `core/services/calendar/` to dynamically fetch official Turkey public holidays from reliable online APIs (Nager.Date / OpenHolidays / iCal), caching results to `$XDG_CACHE_HOME/ogsShell/holidays_{year}.json`, while maintaining the offline algorithmic engine as an immediate zero-network fallback.

## 1. Problem Statement
In Turkey:
- Religious holiday durations or administrative leave extensions (e.g., 9-day bridging holidays) may be officially declared or revised.
- Hardcoded static tables cannot capture mid-year government announcements.
- The shell must remain 100% resilient when offline without crashing or blocking the UI startup.

## 2. Multi-Tiered Architecture (Tiered Fallback)

```
┌────────────────────────────────────────────────────────┐
│  Tier 1: In-Memory Cached Holidays                     │
└───────────────────────────┬────────────────────────────┘
                            │ Cache Miss / Refresh
┌───────────────────────────▼────────────────────────────┐
│  Tier 2: Remote API Fetch (Nager.Date / HTTP Client)   │
│  - Non-blocking goroutine, 5s timeout, ETag/Cache      │
└───────────────────────────┬────────────────────────────┘
                            │ Network Failure / Offline
┌───────────────────────────▼────────────────────────────┐
│  Tier 3: Local JSON Cache (~/.cache/ogsShell/...)      │
└───────────────────────────┬────────────────────────────┘
                            │ First Run & Offline
┌───────────────────────────▼────────────────────────────┐
│  Tier 4: Offline Astronomical Algorithm & Diyanet Table│
└────────────────────────────────────────────────────────┘
```

## 3. Implementation Blueprint
1. **Remote HTTP Fetcher (`core/services/calendar/holidays_fetcher.go`):**
   - Fetches from `https://date.nager.at/api/v3/PublicHolidays/{year}/TR` with a 5s `http.Client` timeout.
   - Maps API payloads (`date`, `localName`, `name`, `types`) to our unified `Holiday` struct.
2. **Local Disk Cache (`core/services/calendar/holidays_cache.go`):**
   - Saves verified fetched holidays to `$XDG_CACHE_HOME/ogsShell/holidays_{year}.json`.
3. **RPC Endpoint:**
   - `sync_holidays`: Triggers an on-demand async remote refresh and broadcasts `holidays_data` and `calendar_month_data`.
