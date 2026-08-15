---
title: "Proposal: Visual Theme Gallery and Interactive Card Redesign"
type: agent-thought
tags:
  - proposal/theme-gallery
  - ui/themes-view
  - quickshell/gridview
  - design-system/tokens
  - apple-hig/cards
created: 2026-08-15
updated: 2026-08-15
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[System-Architecture]]"
---

# Proposal: Visual Theme Gallery and Interactive Card Redesign

> [!IDEA]
> Redesigning `ThemesView.qml` from a generic list into a rich 2-column visual Theme Gallery featuring mini desktop/window UI mockups, real-time color swatches (`bg`, `surface`, `accent`, `accent_secondary`, `cyan`), author badges, and active state indicators provides a tactile, visually stunning theme selection experience.

## Problem Statement

The previous `ThemesView.qml` used a minimal single-column list with tiny 10px dots and 9px plain text. It lacked visual appeal, real-world palette representation, and clear visual differentiation between light and dark themes.

## Proposed Architecture & UI Design

1. **Header with Active Theme Status:**
   - Back button with circular hover glow.
   - "Tema Galerisi" title with active theme pill badge (`● Aktif: Catppuccin Mocha`).
   - Total theme count indicator.

2. **2-Column Responsive Theme Grid:**
   - 2-column `GridView` with smooth scrolling.
   - **Mini Window/Desktop Mockup:**
     - Realistic mini window frame using the theme's exact `bg`, `surface`, and `border` colors.
     - Mini titlebar with macOS-style window control dots.
     - Mini code/text line bars using `accent`, `fg`, and `cyan`/`green` semantic tokens.
   - **5-Color Palette Swatch Strip:**
     - Circular swatches displaying `bg`, `surface`, `accent`, `accent_secondary`, and `cyan`/`green`.
   - **Theme Metadata & Active Badge:**
     - Bold theme name, author tag, and `✓ Seçili` active badge.
   - **Micro-Interactions:**
     - Hover scaling, border glow, and one-tap instant theme switching via `ipc.setActiveTheme(themeId)`.

## Affected Components
- `shell/components/widgets/controlcenter/views/ThemesView.qml` - Complete redesign of the view.
- `ogsShell-qs_brain/03-UI-Components/Control-Center-Widget.md` - Update documentation.
- `.agents/ARCHITECTURE.md` - Update reference map.
