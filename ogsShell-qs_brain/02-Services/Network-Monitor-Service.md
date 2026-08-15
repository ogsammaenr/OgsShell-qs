---
title: "Network Monitor Subsystem Service"
type: service
tags:
  - service/network
  - service/wifi
  - go/monitors
  - dbus/signals
  - routing
  - throughput
created: 2026-08-09
updated: 2026-08-10
status: active
related_notes:
  - "[[SysMetrics-Service]]"
  - "[[Wifi-Client-Service]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Go-Coding-Style]]"
  - "[[Plan-Event-Driven-Wifi-Signal-Monitor]]"
---

# Network Monitor Subsystem Service

> [!NOTE]
> Network monitoring is partitioned into two specialized monitors:
> 1. **`NetMonitor` (`core/monitors/net.go`):** Identifies the default gateway interface via `/proc/net/route` and calculates real-time bandwidth throughput (Rx/Tx bytes/sec) via `/proc/net/dev`.
> 2. **`NetworkMonitor` (`core/monitors/network_mon.go`):** An event-driven D-Bus signal listener that reacts instantly to NetworkManager Wi-Fi events (`AccessPointAdded`, `AccessPointRemoved`, `PropertiesChanged`) with a 500ms debouncing engine to broadcast `wifi_update` JSON events over IPC.

---

## 1. Event-Driven D-Bus Signal Architecture (`NetworkMonitor`)

Rather than inefficient 10-second polling, `NetworkMonitor` uses native D-Bus signal matches on NetworkManager:

```mermaid
sequenceDiagram
    autonumber
    participant NM as NetworkManager D-Bus
    participant Mon as NetworkMonitor (Signal Loop)
    participant Timer as 500ms Debounce Timer
    participant IPC as IPC Server Broadcaster
    participant QML as Quickshell DaemonIPC

    Mon->>IPC: Immediate Initial Push (wifi_update)
    NM->>Mon: AccessPointAdded / PropertiesChanged
    Mon->>Timer: Reset Debounce Timer (500ms)
    Note over Mon,Timer: Multiple burst signals consolidate
    Timer->>Mon: Debounce Expired
    Mon->>NM: ScanAccessPoints()
    Mon->>IPC: Broadcast(Event{type: "wifi_update", payload})
    IPC->>QML: NDJSON line (wifi_update)
```

### Signal Match Filters
* `org.freedesktop.NetworkManager.Device.Wireless.AccessPointAdded`
* `org.freedesktop.NetworkManager.Device.Wireless.AccessPointRemoved`
* `org.freedesktop.DBus.Properties.PropertiesChanged` (filtered for `/org/freedesktop/NetworkManager*` paths)

---

## 2. Bandwidth Throughput Calculation (`NetMonitor`)

```mermaid
graph TD
    ROUTE["/proc/net/route"] --> DEF_IFACE["getDefaultInterface()<br/>Find mask 00000000"]
    DEF_IFACE --> NET_DEV["/proc/net/dev"]
    NET_DEV --> SNAP["readNetSnapshot()<br/>Parse rx_bytes & tx_bytes for target iface"]
    SNAP --> CALC["GetInfo() Throughput Delta"]
    CALC --> OUT["NetworkInfo {RxBytesPerSec, TxBytesPerSec, Interface, IsConnected}"]
```

### Rate of Transfer Formula
$$\Delta t = \text{now} - \text{timestamp}_{\text{prev}}$$
$$\text{Rx Speed} = \frac{\text{rx}_{\text{curr}} - \text{rx}_{\text{prev}}}{\Delta t} \quad (\text{bytes/sec})$$
$$\text{Tx Speed} = \frac{\text{tx}_{\text{curr}} - \text{tx}_{\text{prev}}}{\Delta t} \quad (\text{bytes/sec})$$

---

## 3. Related Links

* Aggregator Manager: `[[SysMetrics-Service]]`
* Wi-Fi Management Client: `[[Wifi-Client-Service]]`
* IPC Schema: `[[IPC-Socket-Schema]]`
* Frontend Socket Client: `[[Daemon-IPC-Client]]`
* Proposal Note: `[[Plan-Event-Driven-Wifi-Signal-Monitor]]`
