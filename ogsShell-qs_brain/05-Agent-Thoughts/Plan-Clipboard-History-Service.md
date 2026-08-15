---
title: "Proposal: Persistent Wayland Clipboard History & Pinned Snippets Service"
type: agent-thought
tags:
  - proposal/clipboard
  - backend/clipboard
  - wayland/cliphist
  - quickshell/drawer
created: 2026-08-11
updated: 2026-08-11
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Clipboard-Service]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Dynamic-Island-Component]]"
---

# Proposal: Persistent Wayland Clipboard History & Pinned Snippets Service

> [!IDEA]
> Implementing a native Wayland Clipboard History subsystem in the Go daemon (`core/services/clipboard/`) that interfaces with `cliphist` and `wl-clipboard`, provides pinned/favorite snippets storage (`$XDG_CONFIG_HOME/ogsShell/clipboard_pinned.json`), and streams real-time updates over Unix Domain Socket NDJSON to Quickshell QML.

## Problem Statement
Users frequently need to search, restore, and pin previously copied snippets (code blocks, links, passwords, terminal output). While `cliphist` runs as a CLI backend on Wayland, Quickshell currently has no dedicated IPC interface to query history, pin favorite items, or copy items back to the active clipboard without launching external blocking shell commands in QML.

## Proposed Solution
1. **Go Backend Subsystem (`core/services/clipboard/`)**:
   - `types.go`: Data models for `ClipboardItem`, `PinnedItem`, `ClipboardUpdatePayload`, `CopyClipboardPayload`, etc.
   - `storage.go`: Persistent JSON storage for pinned/favorite snippets in `$XDG_CONFIG_HOME/ogsShell/clipboard_pinned.json`.
   - `manager.go`: Seamless integration with `cliphist list`, `cliphist decode`, `cliphist delete`, `cliphist wipe`, and `wl-copy`.
   - Background watcher: Real-time clipboard change detection using `wl-paste --watch` to broadcast `clipboard_update` events whenever new text is copied.
   - Comprehensive unit tests in `clipboard_test.go`.
2. **IPC Wiring (`core/main.go`)**:
   - Actions: `get_clipboard_history`, `copy_clipboard_item`, `get_clipboard_content`, `delete_clipboard_item`, `clear_clipboard_history`, `pin_clipboard_item`, `unpin_clipboard_item`, `get_pinned_clipboard_items`.
   - Events: `clipboard_update`, `clipboard_item_copied`, `pinned_clipboard_update`.
3. **Quickshell Frontend Integration (`shell/backend/DaemonIPC.qml`)**:
   - Helper methods: `copyClipboardItem(id)`, `pinClipboardItem(id, label)`, `deleteClipboardItem(id)`, `clearClipboardHistory()`.
   - Reactive properties: `property var clipboardHistory: []`, `property var pinnedClipboardItems: []`.

## Affected Components
- `core/services/clipboard/` (New package: `types.go`, `storage.go`, `manager.go`, `clipboard_test.go`)
- `core/main.go` (Initialization, action handlers, event broadcasts)
- `shell/backend/DaemonIPC.qml` (QML helper functions and event parsing)
- `.agents/BACKEND_ENDPOINTS.md` & `ogsShell-qs_brain/` (Documentation)
