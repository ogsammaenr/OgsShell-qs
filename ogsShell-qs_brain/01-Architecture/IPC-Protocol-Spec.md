---
title: "IPC Protocol Specification"
type: architecture
tags:
  - architecture/ipc
  - ipc/pipe
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[ShellIPC-Service]]"
  - "[[Settings-App-UI]]"
---

# IPC Protocol Specification

> [!IMPORTANT]
> Communication between external hotkeys, scripts, the Python Settings App, and the Quickshell Desktop Shell is handled via a UNIX Named Pipe (FIFO) located at `$XDG_RUNTIME_DIR/ogsshell-ipc` (fallback: `/tmp/ogsshell-ipc`).

## Named Pipe Details

- **Pipe Location:** `$XDG_RUNTIME_DIR/ogsshell-ipc`
- **Listener:** `[[ShellIPC-Service|ShellIpcService.qml]]` executes `tail -f` on the FIFO.
- **Writers:** `shell/ipc.sh` CLI script, `[[Settings-App-UI|settings_app/utils/ipc_client.py]]`.

## Supported Commands & Payloads

| Command String | Description | Example Payload |
| :--- | :--- | :--- |
| `toggle-control-center` | Toggles the Control Center overlay window | `echo "toggle-control-center" > $XDG_RUNTIME_DIR/ogsshell-ipc` |
| `toggle-app-launcher` | Toggles the Application Launcher overlay | `echo "toggle-app-launcher" > $XDG_RUNTIME_DIR/ogsshell-ipc` |
| `set-theme <theme_id>` | Switches the global theme dynamically | `echo "set-theme nord" > $XDG_RUNTIME_DIR/ogsshell-ipc` |
| `toggle-game-mode` | Toggles Hyprland animations & blur for performance | `echo "toggle-game-mode" > $XDG_RUNTIME_DIR/ogsshell-ipc` |

## Python IPC Client Integration

```python
# settings_app/utils/ipc_client.py
import os

def send_ipc_command(command: str) -> bool:
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    pipe_path = os.path.join(runtime_dir, "ogsshell-ipc")
    if os.path.exists(pipe_path):
        with open(pipe_path, "w") as f:
            f.write(command + "\n")
        return True
    return False
```

## Related Notes
- Architectural Overview: `[[Architecture-Overview]]`
- Shell IPC Service: `[[ShellIPC-Service]]`
- Settings App UI: `[[Settings-App-UI]]`
