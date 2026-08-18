---
title: "Proposal: Intelligent In-Memory App Launcher Subsystem in Go"
type: agent-thought
tags:
  - proposal/launcher
  - backend/launcher
  - fuzzy/search
  - xdg/desktop
  - go/daemon
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[App-Launcher-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Go-Daemon-Core]]"
  - "[[Go-Coding-Style]]"
---

# Proposal: Intelligent In-Memory App Launcher Subsystem in Go

> [!IDEA]
> Implementing a high-performance, sub-millisecond in-memory App Launcher subsystem (`core/services/launcher/`) featuring XDG Desktop Entry parsing, multi-tier weighted scoring, typo tolerance (Damerau-Levenshtein fuzzy matching), acronym resolution, real-time `fsnotify` file system watching with 150ms debouncing, and detached process execution via `systemd-run` and POSIX session detachment.

## Problem Statement
A desktop shell requires an instantaneous application launcher that understands user intent even with spelling mistakes (e.g. "firfox" -> "Firefox", "vscdoe" -> "Visual Studio Code"), acronyms (e.g. "gimp" -> "GNU Image Manipulation Program"), and generic category terms (e.g. "editor" -> "Zed", "Vim", "Neovim"). Existing disk-based search or external CLI wrappers introduce latency (>10ms) and lack deep integration with the Quickshell Wayland overlay.

## Proposed Solution & Architecture

1. **Modular Package Hierarchy (`core/services/launcher/`)**:
   - `entry/types.go`: Rich `AppEntry` data model and IPC communication schemas.
   - `parser.go`: XDG Desktop Entry Specification (`.desktop`) parser with field-code sanitization (`%f`, `%u`, `%F`, `%U`, etc.), token aggregation, and acronym generation.
   - `matcher.go`: Multi-tiered weighted scoring engine with exact name (100), name prefix (90), acronym (85), generic/category (70), keywords (50), and typo/fuzzy tolerance (10-45) plus frecency boost.
   - `indexer.go`: In-memory thread-safe (`sync.RWMutex`) index with persistent launch statistics (`$XDG_CONFIG_HOME/ogsShell/launcher_stats.json`).
   - `watcher.go`: Real-time `fsnotify` directory watcher with 150ms debouncing timer.
   - `runner.go`: Non-blocking application launcher with `systemd-run --user --scope` and detached `Setsid` fallback.
   - `manager.go`: Root coordinator exposing IPC action handlers and event broadcasters.

2. **IPC Endpoints & Protocol**:
   - Actions: `search_apps`, `list_apps`, `launch_app`, `reindex_apps`
   - Events: `app_search_results`, `app_list_data`, `app_launched`

3. **Performance Target**:
   - Sub-millisecond (<0.5ms) in-memory linear search for 300+ desktop entries with zero heap allocation in the scoring hot path.

## Affected Components
- `core/services/launcher/`
  - `entry/types.go`
  - `parser.go`
  - `matcher.go`
  - `indexer.go`
  - `watcher.go`
  - `runner.go`
  - `manager.go`
  - `launcher_test.go`
- `core/main.go`
- `core/go.mod` & `core/go.sum`
- `.agents/BACKEND_ENDPOINTS.md`
- `.agents/ARCHITECTURE.md`
- `ogsShell-qs_brain/02-Services/App-Launcher-Service.md`
