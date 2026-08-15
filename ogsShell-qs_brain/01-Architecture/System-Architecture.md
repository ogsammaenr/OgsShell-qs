---
title: "OgsShell-qs System Architecture"
type: architecture
tags:
  - architecture/overview
  - wayland/hyprland
  - quickshell/qml
  - go/daemon
  - config/json
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[IPC-Socket-Schema]]"
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Configuration-System-Spec]]"
  - "[[Go-Daemon-Core]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Configuration-Themes-Spec]]"
---

# OgsShell-qs System Architecture

> [!NOTE]
> `ogsShell-qs` is a modular, high-performance Wayland desktop shell environment optimized for Hyprland. It features dual presentation modes (**Dynamic Island** and **Dynamic Notch**) running on Quickshell QML, powered by an asynchronous low-overhead **Go daemon** backend over Unix Domain Sockets and configured dynamically via `config.json`.

---

## 1. High-Level Architectural Decomposition

The system is decoupled into two primary layers connected via an asynchronous Newline-Delimited JSON (NDJSON) Unix Domain Socket IPC:

1. **Backend Layer (`core/` - Go Daemon):**
   * Manages hardware polling, sysfs/procfs monitoring, D-Bus events, and system metrics aggregation.
   * Runs independently of the graphical session as a background daemon (`ogsshell-core`).
   * Broadcasts real-time events over `/run/user/1000/ogs_shell.sock` without blocking the main event loop.
2. **Frontend Layer (`shell/` - Quickshell QML):**
   * Implements a Wayland LayerShell overlay (`Scope` coordinating `islandWindow` and `backdropWindow`) configured with `ExclusionMode.Ignore`.
   * Houses the `DynamicIsland` container, handling fluid spring animations, state machines (`IDLE`, `HOVER`, `EXPANDED`, `TRANSIENT`), and dual form-factors (`"island"` vs `"notch"`).
   * Reads dynamic configuration from `config.json` via `Config.qml` singleton.
   * Listens to IPC socket streams reactively via `DaemonIPC.qml` and binds system telemetry to the UI.

```mermaid
graph TB
    subgraph Config & Theming
        JSON_CFG["config.json<br/>[[Configuration-System-Spec]]"]
        CFG_MGR["Config Singleton<br/>(backend/Config.qml)"]
        JSON_CFG --> CFG_MGR
    end

    subgraph Backend Core ["core/ (Go Daemon)"]
        MON_MGR["[[SysMetrics-Service]]<br/>Manager Loop (1s Ticker)"]
        IPC_SRV["[[IPC-Server-Service]]<br/>Unix Domain Socket Server"]
        MON_MGR -->|Event: sys_metrics| IPC_SRV
    end

    subgraph IPC Transport Layer
        SOCKET["/run/user/1000/ogs_shell.sock<br/>[[IPC-Socket-Schema]] (NDJSON)"]
        IPC_SRV -->|Broadcast Event| SOCKET
    end

    subgraph Frontend Shell ["shell/ (Quickshell QML)"]
        SCOPE_WIN["[[Shell-Root-PanelWindow]]<br/>(Scope: islandWindow + backdropWindow)"]
        DAEMON_IPC["[[Daemon-IPC-Client]]<br/>Socket / SplitParser"]
        STYLE_TOKENS["[[Style-Design-Tokens]]<br/>(Style.qml Singleton)"]
        
        subgraph Island ["Dynamic Island / Notch Container"]
            ISLAND_CONT["[[Dynamic-Island-Component]]<br/>(Island vs Notch Modes)"]
            CLOCK_WIDGET["[[Clock-Widget]]"]
        end
        
        SOCKET -->|NDJSON Stream| DAEMON_IPC
        CFG_MGR -->|form_factor, geometries| ISLAND_CONT
        CFG_MGR -->|top_margin| SCOPE_WIN
        DAEMON_IPC -->|Reactive Props| ISLAND_CONT
        STYLE_TOKENS -->|Colors & Physics| ISLAND_CONT
        SCOPE_WIN --> ISLAND_CONT
        ISLAND_CONT --> CLOCK_WIDGET
    end

    subgraph Design Specifications
        APPLE_HIG["[[Apple-Dynamic-Island-HIG]]"]
        NOTCH_SPEC["[[Dynamic-Notch-Design-Specification]]"]
        PHYSICS_SPEC["[[Dynamic-Island-Physics-State-Machine]]"]
        
        APPLE_HIG -.-> ISLAND_CONT
        NOTCH_SPEC -.-> ISLAND_CONT
        PHYSICS_SPEC -.-> ISLAND_CONT
    end
```

---

## 2. Directory and Component Map

| Path                                   | Purpose                                  | Documentation Link                                                       |
| :------------------------------------- | :--------------------------------------- | :----------------------------------------------------------------------- |
| `shared/app_configs/shell/config.json` | Master JSON user configuration           | `[[Configuration-System-Spec]]`                                          |
| `shell/backend/Config.qml`             | Reactive config file reader singleton    | `[[Configuration-System-Spec]]`                                          |
| `shell/shell.qml`                      | Quickshell root Wayland LayerShell scope | `[[Shell-Root-PanelWindow]]`                                             |
| `shell/components/island/`             | Dual format (Island & Notch) container   | `[[Dynamic-Island-Component]]`, `[[Dynamic-Notch-Design-Specification]]` |
| `shell/components/widgets/`            | Pluggable island widgets                 | `[[Clock-Widget]]`                                                       |
| `shell/theme/`                         | Central QML style singleton              | `[[Style-Design-Tokens]]`                                                |
