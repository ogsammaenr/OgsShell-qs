---
title: "Screen Capture, OCR and Recording Service (Go Daemon)"
type: service
tags:
  - capture/screen
  - ocr/tesseract
  - record/wf-recorder
  - wayland/grim
  - go/daemon
created: 2026-09-16
updated: 2026-09-16
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Snipping-Overlay]]"
  - "[[Audio-Feedback-Service]]"
  - "[[Go-Daemon-Core]]"
---

# Screen Capture, OCR & Recording Service

Go daemon subsystem responsible for Wayland-native screen freezing, snipping, screenshot persistence, optical character recognition (OCR) with multi-language parsing, hardware-accelerated screen video recording, and external image annotation integration.

## Core Features

1. **Instant Multi-Monitor Screen Freeze (`freeze_screen`):**
   * Triggered immediately at the first millisecond of snipping mode activation BEFORE frontend overlay opens.
   * In multi-monitor setups (e.g., `eDP-1`, `HDMI-A-1`), executes `grim -l 0 -o <name> /tmp/ogs_freeze_<name>.png` in parallel via Go goroutines (~35ms).
   * Fallback copy to `/tmp/ogs_freeze.png`.
   * Queries `hyprctl monitors -j` to provide exact virtual coordinates (`x, y, width, height`) per monitor to the frontend.
   * Emits `screen_frozen` broadcast event containing `timestamp`, `mode`, and authoritative `monitors` list.

2. **Cropped & Fullscreen Screenshot (`capture_screenshot`):**
   * When snipping from the overlay (`monitor`, `local_x`, `local_y`, `width`, `height` provided), crops the sub-image directly from `/tmp/ogs_freeze_<monitor>.png` in ~3ms using Go's standard library `image/png`.
   * Direct image cropping guarantees 100% pixel-perfect output with **ZERO overlay artifacts** (no dimension badges, selection borders, dimming, or unmapping delay races).
   * For full screenshots (`ogsshell screenshot --full`), captures the focused monitor via `grim -o <focused_mon>` to prevent dual-screen stretching.
   * Automatically organizes and commits captures to `$HOME/Pictures/Screenshots/screenshot_YYYY-MM-DD_HH-mm-ss.png`.
   * Automatically pipes image data to the Wayland clipboard via `wl-copy --type image/png` in-memory.
   * Emits `screenshot_captured` broadcast event.

3. **Optical Character Recognition (`capture_ocr`):**
   * Crops directly from `/tmp/ogs_freeze_<monitor>.png` into `/tmp/ogs_ocr.png` (or falls back to `grim`).
   * Runs `tesseract /tmp/ogs_ocr.png stdout -l tur+eng` to extract multilingual text.
   * Copies the raw extracted text to the system clipboard via `wl-copy`.
   * Broadcasts `ocr_completed` with full text, character count, and truncated preview for the Dynamic Island HUD.

4. **Screen Recording Engine (`start_recording` / `stop_recording`):**
   * Launches `wf-recorder -g "<x,y wxh>" -f $HOME/Videos/Recordings/recording_YYYY-MM-DD_HH-mm-ss.mp4`.
   * Emits real-time 1-second elapsed duration ticks via `recording_state_update`.
   * Upon stopping, cleanly sends `syscall.SIGINT` to allow `wf-recorder` to finalize the MP4 container and write the moov atom header without file corruption.
   * Emits `recording_finished` broadcast event.

5. **Gradia External Annotator Integration (`open_annotator`):**
   * Launches `gradia <file_path>` in a detached session via `systemd-run --user --scope` with fallback to `Setsid`.
   * If no file path is specified, falls back to the most recent screenshot taken in the session.

---

## Go Implementation Details

* **Source Path:** `core/services/capture/` (`types.go`, `manager.go`)
* **Interface Contract:** `capture.CaptureManager`
* **Concurrency:** Thread-safe state management with `sync.RWMutex` protecting active recording process, ticker routines, and state transitions.

### RPC Action Specifications

