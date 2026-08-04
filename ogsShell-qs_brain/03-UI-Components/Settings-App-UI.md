---
title: "Python Qt Settings Application UI"
type: ui-component
tags:
  - ui/pyside6
  - settings/app
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[IPC-Protocol-Spec]]"
  - "[[Proposal-Standalone-Settings-App]]"
---

# Python Qt Settings Application UI

> [!NOTE]
> The standalone Settings Application (`settings_app/`) is built with **Qt for Python (PySide6 / PyQt)**. It manages user preferences in `~/.config/ogsshell/config.json` and sends live updates to the shell via `[[IPC-Protocol-Spec|IPC]]`.

## Cross-Version Compatibility Layer (`settings_app/ui/qt_compat.py`)

Provides seamless fallbacks across PySide6, PyQt6, and PyQt5:
- Unified `Property`, `Signal`, `Slot` wrappers.
- Universal Qt Enum accessors (`CursorShape.PointingHandCursor`, `AlignmentFlag.AlignCenter`, `Orientation.Horizontal`).

## UI Pages (`settings_app/ui/pages/`)

- **General Page (`general_page.py`):** Autostart, notification popups, launcher hotkeys.
- **Appearance Page (`appearance_page.py`):** Theme grid, font family, accent colors, wallpaper manager.
- **Modules Page (`modules_page.py`):** Bar widget toggles (Workspace Bar, Media Island, Stats Widget).
- **System Page (`system_page.py`):** Hardware monitoring refresh rates and performance profiles.
- **About Page (`about_page.py`):** System specs, project version, and license information.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- IPC Protocol Specification: `[[IPC-Protocol-Spec]]`
- Standalone Settings App Proposal: `[[Proposal-Standalone-Settings-App]]`
