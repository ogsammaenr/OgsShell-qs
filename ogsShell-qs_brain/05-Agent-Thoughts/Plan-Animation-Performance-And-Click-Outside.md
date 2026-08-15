---
title: "Proposal: Animation Performance Optimization & Global Click-Outside Dismissal"
type: agent-thought
tags:
  - proposal/performance
  - ui/animation-smoothness
  - wayland/surface-optimization
  - interaction/click-outside
created: 2026-08-09
updated: 2026-08-09
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Proposal: Animation Performance Optimization & Global Click-Outside Dismissal

> [!NOTE]
> Implementation completed. Animation stutter was eliminated by fixing the `PanelWindow` Wayland canvas to prevent per-frame buffer reallocations, and tuning GPU-accelerated `Easing.OutBack` curves. Global screen-wide click-outside dismissal has been fully implemented with a dynamic LayerShell anchor and backdrop `MouseArea`.

## 1. Problem Analysis & Resolutions
1. **Wayland Surface Reallocation Stutter:** Fixed by decoupling `PanelWindow` implicit sizing from dynamic frame calculations, maintaining a steady canvas during compact/hover transitions.
2. **Animation Curves:** Switched to GPU-accelerated `Easing.OutBack` (`overshootFactor: 1.12`) with calibrated durations (`320ms` expand, `250ms` collapse), producing fluid 144Hz motion without micro-jitter.
3. **Outside Click Dismissal:** Implemented global backdrop `MouseArea` in `shell.qml` that activates when `EXPANDED` to catch any clicks outside the island bounds and invoke `island.collapse()`.

## 2. Status
* **Status:** `implemented`
