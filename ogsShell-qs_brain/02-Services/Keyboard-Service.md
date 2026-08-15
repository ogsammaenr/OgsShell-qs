---
title: "Keyboard Layout Manager & Hyprland Event Listener Service (Go Daemon)"
type: service
tags:
  - keyboard/layout
  - hyprland/ipc
  - xkb/database
  - go/daemon
  - quickshell/hud
created: 2026-08-11
updated: 2026-08-11
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Go-Daemon-Core]]"
---

# Keyboard Layout Manager & Hyprland Event Listener Service

Go daemon subsystem responsible for Wayland / Hyprland keyboard layout inspection, instant switching (`hyprctl switchxkblayout`), dynamic layout set configuration, persistent preferences, and zero-latency Compositor event monitoring.

## Core Features

1. **Live Hyprland Socket Listener:** Connects to `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock` and captures `activelayout>>` events when hotkeys (`Super+Space` or `Alt+Shift`) are pressed.
2. **Instant Layout Switching:** Dispatches `hyprctl switchxkblayout all <target>` to synchronously update all physical and virtual input devices.
3. **XKB Layout Database:** Parses `/usr/share/X11/xkb/rules/evdev.lst` (cached in-memory) to provide localized language names (e.g. `tr` -> "Turkish", `us` -> "English (US)").
4. **Smart Shortcode Badges:** Computes 2-letter uppercase badges (`TR`, `EN`, `DE`, `FR`, `RU`, `JP`, etc.) for clean HUD rendering.
5. **Config Persistence:** Saves user-defined layout lists to `$XDG_CONFIG_HOME/ogsShell/keyboard_config.json`.

---

## Go Implementation Details

* **Source Path:** `core/services/keyboard/` (`types.go`, `storage.go`, `xkb_parser.go`, `manager.go`)
* **Interface Contract:** `keyboard.KeyboardManager`
* **Concurrency:** Thread-safe state management with `sync.RWMutex`.

### Socket Event Broadcast Schemas

#### 1. `keyboard_layout_update` Event
```json
{
  "type": "keyboard_layout_update",
  "payload": {
    "device_name": "keyd-virtual-keyboard",
    "current_layout_index": 0,
    "current_keymap": "Turkish (Alt-Q)",
    "current_short_code": "TR",
    "current_layout_code": "tr",
    "configured_layouts": ["tr", "us"],
    "configured_variants": ["alt", ""]
  }
}
```

#### 2. `available_layouts_data` Event
```json
{
  "type": "available_layouts_data",
  "payload": [
    { "code": "tr", "description": "Turkish" },
    { "code": "us", "description": "English (US)" },
    { "code": "de", "description": "German" }
  ]
}
```

---

## Related Documentation

* Backend Endpoints Reference: `[[Backend-Endpoints-Reference]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* QML IPC Singleton: `[[Daemon-IPC-Client]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Go Daemon: `[[Go-Daemon-Core]]`
