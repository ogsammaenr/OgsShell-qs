---
title: "Screen Corners UI Component"
type: ui-component
tags:
  - ui/screen-corners
  - quickshell/qml
  - wayland/layershell
  - dynamic-island/ui
created: 2026-09-06
updated: 2026-09-06
status: active
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
  - "[[Plan-Screen-Rounded-Corners]]"
---

# Screen Corners UI Component (`shell/components/corners/ScreenCorners.qml`)

> [!NOTE]
> `ScreenCorners.qml` renders hardware-like, anti-aliased black rounded concave corner cutouts on all 4 corners of connected displays to soften rectangular display edges.

---

## 1. Overview & Architecture

* **Wayland Layer:** `PanelWindow` hosted on `WlrLayer.Overlay` with `exclusionMode: ExclusionMode.Ignore`.
* **Zero Click-Blocking (`mask: Region {}`):** Configured with an empty Wayland input region so that all mouse clicks, drag events, and scrolling pass 100% transparently to underlying tiling and floating applications.
* **Hardware Anti-Aliasing:** Uses `QtQuick.Shapes` vector paths with `layer.samples: 4` and `layer.smooth: true` to prevent pixelation on high-DPI displays.
* **Per-Corner Granularity:** Supports toggling individual corners (`topLeft`, `topRight`, `bottomLeft`, `bottomRight`).
* **Top-Left Dynamic Morphing HUD:** Sol-üst köşede statik kavis yerine `CornerIslandHUD` barındırır.
* **Per-Monitor Workspace Isolation:** Her ekranda `hyprMonitor.activeWorkspace.id` ve o ekrana ait `monitorWorkspaces` listesini dinler; ekranlar arası odak/fare geçişlerinde yanlış tetikleme oluşmasını engeller.

---

## 2. Config Schema Properties (`config.json`)

```json
"screen_corners": {
  "enabled": true,
  "radius": 14,
  "color": "#000000",
  "top_left": true,
  "top_right": true,
  "bottom_left": true,
  "bottom_right": true
}
```

---

## 3. Related Links

* Config Engine Spec: `[[Configuration-System-Spec]]`
* Shell Root Window: `[[Shell-Root-PanelWindow]]`
* Proposal Plan: `[[Plan-Screen-Rounded-Corners]]`
