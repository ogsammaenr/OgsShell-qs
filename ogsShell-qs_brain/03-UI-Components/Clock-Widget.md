---
title: "Clock Widget Component"
type: ui-component
tags:
  - ui/widget
  - widget/clock
  - quickshell/qml
created: 2026-08-09
updated: 2026-08-23
status: active
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Media-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Plan-Dynamic-Island-Idle-And-Hover-Typography-Enlargement]]"
---

# Clock Widget Component

> [!NOTE]
> `shell/components/widgets/ClockWidget.qml` renders a glanceable, low-overhead clock with dual operational modes: single-line compact clock for `IDLE` mode, and two-row typography (Clock on top, Date below) for `HOVER` and extended status presentations.

---

## 1. Features & Implementation (`shell/components/widgets/ClockWidget.qml`)

* **Unified Morphing Coordinate System:** Instead of destroying/recreating DOM elements between `IDLE` and `HOVER`, a single persistent `ClockWidget` instance interpolates all transforms continuously.
* **Idle Typography:** Primary time text displays in bold **`16px`** (`Font.DemiBold` / `Font.Bold`, `0.3px` letter spacing) for effortless glanceability within the 34-36px Island/Notch bar.
* **Hover Expansion & Typography Transition:**
  * In `HOVER`, the primary time text glides upward (`anchors.verticalCenterOffset: -10px`) via `Easing.OutCubic` and expands to **`20px Bold`** (`0.5px` letter spacing) with smooth animation.
  * In `HOVER`, localized date text expands to **`13px Medium`** (`0.3px` letter spacing) and slides up directly beneath the time text (`anchors.topMargin: 3px`).
* **Live Activity Pulse Indicator (Canlı Aktivite Durum Işığı):**
  - Normal saat gösterilirken nokta tamamen gizlenir (`visible: false`, `width: 0`).
  - Arka planda bir **Kronometre**, **Sayaç (Zamanlayıcı)** veya **Pomodoro** seansı başladığında (`isLiveActivity == true`), `7x7px` nokta otomatik olarak o aktivitenin durum rengiyle (yeşil/turuncu/kırmızı) saatin solunda beliriş ve nefes alma animasyonuyla çalışır.
* **1-Second Timer:** Ticks every 1000ms with `triggeredOnStart: true` for zero startup delay.

---

## 2. Related Links

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Media Widget: `[[Media-Widget]]`
* Connectivity Status Widget: `[[Connectivity-Status-Widget]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Typography Plan: `[[Plan-Dynamic-Island-Idle-And-Hover-Typography-Enlargement]]`
