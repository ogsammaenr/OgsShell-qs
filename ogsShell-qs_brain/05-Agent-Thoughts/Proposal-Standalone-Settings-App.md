---
title: "Proposal: Standalone Python Qt Settings Application"
type: agent-thought
tags:
  - proposal/settings
  - python/pyside6
created: 2026-08-03
updated: 2026-08-03
status: implemented
related_notes:
  - "[[Architecture-Overview]]"
  - "[[IPC-Protocol-Spec]]"
  - "[[Settings-App-UI]]"
---

# Proposal: Standalone Python Qt Settings Application

> [!IDEA]
> Creating a dedicated, standalone desktop settings application in `settings_app/` using Python Qt (PySide6 / PyQt) decouples long-term shell preference management from quick panel overlays (Control Center).

## Architecture & Communication
1. **PySide6 / PyQt Compatibility Layer (`settings_app/ui/qt_compat.py`):** Universal wrapper supporting PySide6, PyQt6, and PyQt5.
2. **IPC Integration (`settings_app/utils/ipc_client.py`):** Communicates live theme changes and module toggles to the shell via `$XDG_RUNTIME_DIR/ogsshell-ipc`.
3. **Persistent Config:** Stores user preferences in `~/.config/ogsshell/config.json`.

## Verification Status
- Launched via `make run-settings` or `python3 settings_app/main.py`.
- Evaluated with zero import or runtime syntax errors.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- IPC Protocol Specification: `[[IPC-Protocol-Spec]]`
- Settings App UI: `[[Settings-App-UI]]`
