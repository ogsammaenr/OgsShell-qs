---
title: "Snipping Overlay Component"
type: ui-component
tags:
  - quickshell/qml
  - capture/snipping
  - wayland/layershell
  - hyprland/snapping
  - ui/overlay
created: 2026-09-16
updated: 2026-09-16
status: active
related_notes:
  - "[[Capture-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
  - "[[Dynamic-Island-Component]]"
---

# Snipping Overlay Component

> [!NOTE]
> `shell/components/capture/SnippingOverlay.qml` provides a dedicated Wayland `Overlay` layer (`PanelWindow`) with zero-latency frozen desktop captures (`/tmp/ogs_freeze.png`), single-gesture freeform region selection, smart `Ctrl`-driven Hyprland window snapping, and seamless mode switching between Screenshot, OCR, and Video Recording.

---

## 1. Wayland LayerShell & Multi-Monitor Screen Freeze Architecture

* **File Location:** `shell/components/capture/SnippingOverlay.qml`
* **Layer Shell Configuration:**
  * `WlrLayershell.layer: WlrLayer.Overlay`
  * `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` (Allows simultaneous, non-blocking pointer & click events across all connected monitors)
  * `anchors.fill: parent`
* **Multi-Monitor Screen Freeze Substrate:**
  * Instantiated per-monitor via `Quickshell.screens` variants.
  * Displays per-monitor uncompressed freeze frames: `file:///tmp/ogs_freeze_<monitorName>.png`.
  * Virtual coordinates (`monitorGlobalX`, `monitorGlobalY`) dynamically synchronized via `[[SnippingService]]` and authoritative `hyprctl monitors -j` geometries.
  * Freezes live desktop rendering (videos, animations, moving windows) so the user selects a stable frame.
  * Overlays a 35% dark dimming tint across unselected areas via a 4-rectangle matte.

---

## 2. Interactive Selection & Controls

### A. Shell-Integrated Dynamic Capture HUD (`captureIslandHud`)
* Seamlessly adopts the shell's active form factor and OLED design language (`[[Dynamic-Island-Component]]`):
  * **Dynamic Notch Mode (`Config.isNotch`):** Anchored flush to the screen bezel (`y: 0`) with smooth cubic Bézier drape slopes (`notchEarW: 5, notchEarH: 16`), 4x MSAA anti-aliased OLED black silhouette, and elevation glow shadow.
  * **Dynamic Island Mode (`!Config.isNotch`):** Floating squircle pill at `Config.islandTopMargin` (8px) with dual elevation drop shadow.
* Integrated Capture Actions:
  1. 📸 **Bölge (SS):** Region snipping with dimension overlay; saves to disk & clipboard.
  2. 🔍 **OCR:** Multi-language text recognition via Tesseract `tur+eng`.
  3. 🎥 **Kayıt:** Video screen recording via `wf-recorder`.
  4. 🖥️ **Tam Ekran:** 1-click instantaneous full screen capture of the focused monitor.
  5. ✕ **İptal:** Dismisses capture mode immediately (`SnippingService.close()`).
* **Keyboard Hints:** Integrated subtitle badge displaying `Sürükle: Seçim  •  Ctrl: Pencereye Yapış  •  esc: İptal`.
* **Single-Gesture Fadeout:** Fades smoothly (`opacity: 0.0`) the exact millisecond the user presses the mouse to begin drawing (`isSelecting == true`), preventing UI occlusion over the captured content.

### B. Single Gesture Region Selection
* Mouse press (`onPressed`) establishes the origin point.
* Dragging (`onPositionChanged`) renders a cut-out illuminated aperture with a Catppuccin accent glowing border (`Style.accent` / `#89b4fa`).
* Dimension badge displays real-time pixel geometry (`W x H`).
* Mouse release (`onReleased`) finalizes the bounding box, dispatches the action via `[[Daemon-IPC-Client]]`, and closes the overlay.

### C. Smart Hyprland Window Snapping (`Ctrl` key)
* Holding `Ctrl` while moving the cursor inspects active `Hyprland.toplevels`.
* Automatically identifies the window under the pointer, computing its local bounds from `win.lastIpcObject.at` and `win.lastIpcObject.size`.
* Highlights the snapped window boundary; clicking while `Ctrl` is held immediately captures that window's exact geometry.

### D. Keyboard & Mouse Navigation
* `Right-Click`:
  * If actively drawing or with an active box: Immediately aborts the current selection, restores full dimming, and reveals the capture HUD without capturing.
  * If idle (no active selection): Closes and dismisses the snipping overlay completely.
* `Escape`: Cancels snipping and dismisses the overlay with zero action.

---

## 3. IPC Actions Triggered

* `DaemonIPC.captureScreenshot(geometry)`: In `"SS"` mode.
* `DaemonIPC.captureOCR(geometry)`: In `"OCR"` mode.
* `DaemonIPC.startRecording(geometry)`: In `"RECORD"` mode.

---

## 4. CLI & Keybinding Integration

* `ogsshell screenshot --region`: Opens overlay in `"SS"` mode (`$mainMod SHIFT, S`).
* `ogsshell ocr --region`: Opens overlay in `"OCR"` mode (`$mainMod SHIFT, O`).
* `ogsshell record --toggle`: Toggles recording (`$mainMod ALT, R`).

---

## 5. Related Links

* Backend Capture Engine: `[[Capture-Service]]`
* Frontend IPC Singleton: `[[Daemon-IPC-Client]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Root Window Layout: `[[Shell-Root-PanelWindow]]`
* Design Tokens: `[[Style-Design-Tokens]]`
