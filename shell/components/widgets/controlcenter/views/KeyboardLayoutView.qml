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
    // Direct hyprctl fallback
    hyprCmdProc.command = ["hyprctl", "switchxkblayout", "all", code]
    hyprCmdProc.running = true
  }

  function cycleNextLayout() {
    if (ipc) {
      ipc.switchKeyboardLayout("next")
    }
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
    spacing: 8

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

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
        text: "Klavye Düzeni"
        color: Style.textPrimary
        font.pixelSize: 13
        font.weight: Font.Bold
        Layout.fillWidth: true
      }
    }

    // Active Layout Banner
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      radius: 8
      color: Style.surfaceVariant
      border.color: Style.accentCyan
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
          text: "󰌌"
          font.pixelSize: 18
          color: Style.accentCyan
        }

        Column {
          Layout.fillWidth: true
          spacing: 1
          Text {
            text: (ipc && ipc.keyboardLayout && ipc.keyboardLayout.current_keymap) ? ipc.keyboardLayout.current_keymap : "Türkçe (TR)"
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Style.textPrimary
          }
          Text {
            text: `Aktif Kısa Kod: ${(ipc && ipc.keyboardLayout && ipc.keyboardLayout.current_short_code) ? ipc.keyboardLayout.current_short_code : "TR"}`
            font.pixelSize: 10
            color: Style.textMuted
          }
        }

        // Switch Next Layout Button
        Rectangle {
          Layout.preferredHeight: 26
          Layout.preferredWidth: 88
          radius: 6
          color: nextLayoutHover.containsMouse ? Style.surfaceActive : Style.surface
          border.color: Style.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Sonraki (↻)"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Style.accentCyan
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
    }

    // Configured Layouts List
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 10
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: layoutList
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4
        model: [
          { "code": "tr", "name": "Türkçe (Q - Standart)", "short": "TR" },
          { "code": "us", "name": "English (US)", "short": "US" },
          { "code": "de", "name": "German (Deutsch)", "short": "DE" },
          { "code": "fr", "name": "French (Français)", "short": "FR" }
        ]

        delegate: Rectangle {
          width: layoutList.width
          height: 44
          radius: 8
          readonly property bool isActive: {
            if (!ipc || !ipc.keyboardLayout) return modelData.code === "tr"
            let cur = (ipc.keyboardLayout.current_layout_code || "").toLowerCase()
            let shortC = (ipc.keyboardLayout.current_short_code || "").toUpperCase()
            return cur === modelData.code || shortC === modelData.short
          }

          color: isActive ? Style.surfaceActive : (layHover.containsMouse ? Style.surfaceVariant : "transparent")
          border.color: isActive ? Style.accentCyan : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
              width: 32
              height: 24
              radius: 5
              color: isActive ? Style.accentCyan : Style.surfaceVariant
              Text {
                anchors.centerIn: parent
                text: modelData.short
                font.pixelSize: 11
                font.weight: Font.Bold
                color: isActive ? "#000000" : Style.textPrimary
              }
            }

            Text {
              text: modelData.name
              font.pixelSize: 12
              font.weight: isActive ? Font.Bold : Font.Medium
              color: isActive ? Style.accentCyan : Style.textPrimary
              Layout.fillWidth: true
            }

            Text {
              visible: isActive
              text: "✓"
              font.pixelSize: 13
              color: Style.accentCyan
              font.weight: Font.Bold
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
