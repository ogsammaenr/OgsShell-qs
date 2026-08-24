---
title: "Plan: Rosé Pine Theme Integration for Dolphin File Manager and Qt/KDE"
type: agent-thought
tags:
  - theme/rose-pine
  - file-manager/dolphin
  - kde/qt
  - adapters/qt-dolphin
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Plan-Rose-Pine-Theme-Integration]]"
  - "[[System-Architecture]]"
---

# Plan: Rosé Pine Theme Integration for Dolphin File Manager and Qt/KDE

> [!NOTE]
> Rosé Pine theme integration for Dolphin file manager and Qt/KDE applications has been successfully implemented via `shared/app_configs/dolphin/rosepine.kdeglobals`, `shared/app_configs/qt/rosepine.conf`, and `DolphinQtAdapter.getKdeSchemeName()` in `core/services/theme/adapters/dolphin_qt.go`.

## 1. Problem Statement
The user requested adding Rosé Pine theme support for the **Dolphin** file manager. In the `ogsShell-qs` architecture, Dolphin and KDE 5/6 applications are managed via the `DolphinQtAdapter` in `core/services/theme/adapters/dolphin_qt.go`, which requires:
1. A complete KDE color scheme file: `shared/app_configs/dolphin/rosepine.kdeglobals`.
2. A Qt palette file: `shared/app_configs/qt/rosepine.conf`.
3. Explicit mapping for `rosepine` in `DolphinQtAdapter.getKdeSchemeName()`.

## 2. Color Mapping for Dolphin / KDE
Based on the official Rosé Pine specification:
* **Window Background:** `#1f1d2e` (`31,29,46`)
* **View (File List) Background:** `#191724` (`25,23,36`)
* **Button Background:** `#26233a` (`38,35,58`)
* **Foreground Text:** `#e0def4` (`224,222,244`)
* **Inactive / Muted Text:** `#908caa` (`144,140,170`)
* **Selection / Highlight Accent:** `#ebbcba` (`235,188,186`)
* **Link / Cyan:** `#9ccfd8` (`156,207,216`)
* **Negative (Red):** `#eb6f92` (`235,111,146`)
* **Neutral (Gold):** `#f6c177` (`246,193,119`)
* **Positive (Pine):** `#31748f` (`49,116,143`)
* **Visited (Iris):** `#c4a7e7` (`196,167,231`)

## 3. Implementation Steps & Verification

1. **KDE Color Scheme (`shared/app_configs/dolphin/rosepine.kdeglobals`):**
   - Created comprehensive 13-section KDE 5/6 `.kdeglobals` format under scheme name `OgsRosePine`.

2. **Qt5ct / Qt6ct Palette (`shared/app_configs/qt/rosepine.conf`):**
   - Created Qt ColorScheme definitions with 22 ARGB color roles for Active, Disabled, and Inactive states.

3. **Go Adapter Integration (`core/services/theme/adapters/dolphin_qt.go`):**
   - Added `case "rosepine": return "OgsRosePine"` to `getKdeSchemeName()`.

4. **Testing:**
   - Executed Go tests in `core/` with 100% pass rate.

