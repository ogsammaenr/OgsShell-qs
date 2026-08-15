---
title: "Proposal: Theme-Specific Wallpaper Engine with awww"
type: agent-thought
tags:
  - proposal/awww-wallpaper-engine
  - go/daemon
  - adapters/wallpaper
  - wayland/awww
  - theme/synchronization
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[System-Architecture]]"
---

# Proposal: Theme-Specific Wallpaper Engine with awww

> [!IDEA]
> Implementing a dedicated `WallpaperAdapter` backed by `awww` (`/usr/bin/awww` / `/usr/bin/awww-daemon`) maps each theme (`everforest`, `monochrome`, `catppuccin`, `nord`, `tokyonight`, `gruvbox`) to its corresponding image directory in `~/Pictures/Wallpapers/<Theme>/`. On theme switch or user request, `awww` applies the wallpaper with smooth hardware-accelerated Wayland transitions while maintaining persistent memory per theme in `~/.config/ogsshell/wallpaper_state.json`.

## Proposed Solution

1. Create `core/services/theme/adapters/wallpaper.go`:
   - Checks / ensures `awww-daemon` is running.
   - Maps theme ID to folder (`Everforest`, `Monochrome`, `Catppuccin`, `Nord`, `TokyoNight`, `Gruvbox`).
   - Scans images in `~/Pictures/Wallpapers/<Theme>/`.
   - Reads / writes `~/.config/ogsshell/wallpaper_state.json`.
   - Executes `awww img <file> --transition-type wipe --transition-duration 2 --transition-fps 60`.
   - Exposes `GetThemeWallpapers`, `SetSpecificWallpaper`, and `NextWallpaper` helpers.
2. Update `core/main.go`:
   - Register `adapters.NewWallpaperAdapter()` in `ThemeManager`.
   - Add IPC actions:
     - `get_theme_wallpapers`
     - `set_wallpaper`
     - `next_wallpaper`
3. Update `.agents/BACKEND_ENDPOINTS.md` with new RPC actions and payloads.
