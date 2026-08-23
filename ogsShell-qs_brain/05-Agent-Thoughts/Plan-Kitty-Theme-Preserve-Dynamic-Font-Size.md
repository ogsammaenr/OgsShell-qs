---
title: "Proposal: Preserve Kitty Dynamic Font Size During Theme Transitions"
type: agent-thought
tags:
  - proposal/kitty-font-preservation
  - go/daemon
  - adapters/kitty
  - styling/theme
created: 2026-08-22
updated: 2026-08-22
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Configuration-Themes-Spec]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
  - "[[Plan-Fix-Kitty-Theme-Adapter-Timeout]]"
---

# Proposal: Preserve Kitty Dynamic Font Size During Theme Transitions

> [!IDEA]
> Switching Kitty themes dynamically via `kitten @ set-colors --all --configured` over Unix domain sockets rather than triggering full configuration reloads (`SIGUSR1` / `touch kitty.conf`) completely preserves runtime font scale changes made via `Ctrl+Shift++/-`.

## Problem Statement

When users zoom in or out in Kitty terminal using `Ctrl+Shift++` / `Ctrl+Shift+-` (Kitty's built-in `change_font_size` action), the font size change is stored in Kitty's runtime window memory.

During an `ogsShell` theme transition:
1. `KittyAdapter` in `core/services/theme/adapters/kitty.go` copies the active palette to `~/.config/kitty/current-theme.conf`.
2. It executes `touch kitty.conf` and dispatches `pkill -SIGUSR1 -x kitty`.
3. In response to `SIGUSR1` and file timestamp changes, Kitty reloads its entire `kitty.conf` configuration.
4. During full config reload, Kitty re-evaluates the static `font_size` (e.g. `11`) directive in `kitty.conf` and resets all active windows' font sizes back to default, discarding user font zoom adjustments.

## Proposed Solution

1. **Remote Control Socket Theme Updates:**
   - Enable `allow_remote_control yes` and `listen_on unix:/tmp/kitty` in Kitty configuration (`~/.config/kitty/kitty.conf`).
   - In `KittyAdapter.Apply()`:
     - Persist the theme colors into `~/.config/kitty/current-theme.conf` for persistent restarts and future windows.
     - Discover active Kitty control sockets matching `/tmp/kitty*` and `$XDG_RUNTIME_DIR/kitty*`.
     - For each socket, dispatch `kitten @ --to unix:<socket_path> set-colors --all --configured <theme_file>` with a 200ms timeout.
     - Eliminate `touch kitty.conf`.
     - Only if no remote sockets exist / succeed, fallback to `SIGUSR1`.

2. **Benefits:**
   - **Font Size Preservation:** In-memory font sizing modified via `Ctrl+Shift++/-` is completely retained.
   - **Zero Window Flicker:** No full terminal layout re-initialization.
   - **Sub-Millisecond Speed:** Direct socket communication executes in `<1ms`.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/adapters/kitty.go`)
- `~/.config/kitty/kitty.conf`
- `core/services/theme/adapters/kitty_test.go`
