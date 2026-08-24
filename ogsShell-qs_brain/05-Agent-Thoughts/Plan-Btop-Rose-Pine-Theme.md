---
title: "Plan: Rosé Pine Theme Integration for Btop System Monitor"
type: agent-thought
tags:
  - theme/rose-pine
  - monitor/btop
  - adapters/btop
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Plan-Rose-Pine-Theme-Integration]]"
  - "[[System-Architecture]]"
---

# Plan: Rosé Pine Theme Integration for Btop System Monitor

> [!NOTE]
> Rosé Pine theme integration for Btop process and resource monitor has been successfully implemented via `shared/app_configs/btop/rosepine.theme` and deployed via `BtopAdapter`.

## 1. Problem Statement
The user requested adding Rosé Pine theme support for **btop**. In `ogsShell-qs`, btop theming is handled by `BtopAdapter` (`core/services/theme/adapters/btop.go`), which deploys `.theme` files to `~/.config/btop/themes/ogsshell.theme`.

## 2. Color Mapping for Btop
Based on the official Rosé Pine specification:
* **Foreground:** `#e0def4`
* **Title & Accents:** `#ebbcba` (Rose) / `#c4a7e7` (Iris)
* **Boxes & Overlays:** `#26233a` (Overlay) / `#21202e` (Highlight Low)
* **Gradients (Safe -> Warning -> Critical):** `#9ccfd8` (Foam) / `#31748f` (Pine) -> `#f6c177` (Gold) -> `#eb6f92` (Love)

## 3. Implementation Steps & Verification

1. **Btop Theme Definition (`shared/app_configs/btop/rosepine.theme`):**
   - Created btop color format with Rosé Pine palette.

2. **Testing:**
   - Executed Go unit tests in `core/` with 100% pass rate.

