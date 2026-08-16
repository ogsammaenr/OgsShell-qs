---
title: "Dynamic Island Core QML Component"
type: ui-component
tags:
  - ui/dynamic-island
  - quickshell/qml
  - state-machine
  - animations
  - transient/notifications
  - hover-state
created: 2026-08-09
updated: 2026-08-16
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Clock-Widget]]"
  - "[[Media-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Control-Center-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Plan-Hover-Expanded-Status-Bar]]"
  - "[[Plan-Hover-Right-Click-Control-Center]]"
  - "[[Plan-Dynamic-Island-System-Metrics-Pinning]]"
---

# Dynamic Island Core QML Component

> [!NOTE]
> `shell/components/island/DynamicIsland.qml` contains the core UI container, reactive sizing calculations, spring animations, state machine (`IDLE`, `HOVER`, `EXPANDED`, `TRANSIENT`), D-Bus notification receiver, and gesture handling.

---

## 1. State Machine & Visual Layers

```mermaid
graph TD
    IDLE["IDLE State<br/>(180x36, Compact Clock)"] -->|Mouse Enter| HOVER["HOVER State<br/>(420x50, 3-Column Status Bar)"]
    HOVER -->|Mouse Exit| IDLE
    HOVER -->|Left Click Time| EXPANDED_CLOCK["EXPANDED State (Clock App)"]
    HOVER -->|Left Click Date| EXPANDED_CAL["EXPANDED State (Calendar App)"]
    HOVER -->|Right Click Island| EXPANDED_CC["EXPANDED State (Control Center)"]
    HOVER -->|Left Click Network Pill| EXPANDED_CC
    
    ANY["IDLE / HOVER"] -->|triggerNotification() / notify-send| TRANSIENT["TRANSIENT State<br/>(340x56, Notification Toast)"]
    TRANSIENT -->|transientTimer.onTriggered| IDLE
    TRANSIENT -->|Click Body| IDLE
```

---

## 2. Geometry & Gesture Interactions

* **IDLE State:** `180-190px` $\times$ `34-36px`. Displays single-line `[[Clock-Widget]]`.
* **HOVER State:** `420-430px` $\times$ `48-50px`. Expands into a 3-column status bar with:
  * Left: `[[Media-Widget]]` (MPRIS Player & Animated Equalizer, Left-click toggles play/pause)
  * Center: `[[Clock-Widget]]` (Left-click Time opens Clock Suite, Left-click Date opens Calendar)
  * Right: `[[Connectivity-Status-Widget]]` (Wi-Fi & Bluetooth Button, Left-click opens Control Center)
  * **Ada Geneli Sağ Tık (Right-Click):** Hover durumundayken adanın herhangi bir yerine sağ tıklandığında anında `[[Control-Center-Widget]]` açılır.
* **EXPANDED State:** Full modal with Clock Suite, Calendar & Events, or Control Center Suite.
  * **5-Saniye Odak/Ayrılma Zaman Aşımı (5s Unfocus Auto-Collapse):** Ada genişletilmiş moddayken fare imleci adanın dışına çıktığında 5 saniyelik bir geri sayım başlar. İmleç 5 saniye dolmadan adaya geri dönerse sayaç sıfırlanır; 5 saniye boyunca dönmezse ada kendiliğinden `IDLE` moduna kapanır.
* **TRANSIENT State:** `340-350px` $\times$ `56-58px`. Shows leading notification pulsing badge, bold summary title, and secondary message body.

---

## 3. Related Links

* Shell Root: `[[Shell-Root-PanelWindow]]`
* Clock Widget: `[[Clock-Widget]]`
* Media Widget: `[[Media-Widget]]`
* Connectivity Status Widget: `[[Connectivity-Status-Widget]]`
* Control Center: `[[Control-Center-Widget]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Implementation Plans: `[[Plan-Hover-Expanded-Status-Bar]]`, `[[Plan-Hover-Right-Click-Control-Center]]`
