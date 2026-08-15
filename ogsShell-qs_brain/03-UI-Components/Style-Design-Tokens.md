---
title: "Style Design Tokens Specification"
type: ui-component
tags:
  - ui/styling
  - theme/catppuccin
  - oled/pure-black
  - animation/spring
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Style Design Tokens Specification

> [!NOTE]
> Centralized design token system (`Style.qml`) managing the color palette (Apple OLED Pure Black `#000000` silhouette, Catppuccin accents), geometry constants, and spring/bezier animation parameters.

---

## 1. Color Tokens

| Token | Hex Value | Purpose |
| :--- | :--- | :--- |
| `bgPrimary` | `#000000` | Pure OLED Black borderless silhouette for Island and Notch |
| `bgSecondary` | `#0e0e12` | Deep dark surface for expanded modal card |
| `surface` | `#181822` | Internal widget container background |
| `accent` | `#89b4fa` | Catppuccin Sapphire / Blue indicator accents |
| `accentHover` | `#b4befe` | Highlight hover accent |
| `textPrimary` | `#cdd6f4` | High-contrast foreground text |
| `textMuted` | `#6c7086` | Secondary / subtext |
| `border` | `#262738` | Internal dividers and card strokes (outer island borders removed) |

---

## 2. Related Links

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Dynamic Notch: `[[Dynamic-Notch-Design-Specification]]`
