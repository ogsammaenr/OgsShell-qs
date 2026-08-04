---
title: "Bluetooth Service"
type: service
tags:
  - service/bluetooth
  - script/bash
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[ControlCenter-UI]]"
---

# Bluetooth Service

> [!NOTE]
> `BluetoothService.qml` controls Bluetooth pairing, connections, and device discovery by executing `bin/bluetooth_helper.sh`.

## Helper Script (`bin/bluetooth_helper.sh`)

- Interfaced with `bluetoothctl`.
- Returns pipe-delimited device details (`MAC | Name | Connected | Paired | Icon`).

## Related Notes
- Control Center UI: `[[ControlCenter-UI]]`
