---
title: "Proposal: Global Timezone & Location Synchronization in ClockManager"
type: agent-thought
tags:
  - proposal/feature
  - timezone/sync
  - clock/global
  - dynamic-island
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Clock-Manager]]"
  - "[[Clock-Widget]]"
  - "[[Clock-Suite-View]]"
  - "[[Dynamic-Island-Component]]"
---

# Proposal: Global Timezone & Location Synchronization in ClockManager

> [!IDEA]
> Centralize active timezone (`selectedUtcOffsetHours`), location (`selectedCity`, `selectedCountry`), and 12h/24h format in `ClockManager.qml` singleton so that any user changes made in the Clock Settings immediately synchronize to the Dynamic Island's compact `IDLE` and `HOVER` states.

## 1. Problem Statement
Timezone adjustments and 12h/24h toggles in `WorldClockTab.qml` were local properties, leaving the primary `ClockWidget.qml` in `IDLE`/`HOVER` island states bound only to the local system time without reflecting user-selected timezones.

## 2. Proposed Implementation
1. Elevate timezone properties (`selectedCity`, `selectedCountry`, `selectedUtcOffsetHours`, `is24HourFormat`, `showSeconds`) to `ClockManager.qml`.
2. Compute reactive `currentDisplayTime`, `currentDisplayDate`, and `currentFullDate` inside `ClockManager.qml`.
3. Bind `ClockWidget.qml` and `WorldClockTab.qml` directly to `ClockManager`.
