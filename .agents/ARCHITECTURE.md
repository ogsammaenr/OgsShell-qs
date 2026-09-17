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
│  - bottomNotchWindow (Inverted Bottom Command Notch)   │
│  - BottomCommandNotch (Mirrored G2 Bezier Shell Runner)│
│  - DynamicIsland (Island vs Notch presentation modes)  │
│  - DaemonIPC (Socket & SplitParser JSON receiver)      │
│  - Style.qml (Catppuccin & Pure OLED Black tokens)     │
└────────────────────────────────────────────────────────┘
```

---

## 2. WiFi & Secrets Management Service (`core/services/wifi/`)

* **Interface-Driven:** `wifi.WifiManager` interface abstracts NetworkManager D-Bus and Mock implementations.
* **Embedded Authentication & KDED Suppression:** In-process headless `SecretAgent` answers credential queries directly from memory and returns `UserCanceled` upon missing cache rather than `NoSecrets`, strictly suppressing external desktop/KDE dialogs (`kded6` / `plasma-nm`).
* **Secrets Management:** `GetProfileSecrets` (`Settings.Connection.GetSecrets`) reads stored WPA passwords/keys; `UpdateProfileSecrets` updates stored credentials with `psk-flags: 0` (`NM_SETTING_SECRET_FLAG_NONE`).
* **IPC Endpoints:** `scan_wifi`, `get_saved_wifi_profiles`, `get_wifi_secrets`, `connect_wifi`, `update_wifi_secrets`, `delete_wifi_profile`, `set_wifi_enabled`, `get_active_wifi`.

---

## 3. Bluetooth Management Service (`core/services/bluetooth/`)

* **Interface-Driven:** `bluetooth.BluetoothManager` interface abstracts BlueZ D-Bus (`org.bluez`) and in-memory mock implementations.
* **D-Bus Signal Subscriptions:** Reacts in real-time to `PropertiesChanged`, `InterfacesAdded`, and `InterfacesRemoved` signals on adapter and device objects.
* **IPC Broadcast:** Dispatches `bluetooth_update` events with adapter power, discovery state, and peripheral details (MAC, Name, Icon, Connected, Paired, RSSI).
* **IPC Endpoints:** `toggle_bluetooth`, `connect_bluetooth`, `disconnect_bluetooth`, `start_bluetooth_scan`, `stop_bluetooth_scan`, `get_bluetooth_state` / `get_bluetooth_devices`.

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
* **3D Layered Cards Deck Architecture (Frontend):** Cascading notification stack visualising up to 3 physical depth tiers (Tier 1 @ 100%, Tier 2 @ 91% with +8-10px peek, Tier 3 @ 82% with +16-18px peek) with critical urgency preemption, synchronous dual-card slide transition (outgoing card translates `y: 0 -> -36px` while incoming card simultaneously translates `y: +36px -> 0px` over 260ms `OutCubic`), synchronized deck ascension (`shiftProgress: 0.0 -> 1.0` merging stacked card into notch bottom), modular `NotificationCardView`, hover pause, middle-click dismiss, right-click clear-all, left-click app focus/launch, and dynamic Wayland input envelope extension.
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
  - **Kitty:** `current-theme.conf` sync, live Unix socket color reload (`kitten @ set-colors`) to preserve dynamic runtime font scales (`Ctrl+Shift++/-`), and fallback to `SIGUSR1`.
  - **Zed Editor:** In-place inode-preserving JSON patching of `"theme"` in `~/.config/zed/settings.json` and `themes/ogsshell.json`.
  - **Vesktop (Discord/Vencord):** Dual sync of `themes/ogsshell.theme.css` and `settings/quickCss.css` for instant hot-reloading.
  - **GTK 3 & GTK 4 / Libadwaita & XWayland:** Pre-deploys 7 named themes into `~/.local/share/themes/ogsShell-<id>/` (`gtk-3.0`, `gtk-4.0`, `index.theme`), neutralizes `~/.config/gtk-3.0/gtk.css` to prevent Priority 800 locks, dispatches dynamic `gtk-theme` across `gsettings` and `xfconf-query` (Thunar/XFCE) for 0ms live hot-reloading in running GTK3/GTK4 apps without restart, and generates `~/.config/xsettingsd/xsettingsd.conf` with `SIGHUP` reload / background daemon spawning for XWayland/X11 apps.
  - **Dolphin / Qt:** Dispatching `plasma-apply-colorscheme` or `kdeglobals`.
  - **IntelliJ IDEA / JetBrains:** `colors/<SchemeName>.icls` deployment and `options/colors.scheme.xml` dynamic patch.
  - **Android Studio:** `~/.config/Google/AndroidStudio*`, Flatpak, and Snap config auto-discovery with `colors/<SchemeName>.icls` deployment and atomic `options/colors.scheme.xml` update.
  - **Tmux:** Multi-location `current-theme.conf` sync, `minimal-tmux-status` live reload and client refresh.
  - **Starship Prompt:** Dynamic synthesis of `~/.config/starship.toml` via template concatenation (`base.toml` + `palettes/<theme>.toml`) for instant zero-restart cross-shell prompt recoloring.
* **Concurrent Error-Isolated Dispatcher:** Applies theme updates in parallel goroutines.
* **IPC Endpoints:** `get_theme_state`, `get_available_themes`, `set_active_theme`, `save_custom_theme`, `delete_custom_theme`, `toggle_theme_adapter`.

---

## 10. App Launcher Subsystem (`core/services/launcher/`)

* **In-Memory Sub-Millisecond Search:** Thread-safe (`sync.RWMutex`) in-memory application index with multi-tier weighted scoring.
* **Intelligent Typo-Tolerance & Acronyms:** Zero-heap-allocation Damerau-Levenshtein fuzzy matching, acronym resolution (`gimp` -> `GNU Image Manipulation Program`), and category matching.
* **Real-Time Directory Watcher:** Debounced (150ms) `fsnotify` monitor watching `/usr/share/applications`, `~/.local/share/applications`, and Flatpak export paths.
* **Detached Process Execution:** Spawns applications via `systemd-run --user --scope` with fallback to `syscall.SysProcAttr{Setsid: true}`.
* **Instant Math & Currency Engine (Frontend):** Embedded zero-`eval()` math engine (`MathEvaluator.js`) and offline-first currency engine (`CurrencyEngine.qml`) caching to `$XDG_CONFIG_HOME/ogsShell/currency_rates.json` (>12h background Frankfurter + Binance sync), rendering high-contrast `HeroResultCard` with instant clipboard copy (`DaemonIPC.copyClipboardItem` + `wl-copy`).
* **IPC Endpoints:** `search_apps`, `list_apps`, `launch_app`, `reindex_apps`, `toggle_launcher`, `open_launcher`, `close_launcher`.

---

## 11. Currency Exchange Service (`core/services/currency/`)

* **Low-Footprint Native Daemon Subsystem:** Fully native Go HTTP background synchronization engine completely free of external scripting or Python runtimes.
* **Dual Telemetry & Cryptocurrencies:** Polls Frankfurter API for global fiat pairs (TRY, EUR, USD, GBP, CHF, JPY, CAD, AUD, etc.) and Binance Public Ticker for crypto (BTC, ETH, SOL).
* **Atomic Inode-Preserving Caching:** Commits exchange rates atomically to `$XDG_CONFIG_HOME/ogsShell/currency_rates.json`.
* **Dynamic Configuration Sync:** Configurable via `shell/config.json` (`currency.sync_interval_min`, default: 30m; `currency.default_target`, default: `"TRY"`).
* **IPC Endpoints:** `get_currency_rates`, `sync_currency_rates`, `reload_currency_config`.

---

## 12. Screen Capture, OCR & Recording Engine (`core/services/capture/`)

* **Instant Screen Freeze:** Captures an instant full-screen still to `/tmp/ogs_freeze.png` via `grim` upon snipping activation.
* **Cropped & Fullscreen Screenshot:** Executes `grim -g "<geom>"` (or fullscreen), persists timestamped PNG to `$HOME/Pictures/Screenshots/screenshot_YYYY-MM-DD_HH-mm-ss.png`, and copies directly to Wayland clipboard (`wl-copy --type image/png`).
* **Optical Character Recognition (OCR):** Cuts target geometry to `/tmp/ogs_ocr.png`, runs `tesseract /tmp/ogs_ocr.png stdout -l tur+eng`, copies recognized text to system clipboard, and dispatches `ocr_completed` event with HUD summary preview.
* **Low-Overhead Screen Recording:** Spawns `wf-recorder -g "<geom>" -f $HOME/Videos/Recordings/recording_YYYY-MM-DD_HH-mm-ss.mp4` in a dedicated process group, emits 1-second duration ticks (`recording_state_update`), and cleanly terminates via `syscall.SIGINT` to ensure atomic MP4 moov atom header finalization.
* **External Annotator Integration:** Launches `gradia <file_path>` detached via `systemd-run --user --scope` with `Setsid` fallback.
* **IPC Endpoints:** `freeze_screen`, `capture_screenshot`, `capture_ocr`, `start_recording`, `stop_recording`, `open_annotator`.

### 12.1. Dynamic Island Capture Integration (`shell/components/island/`)

* **Screenshot Thumbnail Notification (TRANSIENT 5s):** Upon `screenshot_captured` event, `DynamicIsland.qml` plays a camera shutter sound via `AudioFeedbackService.playShutterSound()`, then enqueues a rich notification with a rounded `Image` thumbnail preview of the screenshot, "Ekran Görüntüsü Alındı" summary, filename body text, and a trailing ✏️ edit pencil icon button.
* **OCR Text Card (TRANSIENT 5s):** Upon `ocr_completed` event, enqueues a notification with 🔍 magnifier icon, "OCR Metin Tanıma" summary, and an italic snippet of the recognized text in the body.
* **Live Recording Pill:** When `ipc.isRecording` is `true`, the island's `mainBarLayer` hides and a `recordingLayer` appears with a pulsing red dot (🔴 `SequentialAnimation`), live `mm:ss` timer counter bound to `ipc.recordingDuration`, 🎙 mic icon, and a hover-revealed `[⏹ Kaydı Bitir]` stop button.
* **Gradia Launch Action:** Left-clicking on a screenshot notification triggers `ipc.openAnnotator(filePath)` via the notification's action callback, opening the image in Gradia for annotation. Left-clicking the island during recording calls `ipc.stopRecording()`.
* **SpringAnimation Physics:** All island width/height transitions use `SpringAnimation { spring: 28.0; damping: 0.78; epsilon: 0.01 }` per `.agents/AGENTS.md` directive.
* **State Priority:** `EXPANDED_APP > RECORDING / TRANSIENT > HOVER > IDLE`. Recording layer only displays in non-EXPANDED, non-TRANSIENT modes.

---

## 13. Unified CLI Management Architecture (`ogsshell.sh`)

* **Single Consolidated Entrypoint:** All lifecycle management (`run`, `run_backend`, `run_frontend`, `reload`, `stop`, `status`), IPC triggers (`launcher`, `settings`, `bottom_notch`, `cc`, `wifi`, `bluetooth`, `mixer`, `calendar`, `clock`, `media`, `notif`, `power`, `themes`, `dnd`, `switch_layout`, `next_wallpaper`), and developer utilities (`preview_starship`) are consolidated into a single executable script (`scripts/ogsshell.sh`).
* **Canonical Installation Location:** Deployed to `$XDG_CONFIG_HOME/ogsShell/ogsshell.sh` (`~/.config/ogsShell/ogsshell.sh`) with `ogs.sh` symlink and exposed system-wide via `~/.local/bin/ogsshell`.
* **Dynamic Workspace Resolution:** Auto-resolves project root across custom `$OGSSHELL_REPO_ROOT`, local repo checkouts, and canonical home directories without hardcoded path dependencies.
* **Shell Auto-Completion Support:** Native context-aware Tab completion for both Zsh (`~/.config/zsh/custom/ogsshell.zsh`) and Bash (`~/.local/share/bash-completion/completions/ogsshell`), providing command and multi-argument subview completions for `ogsshell`, `ogsshell.sh`, `ogs`, and `ogs.sh`.

---

## 14. Obsidian Brain Vault Reference Map

* **`01-Architecture/`**: `[[System-Architecture]]`, `[[Project-Structure]]`, `[[Backend-Endpoints-Reference]]`, `[[IPC-Socket-Schema]]`, `[[Apple-Dynamic-Island-HIG]]`, `[[Apple-HIG-Minimal-Design-System]]`, `[[Dynamic-Notch-Design-Specification]]`, `[[Dynamic-Island-Physics-State-Machine]]`, `[[Configuration-System-Spec]]`, `[[Configuration-Themes-Spec]]`
* **`02-Services/`**: `[[Go-Daemon-Core]]`, `[[Capture-Service]]`, `[[Currency-Service]]`, `[[App-Launcher-Service]]`, `[[Theme-Service]]`, `[[Keyboard-Service]]`, `[[Clipboard-Service]]`, `[[Notification-Service]]`, `[[Wifi-Client-Service]]`, `[[Bluetooth-Service]]`, `[[Alarm-Service]]`, `[[Calendar-Service]]`, `[[Audio-Feedback-Service]]`, `[[SysMetrics-Service]]`, `[[CPU-Monitor-Service]]`, `[[RAM-Monitor-Service]]`, `[[GPU-Monitor-Service]]`, `[[Network-Monitor-Service]]`, `[[Logger-Service]]`, `[[IPC-Server-Service]]`
* **`03-UI-Components/`**: `[[Shell-Root-PanelWindow]]`, `[[Dynamic-Island-Component]]`, `[[Bottom-Command-Notch]]`, `[[Snipping-Overlay-Component]]`, `[[Notification-Card-View]]`, `[[Notification-Deck-Background]]`, `[[Screen-Corners-Component]]`, `[[Corner-Island-HUD-Component]]`, `[[Top-Right-Tray-HUD-Component]]`, `[[App-Launcher-Widget]]`, `[[Power-Overlay-Component]]`, `[[Clock-Widget]]`, `[[Clock-Suite-View]]`, `[[Clock-Manager]]`, `[[Calendar-Widget]]`, `[[Time-Picker-Component]]`, `[[Media-Widget]]`, `[[Media-Player-View]]`, `[[Audio-Mixer-View]]`, `[[Connectivity-Status-Widget]]`, `[[Control-Center-Widget]]`, `[[Pinned-Metrics-Widget]]`, `[[Settings-Application-Component]]`, `[[Style-Design-Tokens]]`, `[[Daemon-IPC-Client]]`
* **`04-Agent-Rules/`**: `[[Go-Coding-Style]]`, `[[QML-Best-Practices]]`, `[[Agent-Workflow-Directives]]`

