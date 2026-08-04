---
title: "Shell Bar UI Components"
type: ui-component
tags:
  - ui/qml
  - ui/bar
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[SystemStats-Service]]"
  - "[[Workspace-Service]]"
  - "[[ControlCenter-UI]]"
---

# Shell Bar UI Components

> [!NOTE]
> The top bar UI is rendered via `TopBarWindow.qml` and divided into three primary dynamic island sections: Left Workspace Bar, Center HUD Island, and Right Media/Notification Island.

## Component Layout

```text
+-------------------------------------------------------------------------------+
| [Workspaces]               [Clock / Date / HUD]               [Media / Stats] |
| (LeftWorkspaceBar)           (CenterHudIsland)            (RightMediaIsland)  |
+-------------------------------------------------------------------------------+
```

1. **Left Workspace Bar (`shell/components/LeftWorkspaceBar.qml`):**
   - Renders active Hyprland workspaces and window counts.
   - Interfaced with `[[Workspace-Service|WorkspaceService.qml]]`.
2. **Center HUD Island (`shell/components/CenterHudIsland.qml`):**
   - Displays real-time time, date, and expandable calendar popover (`CalendarWidget.qml`).
3. **Right Media & Notification Island (`shell/components/RightMediaNotifIsland.qml`):**
   - Media playback controls, current track title, artist info, and quick stats toggle.
   - Interfaced with `[[SystemStats-Service|SystemStatsService.qml]]`.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Workspace Service: `[[Workspace-Service]]`
- System Stats Service: `[[SystemStats-Service]]`
- Control Center UI: `[[ControlCenter-UI]]`
