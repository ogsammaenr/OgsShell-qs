---
title: "Theme System Specification"
type: architecture
tags:
  - architecture/theme
  - theme/configs
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[ThemeSync-Service]]"
  - "[[Wallpaper-Service]]"
  - "[[ControlCenter-UI]]"
---

# Theme System Specification

> [!NOTE]
> The theme system provides unified color palettes across the Quickshell bar, Control Center, Python Settings App, and third-party desktop applications (GTK3/4, Qt, Kitty, Zed, IntelliJ, Neovim, Tmux, Vesktop).

## Theme Registry (`shared/themes/themes.json`)

The central theme definitions reside in `shared/themes/themes.json`:
- **Nord** (`nord`): Cold Arctic blue palette.
- **Gruvbox** (`gruvbox`): Retro groove warm palette.
- **Catppuccin** (`catppuccin`): Soft pastel palette.
- **Tokyo Night** (`tokyonight`): Deep blue neon night palette.
- **Dracula** (`dracula`): Dark vampire purple palette.
- **Monochrome** (`monochrome`): Sleek minimal greyscale.

## Application Synchronization Architecture

When `[[ThemeSync-Service|ThemeSyncService]]` triggers `bin/theme_sync_helper <theme_id>`:

1. **C Helper Process (`bin/theme_sync_helper`):**
   - Reads `shared/themes/themes.json` for color hex codes.
   - Reads template files from `shared/app_configs/`.
   - Replaces `{{COLOR_BG}}`, `{{COLOR_FG}}`, `{{COLOR_ACCENT}}` tokens.
   - Writes generated configs directly to `~/.config/kitty/`, `~/.config/zed/`, `~/.config/gtk-3.0/`, etc.
   - Reloads application themes instantly (e.g. `killall -USR1 kitty`, `gsettings set org.gnome.desktop.interface gtk-theme`).

## Wallpaper Synchronization
`[[Wallpaper-Service|WallpaperService]]` scans `~/.config/ogsshell/wallpapers/<theme_id>/` and updates the wallpaper daemon (`hyprpaper` / `swww`) synchronously.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Theme Sync Service: `[[ThemeSync-Service]]`
- Wallpaper Service: `[[Wallpaper-Service]]`
- Control Center UI: `[[ControlCenter-UI]]`
