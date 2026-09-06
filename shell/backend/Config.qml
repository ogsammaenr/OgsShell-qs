pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../theme"

Item {
  id: root
  visible: false

  // Active form-factor: "island" (floating pill) or "notch" (top-bezel attached)
  property string formFactor: "island"
  property string theme: "catppuccin"
  property bool showPinnedSystemMetrics: false
  property bool focusMode: false

  // Re-evaluation generation trigger counter (forces dependent bindings to re-evaluate)
  property int configRevision: 0

  // Signal emitted whenever configuration is reloaded from disk
  signal configUpdated(var fullConfig)

  // =========================================================================
  // Raw Configuration Presets (JSON Objects)
  // =========================================================================
  property var island: ({
    "top_margin": 8,
    "idle_width": 180,
    "idle_height": 36,
    "hover_width": 480,
    "hover_height": 58,
    "transient_width": 340,
    "transient_height": 56,
    "expanded_width": 490,
    "expanded_height": 315,
    "radius_full": 18,
    "radius_expanded": 24
  })

  property var notch: ({
    "top_margin": 0,
    "idle_width": 190,
    "idle_height": 32,
    "hover_width": 490,
    "hover_height": 56,
    "transient_width": 350,
    "transient_height": 58,
    "expanded_width": 490,
    "expanded_height": 315,
    "bottom_radius": 20,
    "bottom_radius_expanded": 26
  })

  property var notifications: ({
    "enabled": true,
    "default_timeout_ms": 2200
  })

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

  property var animation: ({
    "duration_compact": 250,
    "duration_transient": 280,
    "duration_expanded": 320,
    "overshoot_factor": 1.12
  })

  property var screenCorners: ({
    "enabled": true,
    "radius": 14,
    "color": "#000000",
    "top_left": true,
    "top_right": true,
    "bottom_left": true,
    "bottom_right": true
  })

  property var audioFeedback: ({
    "enabled": true,
    "volume_change_sound": true,
    "throttle_ms": 100,
    "custom_sound_path": ""
  })

  property var cornerHud: ({
    "enabled": true,
    "volume_enabled": true,
    "workspace_enabled": true,
    "capslock_enabled": true,
    "mic_enabled": true,
    "clipboard_enabled": true,
    "timeout_ms": 1200,
    "height": 34
  })

  // =========================================================================
  // First-Class Typed Reactive Geometry Accessors
  // =========================================================================
  readonly property bool isNotch: formFactor === "notch"

  readonly property int islandTopMargin: (island && island.top_margin !== undefined) ? island.top_margin : 8
  readonly property int islandIdleWidth: (island && island.idle_width) ? island.idle_width : 180
  readonly property int islandIdleHeight: (island && island.idle_height) ? island.idle_height : 36
  readonly property int islandHoverWidth: (island && island.hover_width) ? island.hover_width : 480
  readonly property int islandHoverHeight: (island && island.hover_height) ? island.hover_height : 58
  readonly property int islandTransientWidth: (island && island.transient_width) ? island.transient_width : 340
  readonly property int islandTransientHeight: (island && island.transient_height) ? island.transient_height : 56
  readonly property int islandExpandedWidth: (island && island.expanded_width) ? island.expanded_width : 490
  readonly property int islandExpandedHeight: (island && island.expanded_height) ? island.expanded_height : 315
  readonly property int islandRadiusFull: (island && island.radius_full) ? island.radius_full : 18
  readonly property int islandRadiusExpanded: (island && island.radius_expanded) ? island.radius_expanded : 24

  readonly property int notchTopMargin: (notch && notch.top_margin !== undefined) ? notch.top_margin : 0
  readonly property int notchIdleWidth: (notch && notch.idle_width) ? notch.idle_width : 190
  readonly property int notchIdleHeight: (notch && notch.idle_height) ? notch.idle_height : 32
  readonly property int notchHoverWidth: (notch && notch.hover_width) ? notch.hover_width : 490
  readonly property int notchHoverHeight: (notch && notch.hover_height) ? notch.hover_height : 56
  readonly property int notchTransientWidth: (notch && notch.transient_width) ? notch.transient_width : 350
  readonly property int notchTransientHeight: (notch && notch.transient_height) ? notch.transient_height : 58
  readonly property int notchExpandedWidth: (notch && notch.expanded_width) ? notch.expanded_width : 490
  readonly property int notchExpandedHeight: (notch && notch.expanded_height) ? notch.expanded_height : 315
  readonly property int notchBottomRadius: (notch && notch.bottom_radius) ? notch.bottom_radius : 20
  readonly property int notchBottomRadiusExpanded: (notch && notch.bottom_radius_expanded) ? notch.bottom_radius_expanded : 26

  // =========================================================================
  // First-Class Typed Reactive Notifications Accessors
  // =========================================================================
  readonly property bool notificationsEnabled: (notifications && notifications.enabled !== undefined) ? notifications.enabled : true
  readonly property int notificationTimeoutMs: (notifications && notifications.default_timeout_ms !== undefined) ? notifications.default_timeout_ms : 2200

  // =========================================================================
  // First-Class Typed Reactive Typography Accessors
  // =========================================================================
  readonly property int clockIdleSize: (typography && typography.clock_idle_size) ? typography.clock_idle_size : 18
  readonly property int clockHoverSize: (typography && typography.clock_hover_size) ? typography.clock_hover_size : 22
  readonly property int dateHoverSize: (typography && typography.date_hover_size) ? typography.date_hover_size : 14
  readonly property int mediaTitleSize: (typography && typography.media_title_size) ? typography.media_title_size : 13
  readonly property int mediaArtistSize: (typography && typography.media_artist_size) ? typography.media_artist_size : 12
  readonly property int connectivityTextSize: (typography && typography.connectivity_text_size) ? typography.connectivity_text_size : 12
  readonly property int connectivityIconSize: (typography && typography.connectivity_icon_size) ? typography.connectivity_icon_size : 15
  readonly property int notificationTitleSize: (typography && typography.notification_title_size) ? typography.notification_title_size : 14
  readonly property int notificationBodySize: (typography && typography.notification_body_size) ? typography.notification_body_size : 12
  readonly property int pinnedMetricsSize: (typography && typography.pinned_metrics_size) ? typography.pinned_metrics_size : 12
  readonly property int pinnedMetricsIconSize: (typography && typography.pinned_metrics_icon_size) ? typography.pinned_metrics_icon_size : 14

  // =========================================================================
  // First-Class Typed Reactive Screen Corners Accessors
  // =========================================================================
  readonly property bool screenCornersEnabled: (screenCorners && screenCorners.enabled !== undefined) ? screenCorners.enabled : true
  readonly property int screenCornersRadius: (screenCorners && screenCorners.radius !== undefined) ? screenCorners.radius : 14
  readonly property string screenCornersColor: (screenCorners && screenCorners.color) ? screenCorners.color : "#000000"
  readonly property bool screenCornerTopLeft: (screenCorners && screenCorners.top_left !== undefined) ? screenCorners.top_left : true
  readonly property bool screenCornerTopRight: (screenCorners && screenCorners.top_right !== undefined) ? screenCorners.top_right : true
  readonly property bool screenCornerBottomLeft: (screenCorners && screenCorners.bottom_left !== undefined) ? screenCorners.bottom_left : true
  readonly property bool screenCornerBottomRight: (screenCorners && screenCorners.bottom_right !== undefined) ? screenCorners.bottom_right : true

  // =========================================================================
  // First-Class Typed Reactive Audio Feedback Accessors
  // =========================================================================
  readonly property bool audioFeedbackEnabled: (audioFeedback && audioFeedback.enabled !== undefined) ? audioFeedback.enabled : true
  readonly property bool audioFeedbackVolumeChangeSound: (audioFeedback && audioFeedback.volume_change_sound !== undefined) ? audioFeedback.volume_change_sound : true
  readonly property int audioFeedbackThrottleMs: (audioFeedback && audioFeedback.throttle_ms !== undefined) ? audioFeedback.throttle_ms : 100
  readonly property string audioFeedbackCustomSoundPath: (audioFeedback && audioFeedback.custom_sound_path) ? audioFeedback.custom_sound_path : ""

  // =========================================================================
  // First-Class Typed Reactive Corner Island HUD Accessors
  // =========================================================================
  readonly property bool cornerHudEnabled: (cornerHud && cornerHud.enabled !== undefined) ? cornerHud.enabled : true
  readonly property bool cornerHudVolume: (cornerHud && cornerHud.volume_enabled !== undefined) ? cornerHud.volume_enabled : true
  readonly property bool cornerHudWorkspace: (cornerHud && cornerHud.workspace_enabled !== undefined) ? cornerHud.workspace_enabled : true
  readonly property bool cornerHudCapslock: (cornerHud && cornerHud.capslock_enabled !== undefined) ? cornerHud.capslock_enabled : true
  readonly property bool cornerHudMic: (cornerHud && cornerHud.mic_enabled !== undefined) ? cornerHud.mic_enabled : true
  readonly property bool cornerHudClipboard: (cornerHud && cornerHud.clipboard_enabled !== undefined) ? cornerHud.clipboard_enabled : true
  readonly property int cornerHudTimeoutMs: (cornerHud && cornerHud.timeout_ms !== undefined) ? cornerHud.timeout_ms : 1200
  readonly property int cornerHudHeight: (cornerHud && cornerHud.height !== undefined) ? cornerHud.height : 34

  // Computed active geometry (reactive to formFactor and configRevision)
  readonly property var activeGeometry: {
    let _rev = configRevision
    return isNotch ? notch : island
  }

  // =========================================================================
  // Canonical Paths & Directories
  // =========================================================================
  readonly property string userConfigPath: Quickshell.env("XDG_CONFIG_HOME") ? (Quickshell.env("XDG_CONFIG_HOME") + "/ogsShell/config.json") : (Quickshell.env("HOME") ? (Quickshell.env("HOME") + "/.config/ogsShell/config.json") : "")
  readonly property string userConfigDir: {
    let p = userConfigPath
    if (!p) return ""
    let idx = p.lastIndexOf("/")
    return idx !== -1 ? p.substring(0, idx) : ""
  }

  readonly property string workspaceConfigPath: {
    let u = Qt.resolvedUrl("../config.json").toString()
    if (u.startsWith("file://")) {
      return u.substring(7)
    }
    return u
  }
  readonly property string workspaceConfigDir: {
    let p = workspaceConfigPath
    if (!p) return ""
    let idx = p.lastIndexOf("/")
    return idx !== -1 ? p.substring(0, idx) : ""
  }

  readonly property string sharedConfigPath: {
    let u = Qt.resolvedUrl("../../shared/app_configs/shell/config.json").toString()
    if (u.startsWith("file://")) {
      return u.substring(7)
    }
    return u
  }

  Process {
    id: syncProc
  }

  function writeConfig(jsonContent) {
    if (!jsonContent || jsonContent.trim().length === 0) return
    let uPath = root.userConfigPath
    let wPath = root.workspaceConfigPath
    let sPath = root.sharedConfigPath

    let pyScript = "import os\n" +
      "content = " + JSON.stringify(jsonContent) + "\n" +
      "for path in ['" + uPath + "', '" + wPath + "', '" + sPath + "']:\n" +
      "    if not path: continue\n" +
      "    try:\n" +
      "        os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
      "        with open(path, 'w', encoding='utf-8') as f:\n" +
      "            f.write(content)\n" +
      "    except Exception as e:\n" +
      "        pass\n"

    syncProc.running = false
    syncProc.command = ["python3", "-c", pyScript]
    syncProc.running = true
  }

  function syncToUserConfig(jsonContent) {
    if (!jsonContent || jsonContent.trim().length === 0) return
    let uPath = root.userConfigPath
    let sPath = root.sharedConfigPath

    let pyScript = "import os\n" +
      "content = " + JSON.stringify(jsonContent) + "\n" +
      "for path in ['" + uPath + "', '" + sPath + "']:\n" +
      "    if not path: continue\n" +
      "    try:\n" +
      "        os.makedirs(os.path.dirname(path), exist_ok=True)\n" +
      "        with open(path, 'w', encoding='utf-8') as f:\n" +
      "            f.write(content)\n" +
      "    except Exception as e:\n" +
      "        pass\n"

    syncProc.running = false
    syncProc.command = ["python3", "-c", pyScript]
    syncProc.running = true
  }

  function saveConfig(cfg) {
    if (!cfg) return
    if (cfg.form_factor !== undefined) root.formFactor = cfg.form_factor
    if (cfg.theme !== undefined) {
      root.theme = cfg.theme
      Style.applyThemeById(cfg.theme)
    }
    if (cfg.show_pinned_system_metrics !== undefined) root.showPinnedSystemMetrics = cfg.show_pinned_system_metrics
    if (cfg.focus_mode !== undefined) root.focusMode = cfg.focus_mode
    if (cfg.island) root.island = Object.assign({}, root.island, cfg.island)
    if (cfg.notch) root.notch = Object.assign({}, root.notch, cfg.notch)
    if (cfg.notifications) root.notifications = Object.assign({}, root.notifications, cfg.notifications)
    if (cfg.typography) root.typography = Object.assign({}, root.typography, cfg.typography)
    if (cfg.animation) root.animation = Object.assign({}, root.animation, cfg.animation)
    if (cfg.screen_corners) root.screenCorners = Object.assign({}, root.screenCorners, cfg.screen_corners)
    if (cfg.audio_feedback) root.audioFeedback = Object.assign({}, root.audioFeedback, cfg.audio_feedback)
    if (cfg.corner_hud) root.cornerHud = Object.assign({}, root.cornerHud, cfg.corner_hud)

    let full = {
      "form_factor": root.formFactor,
      "theme": root.theme,
      "show_pinned_system_metrics": root.showPinnedSystemMetrics,
      "focus_mode": root.focusMode,
      "typography": root.typography,
      "island": root.island,
      "notch": root.notch,
      "notifications": root.notifications,
      "animation": root.animation,
      "screen_corners": root.screenCorners,
      "audio_feedback": root.audioFeedback,
      "corner_hud": root.cornerHud
    }

    let jsonStr = JSON.stringify(full, null, 2)
    root.lastLoadedWorkspaceHash = jsonStr.trim()
    root.lastLoadedUserHash = jsonStr.trim()
    root.writeConfig(jsonStr)
    root.configRevision++
    root.configUpdated(full)
  }

  // Content change hash trackers to avoid infinite write cycles
  property string lastLoadedWorkspaceHash: ""
  property string lastLoadedUserHash: ""

  // =========================================================================
  // Real-Time inotify Watcher Process
  // Captures file changes, atomic renames, and writes instantly (<5ms)
  // =========================================================================
  Process {
    id: inotifyProc
    command: {
      let dirs = []
      if (root.workspaceConfigDir && root.workspaceConfigDir.length > 0) dirs.push(root.workspaceConfigDir)
      if (root.userConfigDir && root.userConfigDir.length > 0 && dirs.indexOf(root.userConfigDir) === -1) dirs.push(root.userConfigDir)
      return ["inotifywait", "-m", "-e", "close_write,moved_to,modify", "--format", "%w%f"].concat(dirs)
    }
    running: root.workspaceConfigDir.length > 0
    stdout: SplitParser {
      onRead: path => {
        let clean = path ? path.trim() : ""
        if (clean.endsWith("config.json")) {
          if (clean.indexOf("shell/config.json") !== -1 || clean === root.workspaceConfigPath) {
            triggerWorkspaceRead()
          } else if (clean === root.userConfigPath || clean.indexOf("ogsShell/config.json") !== -1) {
            triggerUserRead()
          }
        }
      }
    }
    onExited: {
      inotifyRestartTimer.restart()
    }
  }

  Timer {
    id: inotifyRestartTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (!inotifyProc.running && root.workspaceConfigDir.length > 0) {
        inotifyProc.running = true
      }
    }
  }

  // =========================================================================
  // Fresh Disk Readers (Zero-Cache Process-driven Reads)
  // =========================================================================
  function triggerWorkspaceRead() {
    if (readWorkspaceConfigProc.running) {
      readWorkspaceConfigProc.running = false
    }
    readWorkspaceConfigProc.buffer = ""
    readWorkspaceConfigProc.running = true
  }

  function triggerUserRead() {
    if (readUserConfigProc.running) {
      readUserConfigProc.running = false
    }
    readUserConfigProc.buffer = ""
    readUserConfigProc.running = true
  }

  Process {
    id: readWorkspaceConfigProc
    command: ["cat", root.workspaceConfigPath]
    running: false
    property string buffer: ""
    stdout: SplitParser {
      onRead: data => {
        readWorkspaceConfigProc.buffer += data + "\n"
      }
    }
    onExited: {
      let content = readWorkspaceConfigProc.buffer.trim()
      readWorkspaceConfigProc.buffer = ""
      if (content.length > 0 && content !== root.lastLoadedWorkspaceHash) {
        root.lastLoadedWorkspaceHash = content
        root.loadConfigString(content, true)
      }
    }
  }

  Process {
    id: readUserConfigProc
    command: ["cat", root.userConfigPath]
    running: false
    property string buffer: ""
    stdout: SplitParser {
      onRead: data => {
        readUserConfigProc.buffer += data + "\n"
      }
    }
    onExited: {
      let content = readUserConfigProc.buffer.trim()
      readUserConfigProc.buffer = ""
      if (content.length > 0 && content !== root.lastLoadedUserHash) {
        root.lastLoadedUserHash = content
        root.loadConfigString(content, false)
      }
    }
  }

  // Fallback Polling Timer: Guarantees synchronization on exotic filesystems
  Timer {
    id: fallbackPollTimer
    interval: 1000
    repeat: true
    running: true
    onTriggered: {
      if (!readWorkspaceConfigProc.running && root.workspaceConfigPath.length > 0) {
        readWorkspaceConfigProc.running = true
      }
    }
  }

  function loadConfigString(jsonStr, shouldSyncToUser) {
    if (!jsonStr || jsonStr.trim().length === 0) return
    try {
      let cfg = JSON.parse(jsonStr)
      if (cfg.form_factor !== undefined) root.formFactor = cfg.form_factor
      if (cfg.theme !== undefined) {
        root.theme = cfg.theme
        Style.applyThemeById(cfg.theme)
      }
      if (cfg.show_pinned_system_metrics !== undefined) root.showPinnedSystemMetrics = cfg.show_pinned_system_metrics
      if (cfg.focus_mode !== undefined) root.focusMode = cfg.focus_mode
      if (cfg.island) root.island = Object.assign({}, root.island, cfg.island)
      if (cfg.notch) root.notch = Object.assign({}, root.notch, cfg.notch)
      if (cfg.notifications) root.notifications = Object.assign({}, root.notifications, cfg.notifications)
      if (cfg.typography) root.typography = Object.assign({}, root.typography, cfg.typography)
      if (cfg.animation) root.animation = Object.assign({}, root.animation, cfg.animation)
      if (cfg.screen_corners) root.screenCorners = Object.assign({}, root.screenCorners, cfg.screen_corners)
      if (cfg.audio_feedback) root.audioFeedback = Object.assign({}, root.audioFeedback, cfg.audio_feedback)
      if (cfg.corner_hud) root.cornerHud = Object.assign({}, root.cornerHud, cfg.corner_hud)

      root.configRevision++
      root.configUpdated(cfg)

      if (shouldSyncToUser) {
        root.lastLoadedUserHash = jsonStr.trim()
        root.syncToUserConfig(jsonStr)
      }

      console.log("[Config] Loaded configuration. Mode:", root.formFactor, "Theme:", root.theme, "Notch Height:", root.notchIdleHeight, "Clock Idle Size:", root.clockIdleSize, "Revision:", root.configRevision)
    } catch (e) {
      console.warn("[Config] Error parsing config.json:", e)
    }
  }

  Component.onCompleted: {
    // Initial pass
    triggerWorkspaceRead()
    triggerUserRead()
  }
}
