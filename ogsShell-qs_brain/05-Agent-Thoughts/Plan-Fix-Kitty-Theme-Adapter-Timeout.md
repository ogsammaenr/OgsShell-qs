---
title: "Proposal: Fix 10-Second Kitty Adapter Timeout Lag"
type: agent-thought
tags:
  - proposal/kitty-timeout-fix
  - go/daemon
  - adapters/kitty
  - performance/latency
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Fix 10-Second Kitty Adapter Timeout Lag

> [!IDEA]
> Removing the blocking `kitty @ set-colors` remote-control invocation in `kitty.go` and relying exclusively on POSIX `SIGUSR1` signal reload eliminates a 10.03-second I/O socket timeout, achieving instant (<2ms) Kitty theme updates.

## Problem Statement

When theme changes were triggered, all adapters finished in <1ms except `kitty`, which stalled for 10 seconds waiting for `kitty @ set-colors` to timeout before logging success. This delayed consecutive theme selections in the background dispatcher queue.

## Proposed Solution

1. In `core/services/theme/adapters/kitty.go`:
   - Eliminate `kitty @ set-colors`.
   - Directly execute `pkill -SIGUSR1 kitty` after copying the theme file.
2. In `core/services/theme/manager.go`:
   - Safeguard each adapter execution with a 1-second timeout context.
