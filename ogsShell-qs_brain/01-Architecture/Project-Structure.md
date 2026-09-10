---
title: "OgsShell-qs Complete Project Structure & Mermaid.js Architecture"
type: architecture
tags:
  - architecture/overview
  - architecture/diagrams
  - mermaid/system
  - wayland/hyprland
  - quickshell/qml
  - go/daemon
created: 2026-09-10
updated: 2026-09-10
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Go-Daemon-Core]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Configuration-System-Spec]]"
  - "[[Configuration-Themes-Spec]]"
  - "[[Style-Design-Tokens]]"
  - "[[Control-Center-Widget]]"
  - "[[Clock-Suite-View]]"
  - "[[Calendar-Widget]]"
  - "[[App-Launcher-Widget]]"
---

# OgsShell-qs Complete Project Structure & Mermaid.js Architecture

> [!NOTE]
> Bu doküman, `OgsShell-qs` sisteminin tüm alt servislerini, QML bileşenlerini, IPC veri hatlarını ve dosya ağacını görselleştiren Obsidian bilgi bankası mimari referansıdır. Proje kök dizinindeki [`PROJECT_STRUCTURE.md`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/PROJECT_STRUCTURE.md) dosyası ile eşzamanlıdır.

---

## 1. Genel Sistem Mimarisi (High-Level Architecture)

```mermaid
graph TB
    subgraph Subsystems ["🐧 Linux Kernel, Hardware & OS Subsystems"]
        PROC["/proc/stat, /proc/meminfo, /proc/net/dev"]
        THERMAL["/sys/class/thermal, /sys/class/drm"]
        SYS_DBUS["System & Session D-Bus<br/>(NetworkManager, BlueZ, WirePlumber)"]
        HYPR_SOCK["Hyprland IPC (.socket2.sock)"]
        WAYLAND_ENV["Wayland (wl-copy, cliphist)"]
        XKB_DB["XKB Database (evdev.lst)"]
    end

    subgraph Core_Daemon ["⚙️ Go Backend Daemon (core/)"]
        MAIN["[[Go-Daemon-Core]]<br/>main.go"]
        LOGGER["[[Logger-Service]]"]
        
        subgraph Core_Monitors ["Telemetry Monitors"]
            MON_MGR["[[SysMetrics-Service]]"]
            MON_CPU["[[CPU-Monitor-Service]]"]
            MON_RAM["[[RAM-Monitor-Service]]"]
            MON_GPU["[[GPU-Monitor-Service]]"]
            MON_NET["[[Network-Monitor-Service]]"]
        end

        subgraph Core_Services ["Background Services"]
            SRV_WIFI["[[Wifi-Client-Service]]"]
            SRV_BT["[[Bluetooth-Service]]"]
            SRV_ALARM["[[Alarm-Service]]"]
            SRV_CAL["[[Calendar-Service]]"]
            SRV_NOTIF["[[Notification-Service]]"]
            SRV_CLIP["[[Clipboard-Service]]"]
            SRV_KB["[[Keyboard-Service]]"]
            SRV_THEME["[[Theme-Service]]"]
            SRV_LAUNCH["[[App-Launcher-Service]]"]
        end

        IPC_SERVER["[[IPC-Server-Service]]<br/>(NDJSON Socket Server)"]
    end

    subgraph IPC_Transport ["🔌 Transport Layer"]
        UDS_SOCKET["[[IPC-Socket-Schema]]<br/>($XDG_RUNTIME_DIR/ogs_shell.sock)"]
    end

    subgraph Frontend_Shell ["🎨 Quickshell Frontend (shell/)"]
        SHELL_ROOT["[[Shell-Root-PanelWindow]]<br/>(shell.qml Scope)"]
        
        subgraph Window_Layers ["Wayland Windows"]
            WIN_ISLAND["islandWindow (540x360 Surface)"]
            WIN_BACKDROP["backdropWindow (Dismiss Layer)"]
            WIN_SPACER["reservedSpacerWindow (Top Margin)"]
        end

        subgraph Singletons ["Singletons & Services"]
            IPC_CLIENT["[[Daemon-IPC-Client]]<br/>(DaemonIPC.qml)"]
            CONFIG_CLIENT["[[Configuration-System-Spec]]<br/>(Config.qml)"]
            STYLE_CLIENT["[[Style-Design-Tokens]]<br/>(Style.qml)"]
            AUDIO_FEEDBACK["[[Audio-Feedback-Service]]"]
            POWER_SERVICE["PowerService.qml"]
        end

        subgraph Dynamic_Container ["Dynamic Island Container"]
            ISLAND_MAIN["[[Dynamic-Island-Component]]<br/>[[Dynamic-Notch-Design-Specification]]<br/>[[Dynamic-Island-Physics-State-Machine]]"]
            WIDGET_SUITE["[[Clock-Suite-View]] | [[Calendar-Widget]] | [[Control-Center-Widget]] | [[App-Launcher-Widget]] | [[Media-Player-View]]"]
        end

        subgraph Corner_HUD ["Screen Corners & Edge HUD"]
            SCREEN_CORNERS["[[Screen-Corners-Component]]"]
            CORNER_HUD["[[Corner-Island-HUD-Component]]"]
        end
    end

    subgraph Settings_App ["🛠️ Standalone Settings App"]
        SET_ROOT["[[Settings-Application-Component]]"]
    end

    PROC & THERMAL --> MON_CPU & MON_RAM & MON_GPU & MON_NET --> MON_MGR
    SYS_DBUS <--> SRV_WIFI & SRV_BT
    HYPR_SOCK <--> SRV_KB & SRV_THEME
    WAYLAND_ENV <--> SRV_CLIP & SRV_LAUNCH
    XKB_DB --> SRV_KB

    MAIN --> LOGGER & IPC_SERVER & MON_MGR
    MON_MGR & SRV_WIFI & SRV_BT & SRV_ALARM & SRV_CAL & SRV_NOTIF & SRV_CLIP & SRV_KB & SRV_THEME & SRV_LAUNCH --> IPC_SERVER

    IPC_SERVER <==>|NDJSON Stream| UDS_SOCKET
    UDS_SOCKET <==> IPC_CLIENT

    IPC_CLIENT & CONFIG_CLIENT & STYLE_CLIENT --> SHELL_ROOT
    SHELL_ROOT --> Window_Layers
    WIN_ISLAND --> ISLAND_MAIN --> WIDGET_SUITE
    SHELL_ROOT --> Corner_HUD
    IPC_CLIENT <--> SET_ROOT
```

