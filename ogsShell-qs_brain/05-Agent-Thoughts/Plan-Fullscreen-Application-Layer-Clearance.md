---
title: "Proposal: Fullscreen Application Layer Clearance for Dynamic Island"
type: agent-thought
tags:
  - proposal/fullscreen-clearance
  - quickshell/panelwindow
  - wayland/layershell
  - hyprland/fullscreen
  - dynamic-island/ui
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Plan-Reserved-Spacer-Window-Layer]]"
  - "[[System-Architecture]]"
  - "[[QML-Best-Practices]]"
---

# Proposal: Fullscreen Application Layer Clearance for Dynamic Island

> [!IDEA]
> Transitioning `islandWindow` from `WlrLayer.Overlay` to `WlrLayer.Top` leverages native Wayland LayerShell protocol rules where fullscreen applications (video players, games, browser fullscreen) are rendered with higher compositor priority than `Top` layer surfaces, preventing island overlap while preserving overlay behavior over normal tiling and floating windows.

## Problem Statement

When an application enters fullscreen mode (e.g. `fullscreen` dispatch in Hyprland or F11 / video playback), `islandWindow` configured with `WlrLayershell.layer: WlrLayer.Overlay` remains rendered on top of the fullscreen application.

## Proposed Architecture

1. **Layer Demotion to `WlrLayer.Top`:**
   * Configure `islandWindow` in `shell/shell.qml` with `WlrLayershell.layer: WlrLayer.Top`.
   * Standard tiling and floating windows remain positioned beneath `WlrLayer.Top`.
   * When an active window enters fullscreen, Wayland compositors (Hyprland / wlroots) render the fullscreen window above `Top` layer surfaces, automatically occluding the idle island without needing complex manual visibility hooks.

2. **Decoupled Architecture:**
   * `reservedSpacerWindow`: `WlrLayer.Bottom`, `ExclusionMode.Normal` (exclusive zone automatically ignored by Wayland in fullscreen).
   * `backdropWindow`: `WlrLayer.Top`, `ExclusionMode.Ignore`.
   * `islandWindow`: `WlrLayer.Top`, `ExclusionMode.Ignore`.

## Affected Files
- `shell/shell.qml` - Update `islandWindow` layer to `WlrLayer.Top`.
- `ogsShell-qs_brain/03-UI-Components/Shell-Root-PanelWindow.md` - Update documentation.
- `.agents/ARCHITECTURE.md` - Update reference vault map.
