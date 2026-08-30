---
title: "Plan: Add Network Usage Telemetry to Control Center and Pinned Metrics"
type: agent-thought
tags:
  - proposal/ui
  - quickshell/qml
  - metrics/network
  - dynamic-island/ui
  - control-center
created: 2026-08-26
updated: 2026-08-26
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Pinned-Metrics-Widget]]"
  - "[[Network-Monitor-Service]]"
  - "[[SysMetrics-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[System-Architecture]]"
  - "[[Style-Design-Tokens]]"
---

# Plan: Add Network Usage Telemetry to Control Center and Pinned Metrics

> [!IDEA]
> Extending the existing hardware monitoring HUD (`PinnedMetricsWidget`) and Control Center status bar (`ControlCenterMain`) with real-time network throughput (Rx/Tx bandwidth) provided by the Go daemon's `sys_metrics` stream.

## 1. Problem Statement & Motivation
Currently, both the Control Center telemetry footer and the pinned metrics HUD next to the Dynamic Island display CPU (percent & temperature), RAM (usage percent), and GPU (percent & temperature). Real-time network throughput data (`rx_bytes_sec`, `tx_bytes_sec`, `interface`, `is_connected`) is already collected by `[[Network-Monitor-Service]]` and broadcast via `[[SysMetrics-Service]]` through IPC, but is not yet rendered in these UI components.

## 2. Proposed Architecture & UI Design

### A. Formatting Utility
Create a lightweight, reactive throughput formatting helper `formatSpeed(bytes)`:
- Values < 1024 B/s: `${Math.round(bytes)} B/s`
- Values < 1 MB/s: `${(bytes / 1024).toFixed(bytes >= 100 * 1024 ? 0 : 1)} KB/s`
- Values >= 1 MB/s: `${(bytes / (1024 * 1024)).toFixed(1)} MB/s`

### B. Dynamic Island Pinned Metrics (`PinnedMetricsWidget.qml`)
- Add a 4th metric slot for Network:
  - Vector glyph: `󰛳` (Nerd Font network / LAN glyph) styled with `Style.accentSecondary`
  - Text label: `NET ${formatSpeed(root.netTotal)}` with high-contrast drop outline
  - High-contrast bullet separator (`•`) connecting GPU and Network metrics

### C. Control Center Telemetry Footer (`ControlCenterMain.qml`)
- Add `NET ${formatSpeed(totalNet)}` to the minimalist telemetry pill in Row 4
- Highlight text in `Style.accentSecondary` when pinned, or `Style.textSecondary` when unpinned
- Maintain responsive layout fitting the footer row

## 3. Affected Components
- `[[Control-Center-Widget]]` (`shell/components/widgets/controlcenter/ControlCenterMain.qml`)
- `[[Pinned-Metrics-Widget]]` (`shell/components/widgets/PinnedMetricsWidget.qml`)
- `[[Network-Monitor-Service]]` (`core/monitors/net.go`)
- `[[SysMetrics-Service]]` (`core/monitors/manager.go`)
- `[[Daemon-IPC-Client]]` (`shell/backend/DaemonIPC.qml`)

## 4. Implementation Summary
- Added `netRx`, `netTx`, `netTotal` properties and `formatSpeed(bytes)` utility in `[[Pinned-Metrics-Widget]]` (`shell/components/widgets/PinnedMetricsWidget.qml`).
- Inserted Metric 4 with `󰛳` glyph (`Style.accentSecondary`) and `NET ${formatSpeed(root.netTotal)}` text.
- Added `formatSpeed(bytes)` and updated the telemetry pill in `[[Control-Center-Widget]]` (`shell/components/widgets/controlcenter/ControlCenterMain.qml`) to display `NET ${root.formatSpeed(rx + tx)}`.
- Created official documentation `[[Pinned-Metrics-Widget]]` and updated `[[Control-Center-Widget]]` and `[[System-Architecture]]`.
