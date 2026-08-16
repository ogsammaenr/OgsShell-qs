---
title: "Plan: Add CPU and GPU Temperature Telemetry Display"
type: agent-thought
tags:
  - telemetry/temperature
  - cpu/gpu/hwmon
  - control-center/ui
  - dynamic-island/pinned
  - quickshell/qml
  - go/monitors
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[SysMetrics-Service]]"
  - "[[CPU-Monitor-Service]]"
  - "[[GPU-Monitor-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Daemon-IPC-Client]]"
---

# Plan: Add CPU and GPU Temperature Telemetry Display

> [!NOTE]
> Added live temperature readings (°C) for CPU and GPU in both the Control Center telemetry pill and the Dynamic Island pinned transparent HUD. Enhanced backend sensor scanning (`core/monitors/`) to discover `coretemp`, `x86_pkg_temp`, `k10temp`, `hwmon`, and NVIDIA NVML sensors.

## Problem Statement & Root Cause

1. **Frontend Omission:** In `ControlCenterMain.qml` and `PinnedMetricsWidget.qml`, the string formatters only bound `cpu_percent`, `ram_percent`, and `gpu_percent`, omitting `cpu_temp` and `gpu_temp`.
2. **DaemonIPC Typo in Default Schema:** `DaemonIPC.qml` initialized `cpu: { "cpu_percent": 0, "cpu-temp": 0 }` with a dash instead of `cpu_temp`.
3. **Backend Multi-Zone Sensor Discovery:** `core/monitors/cpu.go` previously only checked `/sys/class/thermal/thermal_zone0/temp`.

## Implemented Solution

1. **Harded Backend Sensor Collection (`core/monitors/`):**
   - In `cpu.go`: Iterates over `/sys/class/hwmon/hwmon*/` (`coretemp`, `k10temp`, `cpu_thermal`) and `/sys/class/thermal/thermal_zone*/type` (`x86_pkg_temp`, `TCPU`) before falling back to `thermal_zone0`.
   - In `gpu.go`: Added dual-GPU multi-card sysfs fallback (`/sys/class/drm/card*`) and NVIDIA NVML integration.
2. **Frontend Telemetry Schema & Formatter Update:**
   - In `DaemonIPC.qml`: Fixed `cpu_temp` default property.
   - In `PinnedMetricsWidget.qml`: Displays `CPU %<usage> <temp>°C` and `GPU %<usage> <temp>°C` with high-contrast text outlines.
   - In `ControlCenterMain.qml`: Displays `CPU %<usage> <temp>°C` and `GPU %<usage> <temp>°C` in the telemetry pill.
