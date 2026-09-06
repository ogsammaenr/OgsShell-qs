---
title: "Plan: Fix Bluetooth Pairing, Auto-Trust and UI Mouse Interaction"
type: agent-thought
tags:
  - plan/bluetooth
  - bluez/dbus
  - quickshell/qml
  - fix/interaction
created: 2026-09-06
updated: 2026-09-06
status: implemented
related_notes:
  - "[[Bluetooth-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Go-Daemon-Core]]"
---

# Plan: Fix Bluetooth Pairing, Auto-Trust and UI Mouse Interaction

> [!IDEA]
> Fixing the Bluetooth subsystem requires resolving both backend D-Bus lifecycle quirks (missing auto-pairing, missing auto-trust for subsequent reconnections) and frontend QML interaction bugs (wrong RPC endpoint, z-order MouseArea masking).

## Problem Statement

1. **Initial Connection Failures (BlueZ Unpaired State):**
   When connecting to a newly discovered Bluetooth device, `core/services/bluetooth/client_dbus.go` directly called `Device1.Connect`. In BlueZ, unpaired devices require `Device1.Pair` or an authentication handshake first. Without calling `Pair()`, BlueZ rejects the raw `Connect()` call.
2. **Subsequent Connection Failures (Missing `Trusted: true`):**
   When a device is paired, if `Trusted` is not explicitly set to `true`, subsequent connection attempts or reconnects after sleep/reboot can be refused by BlueZ security policies.
3. **Frontend RPC Action Mismatch:**
   In `BluetoothView.qml`, `Component.onCompleted` dispatched `get_bluetooth_devices`, while the Go daemon expected `get_bluetooth_state`.
4. **QML Z-Order & MouseArea Masking:**
   In `BluetoothView.qml`, a full-item `devHover` MouseArea was positioned after the `RowLayout`, intercepting clicks and preventing the user from clicking the "Kes" (Disconnect) button on connected devices.

## Proposed Solution

1. **Backend D-Bus Client (`core/services/bluetooth/client_dbus.go`):**
   - Check if the target device is paired. If not, trigger `Device1.Pair`.
   - Automatically set `Device1.Trusted = true` on the device object.
   - Call `Device1.Connect`.
   - Support `get_bluetooth_devices` as an alias for `get_bluetooth_state` in `core/main.go`.
2. **Frontend QML (`shell/components/widgets/controlcenter/views/BluetoothView.qml`):**
   - Fix initial fetch call to `get_bluetooth_state`.
   - Restructure item delegate so the Connect/Disconnect action button has high z-index and dedicated hover/click handling.
   - Add visual scanning spinner when `ipc.bluetooth.discovering` is true.

## Affected Components
- `[[Bluetooth-Service]]` (`core/services/bluetooth/client_dbus.go`, `core/main.go`)
- `[[Control-Center-Widget]]` (`shell/components/widgets/controlcenter/views/BluetoothView.qml`)
- `[[Backend-Endpoints-Reference]]` (`.agents/BACKEND_ENDPOINTS.md`)
