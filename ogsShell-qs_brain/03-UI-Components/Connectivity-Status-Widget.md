---
title: "Connectivity Status Widget Component (Wi-Fi & Bluetooth)"
type: ui-component
tags:
  - ui/widget
  - widget/network
  - widget/bluetooth
  - quickshell/qml
created: 2026-08-12
updated: 2026-08-23
status: active
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Media-Widget]]"
  - "[[Clock-Widget]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Wifi-Client-Service]]"
  - "[[Bluetooth-Service]]"
  - "[[Style-Design-Tokens]]"
  - "[[Plan-Dynamic-Island-Idle-And-Hover-Typography-Enlargement]]"
---

# Connectivity Status Widget Component (Wi-Fi & Bluetooth)

> [!NOTE]
> `shell/components/widgets/ConnectivityStatusWidget.qml` renders a compact, interactive pill button displaying live Wi-Fi SSID / signal strength and Bluetooth connection status inside the hover layout of the Dynamic Island.

---

## 1. Features & Data Flow

* **Reactivity:** Directly binds to `DaemonIPC` properties (`root.ipc.wifi` and `root.ipc.bluetooth`).
* **Wi-Fi Telemetry:** Displays signal strength graduated Nerd Font icons (`󰤨`, `󰤥`, `󰤢`, `󰤟`, `󰤮` in **`14px`**) alongside the active network SSID in **`11px DemiBold`** (up to 54px text allocation).
* **Bluetooth Telemetry:** Displays adapter power state (`󰂯`, `󰂲` in **`14px`**) and active peripheral connectivity (`󰂱` with active cyan accent indicator dot `5x5px`).
* **Pill Geometry:** Height **`30px`**, width **`104px+`**, radius **`12px`** for balanced proportions alongside the central clock.
* **Interactive Navigation:** Clicking the button triggers `root.clicked()`, smoothly transitioning the Island into the `EXPANDED` mode and focusing the **System** telemetry tab.

---

## 2. Related Links

* Dynamic Island: `[[Dynamic-Island-Component]]`
* IPC Client: `[[Daemon-IPC-Client]]`
* Wi-Fi Service: `[[Wifi-Client-Service]]`
* Bluetooth Service: `[[Bluetooth-Service]]`
* Typography Plan: `[[Plan-Dynamic-Island-Idle-And-Hover-Typography-Enlargement]]`
