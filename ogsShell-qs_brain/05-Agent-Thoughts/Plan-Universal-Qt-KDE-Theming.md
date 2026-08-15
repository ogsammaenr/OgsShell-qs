---
title: "Proposal: Universal Qt & KDE Application Theme Synchronization"
type: agent-thought
tags:
  - proposal/universal-qt-kde-theming
  - go/daemon
  - adapters/qt-kde
  - qt6ct/qt5ct
  - kde/multi-app
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Universal Qt & KDE Application Theme Synchronization

> [!IDEA]
> Expanding the Qt/KDE theme adapter to synchronize Qt6ct, Qt5ct, KDE global color schemes (`kdeglobals`), and all individual KDE application configuration files (`dolphinrc`, `katerc`, `kwriterc`, `okularrc`, `arkrc`, `konsolerc`, `spectaclerc`, `kdenliverc`, `systemmonitorrc`) ensures seamless theme consistency across the entire Qt ecosystem.

## Proposed Solution

1. In `core/services/theme/adapters/dolphin_qt.go`:
   - Synchronize `kdeglobals` and `~/.local/share/color-schemes/Ogs<Name>.colors`.
   - Update `qt6ct.conf` and `qt5ct.conf` pointing to `~/.config/qt*ct/colors/<theme>.conf` with `custom_palette=2` and full fonts/interface specifications.
   - Iterate through all standard KDE application configuration files (`dolphinrc`, `katerc`, `kwriterc`, `okularrc`, `arkrc`, `konsolerc`, `spectaclerc`, `kdenliverc`, `systemmonitorrc`, `gwenviewrc`) using `kwriteconfig6` and `kwriteconfig5`.
   - Broadcast safe session notifications via `plasma-apply-colorscheme` and `/KGlobalSettings`.
