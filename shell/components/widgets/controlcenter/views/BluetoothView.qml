import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  Component.onCompleted: {
    if (ipc) ipc.sendAction("get_bluetooth_state", {})
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 6

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: 6

      Rectangle {
        width: 22
        height: 22
        radius: 11
        color: backHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "‹"
          font.pixelSize: 15
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
        font.pixelSize: 11
        font.weight: Font.DemiBold
        Layout.fillWidth: true
      }

      // Power Toggle Pill
      Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: 44
        radius: 10
        color: (ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered) ? Style.accentGreen : Style.surfaceHover

        Text {
          anchors.centerIn: parent
          text: (ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered) ? "Açık" : "Kapalı"
          font.pixelSize: 8
          font.weight: Font.DemiBold
          color: (ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered) ? "#000000" : Style.textMuted
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
        width: 22
        height: 22
        radius: 11
        color: scanBtHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "↻"
          font.pixelSize: 12
          color: Style.textPrimary
        }

        MouseArea {
          id: scanBtHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.sendAction("start_bluetooth_scan", {})
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
        spacing: 3
        reuseItems: true
        cacheBuffer: 60
        model: (ipc && ipc.bluetooth && ipc.bluetooth.devices) ? ipc.bluetooth.devices : []

        delegate: Rectangle {
          width: btList.width
          height: 32
          radius: 6
          color: modelData.connected ? Style.surfaceActive : (devHover.containsMouse ? Style.surfaceVariant : "transparent")

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
              text: {
                let ic = modelData.icon || ""
                if (ic.indexOf("headset") !== -1 || ic.indexOf("audio") !== -1) return "🎧"
                if (ic.indexOf("keyboard") !== -1) return "⌨"
                if (ic.indexOf("mouse") !== -1) return "🖱"
                if (ic.indexOf("phone") !== -1) return "📱"
                return "󰂯"
              }
              font.pixelSize: 12
            }

            Column {
              Layout.fillWidth: true
              Text {
                text: modelData.name || modelData.mac || "Bilinmeyen Cihaz"
                font.pixelSize: 9
                font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                color: modelData.connected ? Style.accentCyan : Style.textPrimary
                elide: Text.ElideRight
                width: 160
              }
              Text {
                text: modelData.connected ? "Bağlı" : (modelData.paired ? "Eşleşmiş" : "Eşleşmemiş")
                font.pixelSize: 8
                color: modelData.connected ? Style.accentGreen : Style.textMuted
              }
            }

            // Connect / Disconnect Action Pill
            Rectangle {
              Layout.preferredHeight: 18
              Layout.preferredWidth: modelData.connected ? 42 : 36
              radius: 4
              color: modelData.connected ? Style.surfaceVariant : Style.accent

              Text {
                anchors.centerIn: parent
                text: modelData.connected ? "Kes" : "Bağlan"
                font.pixelSize: 8
                font.weight: Font.Medium
                color: modelData.connected ? Style.accentRed : "#ffffff"
              }

              MouseArea {
                anchors.fill: parent
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

          MouseArea {
            id: devHover
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

        // Empty state
        Item {
          anchors.centerIn: parent
          visible: btList.count === 0
          Text {
            anchors.centerIn: parent
            text: (ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered) ? "Cihaz bulunamadı, taratın..." : "Bluetooth kapalı"
            color: Style.textMuted
            font.pixelSize: 9
          }
        }
      }
    }
  }
}
