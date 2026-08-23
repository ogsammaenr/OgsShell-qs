---
title: "Proposal: Fix System Startup Wallpaper and Theme Initialization"
type: agent-thought
tags:
  - proposal/startup-wallpaper-fix
  - go/daemon
  - theme/wallpaper
  - scripts/launcher
created: 2026-08-22
updated: 2026-08-22
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Configuration-Themes-Spec]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
  - "[[Plan-Theme-Specific-Awww-Wallpaper-Engine]]"
---

# Proposal: Fix System Startup Wallpaper and Theme Initialization

> [!IDEA]
> Dispatching the active theme into the theme dispatcher channel on Go daemon startup and ensuring `awww-daemon` is running and ready on boot guarantees seamless wallpaper and theme restoration across system reboots.

## Problem Statement

When the user starts the desktop environment via `scripts/run_shell.sh`:
1. `ogsshell-core` launches and initializes `ThemeManager`.
2. `ThemeManager.Start(ctx)` spins up the adapter dispatcher worker, but does **not** enqueue the active theme (`m.activeTheme`) into `m.applyChan`.
3. Consequently, none of the adapters (including `WallpaperAdapter`) run upon boot unless the user manually opens the UI and clicks to change the theme.
4. Furthermore, if `awww-daemon` is not already initialized when `EnsureAwwwDaemon()` runs, `awww img` could fail due to race conditions before the daemon socket is established.
5. In `run_shell.sh`, `CORE_BIN` was only built if the file did not exist, preventing new Go binaries from being compiled when source code changed.

## Proposed Solution

1. **Automatic Startup Theme Dispatch (`core/services/theme/manager.go`):**
   - In `ThemeManager.Start(ctx)`, automatically enqueue `m.activeTheme` into `m.applyChan` on startup so all adapters (wallpaper, Hyprland borders, Kitty, Zed, etc.) apply the saved theme immediately upon daemon start.

2. **Robust Awww Daemon Readiness Polling (`core/services/theme/adapters/wallpaper.go`):**
   - In `WallpaperAdapter.EnsureAwwwDaemon()`, after spawning `awww-daemon`, poll `awww query` for up to 1.5 seconds (with 50ms sleep intervals) to guarantee the daemon socket is fully ready before sending `awww img`.

3. **Startup Launcher Script Enhancements (`scripts/run_shell.sh`):**
   - Start `awww-daemon` in the background if not already running.
   - Always run incremental `go build` for `${CORE_BIN}` on launch.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/manager.go`, `core/services/theme/adapters/wallpaper.go`)
- `scripts/run_shell.sh`
