# OgsShell-qs System Architecture Reference

> **Notice:** This document serves as the master architectural reference for AI agents operating on `ogsShell-qs`. For comprehensive wikilinked Obsidian documentation, consult the `ogsShell-qs_brain/` vault.

---

## 1. Architectural Overview

`ogsShell-qs` is a modular, high-performance Wayland desktop shell designed for Hyprland. It features dual presentation modes (**Dynamic Island** and **Dynamic Notch**) built in Quickshell QML, configured dynamically via `config.json`, and powered by an asynchronous low-overhead Go daemon over a Unix Domain Socket IPC.

```text
┌────────────────────────────────────────────────────────┐
│               Linux Kernel & Subsystems                │
│  (/proc/stat, /proc/meminfo, /proc/net/dev, NVML/DRM)  │
└───────────────────────────┬────────────────────────────┘
                            │ Hardware Polling / D-Bus
┌───────────────────────────▼────────────────────────────┐
│              Go Backend Daemon (core/)                 │
│  - monitors.Manager (1s collection loop)               │
│  - services/wifi.WifiManager (D-Bus & Mock Clients)    │
│  - services/bluetooth.BluetoothManager (BlueZ D-Bus)   │
│  - Profile & Secrets Engine (WPA/WPA2/WPA3 PSK keys)   │
│  - cpu, ram, gpu, net, bluetooth monitoring routines   │
│  - ipc.Server (Unix Domain Socket Broadcaster)         │
│  - logger (ANSI structured slog handler)               │
└───────────────────────────┬────────────────────────────┘
                            │ NDJSON Stream
                            │ (/run/user/1000/ogs_shell.sock)
┌───────────────────────────▼────────────────────────────┐
│          Quickshell Frontend Shell (shell/)            │
│  - Config.qml (Dynamic config.json watcher singleton)  │
│  - Scope (Root container coordinating multi-windows)   │
│  - reservedSpacerWindow (Top exclusive tiling spacer)  │
│  - backdropWindow (Fullscreen click-outside dismiss)   │
│  - islandWindow (Fixed 540x360 stable Wayland surface) │
│  - DynamicIsland (Island vs Notch presentation modes)  │
│  - DaemonIPC (Socket & SplitParser JSON receiver)      │
│  - Style.qml (Catppuccin & Pure OLED Black tokens)     │
└────────────────────────────────────────────────────────┘
```

---

## 2. WiFi & Secrets Management Service (`core/services/wifi/`)

* **Interface-Driven:** `wifi.WifiManager` interface abstracts NetworkManager D-Bus and Mock implementations.
* **Secrets Management:** `GetProfileSecrets` (`Settings.Connection.GetSecrets`) reads stored WPA passwords/keys; `UpdateProfileSecrets` updates stored credentials.
* **IPC Endpoints:** `scan_wifi`, `get_saved_wifi_profiles`, `get_wifi_secrets`, `connect_wifi`, `update_wifi_secrets`, `delete_wifi_profile`, `set_wifi_enabled`, `get_active_wifi`.

---

## 3. Bluetooth Management Service (`core/services/bluetooth/`)

* **Interface-Driven:** `bluetooth.BluetoothManager` interface abstracts BlueZ D-Bus (`org.bluez`) and in-memory mock implementations.
* **D-Bus Signal Subscriptions:** Reacts in real-time to `PropertiesChanged`, `InterfacesAdded`, and `InterfacesRemoved` signals on adapter and device objects.
* **IPC Broadcast:** Dispatches `bluetooth_update` events with adapter power, discovery state, and peripheral details (MAC, Name, Icon, Connected, Paired, RSSI).
* **IPC Endpoints:** `toggle_bluetooth`, `connect_bluetooth`, `disconnect_bluetooth`, `start_bluetooth_scan`, `stop_bluetooth_scan`, `get_bluetooth_state`.

---

## 4. Alarm & Scheduler Service (`core/services/alarm/`)

* **Persistent JSON Storage:** Saves alarms to `$XDG_CONFIG_HOME/ogsShell/alarms.json` with atomic disk commits.
* **Low-Overhead Event Scheduling:** Calculates earliest upcoming trigger (one-shot or recurring weekdays) and sets a single `time.Timer` (zero busy-polling).
* **Audio Process Control:** Spawns `pw-play` (or `paplay`) while holding process references to allow instant killing upon dismiss or snooze.
* **IPC Endpoints:** `add_alarm`, `delete_alarm`, `toggle_alarm`, `snooze_alarm`, `dismiss_alarm`, `get_alarms`.

---

## 5. Calendar & Holiday Service (`core/services/calendar/`)

* **Turkish Holiday Engine:** Computes static national and Islamic religious holidays (Ramazan/Kurban + Arefeler) for accurate monthly matrix badges.
* **Persistent Event Storage:** Stores reminders/events in `$XDG_CONFIG_HOME/ogsShell/calendar_events.json` with atomic disk commits.
* **Low-Overhead Event Scheduling:** Calculates earliest upcoming reminder time and triggers PipeWire alert and `calendar_reminder_triggered` event.
* **IPC Endpoints:** `get_calendar_month`, `add_calendar_event`, `update_calendar_event`, `delete_calendar_event`, `toggle_calendar_event`, `get_holidays`.

