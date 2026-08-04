---
title: "Proposal: Centralize All Executable Binaries into Root bin/ Directory"
type: agent-thought
tags:
  - proposal/refactor
  - binaries/c
created: 2026-08-03
updated: 2026-08-03
status: implemented
related_notes:
  - "[[Architecture-Overview]]"
  - "[[Development-Rules]]"
  - "[[SystemStats-Service]]"
  - "[[Workspace-Service]]"
  - "[[ThemeSync-Service]]"
---

# Proposal: Centralize All Executable Binaries into Root bin/ Directory

> [!IDEA]
> Moving all compiled C daemons (`monitor`, `workspaces`, `app_launcher_helper`, `wallpaper_helper`, `theme_sync_helper`) and helper scripts (`audio_mixer_helper.py`, `bluetooth_helper.sh`) into a single `./bin/` directory in project root simplifies build management and cleans up the source tree.

## Problem Statement
Previously, binaries were scattered across `shell/`, `shell/services/`, and nested directories, making `make clean` and path resolution prone to breaking when files were reorganized.

## Executed Solution
1. Created root `./bin/` directory.
2. Updated `shell/Makefile` to set build output targets to `$(CURDIR)/../bin/`.
3. Updated `shell/reload.sh` to export `ROOT_DIR`.
4. Updated QML services to resolve binaries dynamically via `binDir` (`Quickshell.env("ROOT_DIR") + "/bin"`).
5. Updated `shell/services/theme_sync_helper.c` to locate root project directory from `bin/theme_sync_helper`.

## Verification Status
- `make -C shell` compiled all daemons into `./bin/` cleanly.
- Quickshell launched with 0 process warnings.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Development Rules: `[[Development-Rules]]`
- System Stats Service: `[[SystemStats-Service]]`
