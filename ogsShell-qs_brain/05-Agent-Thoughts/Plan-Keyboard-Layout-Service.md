---
title: "Proposal: Dynamic Keyboard Layout Manager & Hyprland IPC Listener Service"
type: agent-thought
tags:
  - proposal/keyboard
  - backend/keyboard
  - hyprland/ipc
  - xkb/layouts
  - quickshell/hud
created: 2026-08-11
updated: 2026-08-11
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Keyboard-Service]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Go-Daemon-Core]]"
---

# Proposal: Dynamic Keyboard Layout Manager & Hyprland IPC Listener Service

> [!IDEA]
> Implementing a native Wayland / Hyprland Keyboard Layout management subsystem in the Go daemon (`core/services/keyboard/`) that listens to Hyprland's `.socket2.sock` `activelayout>>` event stream, manages active/configured layouts via `hyprctl`, parses XKB layout catalogs, and broadcasts zero-latency layout updates to Quickshell QML.

## Problem Statement
Users need to inspect, toggle, and configure keyboard layouts (e.g. Turkish Q, English US, German) easily. In Hyprland, layouts are switched via `hyprctl switchxkblayout` or physical hotkeys (like `Super+Space`). Without a dedicated backend service, Quickshell cannot reactively receive layout change events when triggered from hardware shortcuts, nor can it query available system layouts without invoking external shell scripts.

## Proposed Solution
1. **Go Backend Subsystem (`core/services/keyboard/`)**:
   - `types.go`: Data structures for `KeyboardState`, `KeyboardDevice`, `AvailableLayout`, `SwitchLayoutPayload`, `SetConfiguredLayoutsPayload`.
   - `storage.go`: Persistent user preferences in `$XDG_CONFIG_HOME/ogsShell/keyboard_config.json`.
   - `xkb_parser.go`: Fast parser for `/usr/share/X11/xkb/rules/evdev.lst` (cached in-memory) to provide human-readable language names.
   - `manager.go`:
     - Real-time Hyprland event listener on `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock` watching for `activelayout>>`.
     - `hyprctl devices -j` JSON parser to deduce active layout, shortcode, and keymap.
     - `hyprctl switchxkblayout all [next|index]` executor.
     - `hyprctl keyword input:kb_layout` runtime updater.
   - `keyboard_test.go`: Unit tests for evdev parsing, hyprctl JSON decoding, and state synthesis.
2. **IPC Wiring (`core/main.go`)**:
   - Actions: `get_keyboard_layout`, `switch_keyboard_layout`, `set_configured_layouts`, `get_available_system_layouts`.
   - Events: `keyboard_layout_update`, `available_layouts_data`.
3. **Quickshell Frontend Integration (`shell/backend/DaemonIPC.qml`)**:
   - Reactive properties: `property var keyboardLayout: ({ "current_layout": "tr", "current_layout_name": "Turkish", "short_code": "TR", "layouts": [] })`.
   - Helper methods: `switchKeyboardLayout(target)`, `setConfiguredLayouts(layouts, variants)`, `requestKeyboardLayout()`, `requestAvailableLayouts()`.
   - Signal: `signal keyboardLayoutChanged(var payload)` for triggering Dynamic Island HUD badges.

## Affected Components
- `core/services/keyboard/` (`types.go`, `storage.go`, `xkb_parser.go`, `manager.go`, `keyboard_test.go`)
- `core/main.go`
- `shell/backend/DaemonIPC.qml`
- `.agents/BACKEND_ENDPOINTS.md` & `ogsShell-qs_brain/` (Documentation)
