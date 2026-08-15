---
title: "Clipboard History & Pinned Snippets Service (Go Daemon)"
type: service
tags:
  - clipboard/history
  - clipboard/pinned
  - wayland/cliphist
  - go/daemon
  - quickshell/drawer
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

# Clipboard History & Pinned Snippets Service

Go daemon subsystem responsible for Wayland clipboard history management, `cliphist` integration, live clipboard event watching, and persistent pinned/favorite snippets storage.

## Core Features

1. **Wayland Integration:** Interfaces with `/usr/bin/cliphist` and `/usr/bin/wl-clipboard` (`wl-copy`, `wl-paste`) to capture, decode, and restore copied content.
2. **Pinned Favorites:** Bookmarks persistent snippets (commands, code blocks, templates) in `$XDG_CONFIG_HOME/ogsShell/clipboard_pinned.json` with atomic disk writes.
3. **Live Watcher:** Background routine detects clipboard modifications and broadcasts `clipboard_update` and `clipboard_item_copied` events in real-time.
4. **Text & Image Classification:** Automatically classifies items as `"text"` or `"image"`.

---

## Go Implementation Details

* **Source Path:** `core/services/clipboard/` (`types.go`, `storage.go`, `manager.go`)
* **Interface Contract:** `clipboard.ClipboardManager`
* **Concurrency:** Thread-safe state management with `sync.RWMutex`.

### Socket Event Broadcast Schemas

#### 1. `clipboard_update` Event
```json
{
  "type": "clipboard_update",
  "payload": [
    {
      "id": "7563",
      "preview": "const token = \"catppuccin-mocha\";",
      "type": "text",
      "is_pinned": false,
      "timestamp": 1786395000123
    }
  ]
}
```

#### 2. `clipboard_item_copied` Event
```json
{
  "type": "clipboard_item_copied",
  "payload": {
    "id": "7563",
    "preview": "const token = \"catppuccin-mocha\";",
    "type": "text"
  }
}
```

#### 3. `pinned_clipboard_update` Event
```json
{
  "type": "pinned_clipboard_update",
  "payload": [
    {
      "id": "pin_1",
      "content": "git commit -m 'feat: dynamic island'",
      "label": "Git Feat",
      "timestamp": 1786395000
    }
  ]
}
```

---

## Related Documentation

* Backend Endpoints Reference: `[[Backend-Endpoints-Reference]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* QML IPC Singleton: `[[Daemon-IPC-Client]]`
* Go Daemon: `[[Go-Daemon-Core]]`
