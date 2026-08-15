---
title: "Proposal: Theme App Wallpapers Tab & Active Theme Gallery"
type: agent-thought
tags:
  - proposal/theme-app-wallpapers-tab
  - quickshell/qml
  - control-center/themes
  - awww/wallpaper-gallery
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Plan-Theme-Specific-Awww-Wallpaper-Engine]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
---

# Proposal: Theme App Wallpapers Tab & Active Theme Gallery

> [!IDEA]
> Adding a dedicated "Duvar Kağıtları" (Wallpapers) tab to the Control Center Themes View (`ThemesView.qml`) allows users to visually browse and apply wallpapers exclusively from the active theme's pool (`~/Pictures/Wallpapers/<ActiveTheme>/`) with asynchronous high-performance thumbnail previews, active badges, and next/random quick actions.

## Problem Statement

While the Go backend supports theme-specific wallpaper pools via `awww` and IPC, the frontend lacks a visual tab in the theme app to display and pick wallpapers for the active theme.

## Proposed Solution

1. In `shell/backend/DaemonIPC.qml`:
   - Expose `themeWallpapers`, `activeWallpaper`, `requestThemeWallpapers`, `setWallpaper`, and `nextWallpaper`.
   - Automatically request theme wallpapers when active theme changes.
2. In `shell/components/widgets/controlcenter/views/ThemesView.qml`:
   - Add Apple-HIG segmented tab bar: `Temalar` (Themes) vs `Duvar Kağıtları` (Wallpapers).
   - In Wallpapers tab:
     - Header showing active theme folder and "Sıradaki / Rastgele" quick-cycle action button.
     - Asynchronous 2-column image preview grid with active checkmark badge and hover scaling.
     - Click-to-apply via `ipc.setWallpaper(currentActiveThemeId, path)`.
