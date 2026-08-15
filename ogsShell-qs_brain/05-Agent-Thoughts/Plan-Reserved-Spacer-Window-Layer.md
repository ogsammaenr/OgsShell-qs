---
title: "Proposal: Invisible Top Reserved Spacer Window for Tiling Clearance"
type: agent-thought
tags:
  - proposal/spacer-window
  - quickshell/panelwindow
  - wayland/layershell
  - hyprland/tiling
  - dynamic-island/ui
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[System-Architecture]]"
  - "[[QML-Best-Practices]]"
---

# Proposal: Invisible Top Reserved Spacer Window for Tiling Clearance

> [!IDEA]
> Adding an invisible, click-through `PanelWindow` anchored to the top of each screen with `exclusionMode: ExclusionMode.Normal` and `implicitHeight` matching the Island/Notch idle height ensures Hyprland tiling windows maintain top clearance without overlapping the Dynamic Island.

## Problem Statement

The main Dynamic Island overlay window (`islandWindow`) is configured with `exclusionMode: ExclusionMode.Ignore` so that expanding or animating the island does not cause jarring window resizes or tiling jitter on Wayland compositors. However, in idle state, users may want tiled or maximized windows to start below the idle island height rather than extending underneath it.

## Proposed Architecture

1. **Invisible Spacer Surface (`reservedSpacerWindow`):**
   * Add a `PanelWindow` per screen inside `Variants { model: Quickshell.screens }`.
   * Anchor to `top: true`, `left: true`, `right: true`.
   * Configure `exclusionMode: ExclusionMode.Normal` so Wayland reserves the top zone for tiling window clearance.
   * Bind `implicitHeight: Config.isNotch ? Config.notch.idle_height : (Config.island.idle_height + Config.island.top_margin)`.
   * Apply `mask: Region {}` and `color: "transparent"` to guarantee zero click blocking and full input transparency.

2. **Decoupled Architecture:**
   * `islandWindow` remains `exclusionMode: ExclusionMode.Ignore` at `WlrLayer.Overlay`.
   * `reservedSpacerWindow` runs at `WlrLayer.Bottom` with static exclusive clearance.
   * `backdropWindow` runs at `WlrLayer.Top` for outside click dismissal.

## Affected Components
- `shell/shell.qml` - Add `reservedSpacerWindow` `PanelWindow` definition inside `screenScope`.
- `[[Shell-Root-PanelWindow]]` - Update documentation with the spacer window architecture.
