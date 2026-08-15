---
title: "Proposal: System-Wide Theme Management & Multi-App Dispatcher Engine"
type: agent-thought
tags:
  - proposal/theme
  - backend/theme
  - adapters/apps
  - quickshell/styling
created: 2026-08-11
updated: 2026-08-11
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Theme-Service]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
  - "[[Go-Daemon-Core]]"
---

# Proposal: System-Wide Theme Management & Multi-App Dispatcher Engine

> [!IDEA]
> Implementing a central, extensible Theme Management and Multi-App Dispatcher Subsystem in the Go daemon (`core/services/theme/`) with dedicated, type-safe Go application adapters (`Kitty`, `Zed`, `Vesktop`, `Neovim`, `Hyprland`, `Dolphin/Qt`) and dynamically discoverable JSON theme palettes (`$XDG_CONFIG_HOME/ogsShell/themes/`).

## Problem Statement
Users want unified, single-click theme switching across their desktop shell (Quickshell, Hyprland) and development/communication apps (Kitty, Zed, Vesktop, Neovim, Dolphin). Currently, each application must be manually edited in different configuration formats (JSON, Lua, CSS, Conf, CLI).

## Proposed Solution
1. **Dynamic JSON Theme Palettes (`$XDG_CONFIG_HOME/ogsShell/themes/`)**:
   - Auto-discovers and parses theme files (`catppuccin-mocha.json`, `tokyo-night.json`, `everforest.json`, `gruvbox-dark.json`, `nord.json`, `rose-pine.json`).
   - Allows users to save/delete custom palettes from UI.
2. **Type-Safe App Adapters (`core/services/theme/adapters/`)**:
   - `HyprlandAdapter`: Recolor active window borders via `hyprctl keyword general:col.active_border` & update `colors.conf`.
   - `KittyAdapter`: Write `current-theme.conf` & trigger live reload via `pkill -SIGUSR1 kitty` / `kitty @ set-colors`.
   - `ZedAdapter`: Safely patch `"theme"` property in `~/.config/zed/settings.json` without breaking other user settings.
   - `VesktopAdapter`: Render CSS custom properties to `~/.config/vesktop/themes/ogsshell.theme.css`.
   - `NeovimAdapter`: Patch `~/.config/nvim/lua/plugins/theme.lua` with the corresponding colorscheme name.
   - `DolphinQtAdapter`: Invoke `plasma-apply-colorscheme` / `kwriteconfig6`.
3. **IPC Wiring (`core/main.go`)**:
   - Actions: `get_theme_state`, `get_available_themes`, `set_active_theme`, `save_custom_theme`, `delete_custom_theme`, `toggle_theme_adapter`.
   - Events: `theme_update`, `available_themes_data`.
4. **Quickshell Integration (`shell/backend/DaemonIPC.qml`)**:
   - Reactive properties, helper methods, and `signal themeChanged(var palette)`.

## Affected Components
- `core/services/theme/` (`types.go`, `storage.go`, `manager.go`, `theme_test.go`)
- `core/services/theme/adapters/` (`adapter.go`, `hyprland.go`, `kitty.go`, `zed.go`, `vesktop.go`, `nvim.go`, `dolphin_qt.go`)
- `core/main.go`
- `shell/backend/DaemonIPC.qml`
- `.agents/BACKEND_ENDPOINTS.md` & `ogsShell-qs_brain/` (Documentation)
