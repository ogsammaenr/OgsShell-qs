---
title: "Plan: Instant Live Config Hot-Reload and Reactive Sync"
type: agent-thought
tags:
  - proposal/hot-reload
  - config/sync
  - quickshell/qml
  - architecture/reactive
created: 2026-08-28
updated: 2026-08-28
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[System-Architecture]]"
  - "[[Style-Design-Tokens]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
---

# Plan: Instant Live Config Hot-Reload and Reactive Sync

> [!IDEA]
> Replacing static `Quickshell.Io.FileView` with a low-latency event-driven inotify watcher process (`inotifywait`) backed by a dedicated disk reader and multi-target sync engine enables zero-delay live hot reloading when `shell/config.json` or `~/.config/ogsShell/config.json` is modified.

## 1. Problem Statement
1. `Quickshell.Io.FileView` retains cached memory on Linux and fails to emit `textChanged` signals when text editors save files via atomic rename (`tempfile` -> `rename()` changing inode).
2. Polling `FileView.text()` inside a timer returns stale startup content, preventing live visual updates when `shell/config.json` is edited.
3. Bidirectional synchronization between `shell/config.json`, `shared/app_configs/shell/config.json`, and `$XDG_CONFIG_HOME/ogsShell/config.json` was inactive during direct workspace edits.

## 2. Proposed Architecture & Solution

```mermaid
graph TD
    DISK_WS["shell/config.json"] -->|inotify event| WATCHER["inotifywait Process in Config.qml"]
    DISK_USR["~/.config/ogsShell/config.json"] -->|inotify event| WATCHER
    WATCHER -->|SplitParser trigger| READER["Disk Reader Process (cat)"]
    READER -->|onExited raw JSON| PARSER["loadConfigString()"]
    PARSER -->|configRevision++| REACTIVE["Reactive QML Bindings & Geometry"]
    PARSER -->|applyThemeById()| STYLE["Style.qml (Palette & Glass)"]
    PARSER -->|syncToUserConfig()| SYNC["Background Sync Engine"]
    REACTIVE --> ISLAND["DynamicIsland.qml (Notch / Island)"]
    REACTIVE --> SHELL["shell.qml (Spacers & Inputs)"]
    REACTIVE --> WIDGETS["Clock, Media, Connectivity, Pinned Widgets"]
```

1. **Active Real-Time inotify Watcher:**
   - Launch a persistent background `Quickshell.Io.Process` executing `inotifywait -m -e close_write,moved_to,modify --format "%w%f" <workspaceDir> <userConfigDir>`.
   - On write/modify/rename, trigger the disk reader immediately.
2. **Fresh Disk Reader Process:**
   - Read unbuffered content directly from the file via `cat <path>`.
   - Prevent stale caches and inode issues completely.
3. **Hash Tracking & Re-entrancy Protection:**
   - Compare SHA/content strings to avoid recursive write loops.
4. **Reactivity & Live Dispatch:**
   - Update `formFactor`, `theme`, `typography`, `island`, `notch`, `notifications`, `animation`.
   - Increment `configRevision` to trigger re-computation of `implicitWidth`, `implicitHeight`, vector Bézier paths, font pixel sizes, and window layers.
   - Synchronize across user config and shared configs.

## 3. Affected Components
- `[[Configuration-System-Spec]]` (`ogsShell-qs_brain/01-Architecture/Configuration-System-Spec.md`)
- `shell/backend/Config.qml`
- `shell/components/island/DynamicIsland.qml`
- `shell/shell.qml`
- `shell/theme/Style.qml`
