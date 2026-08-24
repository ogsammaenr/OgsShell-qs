---
title: "Plan: Rosé Pine Theme Integration for Vesktop Discord Client"
type: agent-thought
tags:
  - theme/rose-pine
  - chat/vesktop
  - chat/vencord
  - chat/discord
  - adapters/vesktop
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Plan-Rose-Pine-Theme-Integration]]"
  - "[[Plan-Fix-Vesktop-Theme-Sync]]"
  - "[[Plan-Fix-Vesktop-Inotify-Inode-Watch]]"
  - "[[System-Architecture]]"
---

# Plan: Rosé Pine Theme Integration for Vesktop Discord Client

> [!NOTE]
> Rosé Pine theme integration for Vesktop Discord client has been successfully implemented via `shared/app_configs/vesktop/rosepine.css` and deployed dynamically via `VesktopAdapter`.

## 1. Problem Statement
The user requested adding Rosé Pine theme support for **Vesktop** (Discord). In `ogsShell-qs`, Vesktop / Vencord theming is managed by `VesktopAdapter` (`core/services/theme/adapters/vesktop.go`), which deploys `.css` stylesheets in-place to `~/.config/vesktop/themes/ogsshell.theme.css` and `~/.config/vesktop/settings/quickCss.css`.

## 2. Color Mapping for Vesktop / Discord
Based on the official Rosé Pine design tokens:
* **Chat & Content Background:** `#191724` (Base)
* **Sidebar, Channel & Member List:** `#1f1d2e` (Surface)
* **Panels & Elements:** `#26233a` (Overlay)
* **Active Elements & Selected Items:** `#403d52` (Highlight Med)
* **Primary Text:** `#e0def4` (Text)
* **Muted / Subtext:** `#908caa` (Subtle) / `#6e6a86` (Muted)
* **Brand / Accent (Rose):** `#ebbcba`
* **Links & Mentions (Foam/Iris):** `#9ccfd8` / `#c4a7e7`
* **Status Badges & Positive:** `#31748f` (Pine)
* **Danger / Badges / Red:** `#eb6f92` (Love)

## 3. Implementation Steps & Verification

1. **Vesktop CSS Theme (`shared/app_configs/vesktop/rosepine.css`):**
   - Generated full 1,745-line Discord design system stylesheet with Rosé Pine token replacements and fallback overrides.

2. **Testing:**
   - Ran Go unit tests in `core/` with 100% pass rate.