---

## 6. Notification, DND & App Rules Service (`core/services/notifications/`)

* **Persistent History Storage:** Stores notification history in `$XDG_CONFIG_HOME/ogsShell/notifications.json` (max 100 entries).
* **Do Not Disturb (DND) Engine:** Global toggle suppressing transient Island HUD alerts while silently appending incoming alerts to history (critical urgency alerts bypass DND).
* **App-Specific Filtering Rules:** Custom per-app behaviors (`normal`, `mute`, `block`, `priority`) saved to `$XDG_CONFIG_HOME/ogsShell/notification_rules.json`.
* **IPC Endpoints:** `add_notification`, `get_notifications`, `delete_notification`, `clear_notifications`, `mark_notification_read`, `toggle_dnd`, `get_dnd_state`, `set_notification_rule`, `delete_notification_rule`, `get_notification_rules`.

---

## 7. Clipboard History & Pinned Snippets Service (`core/services/clipboard/`)

* **Wayland & Cliphist Integration:** Queries and decodes clipboard entries from `cliphist` with `wl-copy` instant restore.
* **Pinned Favorites Storage:** Persists bookmarked snippets/templates in `$XDG_CONFIG_HOME/ogsShell/clipboard_pinned.json` with atomic disk commits.
* **Live Clipboard Watcher:** Background routine detects new clipboard items and broadcasts `clipboard_update` and `clipboard_item_copied` in real-time.
* **IPC Endpoints:** `get_clipboard_history`, `copy_clipboard_item`, `get_clipboard_content`, `delete_clipboard_item`, `clear_clipboard_history`, `pin_clipboard_item`, `unpin_clipboard_item`, `get_pinned_clipboard_items`.

---

## 8. Keyboard Layout Manager Service (`core/services/keyboard/`)

* **Hyprland IPC & Socket2 Listener:** Connects to `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock` and captures `activelayout>>` events when hardware hotkeys (`Super+Space`) are pressed.
* **Instant Synchronous Switching:** Invokes `hyprctl switchxkblayout all <target>` to update all physical/virtual input devices.
* **XKB Layout Database:** Parses system `/usr/share/X11/xkb/rules/evdev.lst` and maps layout codes to localized names.
* **Configuration Persistence:** Stores custom layout sets in `$XDG_CONFIG_HOME/ogsShell/keyboard_config.json`.
* **IPC Endpoints:** `get_keyboard_layout`, `switch_keyboard_layout`, `set_configured_layouts`, `get_available_system_layouts`.

---

## 9. Theme Management & Multi-App Dispatcher Service (`core/services/theme/`)

* **Dynamic JSON Palettes:** Auto-discovers and manages theme palettes in `$XDG_CONFIG_HOME/ogsShell/themes/`.
* **Type-Safe Concrete App Adapters:**
  - **Hyprland:** Instant border recoloring (`hyprctl keyword general:col.active_border`) and `colors.conf`.
  - **Kitty:** `current-theme.conf` and live signal reload (`pkill -SIGUSR1 kitty`).
  - **Zed Editor:** Safe JSON patching of `"theme"` in `~/.config/zed/settings.json`.
  - **Vesktop (Discord/Vencord):** CSS custom properties at `~/.config/vesktop/themes/ogsshell.theme.css`.
  - **Neovim (LazyVim):** Updating `colorscheme` hook in `~/.config/nvim/lua/plugins/theme.lua` and live socket reload.
  - **Dolphin / Qt:** Dispatching `plasma-apply-colorscheme` or `kdeglobals`.
* **Concurrent Error-Isolated Dispatcher:** Applies theme updates in parallel goroutines.
* **IPC Endpoints:** `get_theme_state`, `get_available_themes`, `set_active_theme`, `save_custom_theme`, `delete_custom_theme`, `toggle_theme_adapter`.

---

## 10. Obsidian Brain Vault Reference Map