| Action Name | Arguments (`args`) | Description |
| :--- | :--- | :--- |
| `freeze_screen` | `{}` | Captures instant full-screen freeze to `/tmp/ogs_freeze.png` |
| `capture_screenshot` | `{"geometry": "x,y wxh"}` | Captures geometry or full screen, saves to disk & copies to clipboard |
| `capture_ocr` | `{"geometry": "x,y wxh"}` | Captures geometry, extracts text via Tesseract & copies to clipboard |
| `start_recording` | `{"geometry": "x,y wxh"}` | Starts `wf-recorder` and initiates 1-second duration ticker |
| `stop_recording` | `{}` | Sends `SIGINT` to recording process and finalizes MP4 file |
| `toggle_recording` | `{"geometry": "x,y wxh"}` | Toggles active recording state (starts or cleanly stops) |
| `open_annotator` | `{"file_path": "..."}` | Launches Gradia editor with specified or latest screenshot |

---

### Socket Event Broadcast Schemas

#### 1. `screen_frozen` Event
```json
{
  "type": "screen_frozen",
  "payload": {
    "file_path": "/tmp/ogs_freeze.png",
    "timestamp": 1786395000123,
    "success": true
  }
}
```

#### 2. `screenshot_captured` Event
```json
{
  "type": "screenshot_captured",
  "payload": {
    "file_path": "/home/user/Pictures/Screenshots/screenshot_2026-09-16_17-30-00.png",
    "geometry": "100,100 800x600",
    "timestamp": 1786395000123,
    "copied": true,
    "success": true
  }
}
```

#### 3. `ocr_completed` Event
```json
{
  "type": "ocr_completed",
  "payload": {
    "text": "Antigravity Agentic AI Engine",
    "preview": "Antigravity Agentic AI Engine",
    "char_count": 29,
    "copied": true,
    "success": true
  }
}
```

#### 4. `recording_state_update` Event
```json
{
  "type": "recording_state_update",
  "payload": {
    "is_recording": true,
    "duration_seconds": 12,
    "file_path": "/home/user/Videos/Recordings/recording_2026-09-16_17-30-00.mp4",
    "geometry": "0,0 1920x1080"
  }
}
```

#### 5. `recording_finished` Event
```json
{
  "type": "recording_finished",
  "payload": {
    "file_path": "/home/user/Videos/Recordings/recording_2026-09-16_17-30-00.mp4",
    "duration_seconds": 45,
    "success": true
  }
}
```

---

## CLI Commands & Hyprland Shortcuts

### CLI Usage (`scripts/ogsshell.sh` / `ogsshell`)

* **Screenshot:** `ogsshell screenshot [--region | --full]`
  * `--region` (default): Freezes screen and opens interactive `[[Snipping-Overlay]]`.
  * `--full`: Captures instantaneous full-screen screenshot to disk and clipboard.
* **OCR:** `ogsshell ocr [--region]`
  * Opens `[[Snipping-Overlay]]` directly in OCR mode (`tur+eng` extraction).
* **Screen Recording:** `ogsshell record [--start | --stop | --toggle]`
  * `--toggle` (default): Toggles recording session on/off.
  * `--start`: Starts full-screen recording immediately.
  * `--stop`: Sends graceful `SIGINT` to finalize MP4 file and write moov atom.

### Hyprland Keybindings (`hyprland.conf`)

```conf
# Ekran dondurmalı Snipping UI (İnteraktif bölge seçimi)
bind = $mainMod SHIFT, S, exec, ogsshell screenshot --region

# Anında tam ekran görüntüsü al
bind = , Print, exec, ogsshell screenshot --full

# Doğrudan OCR modu (Bölgeden metin tanıma ve panoya kopyalama)
bind = $mainMod SHIFT, O, exec, ogsshell ocr --region

# Ekran kaydı başlat / bitir (Toggle video recording)
bind = $mainMod ALT, R, exec, ogsshell record --toggle
```

---

## Related Documentation

* Snipping Overlay Component: `[[Snipping-Overlay]]`
* Dynamic Island Component: `[[Dynamic-Island-Component]]`
* Audio Feedback Service: `[[Audio-Feedback-Service]]`

* Backend Endpoints Reference: `[[Backend-Endpoints-Reference]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* System Architecture: `[[System-Architecture]]`
* QML IPC Singleton: `[[Daemon-IPC-Client]]`
* Go Daemon: `[[Go-Daemon-Core]]`
