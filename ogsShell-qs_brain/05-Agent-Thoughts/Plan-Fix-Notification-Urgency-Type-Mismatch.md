---
title: "Fix: Notification Urgency Type Mismatch in Quickshell IPC"
type: agent-thought
tags:
  - bugfix/notifications
  - quickshell/ipc
  - backend/notifications
created: 2026-09-09
updated: 2026-09-09
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Notification-Service]]"
  - "[[Shell-Root-PanelWindow]]"
---

# Fix: Notification Urgency Type Mismatch in Quickshell IPC

> [!IDEA]
> Normalize `Quickshell.Services.Notifications.Notification.urgency` numeric enum values to string representations (`low`, `normal`, `critical`) in `shell.qml` and `DaemonIPC.qml` before sending `add_notification` RPC action to the Go backend daemon.

## Problem Statement
When a desktop notification is captured by Quickshell's `NotificationServer` in `shell/shell.qml`, `notif.urgency` is provided as an integer enum value (`0` for Low, `1` for Normal, `2` for Critical). The previous expression `notif.urgency || "normal"` evaluated to numeric `1` or `2`, sending a JSON number over the IPC socket:
`{"name": "add_notification", "args": { "urgency": 1, ... }}`.
The Go backend's `AddNotificationPayload` struct defines `Urgency` as a `string`, causing `json.Unmarshal` to fail with:
`[ERROR] [CORE] ActionCalıştırma hatası name=add_notification err=add_notification args çözülemedi: json: cannot unmarshal number into Go struct field AddNotificationPayload.urgency of type string`.

## Proposed Solution
1. In `shell/shell.qml`:
   - Map numeric urgency values (`0` -> `"low"`, `1` -> `"normal"`, `2` -> `"critical"`) and safely handle string or fallback values.
2. In `shell/backend/DaemonIPC.qml`:
   - Add defensive normalization inside `addNotification(...)` to ensure `urgency` is always transmitted as a lowercase string conforming to `[[Backend-Endpoints-Reference]]` (`"low"`, `"normal"`, `"critical"`).

## Affected Components
- `[[Daemon-IPC-Client]]` - `shell/backend/DaemonIPC.qml`
- `[[Shell-Root-PanelWindow]]` - `shell/shell.qml`
- `[[Notification-Service]]` - `ogsShell-qs_brain/02-Services/Notification-Service.md`
