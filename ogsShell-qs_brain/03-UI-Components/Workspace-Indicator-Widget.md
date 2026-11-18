---
title: "Workspace Indicator Widget Component (Hover Dots & Pill)"
type: ui-component
tags:
  - ui/widget
  - ui/workspaces
  - hyprland/workspaces
  - quickshell/qml
  - dynamic-island/hover
status: active
---

# Workspace Indicator Widget Component

> [!NOTE]
> `shell/components/widgets/WorkspaceIndicatorWidget.qml` renders an interactive, per-monitor workspace indicator beneath `[[Connectivity-Status-Widget]]` inside the `HOVER` state of `[[Dynamic-Island-Component]]`.

---

## 1. Visual Language & Theme Integration

* **Active Workspace (Pill):** Horizontal capsule (`20×6px`, `radius: 3`) styled with `Style.accent` from `[[Style-Design-Tokens]]`.
* **Inactive Occupied Workspace (Dot):** `6×6px` dot (`Qt.alpha(Style.textPrimary, 0.52)`) indicating open windows exist on that workspace.
* **Inactive Empty Workspace (Dot):** `6×6px` dot (`Qt.alpha(Style.textPrimary, 0.22)`).
* **Hover State:** Highlights hovered dots/pills using `Style.accent` with subtle scale feedback (`1.15x`) and pointing-hand cursor.
* **Spring Physics:** Width transitions between dot (`6px`) and pill (`20px`) animate via `SpringAnimation { spring: 28.0; damping: 0.78; epsilon: 0.01 }`.

---

## 2. Per-Monitor Isolation & Hyprland Dispatch

* Receives `screen` and `hyprMonitor` context from `[[Shell-Root-PanelWindow]]` via `[[Dynamic-Island-Component]]`, isolating displayed workspaces to the current physical monitor (matching `[[Screen-Corners-Component]]`).
* Inspects `Hyprland.workspaces.values` and `Hyprland.toplevels.values` reactively to compute workspace IDs and window occupancy.
* **Click Action:** Left-clicking an inactive dot invokes `hyprctl dispatch "hl.dsp.focus({ workspace = <id> })"` (with automatic fallback to legacy `workspace <id>` syntax on pre-0.57 Hyprland) without triggering `[[Connectivity-Status-Widget]]` or Control Center expansion.
* **Wheel Action:** Scrolling vertically over the indicator steps between adjacent workspaces on that monitor via `switchToWorkspace()`.

---

## 3. Related Links

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Connectivity Widget: `[[Connectivity-Status-Widget]]`
* Shell Root: `[[Shell-Root-PanelWindow]]`
* Screen Corners: `[[Screen-Corners-Component]]`
* Design Tokens: `[[Style-Design-Tokens]]`
