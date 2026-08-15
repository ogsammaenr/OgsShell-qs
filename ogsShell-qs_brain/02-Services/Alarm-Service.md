---
title: "Alarm Service (Go Daemon)"
type: service
tags:
  - service/alarm
  - scheduler/timer
  - pipewire/audio
  - go/daemon
created: 2026-08-10
updated: 2026-08-10
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Socket-Schema]]"
  - "[[IPC-Server-Service]]"
  - "[[Plan-Persistent-Alarm-Service-And-Scheduler]]"
---

# Alarm Service (`core/services/alarm/`)

> [!NOTE]
> A persistent, low-overhead alarm management and scheduling subsystem with JSON file storage (`~/.config/ogsShell/alarms.json`), event-based `time.Timer` scheduling, audio process playback control (`pw-play`), and IPC synchronization.

---

## 1. Architectural Overview

* **Storage Location:** `$XDG_CONFIG_HOME/ogsShell/alarms.json` (defaults to `~/.config/ogsShell/alarms.json`).
* **Zero-Busy-Waiting Scheduler:** Calculates the nearest upcoming alarm across one-shot and recurring weekly days, setting a single `time.Timer`.
* **One-Shot Auto-Disable:** Vakti gelen tek seferlik (`days: []`) alarmlar tetiklendiği an otomatik olarak pasif duruma (`enabled: false`) geçirilir ve hem diske hem IPC `alarms_update` event'ine bu şekilde yansıtılır. Tekrarlı alarmlar (`days: [1,2,3...]`) ise bir sonraki haftanın gününe zamanlanır.
* **Audio Playback:** Spawns `pw-play` (with fallback to `paplay`) while holding process references so `dismiss_alarm` or `snooze_alarm` can immediately kill the ringing audio.

---

## 2. Component Structure

| File | Purpose |
| :--- | :--- |
| `types.go` | Data models (`Alarm`, request/response payloads) |
| `storage.go` | JSON file persistence engine with atomic saving |
| `manager.go` | Scheduler logic, next-trigger calculation, audio process management |
| `alarm_test.go` | Unit tests for calculation, recurrence, persistence, and CRUD |

---

## 3. IPC Socket Protocol

### A. Events Broadcast
* `alarm_triggered`: Fired when an alarm matures:
  ```json
  {
    "type": "alarm_triggered",
    "payload": {
      "id": "alarm_123",
      "label": "Sistem Toplantısı",
      "time": "07:30"
    }
  }
  ```
* `alarms_update`: Fired when alarms are created, toggled, modified, or deleted:
  ```json
  {
    "type": "alarms_update",
    "payload": [
      {
        "id": "alarm_123",
        "time": "07:30",
        "days": [1, 2, 3, 4, 5],
        "label": "Hafta İçi Uyanma",
        "enabled": true,
        "sound_path": "",
        "snooze_count": 0
      }
    ]
  }
  ```

### B. Inbound RPC Actions
* `add_alarm`: Creates a new alarm and reschedules.
* `delete_alarm`: Deletes an alarm by `id`.
* `toggle_alarm`: Toggles or explicitly sets `enabled` state.
* `snooze_alarm`: Snoozes ringing alarm for X minutes and stops audio.
* `dismiss_alarm`: Stops ringing audio, resets snooze count, disables if one-shot.
* `get_alarms`: Requests full alarms list.

---

## 4. Related Links
* Daemon Core: `[[Go-Daemon-Core]]`
* IPC Schema: `[[IPC-Socket-Schema]]`
* Proposal Note: `[[Plan-Persistent-Alarm-Service-And-Scheduler]]`
