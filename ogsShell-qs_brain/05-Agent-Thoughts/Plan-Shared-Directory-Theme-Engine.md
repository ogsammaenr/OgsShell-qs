---
title: "Proposal: Shared Directory File-Based Theme Engine Architecture"
type: agent-thought
tags:
  - proposal/shared-theme-engine
  - go/daemon
  - shared/themes
  - shared/app_configs
  - quickshell/qml
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[IPC-Socket-Schema]]"
  - "[[System-Architecture]]"
---

# Proposal: Shared Directory File-Based Theme Engine Architecture

> [!IDEA]
> Anchoring the Go daemon theme subsystem directly to the repository's `shared/` directory establishes a single source of truth for both the 6 core themes (`shared/themes/themes.json`) and pre-built multi-app configuration files (`shared/app_configs/`).

## Problem Statement

Previously, theme palettes and multi-app template generation were hardcoded inside Go structs with extraneous/inconsistent theme variants. This created discrepancies between the shell themes and external app configs, slower maintenance, and template parsing overhead.

## Architecture & Implementation Strategy

1. **Strict 6 Theme Set:**
   - Exclusively load themes defined in `shared/themes/themes.json`:
     - `nord`
     - `catppuccin`
     - `everforest`
     - `tokyonight`
     - `gruvbox`
     - `monochrome`
2. **File-Based Multi-App Dispatcher:**
   - For each supported application, read pre-rendered configuration assets from `shared/app_configs/<app>/<theme_id>.<ext>` and write directly to the user's config target path (`kitty`, `zed`, `nvim`, `vesktop`, `dolphin`, `gtk`, `qt`, `btop`, `tmux`, `hyprland`).
3. **High-Performance Async Engine:**
   - In-memory instantaneous active theme update and IPC event broadcasting (<0.1ms).
   - 50ms coalescing debounce channel to prevent command floods during rapid theme clicking.
4. **Frontend Synchronization:**
   - Synchronize `ThemesView.qml` and `DaemonIPC.qml` with the exact 6 themes and strict ID matching.
