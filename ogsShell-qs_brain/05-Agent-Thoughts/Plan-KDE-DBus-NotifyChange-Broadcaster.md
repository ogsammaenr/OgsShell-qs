---
title: "Proposal: Multi-Channel D-Bus KDE notifyChange & KConfig Hot-Reload Broadcaster"
type: agent-thought
tags:
  - proposal/kde-dbus-notifychange
  - go/daemon
  - adapters/dolphin-qt
  - dbus/kglobalsettings
  - kconfig/configchanged
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Multi-Channel D-Bus KDE notifyChange & KConfig Hot-Reload Broadcaster

> [!IDEA]
> Dispatching targeted D-Bus signals (`KGlobalSettings.notifyChange` for PaletteChanged & StyleChanged, `kconfig.notify.ConfigChanged`, and `view_redisplay` to running `org.kde.dolphin-*` instances) enables live, instant color scheme updates in Dolphin and Qt applications without closing or restarting windows.

## Problem Statement

Dolphin caches configuration in-memory and does not hot-reload its widget tree or palette unless explicit D-Bus change notifications are dispatched across the session bus.

## Proposed Solution

1. In `core/services/theme/adapters/dolphin_qt.go`:
   - Send `dbus-send` signals:
     - `org.kde.KGlobalSettings.notifyChange int32:1 int32:0` (PaletteChanged)
     - `org.kde.KGlobalSettings.notifyChange int32:2 int32:0` (StyleChanged)
     - `org.kde.KGlobalSettings.notifyChange int32:0 int32:0` (SettingsChanged)
   - Send `gdbus` emit:
     - `org.kde.kconfig.notify.ConfigChanged` on `/kdeglobals`
   - Discover all running `org.kde.dolphin-*` session bus services via `qdbus` and trigger:
     - `qdbus <service> /MainApplication org.kde.KGlobalSettings.notifyChange 1 0`
     - `qdbus <service> /dolphin/Dolphin_1/actions/view_redisplay org.qtproject.Qt.QAction.trigger`
