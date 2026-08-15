---
title: "Connectivity Status Widget Component (Wi-Fi & Bluetooth)"
type: ui-component
tags:
  - ui/widget
  - widget/network
  - widget/bluetooth
  - quickshell/qml
created: 2026-08-12
updated: 2026-08-12
status: active
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Media-Widget]]"
  - "[[Clock-Widget]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Wifi-Client-Service]]"
  - "[[Bluetooth-Service]]"
  - "[[Style-Design-Tokens]]"
---

# Connectivity Status Widget Component (Wi-Fi & Bluetooth)

> [!NOTE]
> `shell/components/widgets/ConnectivityStatusWidget.qml` renders a compact, interactive pill button displaying live Wi-Fi SSID / signal strength and Bluetooth connection status inside the hover layout of the Dynamic Island.

---

## 1. Features & Data Flow

* **Reactivity:** Directly binds to `DaemonIPC` properties (`root.ipc.wifi` and `root.ipc.bluetooth`).
* **Wi-Fi Telemetry:** Displays signal strength graduated Nerd Font icons (`󰤨`, `󰤥`, `󰤢`, `󰤟`, `󰤮`) alongside the active network SSID.
* **Bluetooth Telemetry:** Displays adapter power state (`󰂯`, `󰂲`) and active peripheral connectivity (`󰂱` with active cyan accent indicator dot).
* **Interactive Navigation:** Clicking the button triggers `root.clicked()`, smoothly transitioning the Island into the `EXPANDED` mode and focusing the **System** telemetry tab.

---

## 2. Related Links

* Dynamic Island: `[[Dynamic-Island-Component]]`
* IPC Client: `[[Daemon-IPC-Client]]`
* Wi-Fi Service: `[[Wifi-Client-Service]]`
* Bluetooth Service: `[[Bluetooth-Service]]`
