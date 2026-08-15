---
title: "Proposal: Complete Authentic KDE 6 .colors Format for Dolphin"
type: agent-thought
tags:
  - proposal/dolphin-kde6-colors
  - go/daemon
  - shared/app-configs
  - kde/color-schemes
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Proposal: Complete Authentic KDE 6 .colors Format for Dolphin

> [!IDEA]
> Upgrading all 6 theme configs in `shared/app_configs/dolphin/` to the complete 13-section KDE 6 `.colors` specification ensures Dolphin toolbars, breadcrumb paths, file selection hover states, sidebars, and tooltips render with pixel-perfect, consistent theme integration.

## Problem Statement

Existing Dolphin color scheme files were truncated (60 lines) and lacked `[Colors:Header]`, `[Colors:Tooltip]`, `[Colors:Complementary]`, `[ColorEffects:Disabled]`, `[ColorEffects:Inactive]`, and `DecorationFocus`/`DecorationHover` keys, causing incomplete styling in Dolphin 26.04.3.

## Proposed Solution

Rewrite all 6 `.kdeglobals` files in `shared/app_configs/dolphin/` (`nord`, `catppuccin`, `everforest`, `tokyonight`, `gruvbox`, `monochrome`) to contain all 13 standard KDE 6 UI sections.
