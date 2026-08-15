---
title: "Plan: Apple macOS Sequoia Minimalist Control Center Redesign"
type: agent-thought
tags:
  - proposal/control-center
  - apple-hig
  - minimalist-design
  - quickshell/qml
  - ux/redesign
created: 2026-08-14
updated: 2026-08-14
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[Style-Design-Tokens]]"
---

# Plan: Apple macOS Sequoia Minimalist Control Center Redesign

> [!IDEA]
> Overhaul the Control Center completely from scratch, eliminating emoji-heavy "AI slop" clutter, redundant nested containers, and cramped bento boxes. Implement a genuine Apple macOS Sequoia / iOS 18 layout with grouped connectivity pills, thick interactive capsule sliders, 2x2 modal triggers, clean Nerd Font iconography, and subtle telemetry.

## Design Structure

1. **Top Section: Split 2-Column Group:**
   * **Left Column (Connectivity Block):** Rounded group containing Wi-Fi & Bluetooth rows with active status and quick navigation arrow.
   * **Right Column (Quick Toggles 2x2 Grid):**
     * **GameMode:** Instant toggle with dynamic accent state.
     * **DND / Notifications:** Quick toggle + sub-view access.
     * **Themes:** Theme palette selector.
     * **Clipboard:** Clipboard history viewer.
2. **Middle Section: Thick Apple Capsule Sliders:**
   * **Display Brightness:** Full-width rounded capsule slider with embedded glyph (`󰃟`) and percentage.
   * **Sound Volume:** Full-width rounded capsule slider with embedded speaker glyph (`󰕾`) and mute toggle.
3. **Bottom Section: Status & Power Bar:**
   * **Telemetry Pill:** Minimalist CPU & RAM stats (`CPU 14% • RAM 35%`).
   * **Keyboard Layout Pill:** Clickable (`TR` / `US`).
   * **Power Session Action:** Subtle circular power button (`󰐥`).
