---
title: "Proposal: Unify Canonical Config Directory and Clean Up Obsolete Paths"
type: agent-thought
tags:
  - proposal/config-standardization
  - xdg/config
  - agent-rules/strict-paths
created: 2026-08-22
updated: 2026-08-22
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Theme-Service]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
  - "[[Agent-Workflow-Directives]]"
---

# Proposal: Unify Canonical Config Directory and Clean Up Obsolete Paths

> [!IDEA]
> Establishing a strict, enforced standard for the user configuration directory (`$XDG_CONFIG_HOME/ogsShell/`) across all Go services, Quickshell QML, and agent directives eliminates directory fragmentation (`ogs-shell`, `ogsshell`, `ogsShell`) and guarantees future AI agents follow consistent path casing.

## Problem Statement

Inspection of `~/.config/` revealed three separate configuration directories:
1. `~/.config/ogs-shell`: Obsolete symlink to a legacy Python/GTK dotfile repository from May 2026.
2. `~/.config/ogsshell`: Lowercase directory containing stale state files, outdated themes, and `wallpaper_state.json` created due to an inconsistent path in `WallpaperAdapter`.
3. `~/.config/ogsShell`: Canonical directory used by all core Go services (`alarms.json`, `calendar_events.json`, `theme_config.json`, `notifications.json`, `keyboard_config.json`, `launcher_stats.json`).

## Proposed Solution

1. **Codebase Standardization:**
   - Fix `core/services/theme/adapters/wallpaper.go` to use `$XDG_CONFIG_HOME/ogsShell/wallpaper_state.json`.
   - Update `shell/backend/Config.qml` to resolve `$XDG_CONFIG_HOME/ogsShell/config.json` with fallback to `~/.config/ogsShell/config.json`.

2. **Filesystem Migration & Cleanup:**
   - Merge `wallpaper_state.json` and `config.json` into `~/.config/ogsShell/`.
   - Remove obsolete symlink `~/.config/ogs-shell`.
   - Remove obsolete duplicate directory `~/.config/ogsshell`.

3. **Agent Rules Enforcement (`.agents/AGENTS.md`):**
   - Add explicit directive section defining the canonical directory name (`$XDG_CONFIG_HOME/ogsShell/`) and prohibiting any variation (`ogsshell`, `ogs-shell`).

## Affected Components

- `core/services/theme/adapters/wallpaper.go`
- `shell/backend/Config.qml`
- `~/.config/` filesystem
- `.agents/AGENTS.md`
- `.agents/ARCHITECTURE.md`
- `ogsShell-qs_brain/01-Architecture/Configuration-System-Spec.md`
