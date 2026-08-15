---
title: "Clock Manager Singleton & Live Activities Engine"
type: ui-component
tags:
  - ui/singleton
  - live-activities
  - pomodoro
  - stopwatch
  - quickshell/qml
created: 2026-08-12
updated: 2026-08-12
status: active
related_notes:
  - "[[Clock-Suite-View]]"
  - "[[Clock-Widget]]"
  - "[[Dynamic-Island-Component]]"
---

# Clock Manager Singleton & Live Activities Engine

> [!NOTE]
> `shell/components/widgets/clock/ClockManager.qml` is a QML singleton managing background timer state (Stopwatch & Pomodoro) and feeding real-time **Live Activities** telemetry to the compact Island pill.

---

## 1. Features & State Machine

* **Stopwatch Engine:** Accumulates elapsed milliseconds, tracks lap timestamps, and updates at ~30 FPS when active. Supports start, pause, lap, and reset.
* **Pomodoro Engine:** Dual-phase interval timer (**Çalışma** & **Mola**) with configurable durations (`pomodoroWorkMinutes`, `pomodoroBreakMinutes`), target session count (`pomodoroTargetSessions`), completed session tracking (`pomodoroCompletedSessions`), completion signals, and goal achievement notifications.
* **Global Time & Location Engine:** Centralizes active timezone (`selectedUtcOffsetHours`), location (`selectedCity`, `selectedCountry`), and 12h/24h format. Computes reactive `currentDisplayTime` and `currentDisplayDate` shared between the modal and the compact `IDLE`/`HOVER` island states.
* **Live Activities Engine:**
  - Evaluates `activeLiveActivity`: `"stopwatch"` | `"pomodoro"` | `"none"`.
  - Formats real-time badge strings (`liveActivityTitle`, `liveActivitySubtitle`, `liveActivityIcon`).
  - Sets `liveActivityTargetTab` for deep-linking click events.

---

## 2. Related Links

* Clock Suite: `[[Clock-Suite-View]]`
* Clock Widget: `[[Clock-Widget]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
