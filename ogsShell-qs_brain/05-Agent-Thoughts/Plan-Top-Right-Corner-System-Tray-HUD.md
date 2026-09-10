---
title: "Plan - Top-Right Screen Corner System Tray HUD"
type: thought
tags:
  - plan
  - system-tray
  - screen-corners
  - ui-components
  - quickshell
created: 2026-09-10
updated: 2026-09-10
status: implemented
related_notes:
  - "[[Screen-Corners-Component]]"
  - "[[Corner-Island-HUD-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Configuration-System-Spec]]"
---

# Plan: Top-Right Screen Corner System Tray HUD

> [!NOTE]
> This proposal details the implementation of an interactive, minimalist System Tray HUD embedded seamlessly into the top-right rounded screen corner cutout. It enables monitoring and interacting with background daemon applications (such as Steam, Discord, Spotify, OBS, Telegram) without the bloat of traditional docks or static status bars.

---

## 1. Problem Statement & Motivation

Many background applications (Steam, Discord, Torrent clients, OBS) minimize to the D-Bus StatusNotifierItem (SNI) / System Tray when their primary window is closed. In a pure tiling window manager setup without a classic taskbar/dock, users lose visibility into these active background daemons.

Rather than building a heavy dock or adding noisy status icons to the Dynamic Island, this feature morphs the top-right screen corner cutout (`ScreenCorners.qml`) into an on-demand, expandable OLED black pill containing native system tray items.

---

## 2. Technical Architecture & Component Flow

```text
┌────────────────────────────────────────────────────────┐
│               Linux D-Bus Subsystem                    │
│    (org.kde.StatusNotifierWatcher / StatusNotifierItem)│
└───────────────────────────┬────────────────────────────┘
                            │ D-Bus Signals
┌───────────────────────────▼────────────────────────────┐
│      Quickshell.Services.SystemTray (Native C++)       │
│  - SystemTray.items (UntypedObjectModel)               │
│  - item.icon, item.title, item.tooltipTitle            │
│  - item.activate() / item.secondaryActivate()          │
│  - item.display() / item.menu                          │
└───────────────────────────┬────────────────────────────┘
                            │ QML Model Binding
┌───────────────────────────▼────────────────────────────┐
│     TopRightTrayHUD.qml (New Corner HUD Component)     │
│  - IDLE: Inverted 14px Concave Screen Corner Cutout    │
│  - EXPANDED: Liquid Morph Vector Pill with Concave Ears│
│  - Delegate: Clean 20px Icons + Left/Right click menus │
│  - BackdropWindow: Instant click-outside dismissal     │
└────────────────────────────────────────────────────────┘
```

---

## 3. Key Design Decisions

1. **Dual Geometry Vector Shape (Top-Right Mirrored Morph):**
   * **IDLE State:** Exact top-right concave cutout matching display bezel radius (`14px`).
   * **EXPANDED State:** Expands from right edge towards the left with a top-left outward concave ear, bottom-left rounded convex corner (`14px`), and bottom-right outward ear connecting to the display's right edge.
2. **Interactive Wayland Surface:**
   * Hosted with precision input envelope so that only the corner hotspot and expanded capsule capture clicks, while the rest of the display passes clicks directly to underlying tiling windows.
3. **Pluggable & Extensible Icon Renderer:**
   * Uses Quickshell's `image://icon/` protocol, local filesystem path resolver, and fallback monograms with theme badges for seamless future icon customization.
4. **Zero Backend Daemon Overhead:**
   * Leverages Quickshell's native C++ SystemTray implementation directly over D-Bus with zero Go daemon modifications required.

---

## 4. Implementation Steps

1. **Create `shell/components/corners/TopRightTrayHUD.qml`:** Vector shape morphing, tray items repeater, and interaction handlers.
2. **Integrate into `shell/shell.qml`:** Configure interactive Wayland input mask and click-outside dismissal backdrop.
3. **Update `Config.qml` & `config.json`:** Add `corner_tray` toggle and geometry options.
4. **Update Obsidian Documentation:** Sync `Screen-Corners-Component.md`.

---

## 5. Related Links

* Screen Corners: `[[Screen-Corners-Component]]`
* Corner Island HUD: `[[Corner-Island-HUD-Component]]`
* Shell Root: `[[Shell-Root-PanelWindow]]`
* Configuration Spec: `[[Configuration-System-Spec]]`
