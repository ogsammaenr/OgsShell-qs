---
title: "Plan: WiFi Scan Refresh Button Rotation Animation"
type: agent-thought
tags:
  - proposal/ui
  - quickshell/qml
  - wifi/scanner
  - animations
created: 2026-09-07
updated: 2026-09-07
status: implemented
related_notes:
  - "[[Wifi-Client-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Backend-Endpoints-Reference]]"
---

# Plan: WiFi Scan Refresh Button Rotation Animation

> [!NOTE]
> Implementation completed successfully. When the user triggers a Wi-Fi scan via the refresh button in `WifiView.qml` or `NetworkPage.qml`, the refresh icon rotates continuously and turns accent-colored while the scan is active, then stops and resets smoothly to 0° upon receiving the scan results from the Go daemon.

## Problem Statement
Previously, clicking the refresh button in `WifiView.qml` triggered `refreshAll()` (`rescanWifi()` + `refreshEthernet()`), but the button provided no visual feedback indicating that the scan was actively in progress or when it concluded.

## Implemented Solution

1. **`shell/backend/DaemonIPC.qml`:**
   - Added `property bool isScanningWifi: false`.
   - Added `signal wifiScanStarted()` and `signal wifiScanCompleted(var payload)`.
   - Added dedicated `scanWifi()` method that sets `isScanningWifi = true`, sends `scan_wifi` and `get_active_wifi` actions, and arms an 8-second safety fallback timer.
   - Automatically sets `isScanningWifi = true` when `sendAction("scan_wifi", ...)` is called.
   - Automatically resets `isScanningWifi = false`, stops the safety timer, and emits `wifiScanCompleted` when `wifi_update` or `wifi_scan_results` is received.

2. **`shell/components/widgets/controlcenter/views/WifiView.qml`:**
   - Added `isManualRefreshing` with an 800ms minimum rotation guarantee timer.
   - Added `isScanning` combining `ipc.isScanningWifi`, `isManualRefreshing`, and active Ethernet `nmcli` processes.
   - Attached `RotationAnimation on rotation` (800ms per loop, infinite) to the `↻` icon, switching to `Style.accentCyan` while scanning and resetting to 0° upon completion.
   - Guarded click handler to prevent redundant clicks during active scans.

3. **`shell/components/settings/components/SettingsButton.qml` & `NetworkPage.qml`:**
   - Added `property bool loading: false` with icon rotation animation to `SettingsButton`.
   - Bound `NetworkPage` "Ağları Yenile" button `loading` to `!!(ipc && ipc.isScanningWifi)`.

## Affected & Updated Components
- `shell/backend/DaemonIPC.qml` (`[[Daemon-IPC-Client]]`)
- `shell/components/widgets/controlcenter/views/WifiView.qml` (`[[Control-Center-Widget]]`)
- `shell/components/settings/components/SettingsButton.qml`
- `shell/components/settings/pages/NetworkPage.qml`
