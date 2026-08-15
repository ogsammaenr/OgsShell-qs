---
title: "Proposal: Dynamic Island Calendar App, Date Click Trigger & Double-Click Event Creation"
type: agent-thought
tags:
  - proposal/feature
  - dynamic-island
  - calendar/events
  - public-holidays
  - double-click
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Calendar-Service]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Widget]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[IPC-Socket-Schema]]"
---

# Proposal: Dynamic Island Calendar App, Date Click Trigger & Double-Click Event Creation

> [!IDEA]
> Extending the Dynamic Island Hover state with an interactive Date trigger that launches a dedicated Apple HIG Calendar Application in `EXPANDED` mode, featuring Turkish national/religious public holidays, day event inspection, and a seamless **double-click event creation modal** directly on any calendar day.

## 1. Requirements & User Workflow

1. **Hover Date Click Trigger:**
   - In `HOVER` mode:
     - Clicking the **Time** opens the **Clock App Suite** (`expandedActiveTab = "CLOCK"`).
     - Clicking the **Date** opens the **Calendar App** (`expandedActiveTab = "CALENDAR"`).
2. **Apple HIG Calendar App (`CalendarWidget.qml`):**
   - Clean, minimalist month grid with sliding segment controls ("Takvim" / "Etkinlikler").
   - Turkish National & Religious Public Holidays (`core/services/calendar/`) highlighted with coral indicator badges.
3. **Double-Click Event Addition:**
   - Single-clicking a day selects the day and shows its events/holidays.
   - Double-clicking any day cell triggers an inline minimalist Event Creation Sheet (`AddEventSheet.qml` / modal overlay) with title input, time picker, and "Kaydet" action via `ipc.addCalendarEvent(...)`.

## 2. Affected Components
- `shell/components/widgets/ClockWidget.qml` - Separated click areas for Time vs Date.
- `shell/components/island/DynamicIsland.qml` - Connected `onDateClicked` to open `expandedActiveTab = "CALENDAR"`.
- `shell/components/widgets/calendar/MonthGridView.qml` - Added double-click event detection and public holiday styling.
- `shell/components/widgets/calendar/CalendarWidget.qml` - Upgraded to Apple HIG styling with sliding segment switcher and inline event creation dialog.
- `shell/components/widgets/calendar/DayDetailView.qml` - Upgraded to Apple HIG typography with holiday banners and event completion toggles.
