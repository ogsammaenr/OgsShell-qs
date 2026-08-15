---
title: "Plan: Pomodoro Target Stack & Dual-Phase Interval Architecture"
type: thought-proposal
tags:
  - architecture/plan
  - widget/clock
  - pomodoro
  - live-activities
  - quickshell/qml
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Clock-Manager]]"
  - "[[Clock-Suite-View]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
---

# Plan: Pomodoro Target Stack & Dual-Phase Interval Architecture

## 1. Problem Statement & User Requirements
The previous Pomodoro implementation had a 3-way split (Focus, Short Break, Long Break) without explicit goal setting. The user requested:
1. **Simplified Dual-Phase Flow:** Remove short/long break distinction; have only **Çalışma (Work)** and **Mola (Break)**.
2. **Configurable Durations:** Both Work and Break durations must be easily adjustable in the UI.
3. **Session Target (Hedef):** Users can define a target number of Pomodoro sessions (e.g. 4, 6, 8).
4. **Visual Session Stack:** Render an empty session stack (segmented pill/capsule slots) that progressively fills as work sessions complete.

---

## 2. Proposed Architecture & State Model

### A. State in `ClockManager.qml`
* `pomodoroPhase`: `"work"` | `"break"`
* `pomodoroWorkMinutes`: default 25
* `pomodoroBreakMinutes`: default 5
* `pomodoroTargetSessions`: default 4 (range: 1 - 12)
* `pomodoroCompletedSessions`: default 0
* `pomodoroRunning`: boolean
* `pomodoroRemainingSec`: current countdown in seconds
* `pomodoroTotalSec`: total seconds for current phase

### B. UI Presentation in `PomodoroTab.qml`
* **Top Phase Bar:** Clean two-way toggle (Çalışma `[25 dk]` vs Mola `[5 dk]`).
* **Timer Canvas:**
  * Large digital countdown (`25:00`).
  * Phase status label ("Çalışma Seansı", "Mola Süresi", "Duraklatıldı").
  * Continuous thin progress bar.
* **Target Session Stack (Hedef Stack Göstergesi):**
  * Horizontal stack of target capsules corresponding to `pomodoroTargetSessions`.
  * Empty slot: `Style.surfaceVariant` with subtle border.
  * Filled slot: Apple Amber (`#FF9F0A` / `#FF6B00`) glowing fill.
  * Active slot: subtle animated highlight.
  * Summary: e.g. `Seans Hedefi: 2 / 4`.
* **Configurable Settings Panel:**
  * Çalışma Süresi stepper (`+ / − 5 dk`, range: 1–90 dk).
  * Mola Süresi stepper (`+ / − 1 dk`, range: 1–30 dk).
  * Hedef Seans Sayısı stepper (`+ / − 1 seans`, range: 1–12 seans).
* **Controls:** Start / Pause / Reset / Duration settings toggle with reliable `MouseArea` click dispatching.

---

## 3. Implementation Steps
1. Update `ClockManager.qml` with the new target session stack and dual-phase engine.
2. Redesign `PomodoroTab.qml` with the segmented target stack and settings panel.
3. Verify with Quickshell compilation.
4. Update Obsidian Brain documentation (`[[Clock-Manager]]`, `[[Clock-Suite-View]]`).
