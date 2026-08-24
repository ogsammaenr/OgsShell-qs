---
title: "Plan: Rosé Pine Theme Integration for Zed Editor"
type: agent-thought
tags:
  - theme/rose-pine
  - editor/zed
  - adapters/zed
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Plan-Rose-Pine-Theme-Integration]]"
  - "[[Plan-Fix-Zed-Theme-Inotify-Inode-Watch]]"
  - "[[System-Architecture]]"
---

# Plan: Rosé Pine Theme Integration for Zed Editor

> [!NOTE]
> Rosé Pine theme integration for Zed editor has been successfully implemented via `shared/app_configs/zed/rosepine.json` and registered in `ZedAdapter.ensureThemeTemplates()` in `core/services/theme/adapters/zed.go`.

## 1. Problem Statement
The user requested adding the **Rosé Pine** theme for the **Zed** editor. In `ogsShell-qs`, Zed theming is handled by `ZedAdapter` (`core/services/theme/adapters/zed.go`), which deploys custom JSON theme definitions to `~/.config/zed/themes/` and patches `~/.config/zed/settings.json` in-place.

## 2. Color Mapping for Zed Editor
* **Workspace & Editor Background:** `#191724`
* **Panels, Status Bar & Tab Bar Background:** `#1f1d2e`
* **Elements / Overlay:** `#1f1d2e` / `#26233a`
* **Active Element & Selection:** `#403d52`
* **Primary Text:** `#e0def4`
* **Muted Text & Line Numbers:** `#6e6a86`
* **Accent (Active Line & Rose):** `#ebbcba`
* **Syntax - Keyword:** `#31748f`
* **Syntax - Function:** `#ebbcba`
* **Syntax - String:** `#f6c177`
* **Syntax - Comment:** `#6e6a86`
* **Syntax - Type:** `#9ccfd8`
* **Syntax - Variable:** `#e0def4`

## 3. Implementation Steps & Verification

1. **Zed Theme Definition (`shared/app_configs/zed/rosepine.json`):**
   - Created schema-compliant Zed theme JSON with `Rosé Pine` palette styling.

2. **Zed Adapter Template List (`core/services/theme/adapters/zed.go`):**
   - Added `"rosepine"` to `themeIDs` in `ensureThemeTemplates()`.

3. **Testing:**
   - Executed Go tests in `core/` with 100% pass rate.

