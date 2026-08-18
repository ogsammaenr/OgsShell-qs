---
title: "Proposal: Apple Spotlight / Raycast Minimalist Redesign for App Launcher (Anti-AI-Slop)"
type: agent-thought
tags:
  - proposal/redesign
  - ui/launcher
  - hig/apple
  - anti-ai-slop
  - minimalism
  - quickshell/qml
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Component]]"
  - "[[App-Launcher-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Proposal: Apple Spotlight / Raycast Minimalist Redesign for App Launcher (Anti-AI-Slop)

> [!IDEA]
> Eliminating nested rectangle clutter, excessive badges, and cliché footers from `AppLauncherWidget.qml` to achieve an authentic Apple Spotlight / Raycast grade minimalist design system, adhering strictly to the guidelines defined in `[[Apple-HIG-Minimal-Design-System]]`.

## Problem Analysis: Identifying the "AI Slop" in the Previous Layout
1. **Excessive Nested Cards Inside Cards (5+ Layers):**
   - Search bar was inside a bordered rectangle $\to$ list was inside a bordered rectangle $\to$ each delegate was inside a bordered rectangle $\to$ icon was inside a bordered rectangle $\to$ count badge was inside a bordered rectangle $\to$ enter hint was inside a bordered rectangle!
2. **Visual Clutter & Cliché Elements:**
   - Shouting bottom footer (`"⚡ <0.5ms In-Memory Arama"` with `"↑↓ Gezin • ↵ Başlat • Esc Kapat"`).
   - Loud orange `"14x"` badges and bright `"↵ Çalıştır"` pills on every selected row.
   - Clunky search box with loud focus outlines.
   - Cartoonish empty state with big round circles and icon glyphs.

## Proposed Minimalist Architecture (Apple HIG & Raycast Standard)

1. **Single Continuous Canvas:**
   - The Dynamic Island's pure OLED black `#000000` squircle acts as the only outer container.
   - Remove all inner nested card boxes.
2. **Edge-to-Edge Spotlight Search Header:**
   - Generous 15px typography with crisp placeholder `"Uygulama ara..."`.
   - Subtle monochrome magnifying glass glyph.
   - 1px hairline translucent separator (`rgba(255, 255, 255, 0.08)`).
3. **Clean, Spacious App Item Delegates:**
   - Height: 42px.
   - 28x28 crisp desktop icon directly on surface (no nested bordered box).
   - Typography: Clean app title (`13.5px`, `Font.Medium`) with generic category/comment in `Style.textMuted` (`11.5px`) on the right.
   - Selection State: Soft translucent frosted pill (`Style.surfaceActive` or `Style.surfaceHover`) with zero harsh neon borders.
   - Subtle monochrome `↵` icon indicator on selected item.
4. **Quiet, Elegant Footer:**
   - 1px hairline top separator.
   - Left: Subtle count (`"248 uygulama"` or `"3 sonuç"` in 11px muted font).
   - Right: Subtle hint (`"↵ Aç"` • `"esc Kapat"`).
5. **Dimensions & Proportions:**
   - Width: `480px` (sleek, well-proportioned for 1080p/4K).
   - Height: `380px` (fits 6-7 items cleanly without taking over the screen).
