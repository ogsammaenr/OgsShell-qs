---
title: "Wallpaper Service"
type: service
tags:
  - service/wallpaper
  - daemon/c
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Theme-System-Spec]]"
  - "[[ThemeSync-Service]]"
---

# Wallpaper Service

> [!NOTE]
> `WallpaperService.qml` scans wallpapers per theme using `bin/wallpaper_helper` and applies image background wallpapers dynamically to `hyprpaper` or `swww`.

## Binary Details (`bin/wallpaper_helper`)

- **Source:** `shell/services/wallpaper_helper.c`
- **Output:** `bin/wallpaper_helper`
- **Functionality:** Scans `~/.config/ogsshell/wallpapers/<theme_id>/` and returns a JSON list of available wallpaper images.

## Related Notes
- Theme System Specification: `[[Theme-System-Spec]]`
- Theme Sync Service: `[[ThemeSync-Service]]`
