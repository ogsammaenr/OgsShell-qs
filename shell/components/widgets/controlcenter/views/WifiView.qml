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
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && ipc.wifi.connected)

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
    onTriggered: root.isManualRefreshing = false
  }

  // Process: Ethernet Device Status
  Process {
    id: ethStatusProc
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,IP4-CONNECTIVITY,CONNECTION,CON-UUID", "device", "status"]
    stdout: SplitParser {
      onRead: data => { ethStatusAccum += data + "\n" }
    }
    onExited: {
      parseEthStatus(ethStatusAccum)
      ethStatusAccum = ""
    }
  }
  property string ethStatusAccum: ""

  // Process: Ethernet Device Details (IP, Gateway, MAC)
  Process {
    id: ethDetailsProc
    command: ["nmcli", "-t", "-f", "GENERAL.DEVICE,IP4.ADDRESS,IP4.GATEWAY,GENERAL.HWADDR", "device", "show"]
    stdout: SplitParser {
      onRead: data => { ethDetailsAccum += data + "\n" }
    }
    onExited: {
      parseEthDetails(ethDetailsAccum)
      ethDetailsAccum = ""
    }
  }
  property string ethDetailsAccum: ""

  // Process: Saved Ethernet Profiles
  Process {
    id: ethProfilesProc
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"]
    stdout: SplitParser {
      onRead: data => { ethProfilesAccum += data + "\n" }
    }
    onExited: {
      parseEthProfiles(ethProfilesAccum)
      ethProfilesAccum = ""
    }
  }
  property string ethProfilesAccum: ""

  // Process: Connect / Disconnect Actions
  Process {
    id: ethActionProc
    onExited: actionRefreshTimer.restart()
  }

  Timer {
    id: actionRefreshTimer
    interval: 400
    repeat: false
    onTriggered: refreshAll()
  }

  Timer {
    id: liveSyncTimer
    interval: 3000
    repeat: true
    running: root.visible
    onTriggered: refreshEthernet()
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
        rawList.push({
          "device": parts[0],
          "state": parts[2],
          "connection": (parts.length > 4) ? parts[4] : "",
          "uuid": (parts.length > 5) ? parts[5] : "",
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

  Component.onCompleted: refreshAll()
  onVisibleChanged: {
    if (visible) refreshAll()
  }

  // ==========================================
  // Layout Root
  // ==========================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 10

    // Unified Header
    CCViewHeader {
      title: "Ağ Bağlantıları"
      onBackRequested: root.backRequested()

      // Rescan Button
      Rectangle {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        radius: 13
        color: scanHover.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
          id: rescanIcon
          anchors.centerIn: parent
          text: "󰑐"
          font.pixelSize: 13
          color: root.isScanning ? Style.accent : Style.textPrimary

          RotationAnimation on rotation {
            running: root.isScanning
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
            onRunningChanged: {
              if (!running) rescanIcon.rotation = 0
            }
          }
        }

        MouseArea {
          id: scanHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: root.isScanning ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: {
            if (!root.isScanning) root.refreshAll()
          }
        }
      }
    }

    // Spring-Animated Sliding Segmented Control
    CCSegmentedControl {
      currentIndex: root.activeTab === "WIRED" ? 0 : 1
      items: [
        {
          "label": "Kablolu",
          "icon": "󰈀",
          "iconColor": root.isEthConnected ? Style.accentGreen : null,
          "showDot": root.isEthConnected,
          "dotColor": Style.accentGreen
        },
        {
          "label": "Wi-Fi",
          "icon": "󰤨",
          "iconColor": root.isWifiConnected ? Style.accent : null,
          "showDot": root.isWifiConnected,
          "dotColor": Style.accent
        }
      ]
      onSelected: idx => {
        root.activeTab = (idx === 0) ? "WIRED" : "WIFI"
      }
    }

    // =========================================================================
    // VIEW 1: KABLOLU (ETHERNET)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 8
      visible: root.activeTab === "WIRED"

      // Active Ethernet Status Strip
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 46
        radius: 14
        color: root.isEthConnected
          ? Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.12)
          : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 10
          spacing: 10

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: root.isEthConnected ? Style.accentGreen : Style.surfaceVariant

            Text {
              anchors.centerIn: parent
              text: root.isEthConnected ? "󰈀" : "󰌙"
              font.pixelSize: 14
              color: root.isEthConnected ? "#000000" : Style.textMuted
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: 1

            Text {
              width: parent.width
              text: root.isEthConnected ? (root.activeEthDevice.connection || root.activeEthDevice.device) : "Kablolu Bağlantı Yok"
              font.family: Style.fontDisplay
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: Style.textPrimary
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: {
                if (root.isEthConnected) {
                  let parts = [root.activeEthDevice.device]
                  if (root.activeEthDevice.ip) parts.push(root.activeEthDevice.ip)
                  if (root.activeEthDevice.gateway) parts.push(`Geçit ${root.activeEthDevice.gateway}`)
                  return parts.join(" · ")
                }
                return "Ethernet kablosu takılı değil"
              }
              font.family: Style.fontText
              font.pixelSize: 10
              color: root.isEthConnected ? Style.textSecondary : Style.textMuted
              elide: Text.ElideRight
            }
          }

          Rectangle {
            visible: root.isEthConnected
            Layout.preferredHeight: 24
            Layout.preferredWidth: 56
            radius: 12
            color: ethDisHover.containsMouse
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24)
              : Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.14)

            Text {
              anchors.centerIn: parent
              text: "Kes"
              font.family: Style.fontDisplay
              font.pixelSize: 10
              font.weight: Font.DemiBold
              color: Style.accentRed
            }

            MouseArea {
              id: ethDisHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.activeEthDevice) root.disconnectEthernet(root.activeEthDevice.device)
              }
            }
          }
        }
      }

      // Continuous Grouped Ethernet List
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 14
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
        border.color: Style.borderSubtle
        border.width: 1
        clip: true

        ListView {
          id: ethList
          anchors.fill: parent
          anchors.margins: 5
          spacing: 2
          reuseItems: true
          boundsBehavior: Flickable.StopAtBounds
          model: root.ethDevices

          delegate: Rectangle {
            width: ethList.width
            height: 46
            radius: 10
            readonly property bool isConnected: modelData.state === "connected"
            readonly property bool isUnavailable: modelData.state === "unavailable"
            color: isConnected
              ? Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.12)
              : (ethItemHover.containsMouse ? Style.surfaceHover : "transparent")

            Behavior on color { ColorAnimation { duration: 140 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              Text {
                text: isConnected ? "󰈀" : (isUnavailable ? "󰌙" : "󰈂")
                font.pixelSize: 16
                color: isConnected ? Style.accentGreen : (isUnavailable ? Style.textMuted : Style.textPrimary)
              }

              Column {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  width: parent.width
                  text: modelData.connection ? `${modelData.device} · ${modelData.connection}` : modelData.device
                  font.family: Style.fontDisplay
                  font.pixelSize: 11
                  font.weight: isConnected ? Font.DemiBold : Font.Medium
                  color: Style.textPrimary
                  elide: Text.ElideRight
                }

                Text {
                  width: parent.width
                  text: {
                    if (isConnected) return modelData.ip ? `Bağlı · ${modelData.ip}` : "Bağlı"
                    if (isUnavailable) return "Kablo takılı değil"
                    return "Bağlantıya hazır"
                  }
                  font.family: Style.fontText
                  font.pixelSize: 10
                  color: isConnected ? Style.accentGreen : Style.textMuted
                  elide: Text.ElideRight
                }
              }

              // Action Pill
              Rectangle {
                visible: !isUnavailable
                Layout.preferredHeight: 24
                Layout.preferredWidth: isConnected ? 48 : 58
                radius: 12
                color: isConnected
                  ? (actionBtnHover.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24) : Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.14))
                  : (actionBtnHover.containsMouse ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.28) : Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.18))

                Text {
                  anchors.centerIn: parent
                  text: isConnected ? "Kes" : "Bağlan"
                  font.family: Style.fontDisplay
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                  color: isConnected ? Style.accentRed : Style.accent
                }

                MouseArea {
                  id: actionBtnHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (isConnected) root.disconnectEthernet(modelData.device)
                    else root.connectEthernet(modelData.device)
                  }
                }
              }

              Text {
                visible: isUnavailable
                text: "Pasif"
                font.family: Style.fontText
                font.pixelSize: 10
                color: Style.textMuted
              }
            }

            MouseArea {
              id: ethItemHover
              anchors.fill: parent
              anchors.rightMargin: 66
              hoverEnabled: true
              cursorShape: isUnavailable ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: {
                if (isUnavailable) return
                if (isConnected) root.disconnectEthernet(modelData.device)
                else root.connectEthernet(modelData.device)
              }
            }
          }

          Item {
            anchors.centerIn: parent
            visible: ethList.count === 0
            Column {
              anchors.centerIn: parent
              spacing: 4
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Ethernet arayüzü bulunamadı"
                font.family: Style.fontDisplay
                color: Style.textSecondary
                font.pixelSize: 11
                font.weight: Font.Medium
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // VIEW 2: KABLOSUZ (WI-FI)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 8
      visible: root.activeTab === "WIFI"

      // Active Wi-Fi Status Strip
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 46
        radius: 14
        color: root.isWifiConnected
          ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.12)
          : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 10
          spacing: 10

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: root.isWifiConnected ? Style.accent : Style.surfaceVariant

            Text {
              anchors.centerIn: parent
              text: root.isWifiConnected ? "󰤨" : "󰤮"
              font.pixelSize: 14
              color: root.isWifiConnected ? "#000000" : Style.textMuted
            }
          }

          Column {
            Layout.fillWidth: true
            spacing: 1

            Text {
              width: parent.width
              text: (ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı")
                ? ipc.wifi.ssid
                : (root.isWifiConnected ? "Bağlı Ağ" : "Bağlantı Yok")
              font.family: Style.fontDisplay
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: Style.textPrimary
              elide: Text.ElideRight
            }

            Text {
              text: root.isWifiConnected
                ? `Sinyal %${ipc.wifi.signal || 75}`
                : "Bağlanmak için bir ağ seçin"
              font.family: Style.fontText
              font.pixelSize: 10
              color: root.isWifiConnected ? Style.textSecondary : Style.textMuted
            }
          }

          Rectangle {
            visible: root.isWifiConnected
            Layout.preferredHeight: 24
            Layout.preferredWidth: 56
            radius: 12
            color: disHover.containsMouse
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24)
              : Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.14)

            Text {
              anchors.centerIn: parent
              text: "Kes"
              font.family: Style.fontDisplay
              font.pixelSize: 10
              font.weight: Font.DemiBold
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

      // Scanned Access Points Continuous List
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 14
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
        border.color: Style.borderSubtle
        border.width: 1
        clip: true

        ListView {
          id: wifiList
          anchors.fill: parent
          anchors.margins: 5
          spacing: 2
          reuseItems: true
          cacheBuffer: 60
          boundsBehavior: Flickable.StopAtBounds
          model: {
            if (!ipc || !ipc.wifi) return []
            let res = ipc.wifi.access_points || ipc.wifi.scan_results || []
            return Array.isArray(res) ? res : []
          }

          delegate: Rectangle {
            width: wifiList.width
            height: 44
            radius: 10
            readonly property bool isActive: !!(modelData.is_active || modelData.is_connected)
            color: isActive
              ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.14)
              : (itemHover.containsMouse ? Style.surfaceHover : "transparent")

            Behavior on color { ColorAnimation { duration: 140 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              Text {
                text: (modelData.signal >= 70) ? "󰤨" : ((modelData.signal >= 45) ? "󰤥" : ((modelData.signal >= 20) ? "󰤢" : "󰤟"))
                font.pixelSize: 15
                color: isActive ? Style.accent : Style.textPrimary
              }

              Column {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  width: parent.width
                  text: modelData.ssid || "Gizli Ağ"
                  font.family: Style.fontDisplay
                  font.pixelSize: 11
                  font.weight: isActive ? Font.DemiBold : Font.Medium
                  color: Style.textPrimary
                  elide: Text.ElideRight
                }

                Text {
                  text: `${modelData.band || "2.4/5GHz"} · %${modelData.signal || 0}`
                  font.family: Style.fontText
                  font.pixelSize: 10
                  color: Style.textMuted
                }
              }

              // Subtle Lock Glyph for Encrypted Networks
              Text {
                visible: !!(modelData.security && modelData.security !== "OPEN")
                text: "󰌾"
                font.pixelSize: 11
                color: Style.textMuted
              }

              // Active Checkmark
              Text {
                visible: isActive
                text: "󰄬"
                font.pixelSize: 13
                color: Style.accent
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

          Item {
            anchors.centerIn: parent
            visible: wifiList.count === 0
            Text {
              anchors.centerIn: parent
              text: "Wi-Fi ağları taranıyor..."
              font.family: Style.fontText
              color: Style.textMuted
              font.pixelSize: 11
            }
          }
        }
      }

      // Inline Password Input Sheet
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 12
        color: Style.surfaceVariant
        border.color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.35)
        border.width: 1
        visible: root.showPasswordModal

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 6
          spacing: 6

          TextInput {
            id: passInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            color: Style.textPrimary
            font.family: Style.fontText
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
              text: `${root.selectedSsid} parolası...`
              font.family: Style.fontText
              color: Style.textMuted
              font.pixelSize: 11
              visible: !passInput.text && !passInput.activeFocus
            }
          }

          Rectangle {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 28
            radius: 10
            color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.24)

            Text {
              anchors.centerIn: parent
              text: "Bağlan"
              font.family: Style.fontDisplay
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: Style.accent
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

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 10
            color: Style.surface

            Text {
              anchors.centerIn: parent
              text: "󰅖"
              font.pixelSize: 12
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
