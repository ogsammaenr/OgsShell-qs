---
title: "Shell IPC Service"
type: service
tags:
  - service/ipc
  - ipc/qml
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[IPC-Protocol-Spec]]"
  - "[[Settings-App-UI]]"
  - "[[ControlCenter-UI]]"
---

# Shell IPC Service

> [!NOTE]
> `ShellIpcService.qml` initializes the UNIX named pipe `$XDG_RUNTIME_DIR/ogsshell-ipc` and processes incoming commands in real-time.

## Processing Pipeline

1. **Initialization:**
   - Ensures pipe path exists (`mkfifo $XDG_RUNTIME_DIR/ogsshell-ipc`).
   - Runs `tail -f $XDG_RUNTIME_DIR/ogsshell-ipc`.
2. **Signal Handling:**
   - `toggle-control-center` -> Toggles `monitorGroup.isControlCenterOpen`.
   - `set-theme <name>` -> Sets `themeConfigService.activeTheme`.
   - `toggle-game-mode` -> Toggles `gameModeService.isGameMode`.

## Related Notes
- IPC Protocol Specification: `[[IPC-Protocol-Spec]]`
- Settings App UI: `[[Settings-App-UI]]`
- Control Center UI: `[[ControlCenter-UI]]`
