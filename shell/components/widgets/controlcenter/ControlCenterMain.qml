import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../.."

Item {
  id: root

  property var ipc
  signal openView(string viewName)

  property int volumeLevel: 50
  property bool isMuted: false
  property int brightnessLevel: 70
  property bool gameModeActive: false

  // Telemetry properties
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && (ipc.wifi.connected || (ipc.net && ipc.net.is_connected)))
  readonly property string wifiSsidText: (ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : (isWifiConnected ? "Bağlı" : "Kapalı")
  readonly property bool isBtPowered: !!(ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered)
  readonly property int notifCount: (ipc && ipc.notifications) ? ipc.notifications.length : 0

  // System processes for Volume & Brightness
  Process {
    id: volGetProc
    command: ["pamixer", "--get-volume"]
    stdout: SplitParser {
      onRead: data => {
        let v = parseInt(data.trim())
        if (!isNaN(v)) root.volumeLevel = Math.max(0, Math.min(100, v))
      }
    }
  }

  Process {
    id: volMuteProc
    command: ["pamixer", "--get-mute"]
    stdout: SplitParser {
      onRead: data => {
        root.isMuted = (data.trim() === "true")
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

  function syncTelemetry() {
    volGetProc.running = true
    volMuteProc.running = true
    brightGetProc.running = true
  }

  function setVolume(val) {
    let target = Math.max(0, Math.min(100, Math.round(val)))
    root.volumeLevel = target
    root.isMuted = false
    setVolProc.command = ["pamixer", "--set-volume", "" + target]
    setVolProc.running = true
  }

  function toggleMute() {
    root.isMuted = !root.isMuted
    toggleMuteProc.command = ["pamixer", "-t"]
    toggleMuteProc.running = true
  }

  function setBrightness(val) {
    let target = Math.max(5, Math.min(100, Math.round(val)))
    root.brightnessLevel = target
    setBrightProc.command = ["brightnessctl", "set", target + "%"]
    setBrightProc.running = true
  }

  function toggleGameMode() {
    root.gameModeActive = !root.gameModeActive
    if (root.gameModeActive) {
      gameModeProc.command = ["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:blur:enabled 0; keyword decoration:drop_shadow 0"]
    } else {
      gameModeProc.command = ["hyprctl", "--batch", "keyword animations:enabled 1; keyword decoration:blur:enabled 1; keyword decoration:drop_shadow 1"]
    }
    gameModeProc.running = true
  }

  Component.onCompleted: syncTelemetry()

  // ==========================================
  // Layout Root
  // ==========================================
  Column {
    anchors.fill: parent
    spacing: 10

    // ==========================================
    // ROW 1: Split Connectivity Card + 2x2 Toggles Grid
    // ==========================================
    Row {
      width: parent.width
      height: 122
      spacing: 10

      // 1.1 Left Card: Connectivity Group (Wi-Fi & Bluetooth)
      Rectangle {
        width: parent.width - 186
        height: 122
        radius: 14
        color: Style.surface
        border.color: Style.border
        border.width: 1

        Column {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 2

          // Wi-Fi Button
          Rectangle {
            width: parent.width
            height: 52
            radius: 10
            color: wifiMouse.containsMouse ? Style.surfaceHover : "transparent"

            Row {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              // Wi-Fi Icon Badge
              Rectangle {
                width: 32
                height: 32
                radius: 16
                anchors.verticalCenter: parent.verticalCenter
                color: root.isWifiConnected ? Style.accentCyan : Style.surfaceVariant

                Text {
                  anchors.centerIn: parent
                  text: root.isWifiConnected ? "󰤨" : "󰤮"
                  font.pixelSize: 15
                  color: root.isWifiConnected ? "#000000" : Style.textMuted
                }
              }

              // Labels
              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 64
                spacing: 1

                Text {
                  text: "Wi-Fi"
                  font.pixelSize: 12
                  font.weight: Font.Bold
                  color: Style.textPrimary
                }
                Text {
                  text: root.wifiSsidText
                  font.pixelSize: 10
                  color: root.isWifiConnected ? Style.accentCyan : Style.textMuted
                  elide: Text.ElideRight
                  width: parent.width
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                font.pixelSize: 15
                color: Style.textMuted
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

          // Divider
          Rectangle {
            width: parent.width - 48
            x: 42
            height: 1
            color: Style.border
            opacity: 0.4
          }

          // Bluetooth Button
          Rectangle {
            width: parent.width
            height: 52
            radius: 10
            color: btMouse.containsMouse ? Style.surfaceHover : "transparent"

            Row {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              // Bluetooth Icon Badge
              Rectangle {
                width: 32
                height: 32
                radius: 16
                anchors.verticalCenter: parent.verticalCenter
                color: root.isBtPowered ? Style.accentCyan : Style.surfaceVariant

                Text {
                  anchors.centerIn: parent
                  text: root.isBtPowered ? "󰂯" : "󰂲"
                  font.pixelSize: 16
                  color: root.isBtPowered ? "#000000" : Style.textMuted
                }
              }

              // Labels
              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 64
                spacing: 1

                Text {
                  text: "Bluetooth"
                  font.pixelSize: 12
                  font.weight: Font.Bold
                  color: Style.textPrimary
                }
                Text {
                  text: root.isBtPowered ? "Açık" : "Kapalı"
                  font.pixelSize: 10
                  color: root.isBtPowered ? Style.accentCyan : Style.textMuted
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                font.pixelSize: 15
                color: Style.textMuted
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
        width: 176
        height: 122
        spacing: 8

        // Row 1: GameMode & Notifications
        Row {
          width: parent.width
          height: 57
          spacing: 8

          // Tile 1: Focus Mode (Odak Modu)
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 12
            color: Config.focusMode ? Style.accent : (focusMouse.containsMouse ? Style.surfaceHover : Style.surface)
            border.color: Config.focusMode ? Style.accent : Style.border
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Column {
              anchors.centerIn: parent
              spacing: 3

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Config.focusMode ? "󰈈" : "󰈉"
                font.pixelSize: 18
                color: Config.focusMode ? "#ffffff" : Style.accentCyan
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Odak Modu"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Config.focusMode ? "#ffffff" : Style.textPrimary
              }
            }

            MouseArea {
              id: focusMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Config.focusMode = !Config.focusMode
              }
            }
          }

          // Tile 2: Notifications
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 12
            color: (ipc && ipc.dndEnabled) ? Style.surfaceActive : (notifMouse.containsMouse ? Style.surfaceHover : Style.surface)
            border.color: (ipc && ipc.dndEnabled) ? Style.accentRed : Style.border
            border.width: 1

            Column {
              anchors.centerIn: parent
              spacing: 3

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (ipc && ipc.dndEnabled) ? "󰂛" : "󰂚"
                font.pixelSize: 18
                color: (ipc && ipc.dndEnabled) ? Style.accentRed : Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bildirimler"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Style.textPrimary
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
          height: 57
          spacing: 8

          // Tile 3: Themes
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 12
            color: themeMouse.containsMouse ? Style.surfaceHover : Style.surface
            border.color: Style.border
            border.width: 1

            Column {
              anchors.centerIn: parent
              spacing: 3

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰔎"
                font.pixelSize: 18
                color: Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tema"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Style.textPrimary
              }
            }

            MouseArea {
              id: themeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openView("THEMES")
            }
          }

          // Tile 4: Clipboard
          Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: 12
            color: clipMouse.containsMouse ? Style.surfaceHover : Style.surface
            border.color: Style.border
            border.width: 1

            Column {
              anchors.centerIn: parent
              spacing: 3

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰅍"
                font.pixelSize: 18
                color: Style.textPrimary
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Pano"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Style.textPrimary
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
      radius: 12
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      // Filled Active Level
      Rectangle {
        id: brightFill
        height: parent.height
        width: Math.max(0, Math.min(parent.width, parent.width * (root.brightnessLevel / 100.0)))
        radius: 12
        color: Style.surfaceActive
        opacity: 0.85
      }

      // Left Content: Icon + Label
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
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
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.textPrimary
        }
      }

      // Right Content: Percentage Indicator (Strictly Right Aligned)
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: `%${root.brightnessLevel}`
        font.pixelSize: 12
        font.weight: Font.Bold
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

        onClicked: mouse => updateLevel(mouse)
        onPositionChanged: mouse => {
          if (pressed) updateLevel(mouse)
        }
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
      radius: 12
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      // Filled Active Level
      Rectangle {
        id: soundFill
        height: parent.height
        width: root.isMuted ? 0 : Math.max(0, Math.min(parent.width, parent.width * (root.volumeLevel / 100.0)))
        radius: 12
        color: Style.surfaceActive
        opacity: 0.85
      }

      // Left Content: Speaker Icon + Label
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

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
            color: root.isMuted ? Style.accentRed : Style.textPrimary
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
          text: root.isMuted ? "Sessiz (Muted)" : "Ses Düzeyi"
          font.pixelSize: 12
          font.weight: Font.Medium
          color: root.isMuted ? Style.accentRed : Style.textPrimary
        }
      }

      // Right Content: Percentage Indicator (Strictly Right Aligned)
      Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.isMuted ? "0%" : `%${root.volumeLevel}`
        font.pixelSize: 12
        font.weight: Font.Bold
        color: Style.textSecondary
      }

      // Slider MouseArea placed on the track area
      MouseArea {
        anchors.fill: parent
        anchors.leftMargin: 38 // Do not overlap speaker mute button
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function updateLevel(mouse) {
          let availableWidth = width
          let pct = (mouse.x / availableWidth) * 100.0
          root.setVolume(pct)
        }

        onClicked: mouse => {
          if (mouse.button === Qt.RightButton) {
            root.openView("AUDIO_MIXER")
          } else {
            updateLevel(mouse)
          }
        }
        onPositionChanged: mouse => {
          if (pressed && (mouse.buttons & Qt.LeftButton)) updateLevel(mouse)
        }
        onWheel: wheel => {
          let delta = wheel.angleDelta.y > 0 ? 5 : -5
          root.setVolume(root.volumeLevel + delta)
        }
      }
    }

    // ==========================================
    // ROW 4: Status Footer & Power Action
    // ==========================================
    Row {
      width: parent.width
      height: 32
      spacing: 8

      // Keyboard Layout Pill
      Rectangle {
        height: 32
        width: 76
        radius: 8
        color: kbMouse.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.border
        border.width: 1

        Row {
          anchors.centerIn: parent
          spacing: 5
          Text { text: "󰌌"; font.pixelSize: 13; color: Style.textSecondary; anchors.verticalCenter: parent.verticalCenter }
          Text {
            text: (ipc && ipc.keyboardLayout && ipc.keyboardLayout.current_short_code) ? ipc.keyboardLayout.current_short_code : "TR"
            font.pixelSize: 11
            font.weight: Font.Bold
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
        width: parent.width - 76 - 40 - 16
        height: 32
        radius: 8
        color: Config.showPinnedSystemMetrics ? Style.surfaceActive : (telemetryMouse.containsMouse ? Style.surfaceHover : Style.surface)
        border.color: Config.showPinnedSystemMetrics ? Style.accentCyan : (telemetryMouse.containsMouse ? Style.borderHover : Style.border)
        border.width: Config.showPinnedSystemMetrics ? 1.5 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
          anchors.centerIn: parent
          spacing: 7

          Text {
            text: {
              let pct = (ipc && ipc.cpu && ipc.cpu.cpu_percent !== undefined) ? Math.round(ipc.cpu.cpu_percent) : 0
              let temp = (ipc && ipc.cpu && ipc.cpu.cpu_temp !== undefined && ipc.cpu.cpu_temp > 0) ? ` ${Math.round(ipc.cpu.cpu_temp)}°` : ""
              return `CPU %${pct}${temp}`
            }
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.accentCyan : (telemetryMouse.containsMouse ? Style.textPrimary : Style.textSecondary)
            font.weight: Config.showPinnedSystemMetrics ? Font.Bold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: 3
            height: 3
            radius: 1.5
            color: Config.showPinnedSystemMetrics ? Style.accentCyan : Style.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: `RAM %${(ipc && ipc.ram && ipc.ram.ram_percent !== undefined) ? Math.round(ipc.ram.ram_percent) : 0}`
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.accentGreen : (telemetryMouse.containsMouse ? Style.textPrimary : Style.textSecondary)
            font.weight: Config.showPinnedSystemMetrics ? Font.Bold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: 3
            height: 3
            radius: 1.5
            color: Config.showPinnedSystemMetrics ? Style.accentGreen : Style.textMuted
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: {
              let pct = (ipc && ipc.gpu && ipc.gpu.gpu_percent !== undefined && ipc.gpu.gpu_percent >= 0) ? Math.round(ipc.gpu.gpu_percent) : 0
              let temp = (ipc && ipc.gpu && ipc.gpu.gpu_temp !== undefined && ipc.gpu.gpu_temp > 0) ? ` ${Math.round(ipc.gpu.gpu_temp)}°` : ""
              return `GPU %${pct}${temp}`
            }
            font.pixelSize: 10
            color: Config.showPinnedSystemMetrics ? Style.accentOrange : (telemetryMouse.containsMouse ? Style.textPrimary : Style.textSecondary)
            font.weight: Config.showPinnedSystemMetrics ? Font.Bold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }
        }


        MouseArea {
          id: telemetryMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Config.showPinnedSystemMetrics = !Config.showPinnedSystemMetrics
          }
        }
      }


      // Power Button
      Rectangle {
        height: 32
        width: 40
        radius: 8
        color: pwrMouse.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.border
        border.width: 1

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
          onClicked: {
            PowerService.open()
          }
        }
      }
    }
  }
}
