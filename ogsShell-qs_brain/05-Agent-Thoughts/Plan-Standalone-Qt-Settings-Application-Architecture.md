---
title: "Plan: Standalone Qt Settings Application in Shell Runtime"
type: agent-thought
tags:
  - proposal/refactor
  - settings/standalone
  - quickshell/floatingwindow
  - control-center/launcher
created: 2026-08-29
updated: 2026-08-29
status: implemented
related_notes:
  - "[[Settings-Application-Component]]"
  - "[[Control-Center-Widget]]"
  - "[[System-Architecture]]"
  - "[[Plan-Fix-Settings-App-Launcher-From-Control-Center]]"
---

# Plan: Standalone Qt Settings Application in Shell Runtime

> [!IDEA]
> Decoupling the Settings UI from the main shell LayerShell overlay into a standalone, dedicated Qt/Quickshell window application (`settings_app/`) invoked from the Control Center and CLI/keybind scripts.

## 1. Requirement & Architecture
- The user requested that the Settings App must be a completely independent Qt application (`settings_app/`), rather than an in-shell modal overlay.
- `settings_app/` runs via `FloatingWindow` (XDG toplevel Wayland window) with dimensions `880x580`, full windowing controls, and independent event loop.
- `shell/shell.qml` is cleaned of overlay modal containers for settings, keeping the shell focused on desktop panels, notches, and status overlays.
- Control Center's settings button and IPC triggers launch `scripts/open_settings_app.sh` and `scripts/toggle_settings.sh`.

## 2. Implementation Steps
1. **Clean `shell/shell.qml`:** Remove `settingsOverlayWindow`.
2. **Update `shell/backend/SettingsService.qml`:** Trigger `scripts/open_settings_app.sh` and `scripts/toggle_settings.sh` via `Process`.
3. **Update `shell/components/widgets/controlcenter/ControlCenterMain.qml`:** Trigger Settings launch on button click.
4. **Update `scripts/open_settings_app.sh` and `scripts/toggle_settings.sh`:** Reliably spawn `quickshell -p settings_app` detached.
5. **Verify `settings_app/shell.qml`:** Validate geometry, theme synchronization, IPC, and page transitions.

## 3. Affected Components
- `shell/shell.qml`
- `shell/backend/SettingsService.qml`
- `shell/components/widgets/controlcenter/ControlCenterMain.qml`
- `scripts/open_settings_app.sh`
- `scripts/toggle_settings.sh`
- `settings_app/shell.qml`
- `ogsShell-qs_brain/03-UI-Components/Settings-Application-Component.md`
