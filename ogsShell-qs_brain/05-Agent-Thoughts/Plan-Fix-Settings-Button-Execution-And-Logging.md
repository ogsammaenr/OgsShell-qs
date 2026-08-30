---
title: "Plan: Fix Settings Button Execution and Add Verbose Logging"
type: agent-thought
tags:
  - fix/settings-launcher
  - quickshell/process
  - control-center/ui
  - logging/diagnostics
created: 2026-08-29
updated: 2026-08-29
status: implemented
related_notes:
  - "[[Settings-Application-Component]]"
  - "[[Control-Center-Widget]]"
  - "[[Plan-Standalone-Qt-Settings-Application-Architecture]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Settings Button Execution and Add Verbose Logging

> [!IDEA]
> Diagnosing and fixing the exact QML execution failure when clicking the Settings button, ensuring robust script path resolution, and streaming verbose STDOUT/STDERR logs to Quickshell diagnostics.

## 1. Identified Issues
1. In `SettingsService.qml`, `Qt.resolvedUrl("../../scripts/...")` was resolving to `qrc:/qs-blackhole` under Quickshell internal virtual filesystem, preventing script execution.
2. An unimported `Config` reference in the fallback block threw `ReferenceError: Config is not defined`.
3. `open_settings_app.sh` lacked precise PID detection for previous instances, causing toggle and restart conflicts.

## 2. Implemented Solutions
1. **Multi-Candidate Path Resolver (`SettingsService.qml`):** Switched to direct path resolution using `Quickshell.env("HOME") + "/WorkSpace/projects/OgsShell-qs/scripts/"` and checking script existence before execution.
2. **Comprehensive Logging:** Added STDOUT, STDERR, process lifecycle, and click handler log statements across `ControlCenterMain.qml`, `SettingsService.qml`, and `scripts/open_settings_app.sh`.
3. **Accurate PID Extraction (`scripts/open_settings_app.sh`):** Implemented `get_settings_pid` reading `/proc/$PID/cmdline` to reliably toggle and spawn `quickshell -p settings_app`.

## 3. Verification
- Verified clicking Settings button / triggering `open_settings` launches PID with code 0 and logs `[open_settings_app.sh] Settings app process dispatched successfully.`
- Verified window appears as XDG toplevel client `"ogsShell Ayarlar"` in Hyprland.
