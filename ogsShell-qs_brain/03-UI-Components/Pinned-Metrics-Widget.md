---
title: "Pinned Metrics Widget Component"
type: ui-component
tags:
  - ui/widgets
  - quickshell/qml
  - metrics/hud
  - dynamic-island/ui
  - system-controls
created: 2026-08-26
updated: 2026-08-26
status: active
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Daemon-IPC-Client]]"
  - "[[SysMetrics-Service]]"
  - "[[Network-Monitor-Service]]"
  - "[[CPU-Monitor-Service]]"
  - "[[RAM-Monitor-Service]]"
  - "[[GPU-Monitor-Service]]"
  - "[[Style-Design-Tokens]]"
  - "[[Configuration-System-Spec]]"
  - "[[Plan-Add-Network-Usage-To-System-Metrics]]"
  - "[[Plan-Fix-Pinned-Metrics-Hover-Clipping-And-Canvas-Width]]"
---

# Pinned Metrics Widget Component

> [!NOTE]
> `shell/components/widgets/PinnedMetricsWidget.qml` is a transparent, zero-click-blocking status HUD pinned directly beside the Dynamic Island when enabled by the user via Control Center.

---

## 1. Overview & Architecture

* **Purpose:** Provides unobtrusive, high-visibility desktop hardware telemetry (CPU, RAM, GPU, and Network throughput) directly on the top panel overlay layer.
* **Toggle Trigger:** Can be enabled/disabled by clicking the telemetry pill inside the Control Center (`ControlCenterMain.qml`), persisting via `Config.showPinnedSystemMetrics`.
* **State Adaptation:**
  - **IDLE / HOVER:** Visible and dynamically animated to follow Island / Notch geometry.
  - **EXPANDED:** Fades out (`opacity: 0.0`) to avoid visual overlap when Dynamic Island expands into applications.
  - **Focus Mode:** Automatically hides and reveals alongside the Dynamic Island via `screenScope.isRevealed`.

```mermaid
graph LR
    DAEMON["Go Daemon<br/>[[SysMetrics-Service]]"] -->|sys_metrics NDJSON| IPC["DaemonIPC.qml<br/>[[Daemon-IPC-Client]]"]
    IPC --> PMW["PinnedMetricsWidget.qml"]
    CFG["Config.showPinnedSystemMetrics"] -->|Toggle| PMW
    PMW --> CPU["CPU Load & Temp"]
    PMW --> RAM["RAM Usage"]
    PMW --> GPU["GPU Load & Temp"]
    PMW --> NET["Network Throughput"]
```

---

## 2. Rendered Telemetry Metrics

1. **CPU:**
   - Glyph: `󰻠` (Color: `Style.accentCyan`)
   - Value: `CPU %<percent> [<temp>°C]`
2. **RAM:**
   - Glyph: `󰍛` (Color: `Style.accentGreen`)
   - Value: `RAM %<percent>`
3. **GPU:**
   - Glyph: `󰢮` (Color: `Style.accentOrange`)
   - Value: `GPU %<percent> [<temp>°C]`
4. **Network:**
   - Glyph: `󰛳` (Color: `Style.accentSecondary`)
   - Value: `NET <throughput>` (e.g. `NET 1.2 MB/s`, `NET 450 KB/s`, `NET 0 B/s`)

---

## 3. Related Links

* Control Center: `[[Control-Center-Widget]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* SysMetrics Service: `[[SysMetrics-Service]]`
* Network Monitor Service: `[[Network-Monitor-Service]]`
* Design Tokens: `[[Style-Design-Tokens]]`
