---
title: "Theme Sync Service"
type: service
tags:
  - service/theme
  - daemon/c
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Theme-System-Spec]]"
  - "[[Wallpaper-Service]]"
  - "[[ControlCenter-UI]]"
---

# Theme Sync Service

> [!NOTE]
> `ThemeSyncService.qml` triggers `bin/theme_sync_helper` whenever the global theme changes in QML or via IPC.

## Binary Details (`bin/theme_sync_helper`)

- **Source:** `shell/services/theme_sync_helper.c`
- **Output:** `bin/theme_sync_helper`
- **Supported Targets:**
  - GTK3 / GTK4 CSS templates
  - Qt / Dolphin color schemes
  - Kitty terminal themes
  - Zed editor themes
  - IntelliJ IDEA color schemes
  - Neovim / Tmux configs
  - Vesktop (Discord) QuickCSS

## Related Notes
- Theme System Specification: `[[Theme-System-Spec]]`
- Wallpaper Service: `[[Wallpaper-Service]]`
- Control Center UI: `[[ControlCenter-UI]]`
