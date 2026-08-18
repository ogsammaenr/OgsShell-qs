---
title: "App Launcher Service (Go Daemon)"
type: service
tags:
  - launcher/search
  - xdg/desktop
  - fuzzy/scoring
  - process/runner
  - go/daemon
created: 2026-08-17
updated: 2026-08-17
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Go-Daemon-Core]]"
  - "[[Go-Coding-Style]]"
---

# App Launcher Service

Go daemon subsystem responsible for discovering, indexing, fuzzy searching, and executing desktop applications with sub-millisecond in-memory performance and real-time filesystem change monitoring.

## Core Features

1. **XDG Desktop Entry Parser (`parser.go`)**:
   - Discovers applications from `/usr/share/applications`, `~/.local/share/applications`, `/var/lib/flatpak/exports/share/applications`, and `~/.local/share/flatpak/exports/share/applications`.
   - Filters out `NoDisplay=true`, `Hidden=true`, and non-application entries.
   - Cleans XDG exec field codes (`%f`, `%F`, `%u`, `%U`, `%i`, `%c`, `%k`, etc.).
   - Derives acronyms from multi-word and CamelCase application names (e.g., `"GNU Image Manipulation Program"` $\to$ `"gimp"`, `"Visual Studio Code"` $\to$ `"vsc"`).
2. **Multi-Tier Weighted Scoring Engine (`matcher.go`)**:
   - **Exact Name Match (100 Pts)**: Case-insensitive exact name equality.
   - **Name Prefix Match (90 Pts)** & **Word Prefix Match (88 Pts)**.
   - **Acronym & Exec Match (85 Pts)**: Matches acronym or base binary name (e.g. `"gimp"`, `"code"`).
   - **Generic Name & Category Match (70 Pts)**: Matches category or generic term (e.g. `"editor"` $\to$ `"Zed"`, `"Vim"`).
   - **Keywords Substring Match (50 Pts)**.
   - **Typo / Fuzzy Tolerant Match (10–45 Pts)**: Zero-allocation Damerau-Levenshtein distance algorithm handling transpositions (`"vscdoe"`), deletions (`"firfox"`), and insertions (`"spotfiy"`).
   - **Frecency / Launch Boost**: Adds up to +15 bonus points based on persistent launch frequency.
3. **Thread-Safe In-Memory Index (`indexer.go`)**:
   - Protected by `sync.RWMutex`.
   - Persists launch usage counters in `$XDG_CONFIG_HOME/ogsShell/launcher_stats.json`.
4. **High-Performance Icon Resolver & Cache (`icon_resolver.go`)**:
   - Scans system and user icon directories (`~/.local/share/icons`, `~/.icons`, `/usr/share/pixmaps`, `/usr/share/icons`, Flatpak export paths).
   - Maps raw icon keys to absolute file paths (`.svg`, `.png`), preventing Qt ImageProvider warning logs.
   - Genuinely missing icons safely resolve to empty string, activating the Hyprland vector SVG fallback in QML.
5. **Real-Time Directory Watcher (`watcher.go`)**:
   - `fsnotify` directory watcher with a 150ms `time.Timer` debouncing mechanism to handle package manager batch installations.
6. **Detached Process Execution (`runner.go`)**:
   - Spawns apps via `systemd-run --user --scope` on Arch Linux Wayland systems for cgroup isolation.
   - Falls back to `syscall.SysProcAttr{Setsid: true}` detached processes.

---

## Go Implementation Details

* **Source Path:** `core/services/launcher/` (`entry/types.go`, `parser.go`, `icon_resolver.go`, `matcher.go`, `indexer.go`, `watcher.go`, `runner.go`, `manager.go`, `launcher_test.go`)
* **Interface Contract:** `launcher.LauncherManager`

### Socket Event Broadcast & RPC Schemas

#### 1. `search_apps` RPC Action
```json
{
  "name": "search_apps",
  "args": {
    "query": "gimp",
    "limit": 15
  }
}
```

#### 2. `app_search_results` Event
```json
{
  "type": "app_search_results",
  "payload": {
    "query": "gimp",
    "results": [
      {
        "id": "org.gimp.GIMP.desktop",
        "name": "GNU Image Manipulation Program",
        "generic_name": "Image Editor",
        "exec": "gimp-2.10",
        "exec_binary": "gimp-2.10",
        "icon": "gimp",
        "categories": ["Graphics", "RasterEditor"],
        "keywords": ["photo", "paint", "edit"],
        "acronym": "gimp",
        "launch_count": 12,
        "score": 100
      }
    ],
    "total": 1
  }
}
```

#### 3. `launch_app` RPC Action
```json
{
  "name": "launch_app",
  "args": {
    "id": "org.gimp.GIMP.desktop"
  }
}
```

#### 4. `app_launched` Event
```json
{
  "type": "app_launched",
  "payload": {
    "id": "org.gimp.GIMP.desktop",
    "name": "GNU Image Manipulation Program",
    "success": true
  }
}
```

---

## Related Documentation

* Architecture: `[[System-Architecture]]`
* Backend Endpoints: `[[Backend-Endpoints-Reference]]`
* IPC Socket Protocol: `[[IPC-Socket-Schema]]`
* Thought Log: `[[Plan-Intelligent-App-Launcher-Service]]`
* Daemon Core: `[[Go-Daemon-Core]]`
