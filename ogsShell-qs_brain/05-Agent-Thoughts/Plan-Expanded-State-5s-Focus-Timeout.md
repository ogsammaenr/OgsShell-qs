---
title: "Proposal: 5-Second Inactivity / Unfocus Auto-Collapse for Expanded State"
type: agent-thought
tags:
  - proposal/expanded-unfocus-timeout
  - quickshell/qml
  - dynamic-island/state-machine
  - interactions/timer
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Control-Center-Widget]]"
  - "[[Clock-Suite-View]]"
  - "[[Calendar-Widget]]"
---

# Proposal: 5-Second Inactivity / Unfocus Auto-Collapse for Expanded State

> [!IDEA]
> When Dynamic Island is in `EXPANDED` state (Clock Suite, Calendar, or Control Center), if mouse focus leaves the island for 5 continuous seconds, the island will automatically collapse back to `IDLE` state. Re-entering the island within 5 seconds cancels the countdown.

## Problem Statement

Currently, when the island enters `EXPANDED` state, it remains expanded indefinitely until the user explicitly clicks the outside backdrop or manually dismisses the modal. If the user moves away to work on another window without clicking outside, the island stays open.

## Proposed Solution

1. In `shell/components/island/DynamicIsland.qml`:
   - Introduce an `expandedUnhoverTimer` with `interval: 5000` and `repeat: false`.
   - In `islandHoverHandler`:
     - When `hovered` is `true` and `stateMode === "EXPANDED"`, stop the countdown (`expandedUnhoverTimer.stop()`).
     - When `hovered` is `false` and `stateMode === "EXPANDED"`, start the 5-second countdown (`expandedUnhoverTimer.restart()`).
   - In `onStateModeChanged`:
     - If transitioning to `EXPANDED` while cursor is outside the island, start the timer; if cursor is inside, ensure timer is stopped.
     - If transitioning away from `EXPANDED`, stop the timer.
   - When `expandedUnhoverTimer` triggers, call `root.collapse()`.
