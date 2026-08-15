---
title: "Proposal: Dynamic Layer Stacking for Expanded Island Application Interaction"
type: agent-thought
tags:
  - proposal/expanded-layer-interaction
  - quickshell/panelwindow
  - wayland/layershell
  - dynamic-island/ui
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Plan-Fullscreen-Application-Layer-Clearance]]"
  - "[[Plan-Reserved-Spacer-Window-Layer]]"
  - "[[System-Architecture]]"
---

# Proposal: Dynamic Layer Stacking for Expanded Island Application Interaction

> [!IDEA]
> Dynamically elevating `islandWindow` to `WlrLayer.Overlay` when `stateMode === "EXPANDED"` while keeping `backdropWindow` on `WlrLayer.Top` ensures that all user clicks within the expanded application are handled by the app's interactive controls, while clicks outside the island hit the backdrop to trigger `island.collapse()`. In `IDLE` state, the island returns to `WlrLayer.Top` so fullscreen games/videos remain unobstructed.

## Problem Statement

When both `islandWindow` and `backdropWindow` were configured on the same `WlrLayer.Top` layer, mapping `backdropWindow` upon island expansion caused the full-screen backdrop to stack over `islandWindow`. Consequently, any click inside the expanded app was captured by the backdrop's click-outside handler, instantly collapsing the island back to `IDLE`.

## Proposed Architecture

1. **Reactive Layer Stacking:**
   - In `shell/shell.qml`, bind `islandWindow.WlrLayershell.layer`:
     ```qml
     WlrLayershell.layer: island.stateMode === "EXPANDED" ? WlrLayer.Overlay : WlrLayer.Top
     ```
   - Keep `backdropWindow` at `WlrLayer.Top`.
   - In `IDLE`/`HOVER`: `islandWindow` is on `Top` (fullscreen apps take precedence and hide it).
   - In `EXPANDED`: `islandWindow` is on `Overlay` (strictly higher than `backdropWindow` on `Top`), giving interactive controls full click priority.

## Affected Components
- `shell/shell.qml` - Dynamic `WlrLayershell.layer` binding.
- `ogsShell-qs_brain/03-UI-Components/Shell-Root-PanelWindow.md` - Document dynamic layer behavior.
- `.agents/ARCHITECTURE.md` - Update reference map.
