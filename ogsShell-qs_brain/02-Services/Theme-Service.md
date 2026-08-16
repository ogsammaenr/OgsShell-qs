---
title: "Theme Management & Multi-App Dispatcher Service (Go Daemon)"
type: service
tags:
  - theme/manager
  - styling/palette
  - adapters/apps
  - go/daemon
  - quickshell/hud
created: 2026-08-11
updated: 2026-08-16
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[Plan-Async-Theme-Engine-And-Exact-Matching]]"
  - "[[Plan-Shared-Directory-Theme-Engine]]"
  - "[[Plan-Fix-Neovim-Theme-LazyVim-Spec]]"
---

# Theme Management & Multi-App Dispatcher Service

Go daemon subsystem responsible for centralizing system-wide color theming across the desktop shell (Quickshell, Hyprland) and productivity/coding applications (Kitty, Zed, Vesktop, Neovim, Dolphin/Qt, Btop, GTK, Tmux).

## Core Architecture

```mermaid
graph TD
    UI[Quickshell / Settings App] -->|set_active_theme 'tokyonight'| Server[Go IPC Server]
    Server --> Engine[ThemeManager (core/services/theme)]

    Engine -->|Immediate In-Memory Switch <1ms| Broadcast[Broadcast: theme_update]
    Broadcast --> QS[Quickshell ThemesView & Style (0ms UI Update)]

    Engine -->|Non-Blocking Queue| Worker[Debounced Adapter Dispatcher (50ms Coalesce)]

    Worker --> SharedThemes[shared/themes/themes.json (6 Core Themes)]
    Worker --> AppConfigs[shared/app_configs/ (Ready-to-Deploy Assets)]

    Worker -->|Copy File & Reload| Kitty[Kitty: shared/app_configs/kitty/ & SIGUSR1]
    Worker -->|Copy File & Patch| Zed[Zed: shared/app_configs/zed/ & settings.json]
    Worker -->|Copy File| Vesk[Vesktop: shared/app_configs/vesktop/]
    Worker -->|Copy File| Nvim[Neovim: shared/app_configs/nvim/]
    Worker -->|Copy File| Dolphin[Dolphin: shared/app_configs/dolphin/]
    Worker -->|Copy File| GTK[GTK 3/4: shared/app_configs/gtk/]
    Worker -->|Copy File| Qt[Qt5/6: shared/app_configs/qt/]
    Worker -->|Copy File| Btop[Btop: shared/app_configs/btop/]
    Worker -->|Copy File & Source| Tmux[Tmux: shared/app_configs/tmux/]
    Worker -->|Live Border Recolor| Hypr[Hyprland: hyprctl col.active_border & colors.conf]
```

## Features

1. **Shared Directory Source of Truth (`shared/`):** Exclusively supports the 6 core desktop themes defined in `shared/themes/themes.json` (`nord`, `catppuccin`, `everforest`, `tokyonight`, `gruvbox`, `monochrome`).
2. **File-Based Multi-App Dispatcher (`shared/app_configs/`):** Deploys pre-rendered, fully-tested theme files directly to user configuration directories without runtime template rendering overhead.
3. **Non-Blocking Asynchronous Engine:** `SetActiveTheme` returns in `<0.1ms` and broadcasts `theme_update` to the UI immediately, eliminating IPC thread blocking.
4. **Debounced Coalescing Dispatcher (50ms):** When themes are switched rapidly, intermediate requests are coalesced so only the latest selected theme executes external app commands, preventing process floods and command lag.
5. **Concrete File-Based Adapters (`adapters/`):**
   - **Hyprland:** Live window border recoloring via `hyprctl keyword general:col.active_border` and `~/.config/hypr/colors.conf`.
   - **Kitty:** Copies `shared/app_configs/kitty/<id>.conf` to `~/.config/kitty/current-theme.conf` and signals live reload via `pkill -SIGUSR1 kitty`.
   - **Zed:** Copies `shared/app_configs/zed/<id>.json` to `~/.config/zed/themes/ogsshell.json` and updates `settings.json`.
   - **Vesktop:** Copies `shared/app_configs/vesktop/<id>.css` to `~/.config/vesktop/themes/ogsshell.theme.css`.
   - **Neovim (LazyVim):** Copies `shared/app_configs/nvim/<id>.lua` to `~/.config/nvim/lua/plugins/theme.lua` and reloads active Neovim sessions live via Unix domain sockets.
   - **Dolphin / Qt:** Copies `shared/app_configs/dolphin/<id>.kdeglobals` to `~/.config/kdeglobals` and `shared/app_configs/qt/<id>.conf` to `~/.config/qt5ct/` / `~/.config/qt6ct/`.
   - **Btop:** Copies `shared/app_configs/btop/<id>.theme` to `~/.config/btop/themes/ogsshell.theme`.
   - **GTK:** Copies `shared/app_configs/gtk/<id>.css` & `.ini` to `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/`.
   - **Tmux:** Copies `shared/app_configs/tmux/<id>.conf` to `~/.config/tmux/theme.conf`.
6. **Concurrent Error & Timeout Isolation:** Adapters execute concurrently with dedicated timeouts; failure or latency in one app adapter does not impact others or the Go daemon.

---

## Related Documentation

* Backend Endpoints Reference: `[[Backend-Endpoints-Reference]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* QML IPC Singleton: `[[Daemon-IPC-Client]]`
* Design Tokens & Style: `[[Style-Design-Tokens]]`
* Go Daemon: `[[Go-Daemon-Core]]`
* Implementation Plans: `[[Plan-Async-Theme-Engine-And-Exact-Matching]]`, `[[Plan-Shared-Directory-Theme-Engine]]`
