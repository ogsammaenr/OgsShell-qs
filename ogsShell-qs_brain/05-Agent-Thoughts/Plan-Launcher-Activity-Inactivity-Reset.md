---
title: "Plan: Dynamic Island Inactivity Timer Reset on App Launcher User Activity"
type: agent-thought
tags:
  - ui/launcher
  - dynamic-island/inactivity
  - quickshell/qml
  - timer/reset
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[App-Launcher-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Dynamic Island Inactivity Timer Reset on App Launcher User Activity

> [!IDEA]
> When the Dynamic Island is in `EXPANDED` mode (specifically the App Launcher), the 5-second auto-collapse timer (`expandedUnhoverTimer`) must reset dynamically whenever the user types in the search bar or performs keyboard navigation, preventing premature closing while the user is interacting.

## Problem Analysis
When the App Launcher is opened via keyboard shortcut (`Super+Space`), the cursor is often outside the island bounds (`!islandHoverHandler.hovered`). As a result, `expandedUnhoverTimer` starts counting down 5 seconds. If the user spends time typing or browsing results, the launcher closes after 5 seconds because typing did not reset the timer.

## Proposed Solution
1. **Dynamic Island Method (`DynamicIsland.qml`)**:
   - Expose `resetInactivityTimer()` which calls `expandedUnhoverTimer.restart()` when `stateMode === "EXPANDED"`.
2. **App Launcher Signal & Hooks (`AppLauncherWidget.qml`)**:
   - Define `signal userActivity()`.
   - On `searchInput.onTextChanged`: emit `userActivity()`.
   - On `Keys.onPressed`: emit `userActivity()`.
   - On `selectedIndexChanged`: emit `userActivity()`.
3. **Loader Connection**:
   - Wire `launcherLoader.item.onUserActivity` to `root.resetInactivityTimer()`.
