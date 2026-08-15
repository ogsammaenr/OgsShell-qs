---
title: "Apple HIG Minimalist Design System & Anti-AI-Slop Guidelines"
type: architecture
tags:
  - hig/apple
  - design-system
  - ui/minimalism
  - dynamic-island
  - typography
  - color-palette
created: 2026-08-12
updated: 2026-08-12
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Suite-View]]"
  - "[[Style-Design-Tokens]]"
---

# Apple HIG Minimalist Design System & Anti-AI-Slop Guidelines

> [!NOTE]
> This standard defines the visual tokens, typography rules, component patterns, and aesthetic hierarchy required to deliver an authentic, Apple-grade minimalist user interface in `ogsShell-qs` while strictly eliminating "AI slop" clichés.

---

## 1. Defining and Eliminating "AI Slop"

| Anti-Pattern ("AI Slop") | Apple HIG Minimalist Standard |
| :--- | :--- |
| **Emoji Overuse:** Primary tabs and buttons stuffed with emojis (`🍅`, `☕`, `🌴`, `🇹🇷`, `🎯`, `✓`, `⚙️`). | **Pure Typography & SF Symbols:** Clean, confident labels with monochrome vector iconography or sleek text. |
| **Nested Cards Inside Cards:** Clunky rectangular borders nested inside multiple layers of gray containers. | **Single Continuous Canvas:** Frosted translucent backdrop (`#000000` base) with whitespace and subtle separators. |
| **Harsh Outlines & High-Contrast Borders:** Colored neon border strokes on cards. | **Hairline Keylines:** $0.5\text{px}-1\text{px}$ translucent borders (`rgba(255, 255, 255, 0.08)`). |
| **Disjointed Pill Buttons:** Multiple separate pill buttons acting as tabs. | **Sliding Segmented Capsule:** A single continuous track with a spring-animated sliding selection thumb. |
| **Heavy Mechanical Rectangles:** Clunky thick rectangular buttons and progress bars. | **Circular Ergonomic Controls:** Round action buttons, circular progress rings, and hairline dials. |

---

## 2. Palette & Glassmorphic Surfaces

* **Base Silhouette:** Pure Pitch Black (`#000000`) for OLED integration.
* **Keyline Stroke:** `rgba(255, 255, 255, 0.10)`
* **Surface Tiers:**
  * Base: `rgba(255, 255, 255, 0.05)`
  * Control / Capsule: `rgba(255, 255, 255, 0.09)`
  * Active Thumb / Hover: `rgba(255, 255, 255, 0.16)`
* **Typography Hierarchy:**
  * `textPrimary`: `#FFFFFF` (100% white, high legibility)
  * `textSecondary`: `rgba(255, 255, 255, 0.60)`
  * `textTertiary`: `rgba(255, 255, 255, 0.35)`
* **Semantic Accents (Apple Palette):**
  * `timerAccent`: `#FF9F0A` (Apple Orange)
  * `stopwatchAccent`: `#30D158` (Apple Green)
  * `clockAccent`: `#64D2FF` (Apple Cyan)
  * `destructiveAccent`: `#FF453A` (Apple Red)

---

## 3. Component Design Patterns

### A. Sliding Segmented Control
```text
+-------------------------------------------------------------+
|  [    Saat    ]   (  Pomodoro  )   [ Kronometre ] [Alarmlar] |
+-------------------------------------------------------------+
         ^               ^
   Track Container   Sliding Thumb Capsule (Spring Animated)
```

### B. Circular Control Actions (Timer & Stopwatch)
* Dual round buttons (Left: Reset/Lap, Right: Start/Pause) positioned at the bottom corners.
* Action buttons use a translucent background with tinted icon and bold label.

---

## 4. Related Links
* Dynamic Island HIG: `[[Apple-Dynamic-Island-HIG]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Clock Suite: `[[Clock-Suite-View]]`
