---
title: "Plan: Screen Rounded Corners and Zero-Click-Blocking Overlay"
type: agent-thought
tags:
  - plan/screen-corners
  - quickshell/qml
  - wayland/layershell
  - config/schema
created: 2026-09-06
updated: 2026-09-06
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Screen-Corners-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Screen Rounded Corners and Zero-Click-Blocking Overlay

> [!IDEA]
> Adding a subtle, hardware-like black rounded bezel to all 4 screen corners softens display sharpness without interfering with window layouts, tiling, or application click events.

## Problem Statement
Standard computer monitors have sharp 90-degree corners. Adding a soft, configurable black rounding cutout improves visual aesthetics and OLED/Retina feel, but it must be completely transparent to mouse clicks (`mask: Region {}`) and hot-reloadable from `config.json`.

## Implementation Strategy
1. **Config Engine (`Config.qml` & JSON schemas):**
   - Add `"screen_corners"` with `enabled`, `radius`, `color`, `top_left`, `top_right`, `bottom_left`, `bottom_right`.
2. **QML Component (`ScreenCorners.qml`):**
   - Create 4 concave `Shape` vector paths with 4x MSAA anti-aliasing.
3. **Wayland LayerShell Window (`shell.qml`):**
   - Dedicated per-screen `PanelWindow` on `WlrLayer.Overlay` with `exclusionMode: ExclusionMode.Ignore`, `WlrKeyboardInteractivity.None`, and `mask: Region {}`.
