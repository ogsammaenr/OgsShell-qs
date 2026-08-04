---
title: "Workspace & Notification Service"
type: service
tags:
  - service/hyprland
  - daemon/c
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[Shell-Bar-Components]]"
---

# Workspace & Notification Service

> [!NOTE]
> `WorkspaceService.qml` connects to `bin/workspaces`, a native C daemon monitoring Hyprland IPC sockets (`$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`) and D-Bus Notification signals (`org.freedesktop.Notifications`).

## Daemon Details (`bin/workspaces`)

- **Source Code:** `shell/services/workspaces/` (`main.c`, `hyprland.c`, `notification.c`)
- **Binary Output:** `bin/workspaces`
- **Functionality:**
  - Real-time active workspace index updates per monitor.
  - Occupied workspace detection.
  - Toast notification popup capture (app name, title, body).

## Data Structure

```json
{
  "monitors": [
    { "name": "eDP-1", "activeWorkspace": 1 }
  ],
  "workspaces": [
    { "id": 1, "windows": 3 },
    { "id": 2, "windows": 1 }
  ]
}
```

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Shell Bar UI Components: `[[Shell-Bar-Components]]`
