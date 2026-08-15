---
title: "Proposal: Dual Form-Factor (Dynamic Island & Notch) and JSON Configuration System"
type: agent-thought
tags:
  - proposal/dual-form-factor
  - ui/dynamic-notch
  - ui/dynamic-island
  - config/json
  - architecture/quickshell
created: 2026-08-09
updated: 2026-08-09
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Configuration-System-Spec]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Shell-Root-PanelWindow]]"
---

# Proposal: Dual Form-Factor (Dynamic Island & Notch) and JSON Configuration System

> [!NOTE]
> Implementation completed. The system now fully supports two distinct visual formats (**Dynamic Island** and **Dynamic Notch**) dynamically configured via `config.json` and parsed reactively by `Config.qml` singleton.

## 1. Summary of Delivered Features
1. **Dynamic Island Mode (`"island"`):**
   * Floating pill presentation (`top_margin: 8px`).
   * Symmetrical 4-corner rounded squircle radius.
   * Full 360-degree ambient keyline border.
2. **Dynamic Notch Mode (`"notch"`):**
   * Attached flush to the top screen bezel (`top_margin: 0px`).
   * Flat top edge seamlessly merging with the physical monitor bezel, with smooth rounded bottom corners (`20px` compact, `26px` expanded).
   * Downward drop-down expansion kinematics.
3. **Centralized Configuration System (`config.json`):**
   * Placed at `shared/app_configs/shell/config.json` and `shell/config.json`.
   * Switchable `form_factor` (`"island"` / `"notch"`), `theme`, discrete geometry presets for both modes, notification timeouts, and animation durations.
   * Loaded reactively by `Config.qml` singleton using `Quickshell.Io.FileView`.

## 2. Status
* **Status:** `implemented`
