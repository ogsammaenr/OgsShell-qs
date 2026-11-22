import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  Process {
    id: hyprCmdProc
  }

  function applyLayout(code) {
    if (ipc) {
      ipc.setConfiguredKeyboardLayouts([code, "tr", "us"], [])
      ipc.switchKeyboardLayout(code)
    }
    hyprCmdProc.command = ["hyprctl", "switchxkblayout", "all", code]
    hyprCmdProc.running = true
  }

  function cycleNextLayout() {
    if (ipc) ipc.switchKeyboardLayout("next")
    hyprCmdProc.command = ["hyprctl", "switchxkblayout", "all", "next"]
    hyprCmdProc.running = true
  }

  Component.onCompleted: {
    if (ipc) {
      ipc.requestKeyboardLayout()
      ipc.requestAvailableKeyboardLayouts()
    }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 10

    // Unified Apple HIG Header
    CCViewHeader {
      title: "Klavye Düzeni"
      subtitle: (ipc && ipc.keyboardLayout && ipc.keyboardLayout.current_keymap) ? ipc.keyboardLayout.current_keymap : "Türkçe (TR)"
      onBackRequested: root.backRequested()

      // Cycle Next Layout Capsule
      Rectangle {
        Layout.preferredHeight: 26
        Layout.preferredWidth: nextLayRow.implicitWidth + 16
        radius: 13
        color: nextLayoutHover.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
          id: nextLayRow
          anchors.centerIn: parent
          spacing: 5
          Text { anchors.verticalCenter: parent.verticalCenter; text: "󰑐"; font.pixelSize: 11; color: Style.textSecondary }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Sonraki"
            font.family: Style.fontDisplay
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }

        MouseArea {
          id: nextLayoutHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.cycleNextLayout()
        }
      }
    }

    // Continuous Layout List Surface
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      ListView {
        id: layoutList
        anchors.fill: parent
        anchors.margins: 5
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: [
          { "code": "tr", "name": "Türkçe (Q - Standart)", "short": "TR" },
          { "code": "us", "name": "English (US)", "short": "US" },
          { "code": "de", "name": "German (Deutsch)", "short": "DE" },
          { "code": "fr", "name": "French (Français)", "short": "FR" }
        ]

        delegate: Rectangle {
          width: layoutList.width
          height: 48
          radius: 10
          readonly property bool isActive: {
            if (!ipc || !ipc.keyboardLayout) return modelData.code === "tr"
            let cur = (ipc.keyboardLayout.current_layout_code || "").toLowerCase()
            let shortC = (ipc.keyboardLayout.current_short_code || "").toUpperCase()
            return cur === modelData.code || shortC === modelData.short
          }

          color: isActive
            ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.14)
            : (layHover.containsMouse ? Style.surfaceHover : "transparent")

          Behavior on color { ColorAnimation { duration: 140 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
              Layout.preferredWidth: 32
              Layout.preferredHeight: 24
              radius: 7
              color: isActive ? Style.accent : Style.surfaceVariant

              Text {
                anchors.centerIn: parent
                text: modelData.short
                font.family: Style.fontDisplay
                font.pixelSize: 10
                font.weight: Font.Bold
                color: isActive ? "#000000" : Style.textSecondary
              }
            }

            Text {
              Layout.fillWidth: true
              text: modelData.name
              font.family: Style.fontDisplay
              font.pixelSize: 12
              font.weight: isActive ? Font.DemiBold : Font.Medium
              color: Style.textPrimary
              elide: Text.ElideRight
            }

            Text {
              visible: isActive
              text: "󰄬"
              font.pixelSize: 13
              color: Style.accent
            }
          }

          MouseArea {
            id: layHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.applyLayout(modelData.code)
              root.backRequested()
            }
          }
        }
      }
    }
  }
}
