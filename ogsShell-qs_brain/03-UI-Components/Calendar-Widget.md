---
title: "Calendar Widget & Event Manager UI Component"
type: ui-component
tags:
  - ui/widget
  - calendar
  - events
  - holidays
  - quickshell/qml
  - right-click/events
created: 2026-08-12
updated: 2026-08-14
status: active
related_notes:
  - "[[Calendar-Service]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Widget]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[Plan-Calendar-Right-Click-Events-View]]"
---

# Calendar Widget & Event Manager UI Component

> [!NOTE]
> `shell/components/widgets/calendar/CalendarWidget.qml` is the focused application component hosted inside the Dynamic Island when the user clicks the Date in `HOVER` mode. It delivers a clean, full-canvas Apple HIG minimalist month calendar, Turkish national/religious public holiday badges, right-click day agenda overlay, and inline event creation via day double-clicks.

---

## 1. Key Features & Interactions

* **Interactive Hover Trigger:**
  - Clicking the **Date** in the Island's `HOVER` mode sets `expandedActiveTab = "CALENDAR"` and expands the island.
* **Full-Height Month Canvas:**
  - Segmented tab bar removed in favor of maximum month grid visibility and clean aesthetic.
* **Right-Click Day Agenda Overlay:**
  - Right-clicking on any calendar day cell instantly opens the `DayDetailView` sheet for that selected date, listing all scheduled reminders, completion checkboxes, event deletion, holiday tag, and a quick-add bar.
* **Official Public Holidays:**
  - National (e.g. 29 Ekim, 23 Nisan, 30 Ağustos, 1 Ocak, 1 Mayıs, 19 Mayıs, 15 Temmuz) and religious holidays (Ramazan & Kurban Bayramları) display a coral red indicator dot and banner.
* **Double-Click Event Addition:**
  - Single-click on a day: selects the active date.
  - Double-click on any day: opens the inline Event Creation Modal with title, time, and reminder fields, sending `add_calendar_event` via IPC.
  - Right-click on any day: opens the detailed day events sheet (`DayDetailView`).

---

## 2. Subcomponents

* **Month Grid View:** `shell/components/widgets/calendar/MonthGridView.qml`
* **Day Detail View:** `shell/components/widgets/calendar/DayDetailView.qml`
* **Root Calendar App:** `shell/components/widgets/calendar/CalendarWidget.qml`

---

## 3. Related Links

* Backend Service: `[[Calendar-Service]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Clock Widget: `[[Clock-Widget]]`
* Design System: `[[Apple-HIG-Minimal-Design-System]]`
* Interaction Proposal: `[[Plan-Calendar-Right-Click-Events-View]]`
