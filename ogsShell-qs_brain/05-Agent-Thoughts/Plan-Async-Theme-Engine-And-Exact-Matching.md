---
title: "Proposal: High-Speed Async Theme Engine and Exact Palette Matching"
type: agent-thought
tags:
  - proposal/async-theme-engine
  - go/daemon
  - theme/performance
  - quickshell/qml
  - debouncing
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[IPC-Socket-Schema]]"
  - "[[System-Architecture]]"
---

# Proposal: High-Speed Async Theme Engine and Exact Palette Matching

> [!IDEA]
> Overhauling `core/services/theme/manager.go` to use an asynchronous debounced worker queue eliminates IPC blocking and external CLI latency during theme switching. Concurrently, removing loose `indexOf` substring matching in `ThemesView.qml` ensures only the exact active theme ID is marked active.

## Problem Statement

1. **Simultaneous Selection Bug:** In `ThemesView.qml`, active state checking used `root.currentActiveThemeId.indexOf(themeItem.id) !== -1`. Because `"everforest"` is a substring of `"everforest-light"`, both themes appeared selected simultaneously when either was active.
2. **IPC Blocking Latency:** In `core/services/theme/manager.go`, `SetActiveTheme` executed all application adapters (`hyprctl`, `kitty`, `zed`, `dolphin`, `vesktop`, `nvim`) synchronously using `wg.Wait()` on the main IPC request thread. Rapid theme switching caused socket backlog, command queue lockups, and several seconds of UI lag.

## Proposed Architecture

1. **Non-Blocking In-Memory State Switch (<1ms):**
   - `SetActiveTheme(themeID)` immediately updates in-memory `activeTheme` under lock.
   - Instantly notifies the IPC server and broadcast callback (`updateCb`).
   - Returns the active palette to the caller immediately without blocking.

2. **Debounced Background Adapter Dispatcher:**
   - A dedicated background worker goroutine reads from an `applyChan` channel with a 50ms coalesce debounce.
   - If a user rapidly clicks 5 themes in 200ms, intermediate states are coalesced, and only the final chosen theme is dispatched to external adapters.
   - Adapters execute in parallel with timeout contexts.

3. **Strict Frontend Matching & Optimistic UI:**
   - In `ThemesView.qml`: `readonly property bool isActive: root.currentActiveThemeId === themeItem.id`.
   - In `DaemonIPC.qml`: `setActiveTheme` optimistically updates `currentTheme` locally for 0ms visual feedback while sending the socket action.

## Affected Components
- `core/services/theme/manager.go` - Asynchronous apply worker and debounced dispatcher.
- `core/services/theme/theme_test.go` - Update tests for async manager.
- `shell/components/widgets/controlcenter/views/ThemesView.qml` - Fix active matching.
- `shell/backend/DaemonIPC.qml` - Add optimistic theme switching.
- `ogsShell-qs_brain/02-Services/Theme-Service.md` - Update architecture doc.
- `.agents/ARCHITECTURE.md` - Update reference map.
