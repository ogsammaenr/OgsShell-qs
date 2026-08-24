---
title: "Plan: Rosé Pine Theme Integration for IntelliJ IDEA and JetBrains IDEs"
type: agent-thought
tags:
  - theme/rose-pine
  - ide/intellij
  - ide/jetbrains
  - adapters/intellij
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Plan-Rose-Pine-Theme-Integration]]"
  - "[[Plan-IntelliJ-Theme-Adapter]]"
  - "[[System-Architecture]]"
---

# Plan: Rosé Pine Theme Integration for IntelliJ IDEA and JetBrains IDEs

> [!NOTE]
> Rosé Pine theme integration for IntelliJ IDEA and JetBrains IDEs has been successfully implemented via `shared/app_configs/intellij/rosepine.icls` and registered in `IntelliJAdapter.getSchemeName()` in `core/services/theme/adapters/intellij.go`.

## 1. Problem Statement
The user requested adding Rosé Pine theme support for **IntelliJ IDEA**. In `ogsShell-qs`, JetBrains IDEs are managed by `IntelliJAdapter` (`core/services/theme/adapters/intellij.go`), which deploys `.icls` color scheme definitions to `~/.config/JetBrains/<Product><Version>/colors/` and updates `options/colors.scheme.xml`.

## 2. Color Mapping for IntelliJ / JetBrains
Based on the official Rosé Pine specification:
* **Scheme Name:** `OgsRosePine`
* **Parent Scheme:** `Darcula`
* **Editor & Gutter Background (`191724`):** Base
* **Selection Background (`403d52`):** Highlight Med
* **Selection & Text Foreground (`e0def4`):** Text

## 3. Implementation Steps & Verification

1. **IntelliJ Color Scheme (`shared/app_configs/intellij/rosepine.icls`):**
   - Created schema definition with `OgsRosePine` palette styling.

2. **IntelliJ Adapter Mapping (`core/services/theme/adapters/intellij.go`):**
   - Added `"rosepine": "OgsRosePine"` to `schemeNames` in `getSchemeName()`.

3. **Testing:**
   - Ran Go unit tests in `core/` with 100% pass rate.

