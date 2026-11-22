import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../.."

Item {
  id: root

  property var ipc
  signal openView(string viewName)

  property int volumeLevel: 50
  property bool isMuted: false
  property int brightnessLevel: 70
  property bool gameModeActive: false
  property bool isDraggingBrightness: false
  property bool isDraggingVolume: false

  // Telemetry properties
  readonly property bool isWifiInterface: !!(ipc && ipc.net && ipc.net.interface && (ipc.net.interface.startsWith("wl") || ipc.net.interface.startsWith("wifi")))
  readonly property bool isEthInterface: !!(ipc && ipc.net && ipc.net.interface && (ipc.net.interface.startsWith("en") || ipc.net.interface.startsWith("eth")))
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && (ipc.wifi.connected || isWifiInterface || (ipc.net && ipc.net.is_connected && !isEthInterface)))
  readonly property bool isEthernetConnected: !!(ipc && ipc.net && ipc.net.is_connected && isEthInterface && !isWifiConnected)
  readonly property bool isNetworkConnected: isEthernetConnected || isWifiConnected
  readonly property string wifiSsidText: (ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : (isWifiConnected ? "Bağlı" : "Kapalı")
  readonly property string networkTitleText: isEthernetConnected ? "Kablolu Ağ" : "Wi-Fi"
  readonly property string networkSubtitleText: {
    if (isEthernetConnected) {
      return (ipc && ipc.net && ipc.net.interface) ? `Bağlı · ${ipc.net.interface}` : "Bağlı"
    }
    return root.wifiSsidText
  }
  readonly property string networkIconGlyph: {
    if (isEthernetConnected) return "󰈀"
    if (isWifiConnected) return "󰤨"
    return "󰤮"
  }
  readonly property bool isBtPowered: !!(ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered)
  readonly property string btSubtitleText: {
    if (!isBtPowered) return "Kapalı"
    if (ipc && ipc.bluetooth && ipc.bluetooth.devices) {
      for (let i = 0; i < ipc.bluetooth.devices.length; i++) {
        if (ipc.bluetooth.devices[i].connected) {
          return ipc.bluetooth.devices[i].name || "Bağlı"
        }
      }
    }
    return "Açık"
  }
  readonly property int notifCount: (ipc && ipc.notifications) ? ipc.notifications.length : 0
  readonly property int unreadNotifCount: (ipc && ipc.unreadNotificationCount !== undefined) ? ipc.unreadNotificationCount : 0
  readonly property string activeThemeShortName: {
    let raw = (ipc && ipc.currentTheme && ipc.currentTheme.name) ? ipc.currentTheme.name : (Style.activeThemeName || "Tema")
    if (raw.indexOf("Catppuccin") !== -1) return "Catppuccin"
    if (raw.indexOf("Everforest") !== -1) return "Everforest"
    if (raw.indexOf("Monochrome") !== -1) return "Monochrome"
    if (raw.indexOf("Gruvbox") !== -1) return "Gruvbox"
    return raw
  }

  // Native PipeWire Volume & Mute Tracking
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  Connections {
    target: Config
    function onAudioMaxVolumeChanged() {
      root.syncTelemetry()
    }
  }

  Connections {
    target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    function onVolumeChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.volumeLevel = Math.max(0, Math.min(Config.audioMaxVolume, Math.round(Pipewire.defaultAudioSink.audio.volume * 100)))
      }
    }
    function onMutedChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.isMuted = Pipewire.defaultAudioSink.audio.muted
      }
    }
  }

  Connections {
    target: Pipewire
    function onDefaultAudioSinkChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.volumeLevel = Math.max(0, Math.min(Config.audioMaxVolume, Math.round(Pipewire.defaultAudioSink.audio.volume * 100)))
        root.isMuted = Pipewire.defaultAudioSink.audio.muted
      }
    }
  }

  // System processes for Volume (Fallback) & Brightness
  Process {
    id: volGetProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    stdout: SplitParser {
      onRead: data => {
        let m = data.match(/Volume:\s*([0-9.]+)/)
        if (m && m[1]) {
          let v = Math.round(parseFloat(m[1]) * 100)
          if (!isNaN(v)) root.volumeLevel = Math.max(0, Math.min(Config.audioMaxVolume, v))
        }
        root.isMuted = data.indexOf("[MUTED]") !== -1
      }
    }
  }

  Process {
    id: brightGetProc
    command: ["brightnessctl", "-m"]
    stdout: SplitParser {
      onRead: data => {
        let parts = data.split(",")
        if (parts.length >= 4) {
          let p = parseInt(parts[3].replace("%", "").trim())
          if (!isNaN(p)) root.brightnessLevel = Math.max(0, Math.min(100, p))
        }
      }
    }
  }

  Process { id: setVolProc }
  Process { id: toggleMuteProc }
  Process { id: setBrightProc }
  Process { id: gameModeProc }

  function openSettingsApp() {
    SettingsService.open()
  }

  function syncTelemetry() {
    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      root.volumeLevel = Math.max(0, Math.min(Config.audioMaxVolume, Math.round(Pipewire.defaultAudioSink.audio.volume * 100)))
      root.isMuted = Pipewire.defaultAudioSink.audio.muted
    } else {
      volGetProc.running = true
    }
    brightGetProc.running = true
  }

  function setVolume(val) {
    let maxVol = Config.audioMaxVolume
    let target = Math.max(0, Math.min(maxVol, Math.round(val)))
    root.volumeLevel = target
    root.isMuted = false
    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      Pipewire.defaultAudioSink.audio.volume = target / 100.0
      Pipewire.defaultAudioSink.audio.muted = false
    }
    if (target > 100 || !Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) {
      let maxRatio = (maxVol / 100.0).toFixed(1)
      setVolProc.running = false
      setVolProc.command = ["wpctl", "set-volume", "-l", maxRatio, "@DEFAULT_AUDIO_SINK@", target + "%"]
      setVolProc.running = true
    }
  }

  function toggleMute() {
    root.isMuted = !root.isMuted
    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      Pipewire.defaultAudioSink.audio.muted = root.isMuted
    } else {
      toggleMuteProc.running = false
      toggleMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
      toggleMuteProc.running = true
    }
  }

  function setBrightness(val) {
    let target = Math.max(5, Math.min(100, Math.round(val)))
    root.brightnessLevel = target
    setBrightProc.command = ["brightnessctl", "set", target + "%"]
    setBrightProc.running = true
  }

  function formatSpeed(bytes) {
    if (!bytes || bytes <= 0) return "0 B/s"
    if (bytes < 1024) return `${Math.round(bytes)} B/s`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(bytes >= 100 * 1024 ? 0 : 1)} KB/s`
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB/s`
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB/s`
  }

  Component.onCompleted: syncTelemetry()

  onVisibleChanged: {
    if (visible) syncTelemetry()
  }

  Timer {
    id: liveSyncTimer
    interval: 2000
    repeat: true
    running: root.visible
    onTriggered: {
      brightGetProc.running = true
      if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) {
        volGetProc.running = true
      }
    }
  }

  // ==========================================
  // Layout Root
  // ==========================================
  Column {
    anchors.fill: parent
    spacing: 10

    // ==========================================
    // ROW 1: Grouped Connectivity Card + 2x2 Quick Action Tiles
    // ==========================================
    Row {
      width: parent.width
      height: 124
      spacing: 10

      // 1.1 Left Card: Connectivity Group (Network & Bluetooth)
      Rectangle {
        width: parent.width - 190
        height: 124
        radius: 16
        color: Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Column {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 2

          // Network (Wi-Fi / Ethernet) Row
          Rectangle {
            width: parent.width
            height: 54
            radius: 11
            color: wifiMouse.containsMouse ? Style.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 140 } }

            Row {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              Rectangle {
                width: 34
                height: 34
                radius: 17
                anchors.verticalCenter: parent.verticalCenter
                color: root.isNetworkConnected
                  ? (root.isEthernetConnected ? Style.accentGreen : Style.accent)
                  : Style.surfaceVariant

                Behavior on color { ColorAnimation { duration: 160 } }

                Text {
                  anchors.centerIn: parent
                  text: root.networkIconGlyph
                  font.pixelSize: 15
                  color: root.isNetworkConnected ? "#000000" : Style.textMuted
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 68
                spacing: 1

                Text {
                  text: root.networkTitleText
                  font.family: Style.fontDisplay
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  color: Style.textPrimary
                }
                Text {
                  text: root.networkSubtitleText
                  font.family: Style.fontText
                  font.pixelSize: 10
                  color: root.isNetworkConnected ? Style.textSecondary : Style.textMuted
                  elide: Text.ElideRight
                  width: parent.width
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                font.pixelSize: 14
                color: wifiMouse.containsMouse ? Style.textSecondary : Style.textMuted
              }
            }

            MouseArea {
              id: wifiMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openView("WIFI")
            }
          }

          // Subtle Inset Hairline Divider
          Rectangle {
            width: parent.width - 54
            x: 46
            height: 1
            color: Style.borderSubtle
          }

          // Bluetooth Row
          Rectangle {
            width: parent.width
            height: 54
            radius: 11
            color: btMouse.containsMouse ? Style.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 140 } }

            Row {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              Rectangle {
                width: 34
                height: 34
                radius: 17
                anchors.verticalCenter: parent.verticalCenter
                color: root.isBtPowered ? Style.accentCyan : Style.surfaceVariant

                Behavior on color { ColorAnimation { duration: 160 } }

                Text {
                  anchors.centerIn: parent
                  text: root.isBtPowered ? "󰂯" : "󰂲"
                  font.pixelSize: 16
                  color: root.isBtPowered ? "#000000" : Style.textMuted
                }
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 68
                spacing: 1

                Text {
                  text: "Bluetooth"
                  font.family: Style.fontDisplay
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  color: Style.textPrimary
                }
                Text {
                  text: root.btSubtitleText
                  font.family: Style.fontText
                  font.pixelSize: 10
                  color: root.isBtPowered ? Style.textSecondary : Style.textMuted
                  elide: Text.ElideRight
                  width: parent.width
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                font.pixelSize: 14
                color: btMouse.containsMouse ? Style.textSecondary : Style.textMuted
              }
            }

            MouseArea {
              id: btMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openView("BLUETOOTH")
            }
          }
        }
      }

      // 1.2 Right 2x2 Action Tiles
      Column {
        width: 180
        height: 124
        spacing: 8

        // Row 1: Focus Mode & Notifications
        Row {
          width: parent.width
          height: 58
          spacing: 8

          // Tile 1: Focus Mode (Odak Modu)
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 14
            color: Config.focusMode
              ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.22)
              : (focusMouse.containsMouse ? Style.surfaceHover : Style.surface)
            border.color: Config.focusMode
              ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.35)
              : Style.borderSubtle
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Column {
              anchors.centerIn: parent
              spacing: 3

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Config.focusMode ? "󰈈" : "󰈉"
                font.pixelSize: 18
                color: Config.focusMode ? Style.accent : Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Odak"
                font.family: Style.fontDisplay
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Config.focusMode ? Style.textPrimary : Style.textSecondary
              }
            }

            MouseArea {
              id: focusMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Config.focusMode = !Config.focusMode
            }
          }

          // Tile 2: Notifications
          Rectangle {
            id: notifTile
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 14
            readonly property bool isDnd: !!(ipc && ipc.dndEnabled)
            color: isDnd
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.18)
              : (notifMouse.containsMouse ? Style.surfaceHover : Style.surface)
            border.color: isDnd
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.32)
              : Style.borderSubtle
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            // Subtle Unread Dot
            Rectangle {
              visible: !notifTile.isDnd && root.unreadNotifCount > 0
              anchors.top: parent.top
              anchors.topMargin: 8
              anchors.right: parent.right
              anchors.rightMargin: 8
              width: 6
              height: 6
              radius: 3
              color: Style.accent
            }

            Column {
              anchors.centerIn: parent
              spacing: 3

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: notifTile.isDnd ? "󰂛" : "󰂚"
                font.pixelSize: 18
                color: notifTile.isDnd ? Style.accentRed : Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: notifTile.isDnd ? "Sessizde" : "Bildirim"
                font.family: Style.fontDisplay
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: notifTile.isDnd ? Style.accentRed : Style.textSecondary
              }
            }

            MouseArea {
              id: notifMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openView("NOTIFICATIONS")
            }
          }
        }

        // Row 2: Themes & Clipboard
        Row {
          width: parent.width
          height: 58
          spacing: 8

          // Tile 3: Appearance / Theme (Left: Open Gallery, Right: Next Wallpaper)
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 14
            color: themeMouse.containsMouse ? Style.surfaceHover : Style.surface
            border.color: Style.borderSubtle
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            // Live Active Theme Accent Dot
            Rectangle {
              anchors.top: parent.top
              anchors.topMargin: 8
              anchors.right: parent.right
              anchors.rightMargin: 8
              width: 6
              height: 6
              radius: 3
              color: Style.accent
            }

            Column {
              anchors.centerIn: parent
              width: parent.width - 12
              spacing: 2

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰔎"
                font.pixelSize: 17
                color: Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.activeThemeShortName
                font.family: Style.fontDisplay
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Style.textSecondary
                elide: Text.ElideRight
              }
            }

            MouseArea {
              id: themeMouse
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor
              onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                  if (ipc) ipc.nextWallpaper("")
                } else {
                  root.openView("THEMES")
                }
              }
            }
          }

          // Tile 4: Clipboard
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 14
            color: clipMouse.containsMouse ? Style.surfaceHover : Style.surface
            border.color: Style.borderSubtle
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
              anchors.centerIn: parent
              spacing: 2

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰅍"
                font.pixelSize: 17
                color: Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Pano"
                font.family: Style.fontDisplay
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Style.textSecondary
              }
            }

            MouseArea {
              id: clipMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openView("CLIPBOARD")
            }
          }
        }
      }
    }

    // ==========================================
    // ROW 2: Apple Capsule Display Brightness Slider
    // ==========================================
    Rectangle {
      id: brightCapsule
      width: parent.width
      height: 38
      radius: 14
      color: Style.surface
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      // Frosted Active Level Fill
      Rectangle {
        id: brightFill
        height: parent.height
        width: Math.max(0, Math.min(parent.width, parent.width * (root.brightnessLevel / 100.0)))
        radius: 14
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14)

        Behavior on width {
          enabled: !root.isDraggingBrightness
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
      }

      // Left Content: Icon + Label
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "󰃟"
          font.pixelSize: 16
          color: Style.textPrimary
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Ekran Parlaklığı"
          font.family: Style.fontDisplay
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.textPrimary
        }
      }

      // Right Content: Percentage Readout
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: `%${root.brightnessLevel}`
        font.family: Style.fontDisplay
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: Style.textSecondary
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateLevel(mouse) {
          let pct = (mouse.x / width) * 100.0
          root.setBrightness(pct)
        }

        onPressed: mouse => {
          root.isDraggingBrightness = true
          updateLevel(mouse)
        }
        onPositionChanged: mouse => {
          if (pressed) updateLevel(mouse)
        }
        onReleased: root.isDraggingBrightness = false
        onCanceled: root.isDraggingBrightness = false
        onWheel: wheel => {
          let delta = wheel.angleDelta.y > 0 ? 5 : -5
          root.setBrightness(root.brightnessLevel + delta)
        }
      }
    }

    // ==========================================
    // ROW 3: Apple Capsule Sound Volume Slider
    // ==========================================
    Rectangle {
      id: soundCapsule
      width: parent.width
      height: 38
      radius: 14
      color: Style.surface
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      // Frosted Active Level Fill
      Rectangle {
        id: soundFill
        height: parent.height
        width: root.isMuted ? 0 : Math.max(0, Math.min(parent.width, parent.width * (root.volumeLevel / Config.audioMaxVolume)))
        radius: 14
        color: (!root.isMuted && root.volumeLevel >= 135)
          ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.28)
          : ((!root.isMuted && root.volumeLevel > 100)
            ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.26)
            : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14))

        Behavior on width {
          enabled: !root.isDraggingVolume
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
      }

      // 100% Threshold Marker (visible when Over-Amplification is enabled)
      Rectangle {
        visible: Config.audioOverAmplification
        x: Math.round(parent.width * (100.0 / Config.audioMaxVolume))
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        width: 1.5
        radius: 1
        color: Style.textMuted
        opacity: 0.45
      }

      // Left Content: Speaker Icon + Label
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Speaker Icon (Clickable for Mute Toggle)
        Rectangle {
          width: 24
          height: 24
          radius: 12
          anchors.verticalCenter: parent.verticalCenter
          color: muteMouse.containsMouse ? Style.surfaceHover : "transparent"
          z: 10

          Text {
            anchors.centerIn: parent
            text: root.isMuted ? "󰖁" : (root.volumeLevel > 50 ? "󰕾" : (root.volumeLevel > 0 ? "󰖀" : "󰕿"))
            font.pixelSize: 16
            color: root.isMuted ? Style.accentRed : (root.volumeLevel >= 135 ? Style.accentRed : (root.volumeLevel > 100 ? Style.accentOrange : Style.textPrimary))
          }

          MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMute()
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.isMuted ? "Sessiz" : (root.volumeLevel > 100 ? "Ses Düzeyi · Boost" : "Ses Düzeyi")
          font.family: Style.fontDisplay
          font.pixelSize: 12
          font.weight: Font.Medium
          color: root.isMuted ? Style.accentRed : (root.volumeLevel > 100 ? Style.accentOrange : Style.textPrimary)
        }
      }

      // Right Content: Percentage Readout
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.isMuted ? "0%" : `%${root.volumeLevel}`
        font.family: Style.fontDisplay
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: root.isMuted ? Style.accentRed : (root.volumeLevel >= 135 ? Style.accentRed : (root.volumeLevel > 100 ? Style.accentOrange : Style.textSecondary))
      }

      // Slider MouseArea (Left: Adjust, Right: Open Audio Mixer)
      MouseArea {
        id: soundSliderMouse
        anchors.fill: parent
        anchors.leftMargin: 38
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateLevel(mouse) {
          let pct = (mouse.x / width) * Config.audioMaxVolume
          root.setVolume(pct)
        }

        onPressed: mouse => {
          if (mouse.button === Qt.LeftButton) {
            root.isDraggingVolume = true
            updateLevel(mouse)
          }
        }
        onPositionChanged: mouse => {
          if (pressed && (mouse.buttons & Qt.LeftButton)) updateLevel(mouse)
        }
        onReleased: root.isDraggingVolume = false
        onCanceled: root.isDraggingVolume = false
        onClicked: mouse => {
          if (mouse.button === Qt.RightButton) {
            root.openView("AUDIO_MIXER")
          }
        }
        onWheel: wheel => {
          let delta = wheel.angleDelta.y > 0 ? 5 : -5
          root.setVolume(root.volumeLevel + delta)
        }
      }
    }

    // ==========================================
    // ROW 4: Minimal Status Footer
    // ==========================================
    Row {
      width: parent.width
      height: 34
      spacing: 8

      // Keyboard Layout Pill
      Rectangle {
        height: 34
        width: 72
        radius: 11
        color: kbMouse.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
          anchors.centerIn: parent
          spacing: 5
          Text { text: "󰌌"; font.pixelSize: 13; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
          Text {
            text: (ipc && ipc.keyboardLayout && ipc.keyboardLayout.current_short_code) ? ipc.keyboardLayout.current_short_code : "TR"
            font.family: Style.fontDisplay
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Style.textPrimary
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: kbMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.openView("KEYBOARD")
        }
      }

      // Minimalist Telemetry Pill (Click to pin beside Dynamic Island)
      Rectangle {
        width: parent.width - 72 - 36 - 36 - 24
        height: 34
        radius: 11
        color: Config.showPinnedSystemMetrics
          ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.16)
          : (telemetryMouse.containsMouse ? Style.surfaceHover : Style.surface)
        border.color: Config.showPinnedSystemMetrics
          ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.30)
          : Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
          anchors.centerIn: parent
          spacing: 6

          Text {
            visible: Config.showPinnedSystemMetrics
            text: "󰐃"
            font.pixelSize: 10
            color: Style.accent
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: {
              let pct = (ipc && ipc.cpu && ipc.cpu.cpu_percent !== undefined) ? Math.round(ipc.cpu.cpu_percent) : 0
              let temp = (ipc && ipc.cpu && ipc.cpu.cpu_temp !== undefined && ipc.cpu.cpu_temp > 0) ? ` ${Math.round(ipc.cpu.cpu_temp)}°` : ""
              return `CPU ${pct}%${temp}`
            }
            font.family: Style.fontDisplay
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.textPrimary : Style.textSecondary
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "·"
            font.pixelSize: 10
            color: Style.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: `RAM ${(ipc && ipc.ram && ipc.ram.ram_percent !== undefined) ? Math.round(ipc.ram.ram_percent) : 0}%`
            font.family: Style.fontDisplay
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.textPrimary : Style.textSecondary
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "·"
            font.pixelSize: 10
            color: Style.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: {
              let pct = (ipc && ipc.gpu && ipc.gpu.gpu_percent !== undefined && ipc.gpu.gpu_percent >= 0) ? Math.round(ipc.gpu.gpu_percent) : 0
              return `GPU ${pct}%`
            }
            font.family: Style.fontDisplay
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.textPrimary : Style.textSecondary
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "·"
            font.pixelSize: 10
            color: Style.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: {
              let rx = (ipc && ipc.net && ipc.net.rx_bytes_sec !== undefined) ? ipc.net.rx_bytes_sec : 0
              let tx = (ipc && ipc.net && ipc.net.tx_bytes_sec !== undefined) ? ipc.net.tx_bytes_sec : 0
              return root.formatSpeed(rx + tx)
            }
            font.family: Style.fontDisplay
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.accent : Style.textMuted
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: telemetryMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.showPinnedSystemMetrics = !Config.showPinnedSystemMetrics
        }
      }

      // Settings Button
      Rectangle {
        height: 34
        width: 36
        radius: 11
        color: setMouse.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
          anchors.centerIn: parent
          text: "󰒓"
          font.pixelSize: 14
          color: setMouse.containsMouse ? Style.textPrimary : Style.textSecondary
        }

        MouseArea {
          id: setMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.openSettingsApp()
        }
      }

      // Power Button
      Rectangle {
        height: 34
        width: 36
        radius: 11
        color: pwrMouse.containsMouse
          ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.20)
          : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
          anchors.centerIn: parent
          text: "󰐥"
          font.pixelSize: 14
          color: Style.accentRed
        }

        MouseArea {
          id: pwrMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: PowerService.open()
        }
      }
    }
  }
}
