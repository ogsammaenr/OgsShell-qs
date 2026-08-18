import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
  id: root

  // Telemetry & Metrics
  property var cpu: ({ "cpu_percent": 0, "cpu_temp": 0 })
  property var ram: ({ "ram_used_mb": 0, "ram_total_mb": 0, "ram_percent": 0 })
  property var gpu: ({ "gpu_temp": 0, "gpu_percent": 0 })
  property var net: ({ "rx_bytes_sec": 0, "tx_bytes_sec": 0, "interface": "", "is_connected": false })

  // Wi-Fi & Bluetooth
  property var wifi: ({ "connected": false, "ssid": "", "signal": 0 })
  property var bluetooth: ({ "adapter_powered": false, "discovering": false, "devices": [] })

  // Alarms
  property var alarms: []

  // Calendar & Holidays
  property var calendarEvents: []
  property var currentMonthData: ({ "year": new Date().getFullYear(), "month": new Date().getMonth() + 1, "holidays": [], "events": [] })
  property var holidays: []

  // Notifications, DND & Rules
  property var notifications: []
  property bool dndEnabled: false
  property var notificationRules: []
  property int unreadNotificationCount: 0

  // Clipboard & Pinned Favorites
  property var clipboardHistory: []
  property var pinnedClipboardItems: []

  // Keyboard Layout
  property var keyboardLayout: ({
    "device_name": "",
    "current_layout_index": 0,
    "current_keymap": "Turkish",
    "current_short_code": "TR",
    "current_layout_code": "tr",
    "configured_layouts": ["tr"],
    "configured_variants": ["alt"]
  })
  property var availableKeyboardLayouts: []

  // Theme Management & Multi-App Dispatcher
  property var currentTheme: ({ "id": "everforest", "name": "Everforest Dark", "colors": {} })
  property var availableThemes: []
  property var enabledThemeAdapters: ({})
  property var themeWallpapers: []
  property string activeWallpaper: ""

  // App Launcher Subsystem
  property var launcherApps: []
  property var launcherSearchResults: []
  property string launcherLastQuery: ""

  // High-Priority Signals
  signal alarmTriggered(var payload)
  signal calendarReminderTriggered(var payload)
  signal notificationReceived(var payload)
  signal clipboardItemCopied(var payload)
  signal keyboardLayoutUpdated(var payload)
  signal themeChanged(var payload)
  signal wallpapersUpdated(var payload)
  signal launcherResultsUpdated(var payload)
  signal appLaunched(var payload)
  signal launcherToggled()
  signal launcherOpened()
  signal launcherClosed()

  // Send JSON RPC Action to daemon
  function sendAction(name, args) {
    if (!socket.connected) {
      console.log("[DaemonIPC] Warning: Socket not connected. Cannot send action:", name);
      return;
    }
    let packet = JSON.stringify({
      "name": name,
      "args": args || {}
    }) + "\n";
    console.log("[DaemonIPC] Sending action:", name, JSON.stringify(args || {}));
    socket.write(packet);
  }

  // Keyboard Layout Helpers
  function switchKeyboardLayout(target) {
    sendAction("switch_keyboard_layout", {
      "target": target || "next",
      "device": "all"
    });
  }

  function setConfiguredKeyboardLayouts(layouts, variants) {
    sendAction("set_configured_layouts", {
      "layouts": layouts || ["tr"],
      "variants": variants || []
    });
  }

  function requestKeyboardLayout() {
    sendAction("get_keyboard_layout", {});
  }

  function requestAvailableKeyboardLayouts() {
    sendAction("get_available_system_layouts", {});
  }

  // Clipboard Helpers
  function requestClipboardHistory(limit, query) {
    sendAction("get_clipboard_history", {
      "limit": limit || 50,
      "query": query || ""
    });
  }

  function copyClipboardItem(id, text) {
    sendAction("copy_clipboard_item", {
      "id": id || "",
      "text": text || ""
    });
  }

  function deleteClipboardItem(id) {
    sendAction("delete_clipboard_item", { "id": id });
  }

  function clearClipboardHistory() {
    sendAction("clear_clipboard_history", {});
  }

  function pinClipboardItem(id, text, label) {
    sendAction("pin_clipboard_item", {
      "id": id || "",
      "text": text || "",
      "label": label || ""
    });
  }

  function unpinClipboardItem(id) {
    sendAction("unpin_clipboard_item", { "id": id });
  }

  function requestPinnedClipboardItems() {
    sendAction("get_pinned_clipboard_items", {});
  }

  // Notification Helpers
  function addNotification(appName, summary, body, icon, urgency) {
    sendAction("add_notification", {
      "app_name": appName || "System",
      "summary": summary || "Notification",
      "body": body || "",
      "icon": icon || "",
      "urgency": urgency || "normal"
    });
  }

  function requestNotifications() {
    sendAction("get_notifications", {});
  }

  function deleteNotification(id) {
    sendAction("delete_notification", { "id": id });
  }

  function clearNotifications() {
    sendAction("clear_notifications", {});
  }

  function markNotificationRead(id) {
    sendAction("mark_notification_read", { "id": id });
  }

  function markAllNotificationsRead() {
    sendAction("mark_notification_read", { "all": true });
  }

  function toggleDND(enabled) {
    if (enabled !== undefined) {
      sendAction("toggle_dnd", { "enabled": enabled });
    } else {
      sendAction("toggle_dnd", {});
    }
  }

  function setNotificationRule(appName, mode, soundEnabled) {
    sendAction("set_notification_rule", {
      "app_name": appName,
      "mode": mode || "normal",
      "sound_enabled": soundEnabled !== undefined ? soundEnabled : false
    });
  }

  function deleteNotificationRule(appName) {
    sendAction("delete_notification_rule", { "app_name": appName });
  }

  function requestNotificationRules() {
    sendAction("get_notification_rules", {});
  }

  function updateUnreadCount() {
    let count = 0;
    if (root.notifications && root.notifications.length) {
      for (let i = 0; i < root.notifications.length; i++) {
        if (!root.notifications[i].read) {
          count++;
        }
      }
    }
    root.unreadNotificationCount = count;
  }

  // Calendar Helpers
  function requestCalendarMonth(year, month) {
    sendAction("get_calendar_month", { "year": year, "month": month });
  }

  function addCalendarEvent(title, date, timeStr, notifyBefore) {
    sendAction("add_calendar_event", {
      "title": title,
      "date": date,
      "time": timeStr || "",
      "notify_before_minutes": notifyBefore || 0
    });
  }

  function deleteCalendarEvent(id) {
    sendAction("delete_calendar_event", { "id": id });
  }

  function toggleCalendarEvent(id, completed) {
    sendAction("toggle_calendar_event", { "id": id, "completed": completed });
  }

  function requestHolidays(year) {
    sendAction("get_holidays", { "year": year });
  }

  // Alarm Helpers
  function addAlarm(timeStr, label, days, soundPath) {
    sendAction("add_alarm", {
      "time": timeStr,
      "label": label || "Alarm",
      "days": days || [],
      "sound_path": soundPath || ""
    });
  }

  function toggleAlarm(id, enabled) {
    sendAction("toggle_alarm", { "id": id, "enabled": enabled });
  }

  function deleteAlarm(id) {
    sendAction("delete_alarm", { "id": id });
  }

  function dismissAlarm(id) {
    sendAction("dismiss_alarm", { "id": id || "" });
  }

  function snoozeAlarm(id, minutes) {
    sendAction("snooze_alarm", { "id": id || "", "minutes": minutes || 5 });
  }

  // Theme Helpers
  function requestThemeState() {
    sendAction("get_theme_state", {});
  }

  function requestAvailableThemes() {
    sendAction("get_available_themes", {});
  }

  function setActiveTheme(themeId) {
    if (availableThemes && availableThemes.length > 0) {
      for (let i = 0; i < availableThemes.length; i++) {
        if (availableThemes[i].id === themeId) {
          root.currentTheme = availableThemes[i];
          Style.applyTheme(availableThemes[i]);
          break;
        }
      }
    } else {
      Style.applyThemeById(themeId);
    }
    sendAction("set_active_theme", { "theme_id": themeId });
  }

  function saveCustomTheme(palette) {
    sendAction("save_custom_theme", { "theme": palette });
  }

  function deleteCustomTheme(themeId) {
    sendAction("delete_custom_theme", { "theme_id": themeId });
  }

  function toggleThemeAdapter(adapterId, enabled) {
    sendAction("toggle_theme_adapter", { "adapter_id": adapterId, "enabled": enabled });
  }

  // Wallpaper Helpers
  function requestThemeWallpapers(themeId) {
    sendAction("get_theme_wallpapers", { "theme_id": themeId || (root.currentTheme ? root.currentTheme.id : "") });
  }

  function setWallpaper(themeId, wallpaperPath) {
    sendAction("set_wallpaper", {
      "theme_id": themeId || (root.currentTheme ? root.currentTheme.id : ""),
      "wallpaper_path": wallpaperPath
    });
  }

  function nextWallpaper(themeId) {
    sendAction("next_wallpaper", { "theme_id": themeId || (root.currentTheme ? root.currentTheme.id : "") });
  }

  // App Launcher Helpers
  function searchApps(query, limit) {
    root.launcherLastQuery = query || "";
    sendAction("search_apps", {
      "query": query || "",
      "limit": limit || 25
    });
  }

  function requestAppsList(limit) {
    sendAction("list_apps", {
      "limit": limit || 50
    });
  }

  function launchApp(id, exec) {
    sendAction("launch_app", {
      "id": id || "",
      "exec": exec || ""
    });
  }

  function reindexApps() {
    sendAction("reindex_apps", {});
  }

  function toggleLauncher() {
    sendAction("toggle_launcher", {});
  }

  function openLauncher() {
    sendAction("open_launcher", {});
  }

  function closeLauncher() {
    sendAction("close_launcher", {});
  }

  function triggerInitialSync() {
    console.log("[DaemonIPC] Triggering initial state sync from Go daemon...");
    let now = new Date();
    requestCalendarMonth(now.getFullYear(), now.getMonth() + 1);
    sendAction("get_alarms", {});
    requestNotifications();
    sendAction("get_dnd_state", {});
    requestNotificationRules();
    requestClipboardHistory(50, "");
    requestPinnedClipboardItems();
    requestKeyboardLayout();
    requestAvailableKeyboardLayouts();
    requestThemeState();
    requestAvailableThemes();
    requestThemeWallpapers("");
    requestAppsList(50);
    sendAction("get_active_wifi", {});
    sendAction("scan_wifi", {});
    sendAction("get_bluetooth_state", {});
  }

  // Initial fetch when loaded
  Component.onCompleted: {
    if (socket.connected) {
      triggerInitialSync();
    }
  }

  Socket {
    id: socket
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/ogs_shell.sock"
    connected: true

    onConnectedChanged: {
      if (connected) {
        console.log("[DaemonIPC] Socket connected to daemon! Sending initial sync requests...");
        root.triggerInitialSync();
      } else {
        console.log("[DaemonIPC] Socket disconnected from daemon.");
      }
    }

    parser: SplitParser {
      onRead: data => {
        try {
          if (!data || data.trim().length === 0) return;
          let msg = JSON.parse(data);

          if (msg.type === "sys_metrics") {
            root.cpu = msg.payload.cpu || ({ "cpu_percent": 0 });
            root.ram = msg.payload.ram || ({ "ram_percent": 0 });
            root.gpu = msg.payload.gpu || ({ "gpu_percent": 0 });
            root.net = msg.payload.net || ({ "is_connected": false });
            if (root.net && root.net.is_connected && !root.wifi.connected) {
              root.wifi = {
                "connected": true,
                "ssid": (root.wifi && root.wifi.ssid) ? root.wifi.ssid : "Bağlı",
                "signal": (root.wifi && root.wifi.signal) ? root.wifi.signal : 80,
                "access_points": (root.wifi && root.wifi.access_points) ? root.wifi.access_points : []
              };
            }
          } else if (msg.type === "wifi_update" || msg.type === "wifi_scan_results") {
            let aps = Array.isArray(msg.payload) ? msg.payload : [];
            let activeAp = aps.find(a => a.is_active || a.is_connected);
            let isConn = !!activeAp || !!(root.net && root.net.is_connected);
            root.wifi = {
              "connected": isConn,
              "ssid": activeAp ? activeAp.ssid : (isConn ? ((root.wifi && root.wifi.ssid && root.wifi.ssid !== "Kapalı") ? root.wifi.ssid : "Bağlı") : "Kapalı"),
              "signal": activeAp ? activeAp.signal : ((root.wifi && root.wifi.signal) ? root.wifi.signal : 70),
              "access_points": aps,
              "scan_results": aps
            };
          } else if (msg.type === "active_wifi_info") {
            let existingAps = (root.wifi && (root.wifi.access_points || root.wifi.scan_results)) ? (root.wifi.access_points || root.wifi.scan_results) : [];
            root.wifi = {
              "connected": true,
              "ssid": msg.payload.ssid || ((root.wifi && root.wifi.ssid) ? root.wifi.ssid : "Bağlı"),
              "signal": msg.payload.signal || 80,
              "ip": msg.payload.ip || "",
              "access_points": existingAps,
              "scan_results": existingAps
            };
          } else if (msg.type === "bluetooth_update") {
            root.bluetooth = msg.payload || ({ "adapter_powered": false, "devices": [] });
          } else if (msg.type === "alarms_update") {
            root.alarms = msg.payload;
          } else if (msg.type === "alarm_triggered") {
            root.alarmTriggered(msg.payload);
          } else if (msg.type === "calendar_events_update") {
            root.calendarEvents = msg.payload;
            let now = new Date();
            root.requestCalendarMonth(root.currentMonthData.year || now.getFullYear(), root.currentMonthData.month || (now.getMonth() + 1));
          } else if (msg.type === "calendar_month_data") {
            root.currentMonthData = msg.payload;
          } else if (msg.type === "calendar_reminder_triggered") {
            root.calendarReminderTriggered(msg.payload);
          } else if (msg.type === "holidays_data") {
            root.holidays = msg.payload;
          } else if (msg.type === "notifications_update") {
            root.notifications = msg.payload || [];
            root.updateUnreadCount();
          } else if (msg.type === "notification_received") {
            root.notificationReceived(msg.payload);
          } else if (msg.type === "dnd_update") {
            root.dndEnabled = !!msg.payload.dnd_enabled;
          } else if (msg.type === "notification_rules_update") {
            root.notificationRules = msg.payload || [];
          } else if (msg.type === "clipboard_update") {
            root.clipboardHistory = msg.payload || [];
          } else if (msg.type === "clipboard_item_copied") {
            root.clipboardItemCopied(msg.payload);
          } else if (msg.type === "pinned_clipboard_update") {
            root.pinnedClipboardItems = msg.payload || [];
          } else if (msg.type === "keyboard_layout_update") {
            root.keyboardLayout = msg.payload;
            root.keyboardLayoutUpdated(msg.payload);
          } else if (msg.type === "available_layouts_data") {
            root.availableKeyboardLayouts = msg.payload || [];
          } else if (msg.type === "theme_update") {
            if (msg.payload.active_theme) {
              root.currentTheme = msg.payload.active_theme;
              Style.applyTheme(msg.payload.active_theme);
              root.requestThemeWallpapers(msg.payload.active_theme.id);
            }
            if (msg.payload.available_themes) {
              root.availableThemes = msg.payload.available_themes;
            }
            if (msg.payload.enabled_adapters) {
              root.enabledThemeAdapters = msg.payload.enabled_adapters;
            }
            root.themeChanged(msg.payload);
          } else if (msg.type === "available_themes_data") {
            root.availableThemes = msg.payload || [];
          } else if (msg.type === "theme_wallpapers_data") {
            root.themeWallpapers = msg.payload.wallpapers || [];
            root.activeWallpaper = msg.payload.active_wallpaper || "";
            root.wallpapersUpdated(msg.payload);
          } else if (msg.type === "app_search_results") {
            root.launcherSearchResults = (msg.payload && msg.payload.results) ? msg.payload.results : [];
            root.launcherResultsUpdated(msg.payload);
          } else if (msg.type === "app_list_data") {
            root.launcherApps = msg.payload || [];
          } else if (msg.type === "app_launched") {
            root.appLaunched(msg.payload);
          } else if (msg.type === "toggle_launcher") {
            root.launcherToggled();
          } else if (msg.type === "open_launcher") {
            root.launcherOpened();
          } else if (msg.type === "close_launcher") {
            root.launcherClosed();
          }
        } catch (e) {
          console.warn("[DaemonIPC] JSON parse hatası: ", e, "Gelen ham veri:", data);
        }
      }
    }
  }
}
