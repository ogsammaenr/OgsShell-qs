---
title: "Plan: Expand Control Center Width for Telemetry Fit"
type: agent-thought
tags:
  - proposal/ui
  - dynamic-island/geometry
  - control-center
  - quickshell/qml
created: 2026-08-26
updated: 2026-08-26
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Pinned-Metrics-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Configuration-System-Spec]]"
---

# Plan: Expand Control Center Width for Telemetry Fit

> [!IDEA]
> Expand the default Control Center expanded island width from 440px to 490px across `ControlCenterView.qml`, `DynamicIsland.qml`, `Config.qml`, and `config.json` to ensure 4-part telemetry (CPU, RAM, GPU, Network) has generous breathing room and zero text clipping.

## 1. Problem Statement
With the addition of Network throughput (`NET <speed>`) to the 4th slot in the Control Center telemetry footer pill alongside CPU, RAM, and GPU, the previous 440px island container allocated only 236px for the pill, causing the 250px+ text row to overflow or become cramped.

## 2. Proposed Changes
1. **ControlCenterView Geometry (`ControlCenterView.qml`):**
   - Update `preferredIslandWidth` for `MAIN` from 440 to 490.
   - Update `preferredIslandHeight` for `MAIN` from 310 to 315 for visual balance.
2. **Dynamic Island Fallback (`DynamicIsland.qml`):**
   - Update `expandedActiveTab === "CONTROL_CENTER"` fallback width from 440 to 490.
3. **Configuration Defaults (`Config.qml`, `shell/config.json`, `shared/app_configs/shell/config.json`):**
   - Update `expanded_width` from 440/450 to 490.
4. **Control Center Telemetry Pill (`ControlCenterMain.qml`):**
   - Fine-tune horizontal spacing and margin alignment for optimal centering.

## 3. Implementation Summary
- Updated `ControlCenterView.preferredIslandWidth` to 490px.
- Updated `DynamicIsland.qml` fallback for `CONTROL_CENTER` to 490px.
- Updated `Config.qml`, `shell/config.json`, `shared/app_configs/shell/config.json`, and user's `~/.config/ogsShell/config.json` `expanded_width` to 490px.
- Telemetry pill now has 286px of space, perfectly fitting the 249px 4-metric text row with 18.5px symmetric padding.
