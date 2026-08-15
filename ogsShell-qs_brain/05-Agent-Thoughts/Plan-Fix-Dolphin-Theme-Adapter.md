---
title: "Proposal: Fix Dolphin / KDE Qt Theme Application"
type: agent-thought
tags:
  - proposal/dolphin-theme-fix
  - go/daemon
  - adapters/dolphin-qt
  - kde/kdeglobals
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Fix Dolphin / KDE Qt Theme Application

> [!IDEA]
> Installing KDE color schemes to `~/.local/share/color-schemes/Ogs<Name>.colors` alongside `~/.config/kdeglobals` and executing `plasma-apply-colorscheme` / `kwriteconfig6` enables full native color theming for Dolphin file manager and Qt applications.

## Problem Statement

Dolphin relies on named color schemes registered in `~/.local/share/color-schemes/` and referenced by `kdeglobals`. Previously, the adapter only copied `.kdeglobals` without installing the `.colors` file or dispatching the KDE plasma colorscheme updater, resulting in Dolphin not changing themes.

## Proposed Solution

1. In `core/services/theme/adapters/dolphin_qt.go`:
   - Map theme IDs to `Ogs<Name>` scheme identifiers (`OgsCatppuccin`, `OgsEverforest`, `OgsNord`, `OgsTokyoNight`, `OgsGruvbox`, `OgsMonochrome`).
   - Copy `shared/app_configs/dolphin/<id>.kdeglobals` to `~/.local/share/color-schemes/<SchemeName>.colors` and `~/.config/kdeglobals`.
   - Copy `shared/app_configs/qt/<id>.conf` to `~/.config/qt5ct/qt5ct.conf` and `~/.config/qt6ct/qt6ct.conf`.
   - Execute `plasma-apply-colorscheme <SchemeName>`, `kwriteconfig6`, `kwriteconfig5`, and D-Bus change signal.
