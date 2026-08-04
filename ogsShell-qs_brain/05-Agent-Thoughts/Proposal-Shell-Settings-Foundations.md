---
title: "Proposal: Shell Settings & Customization Foundations"
type: agent-thought
tags:
  - proposal/settings
  - quickshell/qml
  - python/pyside6
created: 2026-08-03
updated: 2026-08-03
status: implemented
related_notes:
  - "[[Settings-App-UI]]"
  - "[[ShellIPC-Service]]"
  - "[[Shell-Bar-Components]]"
  - "[[Architecture-Overview]]"
---

# Proposal: Shell Settings & Customization Foundations

> [!IDEA]
> Establishing dynamic shell height, island width scaling, and individual island module toggles directly customizable from the Python Qt Settings application with zero-latency IPC synchronization.

## Problem Statement
Currently, top bar dimensions (bar height, island widths) are hardcoded across QML components in `shell/components/` and `shell/windows/TopBarWindow.qml`. Users lack an interface in `settings_app` to customize the shell height, island widths, or individual island visibility.

## Proposed Solution
1. **Config Schema (`settings_app/config.py`):**
   Extend default config parameters with:
   - `bar_height` (int, default: 34, range 24-56px)
   - `island_width_scale` (int, default: 100, range 70-150%)
   - `show_workspaces` (bool, default: True)
   - `show_sys_stats` (bool, default: True)
   - `show_center_hud` (bool, default: True)
   - `show_media` (bool, default: True)
   - `show_pomodoro` (bool, default: True)

2. **PySide6 Settings UI (`settings_app/ui/pages/modules_page.py`):**
   Add interactive sliders for Shell Bar Height and Island Width Scale, along with Toggle switches for each island module. Trigger `send_ipc_command("config_reload")` on changes.

3. **Quickshell Config Service (`shell/services/ShellConfigService.qml`):**
   Create a centralized QML service that loads `~/.config/ogsshell/config.json` and exposes properties (`barHeight`, `islandWidthScale`, island visibility flags) to all UI components.

4. **IPC Signal & UI Bindings:**
   - Listen to `config_reload` in `ShellIpcService.qml`.
   - Bind height, width scale, and visibility properties in `TopBarWindow.qml`, `CenterHudIsland.qml`, `LeftWorkspaceBar.qml`, `SystemStatsIsland.qml`, and `RightMediaNotifIsland.qml`.

## Affected Components
- `[[Settings-App-UI]]` - `settings_app/ui/pages/modules_page.py`, `settings_app/config.py`
- `[[ShellIPC-Service]]` - `shell/services/ShellIpcService.qml`
- `[[Shell-Bar-Components]]` - `shell/windows/TopBarWindow.qml`, `shell/components/*`
