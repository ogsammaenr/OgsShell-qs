---
title: "Proposal: Dynamic Island Clock App Suite & Live Activities Architecture"
type: agent-thought
tags:
  - proposal/ui
  - dynamic-island
  - clock/suite
  - pomodoro
  - stopwatch
  - alarms
  - world-clock
  - live-activities
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Widget]]"
  - "[[Alarm-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Proposal: Dynamic Island Clock App Suite & Live Activities Architecture

> [!IDEA]
> Transforming the Dynamic Island Clock into an interactive gateway to a multi-tab Clock App Suite (World Clock, Pomodoro, Stopwatch, Alarms) with continuous Apple-style **Live Activities** morphing the Island pill in `IDLE` and `HOVER` states when a timer or stopwatch is running.

## 1. Problem & Feature Requirements

1. **Clock Click Gateway:** Clicking on the Clock widget expands the Island into a dedicated **Clock App Suite** with 4 tabs:
   - **World Clock (Dünya Saati):** Detailed digital/analog clock, seconds precision, timezones, and multiple world city cards (Istanbul, London, Tokyo, New York).
   - **Pomodoro Timer (Pomodoro):** 25/5 focus & break intervals, circular progress display, play/pause/reset, notification alerts.
   - **Stopwatch (Kronometre):** High-precision millisecond timer with lap recording and lap history list.
   - **Alarms (Alarmlar):** Full bidirectional integration with Go daemon Alarm service (`core/services/alarm/`) via `DaemonIPC`.
2. **Dynamic Island Live Activities (Canlı Ada Göstergesi):**
   - When Pomodoro or Stopwatch is running/active:
   - The Island's `IDLE` pill smoothly replaces the static clock with the live activity:
     - Stopwatch: `⏱ 02:45.8`
     - Pomodoro: `🍅 23:14` (Focus) / `☕ 04:50` (Break)
   - Clicking on the live activity directly opens the Clock App focused on that active tab.

## 2. Modular Architecture & Directory Structure

```text
shell/components/widgets/clock/
├── ClockManager.qml        # Central state coordinator for timers & live activities
├── ClockSuiteView.qml      # Main tabbed modal container for the expanded island
├── WorldClockTab.qml       # Tab 1: World time & city cards
├── PomodoroTab.qml         # Tab 2: Pomodoro timer & interval controls
├── StopwatchTab.qml        # Tab 3: Millisecond stopwatch with lap tracking
└── AlarmsTab.qml           # Tab 4: Go Daemon IPC Alarms management list
```

## 3. Affected Components
- `shell/components/widgets/ClockWidget.qml` - Enhanced to render Live Activities (Stopwatch/Pomodoro) and emit click signal.
- `shell/components/island/DynamicIsland.qml` - Integrated `ClockSuiteView` in the expanded view and connected clock click triggers.
- `shell/shell.qml` & `shell/config.json` - Expanded canvas dimensions for rich modal views.
