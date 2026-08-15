---
title: "Proposal: Multi-Monitor Support for Dynamic Island"
type: agent-thought
tags:
  - proposal/multi-monitor
  - quickshell/variants
  - wayland/layershell
  - dynamic-island/ui
created: 2026-08-14
updated: 2026-08-14
status: implemented
related_notes:
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Daemon-IPC-Client]]"
  - "[[System-Architecture]]"
---

# Proposal: Multi-Monitor Support for Dynamic Island

> [!IDEA]
> Utilizing Quickshell's `Variants` component with `model: Quickshell.screens`, each physical/virtual connected display will spawn an isolated `Scope` containing its own `PanelWindow` (backdrop and island) while sharing the singleton `DaemonIPC` instance and `ClockManager` state.

## Problem Statement

Currently, in `shell/shell.qml`, `PanelWindow` instances for `backdropWindow` and `islandWindow` are declared directly at the top-level without binding to individual screens (`screen: ...`). Under Wayland/Hyprland, this causes Quickshell to display the Dynamic Island only on the primary or first detected monitor.

## Proposed Architecture

1. **Quickshell Variants Component:**
   * Wrap per-screen windows inside `Variants { model: Quickshell.screens }`.
   * Each variant receives `required property var modelData` (representing `QsScreen`).
   * Bind `screen: screenScope.modelData` on both `backdropWindow` and `islandWindow`.

2. **Decentralized Notification Dispatch:**
   * Move notification popup handling directly into `DynamicIsland.qml` via its existing `ipc` connection (`onNotificationReceived`) so all islands on all screens trigger simultaneously upon incoming notifications.

3. **Multi-Window Isolation:**
   * Each screen manages its own `island.stateMode` (hovering or expanding the island on Monitor 1 does not force expand Monitor 2).
   * Backdrop window clicks on a specific monitor collapse only that monitor's island.

```mermaid
graph TD
    ROOT["Root Scope (shell.qml)"] --> IPC["DaemonIPC Singleton"]
    ROOT --> NOTIF["NotificationServer (D-Bus)"]
    ROOT --> VARIANTS["Variants (model: Quickshell.screens)"]

    VARIANTS --> SCREEN_1["Scope (Screen 1)"]
    VARIANTS --> SCREEN_2["Scope (Screen 2)"]
    VARIANTS --> SCREEN_N["Scope (Screen N)"]

    SCREEN_1 --> BACKDROP_1["PanelWindow (screen: Screen 1)"]
    SCREEN_1 --> ISLAND_1["DynamicIsland (screen: Screen 1)"]

    SCREEN_2 --> BACKDROP_2["PanelWindow (screen: Screen 2)"]
    SCREEN_2 --> ISLAND_2["DynamicIsland (screen: Screen 2)"]
```

## Affected Files
- `shell/shell.qml` - Refactor root windows into `Variants` over `Quickshell.screens`.
- `shell/components/island/DynamicIsland.qml` - Add `onNotificationReceived` listener to `Connections { target: root.ipc }`.
- `ogsShell-qs_brain/03-UI-Components/Shell-Root-PanelWindow.md` - Update architecture documentation.
