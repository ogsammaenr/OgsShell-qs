---
title: "Proposal: Notification Center, Do Not Disturb (DND) & App Rules Subsystem"
type: agent-thought
tags:
  - proposal/notifications
  - backend/notifications
  - architecture/dnd
  - quickshell/drawer
created: 2026-08-11
updated: 2026-08-11
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Notification-Service]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Dynamic-Island-Component]]"
---

# Proposal: Notification Center, Do Not Disturb (DND) & App Rules Subsystem

> [!IDEA]
> Extending the Go backend daemon with a persistent Notification Center, global Do Not Disturb (DND) state engine, and application-specific rule filters (`normal`, `mute`, `block`, `priority`) allows full user control over incoming desktop alerts and provides a persistent history drawer in the Quickshell UI.

## Problem Statement
Currently, desktop notifications received via Quickshell's `NotificationServer` are transient and memory-only; once dismissed or timed out, they are lost. Furthermore, there is no centralized mechanism to toggle Do Not Disturb (DND) or mute noisy applications (such as Discord, Spotify, or Steam) without disabling notifications globally.

## Proposed Solution
1. **Go Backend Subsystem (`core/services/notifications/`)**:
   - Atomic disk storage for notification history (`$XDG_CONFIG_HOME/ogsShell/notifications.json`) and app rules (`$XDG_CONFIG_HOME/ogsShell/notification_rules.json`).
   - Rule evaluation engine that computes whether an incoming alert should popup on the Dynamic Island (`should_popup: true/false`) based on DND status, app rules, and urgency level.
   - Comprehensive IPC RPC actions (`add_notification`, `get_notifications`, `delete_notification`, `clear_notifications`, `mark_notification_read`, `toggle_dnd`, `set_notification_rule`, `delete_notification_rule`).
2. **Quickshell Frontend Integration (`shell/backend/DaemonIPC.qml` & `shell/shell.qml`)**:
   - Route incoming D-Bus notifications from `NotificationServer` into `DaemonIPC.addNotification(...)`.
   - Reactively trigger Dynamic Island transient presentation only when `should_popup == true`.
   - Maintain real-time unread counts and provide data bindings for the upcoming notification history drawer.

## Affected Components
- `core/services/notifications/` (New Go package: `types.go`, `storage.go`, `manager.go`, `notifications_test.go`)
- `core/main.go` (IPC RPC action registration and event broadcasting)
- `shell/backend/DaemonIPC.qml` (QML helper functions, reactive properties, and event parsers)
- `shell/shell.qml` (Routing between `NotificationServer`, `DaemonIPC`, and `DynamicIsland`)
- `.agents/BACKEND_ENDPOINTS.md` & `ogsShell-qs_brain/` (Documentation update)
