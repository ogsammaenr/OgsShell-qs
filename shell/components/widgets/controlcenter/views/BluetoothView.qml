import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  readonly property bool isPowered: !!(ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered)
  readonly property bool isDiscovering: !!(ipc && ipc.bluetooth && ipc.bluetooth.discovering)

  Component.onCompleted: {
    if (ipc) {
      ipc.sendAction("get_bluetooth_state", {})
    }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 6

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: 6

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

      Text {
        text: "Bluetooth Aygıtları"
        color: Style.textPrimary
        font.pixelSize: 13
        font.weight: Font.Bold
        Layout.fillWidth: true
      }

      // Power Toggle Pill
      Rectangle {
        Layout.preferredHeight: 22
        Layout.preferredWidth: btPwrTxt.implicitWidth + 16
        radius: 11
        color: root.isPowered ? Style.accentGreen : Style.surfaceHover

        Text {
          id: btPwrTxt
          anchors.centerIn: parent
          text: root.isPowered ? "Açık" : "Kapalı"
          font.pixelSize: 10
          font.weight: Font.Bold
          color: root.isPowered ? "#000000" : Style.textMuted
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.sendAction("toggle_bluetooth", {})
          }
        }
      }

      // Rescan Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: scanBtHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          id: scanIcon
          anchors.centerIn: parent
          text: "↻"
          font.pixelSize: 14
          color: root.isDiscovering ? Style.accentCyan : Style.textPrimary

          RotationAnimation on rotation {
            running: root.isDiscovering
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1000
          }
        }

        MouseArea {
          id: scanBtHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) {
              if (root.isDiscovering) {
                ipc.sendAction("stop_bluetooth_scan", {})
              } else {
                ipc.sendAction("start_bluetooth_scan", {})
              }
            }
          }
        }
      }
    }

    // Device List Canvas
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 8
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: btList
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        reuseItems: true
        cacheBuffer: 60
        model: (ipc && ipc.bluetooth && ipc.bluetooth.devices) ? ipc.bluetooth.devices : []

        delegate: Rectangle {
          id: devDelegate
          width: btList.width
          height: 42
          radius: 6
          color: modelData.connected ? Style.surfaceActive : (devHover.containsMouse ? Style.surfaceVariant : "transparent")

          // Base background click area for row selection / connecting
          MouseArea {
            id: devHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 1
            onClicked: {
              if (ipc && !modelData.connected) {
                ipc.sendAction("connect_bluetooth", { "mac": modelData.mac })
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            z: 2

            Text {
              text: {
                let ic = modelData.icon || ""
                if (ic.indexOf("headset") !== -1 || ic.indexOf("audio") !== -1) return "🎧"
                if (ic.indexOf("keyboard") !== -1) return "⌨"
                if (ic.indexOf("mouse") !== -1) return "🖱"
                if (ic.indexOf("phone") !== -1) return "📱"
                return "󰂯"
              }
              font.pixelSize: 14
            }

            Column {
              Layout.fillWidth: true
              spacing: 1
              Text {
                text: modelData.name || modelData.mac || "Bilinmeyen Cihaz"
                font.pixelSize: 12
                font.weight: modelData.connected ? Font.Bold : Font.Medium
                color: modelData.connected ? Style.accentCyan : Style.textPrimary
                elide: Text.ElideRight
                width: btList.width - 130
              }
              Text {
                text: modelData.connected ? "Bağlı" : (modelData.paired ? "Eşleşmiş" : "Eşleşmemiş (Yeni)")
                font.pixelSize: 10
                color: modelData.connected ? Style.accentGreen : (modelData.paired ? Style.textSecondary : Style.textMuted)
              }
            }

            // Connect / Disconnect Action Pill (Explicit high z-index & isolated MouseArea)
            Rectangle {
              id: actionPill
              Layout.preferredHeight: 24
              Layout.preferredWidth: modelData.connected ? 52 : 62
              radius: 6
              color: modelData.connected ? (btnMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant) : (btnMouse.containsMouse ? Style.accentHover : Style.accent)
              z: 10

              Text {
                anchors.centerIn: parent
                text: modelData.connected ? "Kes" : "Bağlan"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: modelData.connected ? Style.accentRed : "#ffffff"
              }

              MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) {
                    if (modelData.connected) {
                      ipc.sendAction("disconnect_bluetooth", { "mac": modelData.mac })
                    } else {
                      ipc.sendAction("connect_bluetooth", { "mac": modelData.mac })
                    }
                  }
                }
              }
            }
          }
        }

        // Empty state
        Item {
          anchors.centerIn: parent
          visible: btList.count === 0
          Text {
            anchors.centerIn: parent
            text: !root.isPowered ? "Bluetooth Kapalı" : (root.isDiscovering ? "Cihazlar taranıyor..." : "Cihaz Bulunamadı")
            color: Style.textMuted
            font.pixelSize: 11
          }
        }
      }
    }
  }
}