---

## 2. Frontend Bileşen Ağacı

```mermaid
graph TD
    subgraph Root_Scope ["[[Shell-Root-PanelWindow]] (shell.qml Scope)"]
        RESERVED_SPACER["reservedSpacerWindow"]
        BACKDROP_WIN["backdropWindow"]
        ISLAND_WIN["islandWindow"]
    end

    subgraph Dynamic_Island_Container ["[[Dynamic-Island-Component]]"]
        SHAPE_SELECTOR{"form_factor"}
        ISLAND_SHAPE["Floating Island<br/>[[Apple-Dynamic-Island-HIG]]"]
        NOTCH_SHAPE["Unified Vector Notch<br/>[[Dynamic-Notch-Design-Specification]]"]
        STATE_MACHINE["Physics & State Machine<br/>[[Dynamic-Island-Physics-State-Machine]]"]
        
        SHAPE_SELECTOR -->|'island'| ISLAND_SHAPE
        SHAPE_SELECTOR -->|'notch'| NOTCH_SHAPE
        ISLAND_SHAPE & NOTCH_SHAPE --> STATE_MACHINE
    end

    ISLAND_WIN --> Dynamic_Island_Container

    subgraph Island_Widgets ["Widgets"]
        W_CLOCK["[[Clock-Widget]]"]
        W_METRICS["[[Pinned-Metrics-Widget]]"]
        W_CONN["[[Connectivity-Status-Widget]]"]
        W_MEDIA["[[Media-Widget]]"]

        subgraph Clock_Suite ["[[Clock-Suite-View]]"]
            CLOCK_MGR["[[Clock-Manager]]"]
            TAB_WORLD["WorldClockTab"]
            TAB_ALARM["AlarmsTab"]
            TAB_STOPWATCH["StopwatchTab"]
            TAB_POMODORO["PomodoroTab"]
        end

        subgraph Calendar_Suite ["[[Calendar-Widget]]"]
            V_MONTH["MonthGridView"]
            V_DAY["DayDetailView"]
            W_TIMEPICKER["[[Time-Picker-Component]]"]
        end

        subgraph Control_Center ["[[Control-Center-Widget]]"]
            CC_VIEW["ControlCenterView"]
            CC_POWER["[[Power-Overlay-Component]]"]
            VIEW_WIFI["WifiView"]
            VIEW_BT["BluetoothView"]
            VIEW_AUDIO["[[Audio-Mixer-View]]"]
            VIEW_THEMES["ThemesView"]
            VIEW_NOTIF["NotificationsView"]
            VIEW_CLIP["ClipboardView"]
            VIEW_KB["KeyboardLayoutView"]
        end

        subgraph Launcher ["[[App-Launcher-Widget]]"]
            W_LAUNCHER["Spotlight Fuzzy Launcher"]
        end

        subgraph Media ["[[Media-Player-View]]"]
            V_MEDIA_PLAYER["MPRIS Player Controls"]
        end
    end

    STATE_MACHINE --> Island_Widgets
```

---

## 3. İlgili Mimari ve Servis Notları

* Sistem Mimarisi Detayları: `[[System-Architecture]]`
* IPC API Uçları & JSON Şeması: `[[Backend-Endpoints-Reference]]` & `[[IPC-Socket-Schema]]`
* Go Daemon Çekirdeği: `[[Go-Daemon-Core]]`
* Konfigürasyon ve Canlı Yenileme: `[[Configuration-System-Spec]]`
* Tema Yönetimi & Adaptörler: `[[Configuration-Themes-Spec]]` & `[[Theme-Service]]`
