---
title: "Proposal: Fix Dolphin and Qt6ct/Qt5ct Theme Integration"
type: agent-thought
tags:
  - proposal/dolphin-qt6ct-fix
  - go/daemon
  - adapters/dolphin-qt
  - dolphin/dolphinrc
  - qt6ct/appearance
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Fix Dolphin and Qt6ct/Qt5ct Theme Integration

> [!IDEA]
> Updating `~/.config/dolphinrc` `[UiSettings] ColorScheme=Ogs<Name>`, installing `.colors` palettes to `~/.local/share/color-schemes/`, and configuring `~/.config/qt6ct/` with `custom_palette=2` and valid `color_scheme_path` ensures Dolphin and all Qt applications accurately switch themes across restarts and live sessions.

## Problem Statement

On Hyprland setups utilizing `QT_QPA_PLATFORMTHEME=qt6ct`, Dolphin did not change colors because:
1. `dolphinrc` was not updated with `[UiSettings] ColorScheme`.
2. `qt6ct.conf` lacked the `[Appearance]` section configuring `custom_palette=2` and `color_scheme_path`.

## Proposed Solution

1. In `core/services/theme/adapters/dolphin_qt.go`:
   - Copy `shared/app_configs/dolphin/<id>.kdeglobals` to `~/.config/kdeglobals` and `~/.local/share/color-schemes/Ogs<Name>.colors`.
   - Update `~/.config/dolphinrc` `[UiSettings] ColorScheme=Ogs<Name>`.
   - Copy `shared/app_configs/qt/<id>.conf` to `~/.config/qt6ct/colors/<id>.conf` and `~/.config/qt5ct/colors/<id>.conf`.
   - Write structured `[Appearance]` section in `~/.config/qt6ct/qt6ct.conf` and `~/.config/qt5ct/qt5ct.conf`.
   - Trigger `plasma-apply-colorscheme`, `kwriteconfig6`, and D-Bus notifications.
