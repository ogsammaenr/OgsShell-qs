---
title: "Plan: Fix and Enhance App Launcher List View and Layout"
type: agent-thought
tags:
  - bugfix/launcher-list
  - ui/launcher
  - quickshell/qml
  - listview/rendering
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[App-Launcher-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[Style-Design-Tokens]]"
---

# Plan: Fix and Enhance App Launcher List View and Layout

> [!IMPORTANT]
> The previous over-simplification introduced rendering bugs in `ListView` (such as `reuseItems: true` breaking dynamic array models in QtQuick) and removed crucial visual information (subtitles, generous layout, scroll feedback). We must restore full functionality while retaining a clean, premium Apple HIG aesthetic.

## Root Cause Analysis
1. **`reuseItems: true` in `ListView`**: In QtQuick 6 / Quickshell, enabling `reuseItems` on a JavaScript array model prevents delegates from updating bindings when the active list changes, causing blank/broken lists.
2. **Overly Compressed Single-Line Delegates**: Hiding categories/subtitles when selected and cramming everything into a cramped 42px row degraded readability.
3. **Cramped Island Dimensions (480x380)**: Reduced vertical space allowed only 4 items before clipping.
4. **Missing Scroll Feedback & Width Resolution**: `width: appList.width` inside an anchored list caused geometry cycle delays.

## Proposed Fixes & Architectural Plan
1. **Fix `ListView` Rendering Engine (`AppLauncherWidget.qml`)**:
   - Remove `reuseItems: true`.
   - Use `width: ListView.view ? ListView.view.width : parent.width`.
   - Set `clip: true` and ensure robust reactive array bindings.
2. **Rich Two-Line Elegant Row Architecture**:
   - 32x32 Desktop Icon directly on surface with 3-tier fallback.
   - Column with:
     - Line 1: Application Name (`13.5px`, `Font.Medium`, `color: Style.textPrimary`).
     - Line 2: Generic Name / Category / Description (`11.5px`, `color: Style.textMuted`).
   - Right: Subtle `↵` indicator on selection + discreet frecency badge when `launch_count > 0`.
   - Soft frosted active pill (`Style.surfaceActive`) with smooth hover animations.
3. **Restore Balanced Dimensions (`DynamicIsland.qml`)**:
   - Width: `520px`
   - Height: `440px` (comfortably displays 6-7 rich items + search + footer).
4. **Subtle Glass Scroll Indicator**:
   - Sleek right-hand scroll thumb indicating list position.
