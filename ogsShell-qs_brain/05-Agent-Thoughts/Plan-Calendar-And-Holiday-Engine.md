---
title: "Proposal: Persistent Calendar, Holiday Engine, and Event Reminder Architecture"
type: agent-thought
tags:
  - proposal/calendar
  - service/calendar
  - holidays/turkey
  - scheduler/reminders
  - go/daemon
  - quickshell/qml
created: 2026-08-10
updated: 2026-08-10
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Alarm-Service]]"
  - "[[Dynamic-Island-Component]]"
---

# Proposal: Persistent Calendar, Holiday Engine, and Event Reminder Architecture

> [!IDEA]
> Establishing a robust, low-overhead Calendar & Reminder subsystem combining Go backend persistence (`calendar_events.json`), an offline algorithmic Turkish national/religious Holiday Engine, zero-busy-wait notification scheduling, and a reactive Quickshell QML Calendar widget integrated into the Dynamic Island.

## 1. Architectural Motivation
The shell requires a native calendar system with:
1. **Accurate Holiday Awareness:** Seamlessly marking Turkish official and Islamic religious holidays (Ramazan/Kurban bayramları, Arefe, milli bayramlar).
2. **Persistent Event & Reminder Storage:** JSON-backed thread-safe CRUD (`~/.config/ogsShell/calendar_events.json`).
3. **Low-Overhead Event Scheduling:** Next-event `time.Timer` calculation without polling loops.
4. **Dynamic Island Integration:** Releasing `calendar_reminder_triggered` events to expand the island in `TRANSIENT` state with action controls (complete/dismiss).

---

## 2. Subsystem Layout

```
┌────────────────────────────────────────────────────────┐
│               Go Backend (core/services/calendar/)     │
│  - types.go: CalendarEvent, Holiday, RPC payloads      │
│  - holidays.go: Turkey Official & Religious engine     │
│  - storage.go: Atomic calendar_events.json persistence │
│  - manager.go: Scheduler & reminder dispatcher         │
└───────────────────────────┬────────────────────────────┘
                            │ NDJSON IPC Stream
                            │ ("calendar_events_update", "calendar_reminder_triggered")
┌───────────────────────────▼────────────────────────────┐
│              Quickshell QML (shell/components/...)     │
│  - CalendarWidget.qml: Month matrix, day picker        │
│  - DayDetailView.qml: Event cards & holiday banner     │
│  - EventEditor.qml: Quick event addition               │
│  - DynamicIsland.qml: Transient reminder banner        │
└────────────────────────────────────────────────────────┘
```

---

## 3. Data Contracts & IPC Protocols

### Inbound Actions (`ipc.Action`)
* `get_calendar_month`: `{"year": 2026, "month": 8}`
* `add_calendar_event`: `{"title": "Sprint Review", "date": "2026-08-15", "time": "14:00", "notify_before": 15}`
* `update_calendar_event`: `{"id": "...", "title": "...", ...}`
* `delete_calendar_event`: `{"id": "..."}`
* `toggle_calendar_event_completed`: `{"id": "...", "completed": true}`
* `get_holidays`: `{"year": 2026}`

### Outbound Events (`ipc.Event`)
* `calendar_events_update`: Broadcast full event list or month payload.
* `calendar_reminder_triggered`: Broadcast when an event reminder fires.

---

## 4. Implementation Steps
1. Create `core/services/calendar/` (types, holidays, storage, manager, tests).
2. Wire RPC actions and scheduler in `core/main.go`.
3. Create QML UI components in `shell/components/widgets/calendar/`.
4. Connect QML to `DaemonIPC.qml` and `DynamicIsland.qml`.
