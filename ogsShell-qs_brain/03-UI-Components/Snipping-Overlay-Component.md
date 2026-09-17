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
---

# Snipping Overlay Component

The Snipping Overlay is a dedicated Wayland `Overlay` layer (`PanelWindow`) providing zero-latency frozen desktop captures, single-gesture freeform region selection, smart `Ctrl`-driven Hyprland window snapping, and seamless mode switching between Screenshot, OCR, and Video Recording.

---

## 1. Wayland LayerShell & Screen Freeze Architecture

* **File Location:** `shell/components/capture/SnippingOverlay.qml`
* **Layer Shell Configuration:**
  * `WlrLayershell.layer: WlrLayer.Overlay`
  * `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive`
  * `anchors.fill: parent`
* **Screen Freeze Substrate:**
  * Displays the background image `file:///tmp/ogs_freeze.png` immediately upon invocation.
  * Freezes live desktop rendering (videos, animations, moving windows) so the user selects a stable frame.
  * Overlays a 35% dark dimming tint across unselected areas.

---

## 2. Interactive Selection & Controls

### A. Top Notch Mode Selector Capsule
* Positioned at the top center of the screen with Catppuccin styling:
  1. 📸 **SS (Ekran Görüntüsü):** Full or cropped area screenshot committed to disk and system clipboard.
  2. 🔍 **OCR (Metin Tanıma):** Extracts textual content via Tesseract `tur+eng` and copies to clipboard.
  3. 🎥 **Kayıt (Video):** Starts `wf-recorder` for the selected region.
* **Single-Gesture Fadeout:** Fades smoothly (`opacity: 0.0`) the exact millisecond the user presses the mouse to begin drawing, preventing UI occlusion over the captured content.

### B. Single Gesture Region Selection
* Mouse press (`onPressed`) establishes the origin point.
* Dragging (`onPositionChanged`) renders a cut-out illuminated aperture with a Catppuccin accent glowing border (`Style.accent` / `#89b4fa`).
* Dimension badge displays real-time pixel geometry (`W x H`).
* Mouse release (`onReleased`) finalizes the bounding box, dispatches the action via `[[Daemon-IPC-Client]]`, and closes the overlay.

### C. Smart Hyprland Window Snapping (`Ctrl` key)
* Holding `Ctrl` while moving the cursor inspects active `Hyprland.toplevels`.
* Automatically identifies the window under the pointer, computing its local bounds from `win.lastIpcObject.at` and `win.lastIpcObject.size`.
* Highlights the snapped window boundary; clicking while `Ctrl` is held immediately captures that window's exact geometry.

### D. Keyboard Navigation
* `Escape`: Cancels snipping and dismisses the overlay with zero action.

---

## 3. IPC Actions Triggered

* `DaemonIPC.captureScreenshot(geometry)`: In `"SS"` mode.
* `DaemonIPC.captureOCR(geometry)`: In `"OCR"` mode.
* `DaemonIPC.startRecording(geometry)`: In `"RECORD"` mode.

---

## 4. Related Links

* Backend Capture Engine: `[[Capture-Service]]`
* Frontend IPC Singleton: `[[Daemon-IPC-Client]]`
* Root Window Layout: `[[Shell-Root-PanelWindow]]`
* Design Tokens: `[[Style-Design-Tokens]]`
