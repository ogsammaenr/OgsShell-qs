import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  // Tab State: "WIRED" | "WIFI"
  property string activeTab: {
    if (activeEthDevice) return "WIRED"
    if (ipc && ipc.wifi && ipc.wifi.connected) return "WIFI"
    return "WIRED"
  }

  // Ethernet State
  property var ethDevices: []
  property var ethDetailMap: ({})
  property var ethProfiles: []
  property var activeEthDevice: {
    if (!ethDevices || ethDevices.length === 0) return null
    for (let i = 0; i < ethDevices.length; i++) {
      if (ethDevices[i].state === "connected") return ethDevices[i]
    }
    return null
  }
  readonly property bool isEthConnected: !!activeEthDevice

  // Wi-Fi Password Modal State
  property bool showPasswordModal: false
  property string selectedSsid: ""
  property string wifiPasswordInput: ""

  // Scanning & Refresh State
  property bool isManualRefreshing: false
  readonly property bool isEthRefreshing: ethStatusProc.running || ethDetailsProc.running || ethProfilesProc.running
  readonly property bool isWifiScanning: !!(ipc && ipc.isScanningWifi)
  readonly property bool isScanning: isWifiScanning || isManualRefreshing || isEthRefreshing

  Timer {
    id: manualRefreshTimer
    interval: 800
    repeat: false
    onTriggered: {
      root.isManualRefreshing = false
    }
  }

  // ==========================================
  // Process: Ethernet Device Status
  // ==========================================
  Process {
    id: ethStatusProc
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,IP4-CONNECTIVITY,CONNECTION,CON-UUID", "device", "status"]
    stdout: SplitParser {
      onRead: data => {
        // Collect full output in accumulator
        ethStatusAccum += data + "\n"
      }
    }
    onExited: {
      parseEthStatus(ethStatusAccum)
      ethStatusAccum = ""
    }
  }
  property string ethStatusAccum: ""

  // ==========================================
  // Process: Ethernet Device Details (IP, Gateway, MAC)
  // ==========================================
  Process {
    id: ethDetailsProc
    command: ["nmcli", "-t", "-f", "GENERAL.DEVICE,IP4.ADDRESS,IP4.GATEWAY,GENERAL.HWADDR", "device", "show"]
    stdout: SplitParser {
      onRead: data => {
        ethDetailsAccum += data + "\n"
      }
    }
    onExited: {
      parseEthDetails(ethDetailsAccum)
      ethDetailsAccum = ""
    }
  }
  property string ethDetailsAccum: ""

  // ==========================================
  // Process: Saved Ethernet Profiles
  // ==========================================
  Process {
    id: ethProfilesProc
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"]
    stdout: SplitParser {
      onRead: data => {
        ethProfilesAccum += data + "\n"
      }
    }
    onExited: {
      parseEthProfiles(ethProfilesAccum)
      ethProfilesAccum = ""
    }
  }
  property string ethProfilesAccum: ""

  // ==========================================
  // Process: Connect / Disconnect Actions
  // ==========================================
  Process {
    id: ethActionProc
    onExited: {
      actionRefreshTimer.restart()
    }
  }

  Timer {
    id: actionRefreshTimer
    interval: 400
    repeat: false
    onTriggered: {
      refreshAll()
    }
  }

  // ==========================================
  // Live Refresh & Polling
  // ==========================================
  Timer {
    id: liveSyncTimer
    interval: 3000
    repeat: true
    running: root.visible
    onTriggered: {
      refreshEthernet()
    }
  }

  function parseEthDetails(output) {
    if (!output) return
    let lines = output.split("\n")
    let map = {}
    let currDev = ""

    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim()
      if (!line) continue

      if (line.startsWith("GENERAL.DEVICE:")) {
        currDev = line.substring("GENERAL.DEVICE:".length).trim()
        if (!map[currDev]) {
          map[currDev] = { "ip": "", "gateway": "", "hwaddr": "" }
        }
      } else if (currDev && map[currDev]) {
        if (line.startsWith("IP4.ADDRESS")) {
          let val = line.split(":").slice(1).join(":").trim()
          if (!map[currDev].ip) map[currDev].ip = val
        } else if (line.startsWith("IP4.GATEWAY:")) {
          map[currDev].gateway = line.substring("IP4.GATEWAY:".length).trim()
        } else if (line.startsWith("GENERAL.HWADDR:")) {
          map[currDev].hwaddr = line.substring("GENERAL.HWADDR:".length).trim()
        }
      }
    }
    root.ethDetailMap = map
    mergeEthData()
  }

  function parseEthStatus(output) {
    if (!output) return
    let lines = output.split("\n")
    let rawList = []

    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim()
      if (!line) continue
      let parts = line.split(":")
      if (parts.length >= 3 && parts[1] === "ethernet") {
        let devName = parts[0]
        let state = parts[2]
        let connName = (parts.length > 4) ? parts[4] : ""
        let uuid = (parts.length > 5) ? parts[5] : ""

        rawList.push({
          "device": devName,
          "state": state,
          "connection": connName,
          "uuid": uuid,
          "ip": "",
          "gateway": "",
          "hwaddr": ""
        })
      }
    }
    rawEthList = rawList
    mergeEthData()
  }
  property var rawEthList: []

  function parseEthProfiles(output) {
    if (!output) return
    let lines = output.split("\n")
    let profs = []

    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim()
      if (!line) continue
      let parts = line.split(":")
      if (parts.length >= 3 && (parts[2] === "802-3-ethernet" || parts[2] === "ethernet")) {
        profs.push({
          "name": parts[0],
          "uuid": parts[1],
          "type": parts[2],
          "device": (parts.length > 3) ? parts[3] : ""
        })
      }
    }
    root.ethProfiles = profs
  }

  function mergeEthData() {
    let list = []
    for (let i = 0; i < rawEthList.length; i++) {
      let item = Object.assign({}, rawEthList[i])
      let details = root.ethDetailMap[item.device]
      if (details) {
        item.ip = details.ip || ""
        item.gateway = details.gateway || ""
        item.hwaddr = details.hwaddr || ""
      }
      list.push(item)
    }
    root.ethDevices = list
  }

  function refreshEthernet() {
    ethStatusAccum = ""
    ethDetailsAccum = ""
    ethProfilesAccum = ""
    ethStatusProc.running = true
    ethDetailsProc.running = true
    ethProfilesProc.running = true
  }

  function rescanWifi() {
    if (ipc) {
      if (typeof ipc.scanWifi === "function") {
        ipc.scanWifi()
      } else {
        ipc.sendAction("scan_wifi", {})
        ipc.sendAction("get_active_wifi", {})
      }
    }
  }

  function refreshAll() {
    isManualRefreshing = true
    manualRefreshTimer.restart()
    rescanWifi()
    refreshEthernet()
  }

  function connectEthernet(devName) {
    if (!devName) return
    ethActionProc.command = ["nmcli", "device", "connect", devName]
    ethActionProc.running = true
  }

  function disconnectEthernet(devName) {
    if (!devName) return
    ethActionProc.command = ["nmcli", "device", "disconnect", devName]
    ethActionProc.running = true
  }

  function activateProfile(uuidOrName) {
    if (!uuidOrName) return
    ethActionProc.command = ["nmcli", "connection", "up", uuidOrName]
    ethActionProc.running = true
  }

  function deactivateProfile(uuidOrName) {
    if (!uuidOrName) return
    ethActionProc.command = ["nmcli", "connection", "down", uuidOrName]
    ethActionProc.running = true
  }

  Component.onCompleted: {
    refreshAll()
  }

  onVisibleChanged: {
    if (visible) refreshAll()
  }

  // ==========================================
  // Layout Root
  // ==========================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // Header Row: Back Button + Segmented Switcher + Rescan Button
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back Button
      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: backHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "‹"
          font.pixelSize: 16
          font.weight: Font.Bold
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

      // Segmented Tab Selector (Apple HIG Style)
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 14
        color: Style.surfaceVariant
        border.color: Style.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 2
          spacing: 2

          // Tab 1: Kablolu (Ethernet)
          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: root.activeTab === "WIRED" ? Style.surfaceActive : (ethTabHover.containsMouse ? Style.surfaceHover : "transparent")
            border.color: root.activeTab === "WIRED" ? Style.accent : "transparent"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
              anchors.centerIn: parent
              spacing: 5

              Text {
                text: "󰈀"
                font.pixelSize: 12
                color: root.isEthConnected ? Style.accentGreen : (root.activeTab === "WIRED" ? Style.textPrimary : Style.textMuted)
              }

              Text {
                text: "Kablolu"
                font.pixelSize: 11
                font.weight: root.activeTab === "WIRED" ? Font.Bold : Font.Medium
                color: root.activeTab === "WIRED" ? Style.textPrimary : Style.textMuted
              }

              // Connected Green Dot
              Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: Style.accentGreen
                visible: root.isEthConnected
              }
            }

            MouseArea {
              id: ethTabHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeTab = "WIRED"
            }
          }

          // Tab 2: Kablosuz (Wi-Fi)
          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: root.activeTab === "WIFI" ? Style.surfaceActive : (wifiTabHover.containsMouse ? Style.surfaceHover : "transparent")
            border.color: root.activeTab === "WIFI" ? Style.accent : "transparent"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
              anchors.centerIn: parent
              spacing: 5

              Text {
                text: "󰤨"
                font.pixelSize: 12
                color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : (root.activeTab === "WIFI" ? Style.textPrimary : Style.textMuted)
              }

              Text {
                text: "Wi-Fi"
                font.pixelSize: 11
                font.weight: root.activeTab === "WIFI" ? Font.Bold : Font.Medium
                color: root.activeTab === "WIFI" ? Style.textPrimary : Style.textMuted
              }

              // Connected Cyan Dot
              Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: Style.accentCyan
                visible: !!(ipc && ipc.wifi && ipc.wifi.connected)
              }
            }

            MouseArea {
              id: wifiTabHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeTab = "WIFI"
            }
          }
        }
      }

      // Rescan Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: scanHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          id: rescanIcon
          anchors.centerIn: parent
          text: "↻"
          font.pixelSize: 14
          color: root.isScanning ? Style.accentCyan : Style.textPrimary

          RotationAnimation on rotation {
            id: scanAnim
            running: root.isScanning
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
            onRunningChanged: {
              if (!running) {
                rescanIcon.rotation = 0
              }
            }
          }
        }

        MouseArea {
          id: scanHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: root.isScanning ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: {
            if (!root.isScanning) {
              root.refreshAll()
            }
          }
        }
      }
    }

    // =========================================================================
    // VIEW 1: KABLOLU (ETHERNET) VIEW
    // =========================================================================
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.activeTab === "WIRED"

      ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Active Ethernet Connection Banner Card
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          radius: 8
          color: Style.surfaceVariant
          border.color: root.isEthConnected ? Style.accentGreen : Style.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: root.isEthConnected ? "󰈀" : "󰌙"
              font.pixelSize: 20
              color: root.isEthConnected ? Style.accentGreen : Style.textMuted
            }

            Column {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: root.isEthConnected ? (root.activeEthDevice.connection || root.activeEthDevice.device) : "Kablolu Bağlantı Yok"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Style.textPrimary
                elide: Text.ElideRight
              }

              Text {
                text: {
                  if (root.isEthConnected) {
                    let parts = [root.activeEthDevice.device]
                    if (root.activeEthDevice.ip) parts.push(`IP: ${root.activeEthDevice.ip}`)
                    if (root.activeEthDevice.gateway) parts.push(`Geçit: ${root.activeEthDevice.gateway}`)
                    return parts.join(" • ")
                  }
                  return "Bir ethernet kablosu takın veya bağlantıyı etkinleştirin"
                }
                font.pixelSize: 10
                color: root.isEthConnected ? Style.accentGreen : Style.textMuted
                elide: Text.ElideRight
                width: parent.width
              }
            }

            // Disconnect Button
            Rectangle {
              visible: root.isEthConnected
              Layout.preferredHeight: 26
              Layout.preferredWidth: 80
              radius: 6
              color: ethDisHover.containsMouse ? Style.surfaceActive : Style.surface
              border.color: Style.border
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Bağlantıyı Kes"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Style.accentRed
              }

              MouseArea {
                id: ethDisHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.activeEthDevice) {
                    root.disconnectEthernet(root.activeEthDevice.device)
                  }
                }
              }
            }
          }
        }

        // Ethernet Adapters & Interfaces List Container
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 10
          color: Style.surface
          border.color: Style.border
          border.width: 1
          clip: true

          ListView {
            id: ethList
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4
            reuseItems: true
            model: root.ethDevices

            delegate: Rectangle {
              width: ethList.width
              height: 48
              radius: 8
              readonly property bool isConnected: modelData.state === "connected"
              readonly property bool isUnavailable: modelData.state === "unavailable"
              color: isConnected ? Style.surfaceActive : (ethItemHover.containsMouse ? Style.surfaceVariant : "transparent")
              border.color: isConnected ? Style.accentGreen : "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // Device Icon
                Text {
                  text: isConnected ? "󰈀" : (isUnavailable ? "󰌙" : "󰈂")
                  font.pixelSize: 18
                  color: isConnected ? Style.accentGreen : (isUnavailable ? Style.textMuted : Style.textPrimary)
                }

                // Device Info
                Column {
                  Layout.fillWidth: true
                  spacing: 1

                  RowLayout {
                    spacing: 6
                    Text {
                      text: modelData.device
                      font.pixelSize: 12
                      font.weight: isConnected ? Font.Bold : Font.Medium
                      color: isConnected ? Style.accentGreen : Style.textPrimary
                    }
                    Text {
                      visible: !!modelData.connection
                      text: `(${modelData.connection})`
                      font.pixelSize: 11
                      color: Style.textMuted
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    text: {
                      if (isConnected) {
                        return modelData.ip ? `Bağlı • ${modelData.ip}` : "Bağlantı Aktif"
                      }
                      if (isUnavailable) {
                        return "Kablo takılı değil (Kullanılamıyor)"
                      }
                      return "Bağlantıya hazır"
                    }
                    font.pixelSize: 10
                    color: isConnected ? Style.accentGreen : Style.textMuted
                  }
                }

                // MAC Address badge (if available)
                Rectangle {
                  visible: !!modelData.hwaddr
                  Layout.preferredHeight: 18
                  Layout.preferredWidth: 92
                  radius: 4
                  color: Style.surfaceVariant

                  Text {
                    anchors.centerIn: parent
                    text: modelData.hwaddr
                    font.pixelSize: 9
                    font.family: "monospace"
                    color: Style.textMuted
                  }
                }

                // Action Button (Connect / Disconnect)
                Rectangle {
                  visible: !isUnavailable
                  Layout.preferredHeight: 24
                  Layout.preferredWidth: isConnected ? 64 : 54
                  radius: 5
                  color: isConnected ? (actionBtnHover.containsMouse ? Style.surfaceActive : Style.surfaceVariant) : (actionBtnHover.containsMouse ? Style.accentCyan : Style.surfaceVariant)
                  border.color: isConnected ? Style.border : Style.accentCyan
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: isConnected ? "Kes" : "Bağlan"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: isConnected ? Style.accentRed : (isConnected ? Style.textPrimary : Style.textPrimary)
                  }

                  MouseArea {
                    id: actionBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (isConnected) {
                        root.disconnectEthernet(modelData.device)
                      } else {
                        root.connectEthernet(modelData.device)
                      }
                    }
                  }
                }

                // Unavailable Badge
                Rectangle {
                  visible: isUnavailable
                  Layout.preferredHeight: 20
                  Layout.preferredWidth: 64
                  radius: 4
                  color: Style.surfaceVariant

                  Text {
                    anchors.centerIn: parent
                    text: "Pasif"
                    font.pixelSize: 9
                    color: Style.textMuted
                  }
                }
              }

              MouseArea {
                id: ethItemHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isUnavailable ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: {
                  if (isUnavailable) return
                  if (isConnected) {
                    root.disconnectEthernet(modelData.device)
                  } else {
                    root.connectEthernet(modelData.device)
                  }
                }
              }
            }

            // Empty state placeholder
            Item {
              anchors.centerIn: parent
              visible: ethList.count === 0
              Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Kablolu Arayüz Taranıyor..."
                  color: Style.textPrimary
                  font.pixelSize: 12
                  font.weight: Font.Bold
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Sistemdeki ethernet adaptörleri aranıyor."
                  color: Style.textMuted
                  font.pixelSize: 10
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // VIEW 2: KABLOSUZ (WI-FI) VIEW
    // =========================================================================
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.activeTab === "WIFI"

      ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Active Wi-Fi Connection Banner
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 44
          radius: 8
          color: Style.surfaceVariant
          border.color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : Style.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: (ipc && ipc.wifi && ipc.wifi.connected) ? "󰤨" : "󰤮"
              font.pixelSize: 18
              color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : Style.textMuted
            }

            Column {
              Layout.fillWidth: true
              spacing: 1
              Text {
                text: (ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : ((ipc && ipc.wifi && ipc.wifi.connected) ? "Bağlı Ağ" : "Bağlantı Yok")
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Style.textPrimary
                elide: Text.ElideRight
              }
              Text {
                text: (ipc && ipc.wifi && ipc.wifi.connected) ? `Sinyal Gücü: %${ipc.wifi.signal || 75}` : "Kullanılabilir bir ağ seçip bağlanın"
                font.pixelSize: 10
                color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : Style.textMuted
              }
            }

            // Disconnect Button
            Rectangle {
              visible: !!(ipc && ipc.wifi && ipc.wifi.connected)
              Layout.preferredHeight: 26
              Layout.preferredWidth: 80
              radius: 6
              color: disHover.containsMouse ? Style.surfaceActive : Style.surface
              border.color: Style.border
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Bağlantıyı Kes"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Style.accentRed
              }

              MouseArea {
                id: disHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) ipc.sendAction("disconnect_wifi", {})
                }
              }
            }
          }
        }

        // Scanned Access Points List
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 10
          color: Style.surface
          border.color: Style.border
          border.width: 1
          clip: true

          ListView {
            id: wifiList
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4
            reuseItems: true
            cacheBuffer: 60
            model: {
              if (!ipc || !ipc.wifi) return []
              let res = ipc.wifi.access_points || ipc.wifi.scan_results || []
              return Array.isArray(res) ? res : []
            }

            delegate: Rectangle {
              width: wifiList.width
              height: 44
              radius: 8
              readonly property bool isActive: !!(modelData.is_active || modelData.is_connected)
              color: isActive ? Style.surfaceActive : (itemHover.containsMouse ? Style.surfaceVariant : "transparent")
              border.color: isActive ? Style.accentCyan : "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // Signal Icon
                Text {
                  text: (modelData.signal >= 70) ? "󰤨" : ((modelData.signal >= 45) ? "󰤥" : ((modelData.signal >= 20) ? "󰤢" : "󰤟"))
                  font.pixelSize: 16
                  color: isActive ? Style.accentCyan : Style.textPrimary
                }

                // Network Name & Info
                Column {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    text: modelData.ssid || "Gizli Ağ (Hidden)"
                    font.pixelSize: 12
                    font.weight: isActive ? Font.Bold : Font.Medium
                    color: isActive ? Style.accentCyan : Style.textPrimary
                    elide: Text.ElideRight
                    width: wifiList.width - 120
                  }
                  Text {
                    text: `${modelData.band || "2.4/5GHz"} • Sinyal: %${modelData.signal || 0}`
                    font.pixelSize: 10
                    color: Style.textMuted
                  }
                }

                // Security Badge / Icon
                Rectangle {
                  visible: !!(modelData.security && modelData.security !== "OPEN")
                  Layout.preferredHeight: 20
                  Layout.preferredWidth: 46
                  radius: 4
                  color: Style.surfaceVariant

                  Text {
                    anchors.centerIn: parent
                    text: modelData.security || "WPA2"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Style.textMuted
                  }
                }

                // Active Checkmark
                Text {
                  visible: isActive
                  text: "✓"
                  font.pixelSize: 13
                  color: Style.accentCyan
                  font.weight: Font.Bold
                }
              }

              MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (isActive) return
                  root.selectedSsid = modelData.ssid || ""
                  if (modelData.security === "OPEN" || (modelData.is_saved && modelData.has_password !== false)) {
                    if (ipc) ipc.sendAction("connect_wifi", { "ssid": modelData.ssid, "password": "" })
                  } else {
                    root.wifiPasswordInput = ""
                    root.showPasswordModal = true
                  }
                }
              }
            }

            // Empty state placeholder
            Item {
              anchors.centerIn: parent
              visible: wifiList.count === 0
              Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Ağlar Taranıyor..."
                  color: Style.textPrimary
                  font.pixelSize: 12
                  font.weight: Font.Bold
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Çevredeki Wi-Fi ağları aranıyor, lütfen bekleyin."
                  color: Style.textMuted
                  font.pixelSize: 10
                }
              }
            }
          }
        }

        // Inline Password Input Sheet
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 42
          radius: 8
          color: Style.surfaceActive
          border.color: Style.accentCyan
          border.width: 1
          visible: root.showPasswordModal

          RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            TextInput {
              id: passInput
              Layout.fillWidth: true
              verticalAlignment: TextInput.AlignVCenter
              color: Style.textPrimary
              font.pixelSize: 12
              echoMode: TextInput.Password
              text: root.wifiPasswordInput
              onTextChanged: root.wifiPasswordInput = text
              focus: root.showPasswordModal
              onAccepted: {
                if (ipc && root.selectedSsid) {
                  ipc.sendAction("connect_wifi", { "ssid": root.selectedSsid, "password": root.wifiPasswordInput })
                }
                root.showPasswordModal = false
              }

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: `${root.selectedSsid} ağ parolası...`
                color: Style.textMuted
                font.pixelSize: 12
                visible: !passInput.text && !passInput.activeFocus
              }
            }

            // Connect Button
            Rectangle {
              Layout.preferredWidth: 68
              Layout.preferredHeight: 28
              radius: 6
              color: Style.accent

              Text {
                anchors.centerIn: parent
                text: "Bağlan"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#ffffff"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc && root.selectedSsid) {
                    ipc.sendAction("connect_wifi", { "ssid": root.selectedSsid, "password": root.wifiPasswordInput })
                  }
                  root.showPasswordModal = false
                }
              }
            }

            // Cancel Button
            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 6
              color: Style.surfaceVariant

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 11
                color: Style.textMuted
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showPasswordModal = false
              }
            }
          }
        }
      }
    }
  }
}
