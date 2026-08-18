---
title: "Plan: Per-Monitor App Launcher Activation on Focused Screen"
type: agent-thought
tags:
  - ui/launcher
  - multi-monitor
  - hyprland/focus
  - quickshell/qml
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Dynamic-Island-Component]]"
  - "[[App-Launcher-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Plan-Dynamic-Island-App-Launcher-Widget]]"
---

# Plan: Per-Monitor App Launcher Activation on Focused Screen

> [!IDEA]
> Restricting App Launcher expansion (`toggle_launcher` / `open_launcher`) to exclusively the currently focused Hyprland monitor (`Hyprland.focusedMonitor`), preventing redundant and distracting multi-screen overlay expansion across all attached displays.

## Problem Analysis
Because `shell.qml` instantiates `DynamicIsland` inside a `Variants { model: Quickshell.screens }` loop, each screen instance was independently listening to the IPC `toggle_launcher` broadcast. Consequently, triggering the launcher expanded the island on all attached monitors simultaneously.

## Proposed Solution
1. **Screen Focus Binding (`shell/shell.qml`)**:
   - In `screenScope`, define `isFocusedMonitor` deriving from `Hyprland.focusedMonitor` (matching `screenScope.modelData.name`) with fallback to `hyprMonitor.focused` and primary screen.
   - Pass `isScreenFocused: screenScope.isFocusedMonitor` to each `DynamicIsland` instance.
2. **Dynamic Island Guard (`DynamicIsland.qml`)**:
   - Add property `property bool isScreenFocused: true`.
   - In `onLauncherToggled` and `onLauncherOpened`: verify `root.isScreenFocused` before expanding to `LAUNCHER`.
   - If `stateMode === "EXPANDED" && expandedActiveTab === "LAUNCHER"`, allow `collapse()` unconditionally.
3. **Auto-Reveal on Target Screen (`shell/shell.qml`)**:
   - Ensure `isRevealed = true` is triggered on the focused monitor when the launcher opens.
