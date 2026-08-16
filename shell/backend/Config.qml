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

  // Island configuration preset
  property var island: ({
    "top_margin": 8,
    "idle_width": 180,
    "idle_height": 36,
    "hover_width": 420,
    "hover_height": 50,
    "transient_width": 340,
    "transient_height": 56,
    "expanded_width": 420,
    "expanded_height": 280,
    "radius_full": 18,
    "radius_expanded": 24
  })

  // Notch configuration preset
  property var notch: ({
    "top_margin": 0,
    "idle_width": 190,
    "idle_height": 34,
    "hover_width": 430,
    "hover_height": 48,
    "transient_width": 350,
    "transient_height": 58,
    "expanded_width": 430,
    "expanded_height": 280,
    "bottom_radius": 20,
    "bottom_radius_expanded": 26
  })

  // Animation configuration preset
  property var animation: ({
    "duration_compact": 250,
    "duration_transient": 280,
    "duration_expanded": 320,
    "overshoot_factor": 1.12
  })

  // Computed helper accessors
  readonly property bool isNotch: formFactor === "notch"
  readonly property var activeGeometry: isNotch ? notch : island

  // FileView to watch and parse config.json
  property var configFile: FileView {
    path: Quickshell.env("XDG_CONFIG_HOME") ? (Quickshell.env("XDG_CONFIG_HOME") + "/ogsShell/config.json") : ""
    preload: true
    printErrors: false
    onTextChanged: {
      root.loadConfigString(text())
    }
  }

  // Fallback workspace file reader
  property var workspaceConfigFile: FileView {
    path: Qt.resolvedUrl("../config.json").toString().replace("file://", "")
    preload: true
    printErrors: false
    onTextChanged: {
      if (!configFile.path || configFile.text().length === 0) {
        root.loadConfigString(text())
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
      if (cfg.island) root.island = Object.assign({}, root.island, cfg.island)
      if (cfg.notch) root.notch = Object.assign({}, root.notch, cfg.notch)
      if (cfg.animation) root.animation = Object.assign({}, root.animation, cfg.animation)
      console.log("[Config] Loaded configuration. Mode:", root.formFactor, "Theme:", root.theme)
    } catch (e) {
      console.warn("[Config] Error parsing config.json:", e)
    }
  }

  Component.onCompleted: {
    // Initial parse pass
    if (configFile.text().length > 0) {
      loadConfigString(configFile.text())
    } else if (workspaceConfigFile.text().length > 0) {
      loadConfigString(workspaceConfigFile.text())
    }
  }
}
