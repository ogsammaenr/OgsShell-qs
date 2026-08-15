---
title: "Calendar & Holiday Service (Go Daemon)"
type: service
tags:
  - service/calendar
  - holidays/turkey
  - scheduler/reminders
  - go/daemon
created: 2026-08-10
updated: 2026-08-10
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Alarm-Service]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Plan-Calendar-And-Holiday-Engine]]"
---

# Calendar & Holiday Service (`core/services/calendar/`)

> [!NOTE]
> A lightweight, persistent calendar and event reminder subsystem with an offline Turkish national and religious Holiday Engine (`holidays.go`), atomic JSON persistence (`~/.config/ogsShell/calendar_events.json`), and zero-CPU event-driven reminder scheduling.

---

## 1. Architectural Overview

* **Storage Location:** `$XDG_CONFIG_HOME/ogsShell/calendar_events.json` (defaults to `~/.config/ogsShell/calendar_events.json`).
* **Holiday Cache Location:** `$XDG_CACHE_HOME/ogsShell/holidays_{year}.json` (defaults to `~/.cache/ogsShell/holidays_{year}.json`).
* **4-Tiered Holiday Resolution Engine:**
  1. **Tier 1 (In-Memory Cache):** Instant sub-millisecond lookups for QML rendering.
  2. **Tier 2 (Disk Cache):** Reads verified local cached JSON files from previous online synchronizations.
  3. **Tier 3 (Online Sync):** Asynchronous background fetching from Nager.Date API (`https://date.nager.at/api/v3/PublicHolidays/{year}/TR`) to automatically capture government-announced holiday extensions and revisions.
  4. **Tier 4 (Offline Engine Fallback):** Algorithmic lunar calculation and built-in Diyanet astronomical tables used when offline.
* **Low-Overhead Scheduler:** Gelecekteki en yakın hatırlatıcı zamanını hesaplayıp tek bir `time.Timer` ile bekler. Vakti geldiğinde `calendar_reminder_triggered` fırlatır ve PipeWire ses çalar.

---

## 2. Component Structure

| File | Purpose |
| :--- | :--- |
| `types.go` | Veri yapıları (`Holiday`, `CalendarEvent`, `MonthData`, RPC yükleri) |
| `holidays.go` | 4 kademeli Türkiye resmi ve dini tatil çözümleme motoru |
| `holidays_fetcher.go` | Çevrim içi Nager.Date API HTTP istemcisi |
| `storage.go` | Atomic dosya yazma, etkinlik depolama ve tatil önbellek yöneticisi |
| `manager.go` | Etkinlik CRUD işlemleri, asenkron tatil senkronizasyonu ve `wakeupCh` zamanlayıcı motoru |
| `calendar_test.go` | Tatil motoru, HTTP mock testleri, disk önbelleği, CRUD ve hatırlatıcı testleri |

---

## 3. IPC Socket Protocol

### A. Events Broadcast
* `calendar_events_update`: Etkinlik listesi değiştiğinde yayınlanır:
  ```json
  {
    "type": "calendar_events_update",
    "payload": [
      {
        "id": "evt_1786395000",
        "title": "Mühendislik Sunumu",
        "date": "2026-08-15",
        "time": "14:30",
        "completed": false
      }
    ]
  }
  ```
* `calendar_reminder_triggered`: Hatırlatıcı vakti geldiğinde yayınlanır:
  ```json
  {
    "type": "calendar_reminder_triggered",
    "payload": {
      "id": "evt_1786395000",
      "title": "Mühendislik Sunumu",
      "date": "2026-08-15",
      "time": "14:30",
      "minutes_until": 15
    }
  }
  ```
* `calendar_month_data`: İstenen ayın gün, tatil ve etkinlik matrisi.
* `holidays_data`: Yıllık tatil listesi.

### B. Inbound RPC Actions
* `get_calendar_month`: `{"year": 2026, "month": 8}`
* `add_calendar_event`: `{"title": "...", "date": "2026-08-15", "time": "14:00", ...}`
* `update_calendar_event`: `{"id": "...", "title": "...", ...}`
* `delete_calendar_event`: `{"id": "..."}`
* `toggle_calendar_event`: `{"id": "...", "completed": true}`
* `get_holidays`: `{"year": 2026}`

---

## 4. Related Links
* Daemon Core: `[[Go-Daemon-Core]]`
* IPC Schema: `[[IPC-Socket-Schema]]`
* Proposal Note: `[[Plan-Calendar-And-Holiday-Engine]]`
