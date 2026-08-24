pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // Active form-factor: "island" (floating pill) or "notch" (top-bezel attached)
  property string formFactor: "island"
  property string theme: "catppuccin"
  property bool showPinnedSystemMetrics: false
  property bool focusMode: false

  // Re-evaluation generation trigger counter (forces dependent bindings to re-evaluate)
  property int configRevision: 0

  // Island configuration preset
  property var island: ({
    "top_margin": 8,
    "idle_width": 180,
    "idle_height": 36,
    "hover_width": 480,
    "hover_height": 56,
    "transient_width": 340,
    "transient_height": 56,
    "expanded_width": 440,
    "expanded_height": 310,
    "radius_full": 18,
    "radius_expanded": 24
  })

  // Notch configuration preset
  property var notch: ({
    "top_margin": 0,
    "idle_width": 190,
    "idle_height": 34,
    "hover_width": 490,
    "hover_height": 54,
    "transient_width": 350,
    "transient_height": 58,
    "expanded_width": 450,
    "expanded_height": 310,
    "bottom_radius": 20,
    "bottom_radius_expanded": 26
  })

  // Notifications configuration preset
  property var notifications: ({
    "enabled": true,
    "default_timeout_ms": 3500
  })

  // Typography configuration preset (reactive font sizes across Island & HUD)
  property var typography: ({
    "clock_idle_size": 18,
    "clock_hover_size": 22,
    "date_hover_size": 14,
    "media_title_size": 13,
    "media_artist_size": 12,
    "connectivity_text_size": 12,
    "connectivity_icon_size": 15,
    "notification_title_size": 14,
    "notification_body_size": 12,
    "pinned_metrics_size": 12,
    "pinned_metrics_icon_size": 14
  })

  // Animation configuration preset
  property var animation: ({
    "duration_compact": 250,
    "duration_transient": 280,
    "duration_expanded": 320,
    "overshoot_factor": 1.12
  })

  // Computed helper accessors (reactive to formFactor and configRevision)
  readonly property bool isNotch: formFactor === "notch"
  readonly property var activeGeometry: {
    let _rev = configRevision
    return isNotch ? notch : island
  }

  // Paths
  readonly property string userConfigPath: Quickshell.env("XDG_CONFIG_HOME") ? (Quickshell.env("XDG_CONFIG_HOME") + "/ogsShell/config.json") : (Quickshell.env("HOME") ? (Quickshell.env("HOME") + "/.config/ogsShell/config.json") : "")
  readonly property string workspaceConfigPath: Qt.resolvedUrl("../config.json").toString().replace("file://", "")

  property Process syncProc: Process {
    id: syncProc
  }

  function syncToUserConfig(jsonContent) {
    if (!userConfigPath || !jsonContent || jsonContent.trim().length === 0) return
    let dir = userConfigPath.substring(0, userConfigPath.lastIndexOf("/"))
    syncProc.command = ["bash", "-c", "mkdir -p '" + dir + "' && cat > '" + userConfigPath + "' << 'EOF'\n" + jsonContent + "\nEOF"]
    syncProc.running = true
  }

  // FileView to watch user config (~/.config/ogsShell/config.json)
  property var configFile: FileView {
    path: root.userConfigPath
    preload: true
    printErrors: false
    onTextChanged: {
      if (text() && text().trim().length > 0) {
        root.loadConfigString(text())
      }
    }
  }

  // FileView to watch workspace config (shell/config.json)
  property var workspaceConfigFile: FileView {
    path: root.workspaceConfigPath
    preload: true
    printErrors: false
    onTextChanged: {
      if (text() && text().trim().length > 0) {
        root.loadConfigString(text())
        root.syncToUserConfig(text())
      }
    }
  }

  function loadConfigString(jsonStr) {
    if (!jsonStr || jsonStr.trim().length === 0) return
    try {
      let cfg = JSON.parse(jsonStr)
      if (cfg.form_factor) root.formFactor = cfg.form_factor
      if (cfg.theme) root.theme = cfg.theme
      if (cfg.show_pinned_system_metrics !== undefined) root.showPinnedSystemMetrics = cfg.show_pinned_system_metrics
      if (cfg.focus_mode !== undefined) root.focusMode = cfg.focus_mode
      if (cfg.island) root.island = Object.assign({}, root.island, cfg.island)
      if (cfg.notch) root.notch = Object.assign({}, root.notch, cfg.notch)
      if (cfg.notifications) root.notifications = Object.assign({}, root.notifications, cfg.notifications)
      if (cfg.typography) root.typography = Object.assign({}, root.typography, cfg.typography)
      if (cfg.animation) root.animation = Object.assign({}, root.animation, cfg.animation)
      root.configRevision++
      console.log("[Config] Loaded configuration. Mode:", root.formFactor, "Theme:", root.theme, "Notch Height:", root.notch.idle_height, "Clock Idle Size:", root.typography.clock_idle_size)
    } catch (e) {
      console.warn("[Config] Error parsing config.json:", e)
    }
  }

  Component.onCompleted: {
    // Initial parse pass (load workspace config then user config if present)
    if (workspaceConfigFile && workspaceConfigFile.text().length > 0) {
      loadConfigString(workspaceConfigFile.text())
    }
    if (configFile && configFile.text().length > 0) {
      loadConfigString(configFile.text())
    }
  }
}
