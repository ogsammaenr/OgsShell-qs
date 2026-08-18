import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property int activeTab: 0 // 0: Uygulamalar (Apps), 1: Çıkış Cihazları (Sinks)
  property var appStreams: []
  property var outputSinks: []
  property bool isLoading: false

  // Helper Python script for fast and robust JSON parsing from pactl
  readonly property string getStreamsCmd: "import subprocess, json\n" +
    "try:\n" +
    "    res = subprocess.run(['pactl', '--format=json', 'list', 'sink-inputs'], capture_output=True, text=True)\n" +
    "    txt = res.stdout.strip()\n" +
    "    idx = txt.find('[')\n" +
    "    if idx != -1: txt = txt[idx:]\n" +
    "    data = json.loads(txt)\n" +
    "    streams = []\n" +
    "    for item in data:\n" +
    "        vol = 50\n" +
    "        vdict = item.get('volume', {})\n" +
    "        for ch, vinfo in vdict.items():\n" +
    "            if isinstance(vinfo, dict) and 'value_percent' in vinfo:\n" +
    "                vol = int(vinfo['value_percent'].replace('%', ''))\n" +
    "                break\n" +
    "        props = item.get('properties', {})\n" +
    "        name = props.get('application.name', props.get('media.name', 'Uygulama'))\n" +
    "        icon = props.get('application.icon_name', '')\n" +
    "        media = props.get('media.name', '')\n" +
    "        streams.append({'id': item.get('index'), 'name': name, 'media': media, 'icon': icon, 'volume': vol, 'mute': item.get('mute', False)})\n" +
    "    print(json.dumps(streams))\n" +
    "except Exception:\n" +
    "    print('[]')"

  readonly property string getSinksCmd: "import subprocess, json\n" +
    "try:\n" +
    "    res = subprocess.run(['pactl', '--format=json', 'list', 'sinks'], capture_output=True, text=True)\n" +
    "    txt = res.stdout.strip()\n" +
    "    idx = txt.find('[')\n" +
    "    if idx != -1: txt = txt[idx:]\n" +
    "    data = json.loads(txt)\n" +
    "    sinks = []\n" +
    "    for item in data:\n" +
    "        vol = 50\n" +
    "        vdict = item.get('volume', {})\n" +
    "        for ch, vinfo in vdict.items():\n" +
    "            if isinstance(vinfo, dict) and 'value_percent' in vinfo:\n" +
    "                vol = int(vinfo['value_percent'].replace('%', ''))\n" +
    "                break\n" +
    "        name = item.get('name', '')\n" +
    "        desc = item.get('description', name)\n" +
    "        active_port = item.get('active_port', '')\n" +
    "        sinks.append({'id': item.get('index'), 'name': name, 'description': desc, 'volume': vol, 'mute': item.get('mute', False), 'port': active_port})\n" +
    "    print(json.dumps(sinks))\n" +
    "except Exception:\n" +
    "    print('[]')"

  // =========================================================================
  // Background Process Runners
  // =========================================================================
  Process {
    id: fetchStreamsProc
    command: ["python3", "-c", root.getStreamsCmd]
    stdout: SplitParser {
      onRead: data => {
        try {
          let list = JSON.parse(data.trim())
          if (Array.isArray(list)) {
            root.appStreams = list
          }
        } catch (e) {}
        root.isLoading = false
      }
    }
  }

  Process {
    id: fetchSinksProc
    command: ["python3", "-c", root.getSinksCmd]
    stdout: SplitParser {
      onRead: data => {
        try {
          let list = JSON.parse(data.trim())
          if (Array.isArray(list)) {
            root.outputSinks = list
          }
        } catch (e) {}
      }
    }
  }

  Process { id: controlCmdProc }

  function refreshAudio() {
    root.isLoading = true
    fetchStreamsProc.running = true
    fetchSinksProc.running = true
  }

  function setStreamVolume(streamId, targetVol) {
    let vol = Math.max(0, Math.min(100, Math.round(targetVol)))
    // Optimistic UI update
    let updated = []
    for (let i = 0; i < root.appStreams.length; i++) {
      let s = root.appStreams[i]
      if (s.id === streamId) s.volume = vol
      updated.push(s)
    }
    root.appStreams = updated

    controlCmdProc.command = ["pactl", "set-sink-input-volume", "" + streamId, "" + vol + "%"]
    controlCmdProc.running = true
  }

  function toggleStreamMute(streamId) {
    // Optimistic UI update
    let updated = []
    for (let i = 0; i < root.appStreams.length; i++) {
      let s = root.appStreams[i]
      if (s.id === streamId) s.mute = !s.mute
      updated.push(s)
    }
    root.appStreams = updated

    controlCmdProc.command = ["pactl", "set-sink-input-mute", "" + streamId, "toggle"]
    controlCmdProc.running = true
  }

  function setSinkVolume(sinkId, targetVol) {
    let vol = Math.max(0, Math.min(100, Math.round(targetVol)))
    let updated = []
    for (let i = 0; i < root.outputSinks.length; i++) {
      let s = root.outputSinks[i]
      if (s.id === sinkId) s.volume = vol
      updated.push(s)
    }
    root.outputSinks = updated

    controlCmdProc.command = ["pactl", "set-sink-volume", "" + sinkId, "" + vol + "%"]
    controlCmdProc.running = true
  }

  function toggleSinkMute(sinkId) {
    let updated = []
    for (let i = 0; i < root.outputSinks.length; i++) {
      let s = root.outputSinks[i]
      if (s.id === sinkId) s.mute = !s.mute
      updated.push(s)
    }
    root.outputSinks = updated

    controlCmdProc.command = ["pactl", "set-sink-mute", "" + sinkId, "toggle"]
    controlCmdProc.running = true
  }

  function setDefaultSink(sinkNameOrId) {
    controlCmdProc.command = ["pactl", "set-default-sink", "" + sinkNameOrId]
    controlCmdProc.running = true
    pollTimer.restart()
  }

  function getAppGlyph(name) {
    let n = (name || "").toLowerCase()
    if (n.includes("firefox") || n.includes("zen") || n.includes("librewolf") || n.includes("browser")) return "󰖟"
    if (n.includes("spotify")) return "󰓇"
    if (n.includes("discord") || n.includes("vesktop") || n.includes("vencord")) return "󰙯"
    if (n.includes("chromium") || n.includes("chrome") || n.includes("brave")) return "󰊯"
    if (n.includes("steam") || n.includes("game") || n.includes("wine") || n.includes("proton")) return "󰊴"
    if (n.includes("vlc") || n.includes("mpv") || n.includes("player") || n.includes("video")) return "󰕼"
    if (n.includes("telegram")) return "󰀨"
    return "󰎆"
  }

  function getSinkGlyph(name, desc, port) {
    let s = (name + " " + desc + " " + port).toLowerCase()
    if (s.includes("headphone") || s.includes("headset") || s.includes("kulaklık")) return "󰋋"
    if (s.includes("hdmi") || s.includes("displayport") || s.includes("dp")) return "󰡁"
    if (s.includes("usb") || s.includes("dac")) return "󱡬"
    return "󰓃"
  }

  Component.onCompleted: {
    refreshAudio()
  }

  // Periodic poll timer while view is open
  Timer {
    id: pollTimer
    interval: 1800
    repeat: true
    running: root.visible
    onTriggered: refreshAudio()
  }

  // =========================================================================
  // Main Layout
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // -----------------------------------------------------------------------
    // 1. Header Bar: Navigation, Title & Refresh Action
    // -----------------------------------------------------------------------
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: backHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant
        border.color: backHover.containsMouse ? Style.borderHover : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "󰁍"
          font.pixelSize: 13
          color: Style.textPrimary
        }

        MouseArea {
          id: backHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.backRequested()
        }
      }

      // Title & Badge
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
          width: 24
          height: 24
          radius: 6
          color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.16)

          Text {
            anchors.centerIn: parent
            text: "󰓃"
            font.pixelSize: 14
            color: Style.accent
          }
        }

        Text {
          text: "Ses Karıştırıcısı"
          font.pixelSize: 13
          font.weight: Font.Bold
          color: Style.textPrimary
        }
      }

      // Refresh Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: refHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant
        border.color: refHover.containsMouse ? Style.borderHover : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "󰑐"
          font.pixelSize: 13
          color: root.isLoading ? Style.accent : Style.textPrimary

          RotationAnimation on rotation {
            running: root.isLoading
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
          }
        }

        MouseArea {
          id: refHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.refreshAudio()
        }
      }
    }

    // -----------------------------------------------------------------------
    // 2. Apple Segmented Pill Tab Bar (Uygulamalar / Çıkış Cihazları)
    // -----------------------------------------------------------------------
    Rectangle {
      Layout.fillWidth: true
      height: 30
      radius: 8
      color: Style.surfaceVariant
      border.color: Style.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2

        // Tab 0: Uygulamalar
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: root.activeTab === 0 ? Style.surfaceActive : "transparent"
          border.color: root.activeTab === 0 ? Style.borderHover : "transparent"
          border.width: root.activeTab === 0 ? 1 : 0

          Behavior on color { ColorAnimation { duration: 150 } }

          Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Uygulamalar"
              font.pixelSize: 11
              font.weight: root.activeTab === 0 ? Font.Bold : Font.Normal
              color: root.activeTab === 0 ? Style.textPrimary : Style.textMuted
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: appBadgeTxt.implicitWidth + 8
              height: 14
              radius: 7
              color: root.activeTab === 0 ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.25) : Style.surface
              visible: root.appStreams.length > 0

              Text {
                id: appBadgeTxt
                anchors.centerIn: parent
                text: "" + root.appStreams.length
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: root.activeTab === 0 ? Style.accent : Style.textMuted
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activeTab = 0
          }
        }

        // Tab 1: Çıkış Cihazları
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: root.activeTab === 1 ? Style.surfaceActive : "transparent"
          border.color: root.activeTab === 1 ? Style.borderHover : "transparent"
          border.width: root.activeTab === 1 ? 1 : 0

          Behavior on color { ColorAnimation { duration: 150 } }

          Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Çıkış Aygıtları"
              font.pixelSize: 11
              font.weight: root.activeTab === 1 ? Font.Bold : Font.Normal
              color: root.activeTab === 1 ? Style.textPrimary : Style.textMuted
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: sinkBadgeTxt.implicitWidth + 8
              height: 14
              radius: 7
              color: root.activeTab === 1 ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.25) : Style.surface
              visible: root.outputSinks.length > 0

              Text {
                id: sinkBadgeTxt
                anchors.centerIn: parent
                text: "" + root.outputSinks.length
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: root.activeTab === 1 ? Style.accent : Style.textMuted
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activeTab = 1
          }
        }
      }
    }

    // -----------------------------------------------------------------------
    // 3. Tab Content View
    // -----------------------------------------------------------------------
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      // =====================================================================
      // VIEW 1: Active Application Streams
      // =====================================================================
      Item {
        anchors.fill: parent
        visible: root.activeTab === 0

        // Empty State: No active audio streams
        ColumnLayout {
          anchors.centerIn: parent
          visible: root.appStreams.length === 0
          spacing: 8

          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 44
            radius: 22
            color: Style.surfaceVariant
            border.color: Style.border
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "󰎆"
              font.pixelSize: 20
              color: Style.textMuted
            }
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Aktif ses akışı yok"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bir müzik, video veya oyun sesi başlatın"
            font.pixelSize: 10
            color: Style.textMuted
          }
        }

        // Active Streams List
        ListView {
          id: streamsList
          anchors.fill: parent
          visible: root.appStreams.length > 0
          model: root.appStreams
          clip: true
          spacing: 6

          delegate: Rectangle {
            width: streamsList.width
            height: 64
            radius: 10
            color: Style.surfaceVariant
            border.color: Style.border
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 8
              spacing: 4

              // Stream Title Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App Glyph Badge
                Rectangle {
                  width: 22
                  height: 22
                  radius: 5
                  color: Style.surface

                  Text {
                    anchors.centerIn: parent
                    text: root.getAppGlyph(modelData.name)
                    font.pixelSize: 13
                    color: Style.accent
                  }
                }

                // App Name & Subtitle
                Column {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    width: parent.width
                    text: modelData.name || "Uygulama"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Style.textPrimary
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: (modelData.media && modelData.media !== "(null)") ? modelData.media : "Ses Akışı"
                    font.pixelSize: 9
                    color: Style.textMuted
                    elide: Text.ElideRight
                  }
                }

                // Stream Mute Toggle Button
                Rectangle {
                  width: 24
                  height: 24
                  radius: 12
                  color: modelData.mute ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.20) : (streamMuteHover.containsMouse ? Style.surfaceHover : Style.surface)
                  border.color: modelData.mute ? Style.accentRed : Style.border
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: modelData.mute ? "󰖁" : (modelData.volume > 50 ? "󰕾" : (modelData.volume > 0 ? "󰖀" : "󰕿"))
                    font.pixelSize: 12
                    color: modelData.mute ? Style.accentRed : Style.textPrimary
                  }

                  MouseArea {
                    id: streamMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleStreamMute(modelData.id)
                  }
                }
              }

              // Stream Volume Slider Capsule
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                radius: 6
                color: Style.surface
                border.color: Style.border
                border.width: 1
                clip: true

                // Active Fill Bar
                Rectangle {
                  height: parent.height
                  width: modelData.mute ? 0 : Math.max(0, Math.min(parent.width, parent.width * (modelData.volume / 100.0)))
                  radius: 6
                  color: Style.accent
                  opacity: 0.85

                  Behavior on width { NumberAnimation { duration: 100 } }
                }

                // Percentage Text
                Text {
                  anchors.right: parent.right
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.mute ? "Sessiz" : `%${modelData.volume}`
                  font.pixelSize: 9
                  font.weight: Font.Bold
                  color: modelData.mute ? Style.accentRed : Style.textPrimary
                }

                // Slider Mouse Handler
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  function updateStreamVol(mouse) {
                    let pct = Math.max(0, Math.min(100, (mouse.x / width) * 100.0))
                    root.setStreamVolume(modelData.id, pct)
                  }
                  onClicked: mouse => updateStreamVol(mouse)
                  onPositionChanged: mouse => {
                    if (pressed) updateStreamVol(mouse)
                  }
                  onWheel: wheel => {
                    let delta = wheel.angleDelta.y > 0 ? 5 : -5
                    root.setStreamVolume(modelData.id, modelData.volume + delta)
                  }
                }
              }
            }
          }
        }
      }

      // =====================================================================
      // VIEW 2: Output Sinks (Devices)
      // =====================================================================
      Item {
        anchors.fill: parent
        visible: root.activeTab === 1

        ListView {
          id: sinksList
          anchors.fill: parent
          model: root.outputSinks
          clip: true
          spacing: 6

          delegate: Rectangle {
            width: sinksList.width
            height: 64
            radius: 10
            color: Style.surfaceVariant
            border.color: Style.border
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 8
              spacing: 4

              // Sink Device Header Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Device Glyph Badge
                Rectangle {
                  width: 22
                  height: 22
                  radius: 5
                  color: Style.surface

                  Text {
                    anchors.centerIn: parent
                    text: root.getSinkGlyph(modelData.name, modelData.description, modelData.port)
                    font.pixelSize: 13
                    color: Style.accent
                  }
                }

                // Device Description
                Column {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    width: parent.width
                    text: modelData.description || modelData.name
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Style.textPrimary
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: modelData.port ? ("Port: " + modelData.port) : "Çıkış Aygıtı"
                    font.pixelSize: 9
                    color: Style.textMuted
                    elide: Text.ElideRight
                  }
                }

                // Default Sink Set Button
                Rectangle {
                  width: defaultTxt.implicitWidth + 10
                  height: 20
                  radius: 10
                  color: defaultHover.containsMouse ? Style.surfaceHover : Style.surface
                  border.color: Style.border
                  border.width: 1

                  Text {
                    id: defaultTxt
                    anchors.centerIn: parent
                    text: "Varsayılan"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: Style.textSecondary
                  }

                  MouseArea {
                    id: defaultHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setDefaultSink(modelData.name || modelData.id)
                  }
                }

                // Sink Mute Button
                Rectangle {
                  width: 24
                  height: 24
                  radius: 12
                  color: modelData.mute ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.20) : (sinkMuteHover.containsMouse ? Style.surfaceHover : Style.surface)
                  border.color: modelData.mute ? Style.accentRed : Style.border
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: modelData.mute ? "󰖁" : (modelData.volume > 50 ? "󰕾" : (modelData.volume > 0 ? "󰖀" : "󰕿"))
                    font.pixelSize: 12
                    color: modelData.mute ? Style.accentRed : Style.textPrimary
                  }

                  MouseArea {
                    id: sinkMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleSinkMute(modelData.id)
                  }
                }
              }

              // Master Sink Volume Slider Capsule
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                radius: 6
                color: Style.surface
                border.color: Style.border
                border.width: 1
                clip: true

                Rectangle {
                  height: parent.height
                  width: modelData.mute ? 0 : Math.max(0, Math.min(parent.width, parent.width * (modelData.volume / 100.0)))
                  radius: 6
                  color: Style.accent
                  opacity: 0.85

                  Behavior on width { NumberAnimation { duration: 100 } }
                }

                Text {
                  anchors.right: parent.right
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.mute ? "Sessiz" : `%${modelData.volume}`
                  font.pixelSize: 9
                  font.weight: Font.Bold
                  color: modelData.mute ? Style.accentRed : Style.textPrimary
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  function updateSinkVol(mouse) {
                    let pct = Math.max(0, Math.min(100, (mouse.x / width) * 100.0))
                    root.setSinkVolume(modelData.id, pct)
                  }
                  onClicked: mouse => updateSinkVol(mouse)
                  onPositionChanged: mouse => {
                    if (pressed) updateSinkVol(mouse)
                  }
                  onWheel: wheel => {
                    let delta = wheel.angleDelta.y > 0 ? 5 : -5
                    root.setSinkVolume(modelData.id, modelData.volume + delta)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
