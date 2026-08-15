---
title: "Proposal: Fix Dolphin Crash on Live Theme Switch"
type: agent-thought
tags:
  - proposal/dolphin-crash-fix
  - go/daemon
  - adapters/dolphin-qt
  - dbus/kglobalsettings
  - qt6ct/stability
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Fix Dolphin Crash on Live Theme Switch

> [!IDEA]
> Replacing unsafe CLI `gdbus emit ConfigChanged` and invalid `/MainApplication` QDBus calls with official `plasma-apply-colorscheme` and standard `/KGlobalSettings` signals, while writing complete `qt6ct.conf` structures (with `[Fonts]` and `[Interface]`), eliminates segfaults and keeps Dolphin 100% stable during theme changes.

## Problem Statement

Manually emitting `org.kde.kconfig.notify.ConfigChanged` with plain text payloads caused Qt `QDBusArgument` unmarshaling to crash KDE Frameworks (KF6) `KConfigWatcher` in Dolphin.

## Proposed Solution

1. In `core/services/theme/adapters/dolphin_qt.go`:
   - Remove `gdbus emit ConfigChanged`.
   - Remove invalid `/MainApplication` and `view_redisplay` QDBus calls.
   - Rely on `plasma-apply-colorscheme <SchemeName>` and standard `/KGlobalSettings` `PaletteChanged` (`int32:1`), `StyleChanged` (`int32:2`), and `SettingsChanged` (`int32:0`).
   - Write complete `qt6ct.conf` and `qt5ct.conf` with `[Appearance]`, `[Fonts]`, and `[Interface]`.
