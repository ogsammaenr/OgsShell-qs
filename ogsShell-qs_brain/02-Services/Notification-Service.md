---
title: "Notification Center, DND & Rules Service (Go Daemon)"
type: service
tags:
  - notifications/history
  - notifications/dnd
  - notifications/rules
  - go/daemon
  - quickshell/drawer
created: 2026-08-11
updated: 2026-08-11
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Go-Daemon-Core]]"
---

# Notification Center, DND & Rules Service

Go daemon subsystem responsible for managing desktop notification history, evaluating global Do Not Disturb (DND) modes, and enforcing app-specific muting/filtering rules.

## Core Features

1. **Persistent History:** Automatically saves notifications to `$XDG_CONFIG_HOME/ogsShell/notifications.json` with atomic disk commits and automatic history trimming (max 100 entries).
2. **Do Not Disturb (DND) Engine:** Global toggle suppressing transient Island HUD alerts while silently appending incoming notifications to the history list.
3. **Critical Urgency Override:** Notifications marked `urgency: "critical"` bypass both DND and app mute rules to ensure safety/system alarms are never missed.
4. **App-Specific Filtering Rules:** Configurable per-app policies stored in `$XDG_CONFIG_HOME/ogsShell/notification_rules.json`:
   - `normal`: Standard popup + history.
   - `mute`: Silent history recording (no popup).
   - `block`: Complete discard (no history, no popup).
   - `priority`: Always pops up on Dynamic Island (bypasses DND).

---

## Go Implementation Details

* **Source Path:** `core/services/notifications/` (`types.go`, `storage.go`, `manager.go`)
* **Interface Contract:** `notifications.NotificationManager`
* **Concurrency:** Thread-safe state management with `sync.RWMutex`.

### Socket Event Broadcast Schemas

#### 1. `notification_received` Event
Dispatched whenever an incoming alert is evaluated:

```json
{
  "type": "notification_received",
  "payload": {
    "notification": {
      "id": "notif_1786395000123_1",
      "app_name": "Discord",
      "summary": "Yeni Mesaj",
      "body": "Toplantı saat 15:00'te başlıyor.",
      "urgency": "normal",
      "timestamp": 1786395000123,
      "read": false
    },
    "should_popup": true,
    "reason": "normal"
  }
}
```

#### 2. `notifications_update` Event
Dispatched on notification CRUD operations and read-state updates:

```json
{
  "type": "notifications_update",
  "payload": [
    {
      "id": "notif_1786395000123_1",
      "app_name": "Discord",
      "summary": "Yeni Mesaj",
      "body": "Toplantı saat 15:00'te başlıyor.",
      "urgency": "normal",
      "timestamp": 1786395000123,
      "read": false
    }
  ]
}
```

#### 3. `dnd_update` Event
```json
{
  "type": "dnd_update",
  "payload": {
    "dnd_enabled": true
  }
}
```

---

## Related Documentation

* Backend Endpoints Reference: `[[Backend-Endpoints-Reference]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* QML IPC Singleton: `[[Daemon-IPC-Client]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Control Center UI: `[[Control-Center-Widget]]`
* Go Daemon: `[[Go-Daemon-Core]]`
* Proposal: `[[Plan-Notification-Detail-Inspection-View]]`
