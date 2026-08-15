---
title: "Proposal: Hover State Expanded Layout (Media, Clock/Date, Connectivity)"
type: agent-thought
tags:
  - proposal/ui
  - dynamic-island
  - quickshell/qml
  - hover-state
  - widgets
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Proposal: Hover State Expanded Layout (Media, Clock/Date, Connectivity)

> [!IDEA]
> Expanding the Dynamic Island / Notch during the `HOVER` state into a three-column modular status bar:
> 1. **Left Column:** Live MPRIS Media Player status (track title, artist, playback indicator, play/pause trigger).
> 2. **Center Column:** Two-row typography with large Clock on top and localized Date below.
> 3. **Right Column:** Unified Wi-Fi and Bluetooth interactive status button/pill reflecting real-time connection telemetry from DaemonIPC.

## 1. Problem & Requirement Statement

Currently, the `HOVER` state of the Dynamic Island and Notch merely increases the island's dimensions slightly (`220x42` px) and retains a single centered clock. 
The user requested an interactive, rich hover experience where:
* The island/notch expands in width and height.
* The center features the **Clock** on top and the **Date** below it.
* The left features **Media Status** (MPRIS).
* The right features a **Wi-Fi & Bluetooth status button**.

## 2. Proposed Architecture & Modular Slot Decomposition

In compliance with the **Modular Slot Architecture** rule in `[[Agent-Workflow-Directives]]`:
* `shell/components/widgets/ClockWidget.qml`: Updated to support both compact (idle) and multi-line (hover) modes.
* `shell/components/widgets/MediaWidget.qml`: New modular component reading `Quickshell.Services.Mpris` with animated equalizer, track info, and playback controls.
* `shell/components/widgets/ConnectivityStatusWidget.qml`: New modular button component reading Wi-Fi and Bluetooth state from `DaemonIPC`.
* `shell/components/island/DynamicIsland.qml`: Coordinates the `IDLE`, `HOVER`, `TRANSIENT`, and `EXPANDED` layers with smooth spring transitions.
* `shell/backend/Config.qml` & `shell/config.json`: Adjusting `hover_width` (to ~400-420px) and `hover_height` (to ~52px) for proportional balance.

## 3. Affected Files

- `shell/components/widgets/ClockWidget.qml` - Enhanced with hover multi-line mode.
- `shell/components/widgets/MediaWidget.qml` - New modular MPRIS media widget.
- `shell/components/widgets/ConnectivityStatusWidget.qml` - New modular Wi-Fi/BT status button widget.
- `shell/components/island/DynamicIsland.qml` - Integrating modular hover layout into layer structure.
- `shell/config.json` & `shell/backend/Config.qml` - Adjusted hover geometry tokens.
- `shell/shell.qml` - Adjusted `islandWindow` implicit size canvas.
- `ogsShell-qs_brain/03-UI-Components/` - New and updated UI documentation notes.
