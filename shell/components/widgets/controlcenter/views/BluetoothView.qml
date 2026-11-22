import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  readonly property bool isPowered: !!(ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered)
  readonly property bool isDiscovering: !!(ipc && ipc.bluetooth && ipc.bluetooth.discovering)

  function deviceGlyph(iconName) {
    let ic = (iconName || "").toLowerCase()
    if (ic.indexOf("headset") !== -1 || ic.indexOf("headphone") !== -1 || ic.indexOf("audio") !== -1) return "󰋋"
    if (ic.indexOf("keyboard") !== -1) return "󰌌"
    if (ic.indexOf("mouse") !== -1) return "󰍽"
    if (ic.indexOf("gaming") !== -1 || ic.indexOf("joystick") !== -1) return "󰊴"
    if (ic.indexOf("phone") !== -1) return "󰏲"
    if (ic.indexOf("computer") !== -1) return "󰍹"
    return "󰂯"
  }

  Component.onCompleted: {
    if (ipc) ipc.sendAction("get_bluetooth_state", {})
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 10

    // Unified Apple HIG Header
    CCViewHeader {
      title: "Bluetooth"
      subtitle: root.isPowered ? (root.isDiscovering ? "Cihazlar taranıyor..." : "Açık") : "Kapalı"
      onBackRequested: root.backRequested()

      // Rescan Circular Button
      Rectangle {
        visible: root.isPowered
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        radius: 13
        color: scanBtHover.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
          id: scanIcon
          anchors.centerIn: parent
          text: "󰑐"
          font.pixelSize: 13
          color: root.isDiscovering ? Style.accent : Style.textPrimary

          RotationAnimation on rotation {
            running: root.isDiscovering
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 900
            onRunningChanged: {
              if (!running) scanIcon.rotation = 0
            }
          }
        }

        MouseArea {
          id: scanBtHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) {
              if (root.isDiscovering) ipc.sendAction("stop_bluetooth_scan", {})
              else ipc.sendAction("start_bluetooth_scan", {})
            }
          }
        }
      }

      // Minimal Apple-Style Power Toggle Switch
      Rectangle {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 20
        radius: 10
        color: root.isPowered
          ? Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.85)
          : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14)

        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
          width: 16
          height: 16
          radius: 8
          y: 2
          x: root.isPowered ? (parent.width - width - 2) : 2
          color: "#ffffff"

          Behavior on x {
            SpringAnimation {
              spring: 28.0
              damping: 0.78
              epsilon: 0.01
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.sendAction("toggle_bluetooth", {})
          }
        }
      }
    }

    // Continuous Grouped Device List
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      ListView {
        id: btList
        anchors.fill: parent
        anchors.margins: 5
        spacing: 2
        reuseItems: true
        cacheBuffer: 60
        boundsBehavior: Flickable.StopAtBounds
        model: (ipc && ipc.bluetooth && ipc.bluetooth.devices) ? ipc.bluetooth.devices : []

        delegate: Rectangle {
          id: devDelegate
          width: btList.width
          height: 46
          radius: 10
          color: modelData.connected
            ? Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.14)
            : (devHover.containsMouse ? Style.surfaceHover : "transparent")

          Behavior on color { ColorAnimation { duration: 140 } }

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
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            z: 2

            // Circular Vector Device Icon
            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 14
              color: modelData.connected ? Style.accentCyan : Style.surfaceVariant

              Text {
                anchors.centerIn: parent
                text: root.deviceGlyph(modelData.icon)
                font.pixelSize: 14
                color: modelData.connected ? "#000000" : Style.textSecondary
              }
            }

            Column {
              Layout.fillWidth: true
              spacing: 1

              Text {
                width: parent.width
                text: modelData.name || modelData.mac || "Bilinmeyen Cihaz"
                font.family: Style.fontDisplay
                font.pixelSize: 11
                font.weight: modelData.connected ? Font.DemiBold : Font.Medium
                color: Style.textPrimary
                elide: Text.ElideRight
              }

              Text {
                text: modelData.connected ? "Bağlı" : (modelData.paired ? "Eşleşmiş" : "Yeni Cihaz")
                font.family: Style.fontText
                font.pixelSize: 10
                color: modelData.connected ? Style.accentCyan : Style.textMuted
              }
            }

            // Connect / Disconnect Tinted Capsule
            Rectangle {
              id: actionPill
              Layout.preferredHeight: 24
              Layout.preferredWidth: modelData.connected ? 48 : 58
              radius: 12
              color: modelData.connected
                ? (btnMouse.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24) : Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.14))
                : (btnMouse.containsMouse ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.28) : Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.18))
              z: 10

              Text {
                anchors.centerIn: parent
                text: modelData.connected ? "Kes" : "Bağlan"
                font.family: Style.fontDisplay
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: modelData.connected ? Style.accentRed : Style.accent
              }

              MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) {
                    if (modelData.connected) ipc.sendAction("disconnect_bluetooth", { "mac": modelData.mac })
                    else ipc.sendAction("connect_bluetooth", { "mac": modelData.mac })
                  }
                }
              }
            }
          }
        }

        // Empty State
        Item {
          anchors.centerIn: parent
          visible: btList.count === 0
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.isPowered ? "󰂯" : "󰂲"
              font.pixelSize: 22
              color: Style.textMuted
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: !root.isPowered ? "Bluetooth kapalı" : (root.isDiscovering ? "Cihazlar taranıyor..." : "Cihaz bulunamadı")
              font.family: Style.fontText
              color: Style.textMuted
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }
}
