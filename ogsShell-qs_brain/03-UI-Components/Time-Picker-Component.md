---
title: "Time Picker UI Component"
type: ui-component
tags:
  - ui/widget
  - time-picker
  - ergonomics
  - quickshell/qml
  - apple-hig
created: 2026-08-14
updated: 2026-08-14
status: active
related_notes:
  - "[[Calendar-Widget]]"
  - "[[Clock-Suite-View]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[Plan-Apple-HIG-Time-Picker-Component]]"
---

# Time Picker UI Component

> [!NOTE]
> `shell/components/widgets/TimePicker.qml` is a unified, Apple HIG inspired time selection component designed to replace awkward keyboard text inputs and single-step steppers across the Dynamic Island clock and calendar applications.

---

## 1. Interaction Models

* **Dual Digital Segmented Tiles (`[ 08 ] : [ 30 ]`):**
  - **Mouse Wheel Scrolling:** Hovering over the Hour or Minute tile and scrolling up/down cycles through hours (`00-23`) and minutes (`00-59`, single-minute step) effortlessly.
  - **Direct Increment/Decrement Controls & Split Clicking:** Clicking the upper half increments, while clicking the lower half decrements by 1 step.
* **Rapid 15-Minute Preset Chips:**
  - One-tap quick selection pills for common intervals: `:00`, `:15`, `:30`, and `:45`.
* **Dual Display Form-Factors:**
  - **Full Embedded Mode (`compact: false`):** Directly embedded in the Alarm Configuration Sheet (`AlarmsTab.qml`) and Event Creation Modal (`CalendarWidget.qml`).
  - **Compact Popover Mode (`compact: true`):** Displays a compact pill button (`🕒 12:00`) that opens a floating Apple-style popover selector upon click, perfect for tight toolbars like the Quick-Add bar in `DayDetailView.qml`.

---

## 2. Component Interface (API)

```qml
TimePicker {
  hour: 8            // 0-23
  minute: 30         // 0-59
  compact: false     // true for mini popover mode
  onTimeChanged: (h, m, str) => {
    console.log("Selected time:", str) // e.g. "08:30"
  }
}
```

---

## 3. Related Links

* Calendar Widget: `[[Calendar-Widget]]`
* Clock Suite View: `[[Clock-Suite-View]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Proposal Note: `[[Plan-Apple-HIG-Time-Picker-Component]]`
