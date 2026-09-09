---
title: "Plan: Control Center Wired Ethernet Management"
type: agent-thought
tags:
  - control-center/network
  - ethernet/wired
  - quickshell/qml
  - apple-hig
created: 2026-09-07
updated: 2026-09-07
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Wifi-Client-Service]]"
  - "[[Daemon-IPC-Client]]"
---

# Plan: Control Center Wired Ethernet & Network Management

> [!NOTE]
> Unified management of **Wired (Ethernet)** and **Wireless (Wi-Fi)** connections implemented in `shell/components/widgets/controlcenter/views/WifiView.qml`, `ControlCenterMain.qml`, and `ConnectivityStatusWidget.qml`.

## 1. Objectives & User Requirements
- The user requested the ability to manage wired (ethernet) connections in the Control Center's Wi-Fi / Network application.
- When an Ethernet cable is plugged in or available, the system shows Ethernet interfaces (e.g., `enp0s20f0u4`, `eth0`), active status, IP address, gateway, MAC, and carrier state.
- Provide user controls to Connect / Disconnect wired interfaces and switch between saved profiles.
- In `ControlCenterMain.qml`, display adaptive iconography and labels (`󰈀` for wired Ethernet, `󰤨` for Wi-Fi, or combined status) in the connectivity tile.
- In `ConnectivityStatusWidget.qml`, reflect active Ethernet / Wi-Fi status on the Dynamic Island top pill.

## 2. Implementation Summary
1. **`WifiView.qml` (Ağ ve Bağlantı Yöneticisi):**
   - **Segmented / Tab Navigation:** Apple HIG style segmented toggle (`[ 󰈀 Kablolu ]` and `[ 󰤨 Wi-Fi ]`) with real-time green/cyan connection indicator dots.
   - **Wired (Ethernet) Sub-view:**
     - Runs asynchronous `nmcli` processes (`device status`, `device show`, `connection show`).
     - Displays Active Ethernet Connection card with interface name, IP address (`10.70.71.62/24`), Gateway, and a "Bağlantıyı Kes" button.
     - Lists all physical Ethernet interfaces with carrier states (Connected, Ready/Disconnected, Cable Unplugged/Unavailable) and action buttons ("Bağlan", "Bağlantıyı Kes").
   - **Wireless (Wi-Fi) Sub-view:**
     - Preserves full Wi-Fi scanning, signal strength bars, security badges, and password input modal.
2. **`ControlCenterMain.qml`:**
   - Detects `isEthernetConnected` and dynamically updates the Connectivity tile to show `󰈀` (green badge) with "Kablolu Ağ" and interface name when wired connection is active.
3. **`ConnectivityStatusWidget.qml`:**
   - Adapts the Dynamic Island pill icon (`󰈀` in green for wired ethernet, `󰤨` for Wi-Fi).

## 3. Verification & Testing
- Validated with `qmllint`: zero syntax errors or warnings.
- Tested `nmcli` parsing logic across physical adapters and carrier states.
