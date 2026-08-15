---
title: "Proposal: Focused Single-App Island Hosting, LayerShell Stacking & Detailed Clock"
type: agent-thought
tags:
  - proposal/architecture
  - wayland/layershell
  - dynamic-island
  - clock/suite
  - click-outside
created: 2026-08-12
updated: 2026-08-12
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Suite-View]]"
  - "[[Clock-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Proposal: Focused Single-App Island Hosting, LayerShell Stacking & Detailed Clock

> [!IDEA]
> 1. **True Wayland Layer-Shell Z-Ordering:** Assign `WlrLayershell.layer: WlrLayer.Overlay` to `islandWindow` and `WlrLayershell.layer: WlrLayer.Top` to `backdropWindow` so clicks inside the island are never stolen by the backdrop.
> 2. **Dedicated Single-App Container:** When the Clock is clicked, the Island hosts only the Clock App with its 4 internal tabs (`[ 🌐 Saat & Konum ] [ 🍅 Pomodoro ] [ ⏱ Kronometre ] [ ⏰ Alarmlar ]`), removing unrelated cross-app tabs.
> 3. **Redesigned Detailed Clock & Location:** Replacing multi-city cards with a high-fidelity detailed clock display and an interactive time/timezone/location configuration button.

## 1. Problem & Root Causes

- **Accidental Collapse on Tab Click:** The fullscreen `backdropWindow` was receiving clicks over the entire screen because both windows were on the default layer and `backdropWindow` mapped over `islandWindow`.
- **Cross-App Tab Clutter:** The expanded island showed "Saat", "Takvim", "Sistem" tabs mixed together instead of dedicating the view to the opened application.
- **World Clock Misalignment:** The previous design showed London/Tokyo/NY city cards rather than a detailed clock display with a timezone/location adjustment button.

## 2. Proposed Architectural Solution

1. **Wayland LayerShell Stacking (`shell.qml`):**
   - `islandWindow`: `WlrLayershell.layer: WlrLayer.Overlay`
   - `backdropWindow`: `WlrLayershell.layer: WlrLayer.Top`
   - In `DynamicIsland.qml`: `HoverHandler` only modifies state when in `IDLE` or `HOVER`, never in `EXPANDED`.
2. **Dedicated Active App Architecture (`DynamicIsland.qml`):**
   - `property string activeApp: "CLOCK"`
   - When Clock is opened, `ClockSuiteView` owns the entire top sub-tab bar.
3. **Detailed Clock & Location View (`WorldClockTab.qml` -> `ClockDetailTab.qml`):**
   - Large digital clock with running seconds.
   - Date, weekday, and active timezone badge.
   - Location & Timezone adjustment button with interactive timezone presets and 12h/24h toggle.
