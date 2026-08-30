---
title: "Plan: Fix Settings App Launcher From Control Center"
type: agent-thought
tags:
  - proposal/fix
  - settings/launcher
  - control-center/ui
  - quickshell/process
created: 2026-08-28
updated: 2026-08-28
status: implemented
related_notes:
  - "[[Settings-Application-Component]]"
  - "[[Control-Center-Widget]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Settings App Launcher From Control Center

> [!IDEA]
> Fixing the relative path resolution in `ControlCenterMain.qml`, updating `scripts/open_settings_app.sh` and `scripts/toggle_settings.sh` with robust process management, and wiring `SettingsService.qml` ensures the Settings App opens reliably and instantly upon clicking the Settings button.

## 1. Problem Statement
1. In `ControlCenterMain.qml`, `openSettingsApp()` was trying to execute an external bash process with inconsistent relative path resolution, while the standalone `settings_app` floating window was being trapped on inactive workspaces.
2. In `shell/shell.qml`, `SettingsWindow` was not hosted in a dedicated `PanelWindow` overlay layer (unlike `PowerOverlay`), causing `SettingsService.isOpen` to have no visual presentation in the desktop shell.
3. `SettingsWindow.qml` was missing `IslandPage` and the associated components (`SettingsChoiceCard.qml`, `SettingsNumberRow.qml`).

## 2. Implemented Solution
1. **Shell Overlay Hosting (`shell/shell.qml`):** Embedded `SettingsWindow` inside a top-level `settingsOverlayWindow` (`PanelWindow`, `WlrLayer.Overlay`) bound to `SettingsService.isOpen`.
2. **Control Center Direct Binding (`ControlCenterMain.qml`):** Connected the Settings button directly to `SettingsService.open()`, opening the modal dialog instantly with zero process spawning overhead.
3. **IPC Socket Integration (`scripts/open_settings_app.sh` & `toggle_settings.sh`):** Scripts send standard IPC actions (`open_settings`, `toggle_settings`) through `/run/user/1000/ogs_shell.sock`, with standalone quickshell fallback.
4. **Full Feature Parity (`shell/components/settings/`):** Added `IslandPage.qml`, `SettingsChoiceCard.qml`, and `SettingsNumberRow.qml` to `shell/components/settings/`, completing the Network and Island/Notch configuration tabs.
