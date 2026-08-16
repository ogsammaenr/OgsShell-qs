---
title: "Plan: Fix Pinned Metrics Hover Clipping and Invariant Top Anchoring"
type: agent-thought
tags:
  - bugfix/geometry
  - dynamic-island/pinned
  - quickshell/wayland
  - layer-shell/canvas
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Control-Center-Widget]]"
  - "[[Plan-Dynamic-Island-System-Metrics-Pinning]]"
  - "[[Plan-Add-CPU-GPU-Temperature-Metrics]]"
---

# Plan: Fix Pinned Metrics Hover Clipping and Invariant Top Anchoring

> [!NOTE]
> Expanded `islandWindow` Wayland canvas width to 1200px to prevent clipping the GPU metric when the island widens in hover mode. Re-anchored the pinned telemetry widget to a fixed top margin calculated from idle geometry so that its distance from the top of the monitor remains completely invariant regardless of the island's dynamic height expansions.

## Problem Statement & Root Cause

1. **GPU Clipping in Hover:** `islandWindow` had `implicitWidth: 840`. In hover mode, the island widens from 180px to 430px, pushing the right side HUD beyond 840px and clipping off the rightmost GPU data.
2. **Vertical Shifting with Island Center:** `pinnedMetrics` was previously anchored to `island.verticalCenter`. When the island grew vertically from 36px to 50px in hover, the center shifted downward, displacing the pinned metrics vertically.

## Implemented Solution

1. **Widen Canvas:** Set `islandWindow.implicitWidth: 1200` to provide ample canvas room across all island state transitions.
2. **Fixed Top Anchoring:** Set `anchors.top: parent.top` and `anchors.topMargin: Config.isNotch ? Math.round((Config.notch.idle_height - height) / 2) : Math.round(Config.island.top_margin + (Config.island.idle_height - height) / 2)`, keeping the vertical position rock-solid.
