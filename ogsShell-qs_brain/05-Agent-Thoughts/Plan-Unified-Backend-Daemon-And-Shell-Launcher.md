---
title: "Proposal: Unified Backend Daemon & Shell Launcher Script (make run-shell)"
type: agent-thought
tags:
  - proposal/feature
  - backend/ipc
  - build/makefile
  - quickshell/launcher
  - automation
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Shell-Root-PanelWindow]]"
---

# Proposal: Unified Backend Daemon & Shell Launcher Script (make run-shell)

> [!IDEA]
> Implement a unified startup and lifecycle management mechanism that coordinates building and launching the Go daemon (`ogsshell-core`), waiting for the Unix domain socket (`$XDG_RUNTIME_DIR/ogs_shell.sock`), and starting Quickshell frontend with graceful SIGINT/SIGTERM process cleanup, executed via `make run-shell`.

## 1. Problem Statement
1. Currently, running `make run-shell` or `./shell/reload.sh` only launches Quickshell without starting the Go backend daemon `ogsshell-core`.
2. Without the daemon running, the Unix domain socket is inactive and `DaemonIPC.qml` cannot communicate with backend services (alarms, calendar events, network telemetry).
3. `DaemonIPC.qml` attempted to fetch initial state during `Component.onCompleted` before the socket connection was fully established, causing initial sync payloads to be dropped.
4. `Makefile` had an outdated build path for `core` (`./cmd/ogsshell-core` instead of `.`).

## 2. Proposed Solution
1. **Unified Launch Script (`scripts/run_shell.sh`):**
   - Automatically builds `bin/ogsshell-core` if missing or outdated.
   - Cleans up stale sockets and conflicting notification daemons.
   - Starts `bin/ogsshell-core` in background and waits for `$XDG_RUNTIME_DIR/ogs_shell.sock` to be ready.
   - Launches `quickshell -p shell/`.
   - Traps exit signals to gracefully terminate the background Go daemon when Quickshell exits.
2. **`Makefile` Targets:**
   - Fix `build-core`: `mkdir -p bin && cd core && go build -o ../bin/ogsshell-core .`
   - Update `run-shell`: builds core and executes `scripts/run_shell.sh`.
3. **`DaemonIPC.qml` Reactive Connection Sync:**
   - Listen to `onConnectedChanged` on the socket to immediately trigger initial synchronization queries as soon as the socket handshake completes.
