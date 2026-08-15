---
title: "Clock Suite View Component"
type: ui-component
tags:
  - ui/widget
  - widget/clock
  - world-clock
  - pomodoro
  - stopwatch
  - alarms
  - quickshell/qml
created: 2026-08-12
updated: 2026-08-12
status: active
related_notes:
  - "[[Clock-Manager]]"
  - "[[Clock-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Alarm-Service]]"
  - "[[Style-Design-Tokens]]"
---

# Clock Suite View Component

> [!NOTE]
> `shell/components/widgets/clock/ClockSuiteView.qml` coordinates the multi-tab Clock App Suite inside the expanded state of the Dynamic Island.

---

## 1. Sub-Tabs & Architecture

1. **Detailed Clock & Location Settings (`WorldClockTab.qml`):**
   - Large digital clock with running seconds (`hh:mm:ss`), full date, and active timezone badge.
   - Interactive "Saat Konumu & Zaman Dilimini Ayarla" button with quick timezone preset selection (Istanbul, London, Berlin, NY, Tokyo) and 12h/24h format toggles.
2. **Pomodoro Timer (`PomodoroTab.qml`):**
   - Dual-phase interval model (**Çalışma** & **Mola**) without short/long break complexity.
   - Configurable Çalışma Süresi (5–90 dk), Mola Süresi (1–30 dk), and Hedef Seans Sayısı (1–12 seans).
   - Visual empty session stack that fills progressively as work sessions complete, with checkmarks and celebratory completion banner.
   - Triggers desktop notifications upon session completion and goal achievement.
3. **Stopwatch (`StopwatchTab.qml`):**
   - Millisecond precision digital counter (`00:00.00`).
   - Start / Pause / Lap / Reset actions.
   - Scrollable lap history list with delta calculations.
4. **Alarms (`AlarmsTab.qml`):**
   - Full IPC integration with Go backend `core/services/alarm/` (`DaemonIPC`).
   - Toggle switch controls, delete alarm (`delete_alarm`), repeat day presets (Hafta İçi, Her Gün, Tek Sefer), individual day toggles, and new alarm creation sheet.

---

## 2. Related Links

* State Coordinator: `[[Clock-Manager]]`
* Clock Widget: `[[Clock-Widget]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Alarm Service: `[[Alarm-Service]]`
