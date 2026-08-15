---
title: "Proposal: Dynamic Island Transient Notification System via Quickshell NotificationServer"
type: agent-thought
tags:
  - proposal/notifications
  - quickshell/services
  - dbus/freedesktop-notifications
  - dynamic-island/transient
created: 2026-08-09
updated: 2026-08-09
status: implemented
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
---

# Proposal: Dynamic Island Transient Notification System via Quickshell NotificationServer

> [!NOTE]
> Implementation completed. The `TRANSIENT` presentation mode has been integrated into `DynamicIsland.qml` and connected to `Quickshell.Services.Notifications.NotificationServer` in `shell.qml`.

## 1. Summary of Changes
1. **D-Bus Notification Server:** Registered `NotificationServer` in `shell.qml` routing desktop notifications (`notify-send`) to `island.triggerNotification(summary, body, appName, timeout)`.
2. **Transient UI Layer:** Added `transientLayer` inside `DynamicIsland.qml` (`340x56px`) with leading glowing badge, bold summary text, and muted body/app name with clean ellipsis.
3. **Auto-Dismiss & Priority:** Non-blocking `Timer` auto-collapses transient notifications after `expireTimeout` (default 3500ms) without overriding active `EXPANDED` states.
4. **Direct Test Interaction:** Right-clicking on the island or running `notify-send "Başlık" "Mesaj"` triggers the transient notification presentation.

## 2. Status
* **Status:** `implemented`
