---
title: "Proposal: Borderless Pure Black Silhouette for Dynamic Island & Notch"
type: agent-thought
tags:
  - proposal/borderless
  - ui/pure-black
  - oled/silhouette
  - quickshell/styling
created: 2026-08-09
updated: 2026-08-09
status: implemented
related_notes:
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Proposal: Borderless Pure Black Silhouette for Dynamic Island & Notch

> [!NOTE]
> Implementation completed. All outer border strokes have been stripped from both Dynamic Island and Dynamic Notch modes. The container now renders as a pure deep black OLED silhouette (`#000000`) that organically blends into the display bezel.

## 1. Summary of Changes
1. **Outer Border Elimination:** Removed the outer stroke `ShapePath` in Notch mode and set `border.width: 0` in Island mode.
2. **Pure OLED Black Palette:** Updated `bgPrimary` to `#000000` in `Style.qml` to match Apple's native hardware look.

## 2. Status
* **Status:** `implemented`
