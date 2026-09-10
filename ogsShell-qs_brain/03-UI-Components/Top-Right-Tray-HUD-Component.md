---
title: "Top-Right Screen Corner System Tray HUD Component"
type: ui-component
tags:
  - ui/system-tray
  - ui/screen-corners
  - quickshell/qml
  - wayland/layershell
created: 2026-09-10
updated: 2026-09-10
status: active
related_notes:
  - "[[Screen-Corners-Component]]"
  - "[[Corner-Island-HUD-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Configuration-System-Spec]]"
  - "[[Plan-Top-Right-Corner-System-Tray-HUD]]"
---

# Top-Right Screen Corner System Tray HUD Component (`shell/components/corners/TopRightTrayHUD.qml`)

> [!NOTE]
> `TopRightTrayHUD.qml` embeds an interactive, expandable System Tray HUD into the top-right screen corner. It provides instant visibility into background daemon applications (Steam, Discord, Spotify, OBS, Telegram) with zero backend overhead.

---

## 1. Overview & Architecture

* **Wayland Layer & Surface:** Hosted in a dedicated `topRightTrayWindow` (`PanelWindow`) on `WlrLayer.Overlay` / `WlrLayer.Top` with `exclusionMode: ExclusionMode.Ignore`.
* **Precision Wayland Input Mask:** Uses a dynamic `Region` conforming strictly to `TopRightTrayHUD`'s visual footprint (24x24px when idle, or the exact capsule bounds when expanded). All other display areas remain 100% click-through for underlying tiling windows.
* **Dual Morphing Geometry:**
  - **IDLE State:** Inverted concave arc matching the 14px display corner cutout.
  - **EXPANDED State:** Liquid-morphed OLED black vector pill (`#000000`) with top-left concave ear, bottom-left convex corner radius (`14px`), and bottom-right concave ear connecting to the display's right bezel.
* **Native D-Bus Integration:** Directly connects to `Quickshell.Services.SystemTray` (`SystemTray.items`).

---

## 2. Interactions & Behavior

* **Left Click on Icon:** Calls `item.activate()` to restore/bring the application window to focus.
* **Right Click on Icon:** Calls `item.display()` / `item.secondaryActivate()` to open the native Linux D-Bus tray context menu (Quit, Settings, etc.).
* **Middle Click on Icon:** Triggers secondary action (`item.secondaryActivate()`).
* **Click Outside:** Fullscreen transparent `backdropWindow` dismisses and smoothly collapses the capsule back into the corner cutout.

---

## 3. Config Schema Properties (`config.json`)

```json
"corner_tray": {
  "enabled": true,
  "height": 34,
  "trigger_mode": "click",
  "timeout_ms": 0
}
```

---

## 4. Related Links

* Screen Corners: `[[Screen-Corners-Component]]`
* Corner Island HUD: `[[Corner-Island-HUD-Component]]`
* Shell Root: `[[Shell-Root-PanelWindow]]`
* Configuration Spec: `[[Configuration-System-Spec]]`
* Implementation Plan: `[[Plan-Top-Right-Corner-System-Tray-HUD]]`
