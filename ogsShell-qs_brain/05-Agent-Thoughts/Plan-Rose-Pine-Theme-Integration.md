---
title: "Plan: Rosé Pine Theme Integration for Shell, Terminal, and Neovim"
type: agent-thought
tags:
  - theme/rose-pine
  - styling/palette
  - terminal/kitty
  - editor/neovim
  - quickshell/hud
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Control-Center-Widget]]"
---

# Plan: Rosé Pine Theme Integration for Shell, Terminal, and Neovim

> [!NOTE]
> Rosé Pine theme integration has been fully implemented across `shared/themes/themes.json`, Quickshell Style engine, Control Center ThemesView, Go backend storage defaults, Kitty terminal (`shared/app_configs/kitty/rosepine.conf`), Neovim Lua configuration (`shared/app_configs/nvim/rosepine.lua`), and Tmux status styling (`shared/app_configs/tmux/rosepine.conf`).

## 1. Problem Statement & User Intent
The user requested the addition of the **Rosé Pine** theme to the `ogsShell-qs` ecosystem, specifically creating and integrating configurations for:
1. The shell's global theme system (`shared/themes/themes.json`, `shell/theme/Style.qml`, and `ThemesView.qml`).
2. Terminal configuration (`shared/app_configs/kitty/rosepine.conf`).
3. Neovim configuration (`shared/app_configs/nvim/rosepine.lua`).
4. Tmux status line styling (`shared/app_configs/tmux/rosepine.conf`).

## 2. Rosé Pine Color Palette Specification
Based on the official Rosé Pine specification:
* **Base (Background):** `#191724`
* **Surface:** `#1f1d2e`
* **Overlay (Surface Variant):** `#26233a`
* **Muted:** `#6e6a86`
* **Subtle:** `#908caa`
* **Text (Foreground):** `#e0def4`
* **Love (Red):** `#eb6f92`
* **Gold (Yellow/Orange):** `#f6c177`
* **Rose (Primary Accent):** `#ebbcba`
* **Pine (Green):** `#31748f`
* **Foam (Cyan):** `#9ccfd8`
* **Iris (Secondary Accent / Purple):** `#c4a7e7`
* **Highlight Low:** `#21202e`
* **Highlight Med:** `#403d52`
* **Highlight High:** `#524f67`

## 3. Implementation Steps & Verification

1. **Shared Theme Registry (`shared/themes/themes.json`):**
   - Added `"rosepine"` entry with `id: "rosepine"`, `name: "Rosé Pine"`, `accent: "#ebbcba"`, `bg: "#191724"`, `fg: "#e0def4"`, `card_bg: "#1f1d2e"`.

2. **Quickshell Style Engine (`shell/theme/Style.qml`):**
   - Registered `"rosepine"` in `builtinPalettes` while maintaining the Apple Dynamic Island pure OLED black `#000000` silhouette for the HUD capsule.
   - Configured semantic accents: `accent: "#ebbcba"`, `accentSecondary: "#c4a7e7"`, `accentCyan: "#9ccfd8"`, `accentGreen: "#31748f"`, `accentOrange: "#f6c177"`, `accentRed: "#eb6f92"`.

3. **Theme Selector Gallery (`shell/components/widgets/controlcenter/views/ThemesView.qml`):**
   - Added `"rosepine"` to `fallbackThemes` so offline or initial render includes Rosé Pine swatches.

4. **Go Backend Storage Default List (`core/services/theme/storage.go` & `wallpaper.go`):**
   - Added `rosepine` palette to `DefaultSharedThemes` and mapped folder name `"RosePine"` in `wallpaper.go`.

5. **Kitty Terminal Config (`shared/app_configs/kitty/rosepine.conf`):**
   - Created official Kitty color mappings for Rosé Pine including 16 ANSI colors, tab bar, borders, and cursor styling.

6. **Neovim Lua Theme (`shared/app_configs/nvim/rosepine.lua`):**
   - Created `OgsRosePine` syntax and UI highlights with LazyVim compatibility hooks.

7. **Tmux Theme Config (`shared/app_configs/tmux/rosepine.conf`):**
   - Defined status bar and active pane borders for Rosé Pine.

8. **Testing:**
   - Ran `go test -v ./...` in `core/` with 100% tests passing.

