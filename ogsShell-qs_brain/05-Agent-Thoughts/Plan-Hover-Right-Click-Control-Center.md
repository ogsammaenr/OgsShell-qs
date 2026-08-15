---
title: "Proposal: Hover State Right-Click Shortcut to Open Control Center"
type: agent-thought
tags:
  - proposal/right-click-control-center
  - dynamic-island/ui
  - control-center/gesture
  - quickshell/pointer-handlers
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Control-Center-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Proposal: Hover State Right-Click Shortcut to Open Control Center

> [!IDEA]
> Adding a dedicated `TapHandler` with `acceptedButtons: Qt.RightButton` to `DynamicIsland.qml` allows users hovering over the island to instantly expand into the Control Center with a single right-click gesture.

## Problem Statement & User Intent

Currently, opening the Control Center requires the user to hover over the island, locate the right-aligned `ConnectivityStatusWidget` pill, and left-click it. To streamline quick system toggles (Wi-Fi, Bluetooth, Audio, Power, DND), the user requested opening the Control Center directly via a right-click anywhere on the island in `HOVER` state.

## Proposed Implementation

1. **Right-Click TapHandler in `DynamicIsland.qml`:**
   * Attach a `TapHandler` configured with `acceptedButtons: Qt.RightButton`.
   * Check for `root.stateMode === "HOVER"` (or `"IDLE"`).
   * Reset the Control Center navigation stack (`controlCenterLoader.item.resetToMain()`).
   * Set `root.expandedActiveTab = "CONTROL_CENTER"` and transition `root.stateMode = "EXPANDED"`.

## Affected Files
- `shell/components/island/DynamicIsland.qml` - Add right-click `TapHandler`.
- `ogsShell-qs_brain/03-UI-Components/Dynamic-Island-Component.md` - Document gesture interactions.
- `.agents/ARCHITECTURE.md` - Update reference map.
