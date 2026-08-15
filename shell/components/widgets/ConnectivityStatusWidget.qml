import QtQuick
import QtQuick.Layouts
import "../.."

Item {
  id: root

  // DaemonIPC Reference
  property var ipc

  // Click signal to allow opening system tab or settings
  signal clicked()

  // ==========================================
  // Wi-Fi Telemetry & State
  // ==========================================
  readonly property var wifi: ipc ? ipc.wifi : null
  readonly property bool wifiConnected: !!(wifi && wifi.connected)
  readonly property string wifiSsid: (wifi && wifi.ssid && wifi.ssid.length > 0) ? wifi.ssid : (wifiConnected ? "Bağlı" : "Bağlantı Yok")
  readonly property int wifiSignal: wifi && wifi.signal ? wifi.signal : 0

  readonly property string wifiIcon: {
    if (!wifiConnected) return "󰤮"
    if (wifiSignal >= 75) return "󰤨"
    if (wifiSignal >= 50) return "󰤥"
    if (wifiSignal >= 25) return "󰤢"
    return "󰤟"
  }

  // ==========================================
  // Bluetooth Telemetry & State
  // ==========================================
  readonly property var bt: ipc ? ipc.bluetooth : null
  readonly property bool btPowered: !!(bt && bt.adapter_powered)
  readonly property bool btDiscovering: !!(bt && bt.discovering)
  readonly property var btDevices: bt && bt.devices ? bt.devices : []

  readonly property int btConnectedCount: {
    if (!btDevices || btDevices.length === 0) return 0
    let count = 0
    for (let i = 0; i < btDevices.length; i++) {
      if (btDevices[i].connected) count++
    }
    return count
  }
  readonly property bool btConnected: btConnectedCount > 0

  readonly property string btIcon: {
    if (!btPowered) return "󰂲"
    if (btConnected) return "󰂱"
    return "󰂯"
  }

  implicitWidth: Math.max(90, contentRow.implicitWidth + 18)
  implicitHeight: 28

  // ==========================================
  // Interactive Button Pill Container
  // ==========================================
  Rectangle {
    id: buttonContainer
    anchors.fill: parent
    radius: 10
    color: statusHoverHandler.hovered ? Style.surfaceVariant : Style.surface
    border.color: statusHoverHandler.hovered ? Style.accent : Style.border
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler {
      id: statusHoverHandler
      cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
      onTapped: root.clicked()
    }

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      spacing: 6

      // Wi-Fi Status Item
      Row {
        Layout.alignment: Qt.AlignVCenter
        spacing: 4

        Text {
          text: root.wifiIcon
          color: root.wifiConnected ? Style.accent : Style.textMuted
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: ssidText
          text: root.wifiConnected ? root.wifiSsid : "Kapalı"
          color: root.wifiConnected ? Style.textPrimary : Style.textMuted
          font.pixelSize: 9
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          maximumLineCount: 1
          width: Math.min(implicitWidth, 42)
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // Vertical Divider
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 12
        Layout.alignment: Qt.AlignVCenter
        color: Style.border
      }

      // Bluetooth Status Item
      Row {
        Layout.alignment: Qt.AlignVCenter
        spacing: 3

        Text {
          text: root.btIcon
          color: root.btConnected ? Style.accent : (root.btPowered ? Style.textPrimary : Style.textMuted)
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }

        // Active Connection Indicator Dot
        Rectangle {
          width: 4
          height: 4
          radius: 2
          color: Style.accent
          visible: root.btConnected
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
