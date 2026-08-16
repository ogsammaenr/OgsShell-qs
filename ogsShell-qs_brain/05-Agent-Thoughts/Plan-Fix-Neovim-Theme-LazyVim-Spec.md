---
title: "Plan: Fix Neovim LazyVim Plugin Spec Theme Return and Live Reload"
type: agent-thought
tags:
  - theme/nvim
  - lazyvim/spec
  - bugfix
  - adapters
  - live-reload
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[System-Architecture]]"
  - "[[Configuration-Themes-Spec]]"
---

# Plan: Fix Neovim LazyVim Plugin Spec Theme Return and Live Reload

> [!NOTE]
> Neovim's `lazy.nvim` / `LazyVim` startup overrides top-level `nvim_set_hl` highlights with its default `colorscheme` option unless integrated via the LazyVim `opts.colorscheme` hook function. Additionally, `NvimAdapter` now dynamically broadcasts live `luafile` reload commands to active Neovim Unix sockets across `$XDG_RUNTIME_DIR/nvim.*`.

## Problem Statement

1. **Lazy.nvim Spec Requirement & LazyVim Override:** When `theme.lua` merely returned `{}` or `nil`, LazyVim's initialization process subsequently invoked `vim.cmd.colorscheme("tokyonight")` upon startup, overriding all custom `nvim_set_hl` color definitions.
2. **Missing Live Socket Reload:** The Go `NvimAdapter` (`core/services/theme/adapters/nvim.go`) previously copied the file but lacked live socket notification for currently active Neovim instances.

## Solution Implemented

1. **LazyVim Integration in Lua Templates (`shared/app_configs/nvim/`):**
   Wrapped color definitions inside `apply_theme()` and exported LazyVim's `colorscheme` hook:
   ```lua
   apply_theme()
   return {
     {
       "LazyVim/LazyVim",
       opts = {
         colorscheme = function()
           apply_theme()
         end,
       },
     },
   }
   ```
2. **Real-time Session Reload in `NvimAdapter` (`core/services/theme/adapters/nvim.go`):**
   Added socket discovery over `$XDG_RUNTIME_DIR/nvim.*` and `/tmp/nvim.*/*` with automated `nvim --server <sock> --remote-send "<Cmd>luafile <path><CR>"` dispatch.
3. **End-to-End Verification:**
   - Switched between `nord`, `catppuccin`, `everforest`, and `tokyonight` over the IPC Unix domain socket (`ogs_shell.sock`).
   - Verified that `theme.lua` is updated, live sessions reload, and fresh Neovim instances initialize with the chosen theme without any error or color fallback.