* **`01-Architecture/`**: `[[System-Architecture]]`, `[[Backend-Endpoints-Reference]]`, `[[IPC-Socket-Schema]]`, `[[Apple-Dynamic-Island-HIG]]`, `[[Apple-HIG-Minimal-Design-System]]`, `[[Dynamic-Notch-Design-Specification]]`, `[[Dynamic-Island-Physics-State-Machine]]`, `[[Configuration-System-Spec]]`, `[[Configuration-Themes-Spec]]`
* **`02-Services/`**: `[[Go-Daemon-Core]]`, `[[Theme-Service]]`, `[[Keyboard-Service]]`, `[[Clipboard-Service]]`, `[[Notification-Service]]`, `[[Wifi-Client-Service]]`, `[[Bluetooth-Service]]`, `[[Alarm-Service]]`, `[[Calendar-Service]]`, `[[SysMetrics-Service]]`, `[[CPU-Monitor-Service]]`, `[[RAM-Monitor-Service]]`, `[[GPU-Monitor-Service]]`, `[[Network-Monitor-Service]]`, `[[Logger-Service]]`, `[[IPC-Server-Service]]`
* **`03-UI-Components/`**: `[[Shell-Root-PanelWindow]]`, `[[Dynamic-Island-Component]]`, `[[Power-Overlay-Component]]`, `[[Clock-Widget]]`, `[[Clock-Suite-View]]`, `[[Clock-Manager]]`, `[[Calendar-Widget]]`, `[[Time-Picker-Component]]`, `[[Media-Widget]]`, `[[Connectivity-Status-Widget]]`, `[[Control-Center-Widget]]`, `[[Style-Design-Tokens]]`, `[[Daemon-IPC-Client]]`
* **`04-Agent-Rules/`**: `[[Go-Coding-Style]]`, `[[QML-Best-Practices]]`, `[[Agent-Workflow-Directives]]`
* **`05-Agent-Thoughts/`**: `[[Plan-Obsidian-Vault-And-Dynamic-Island-Analysis]]`, `[[Plan-Rebuild-Dynamic-Island-Test]]`, `[[Plan-Animation-Performance-And-Click-Outside]]`, `[[Plan-Dynamic-Island-Transient-Notifications]]`, `[[Plan-Dual-Format-Island-And-Notch-Architecture]]`, `[[Plan-Unified-Vector-Shape-Notch]]`, `[[Plan-High-DPI-Anti-Aliasing-And-Proportional-Notch-Slope]]`, `[[Plan-Borderless-Pure-Black-Silhouette]]`, `[[Plan-Modular-WiFi-Settings-And-Secrets-Client]]`, `[[Plan-Modular-Bluetooth-Service-And-DBus-Monitor]]`, `[[Plan-Event-Driven-Wifi-Signal-Monitor]]`, `[[Plan-Event-Driven-Bluetooth-Signal-Monitor]]`, `[[Plan-Persistent-Alarm-Service-And-Scheduler]]`, `[[Plan-Calendar-And-Holiday-Engine]]`, `[[Plan-Backend-Endpoints-Documentation]]`, `[[Plan-Notification-Center-And-Rules-Service]]`, `[[Plan-Clipboard-History-Service]]`, `[[Plan-Keyboard-Layout-Service]]`, `[[Plan-Theme-Management-Service]]`, `[[Plan-Hover-Expanded-Status-Bar]]`, `[[Plan-Clock-App-Suite-And-Live-Activities]]`, `[[Plan-Focused-Single-App-Island-Hosting]]`, `[[Plan-Apple-HIG-Minimal-Redesign]]`, `[[Plan-Global-Timezone-Sync]]`, `[[Plan-Dynamic-Island-Calendar-App-And-Events]]`, `[[Plan-Unified-Backend-Daemon-And-Shell-Launcher]]`, `[[Plan-Pomodoro-Target-Stack-And-Custom-Intervals]]`, `[[Plan-Multi-Monitor-Dynamic-Island]]`, `[[Plan-Calendar-Right-Click-Events-View]]`, `[[Plan-Apple-HIG-Time-Picker-Component]]`, `[[Plan-Unified-Control-Center-Suite]]`, `[[Plan-Apple-Minimal-Control-Center]]`, `[[Plan-Reserved-Spacer-Window-Layer]]`, `[[Plan-Fullscreen-Application-Layer-Clearance]]`, `[[Plan-Dynamic-Expanded-Layer-Interaction]]`, `[[Plan-Hover-Right-Click-Control-Center]]`, `[[Plan-Theme-Selector-Gallery-Redesign]]`, `[[Plan-Async-Theme-Engine-And-Exact-Matching]]`, `[[Plan-Shared-Directory-Theme-Engine]]`, `[[Plan-Fix-Kitty-Theme-Adapter-Timeout]]`, `[[Plan-Fix-Dolphin-Theme-Adapter]]`, `[[Plan-Fix-Dolphin-Qt-Color-Integration]]`, `[[Plan-KDE-DBus-NotifyChange-Broadcaster]]`, `[[Plan-Fix-Dolphin-Crash-On-Theme-Switch]]`, `[[Plan-Complete-Dolphin-KDE-Color-Format]]`, `[[Plan-Universal-Qt-KDE-Theming]]`, `[[Plan-Expanded-State-5s-Focus-Timeout]]`, `[[Plan-Theme-Specific-Awww-Wallpaper-Engine]]`, `[[Plan-Theme-App-Wallpapers-Tab]]`, `[[Plan-Fix-Neovim-Theme-LazyVim-Spec]]`, `[[Plan-Dynamic-Island-System-Metrics-Pinning]]`, `[[Plan-Add-CPU-GPU-Temperature-Metrics]]`, `[[Plan-Fix-Pinned-Metrics-Hover-Clipping-And-Top-Anchor]]`, `[[Plan-Dynamic-Island-Theme-Sync-With-Pure-Black-Background]]`, `[[Plan-Fullscreen-Power-And-Session-Overlay]]`




