import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../.."

FocusScope {
  id: root

  focus: true

  Process {
    id: cmdExec
  }

  function executeCmd(cmdList) {
    if (!cmdList || cmdList.length === 0) return
    console.log("[PowerOverlay] Executing command:", JSON.stringify(cmdList))
    cmdExec.command = cmdList
    cmdExec.running = true
    PowerService.close()
  }

  // Keyboard Shortcuts (Escape to dismiss, hotkeys for fast action)
  Keys.onEscapePressed: {
    PowerService.close()
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_P) {
      executeCmd(["systemctl", "poweroff"])
      event.accepted = true
    } else if (event.key === Qt.Key_R) {
      executeCmd(["systemctl", "reboot"])
      event.accepted = true
    } else if (event.key === Qt.Key_S) {
      executeCmd(["systemctl", "suspend"])
      event.accepted = true
    } else if (event.key === Qt.Key_L || event.key === Qt.Key_E) {
      executeCmd(["hyprctl", "dispatch", "exit"])
      event.accepted = true
    }
  }

  // =========================================================================
  // 1. Dark Translucent / Blurred Backdrop (Dismisses on outside click)
  // =========================================================================
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(6 / 255, 7 / 255, 10 / 255, 0.72)

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.ArrowCursor
      onClicked: {
        PowerService.close()
      }
    }
  }

  // =========================================================================
  // 2. Central Floating Large Circular Action Buttons
  // =========================================================================
  Item {
    id: centerContainer
    anchors.centerIn: parent
    width: actionRow.implicitWidth
    height: 160

    RowLayout {
      id: actionRow
      anchors.centerIn: parent
      spacing: 48

      // Button 1: Kapat (Power Off)
      Item {
        implicitWidth: 104
        implicitHeight: 160

        Rectangle {
          id: pwrOffBtn
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          width: 96
          height: 96
          radius: 48
          color: offMouse.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24) : Qt.rgba(24 / 255, 26 / 255, 32 / 255, 0.75)
          border.color: offMouse.containsMouse ? Style.accentRed : Qt.rgba(255, 255, 255, 0.12)
          border.width: offMouse.containsMouse ? 1.5 : 1

          scale: offMouse.pressed ? 0.94 : (offMouse.containsMouse ? 1.10 : 1.0)
          Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.pixelSize: 38
            color: offMouse.containsMouse ? Style.accentRed : Style.textPrimary
            Behavior on color { ColorAnimation { duration: 140 } }
          }

          MouseArea {
            id: offMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["systemctl", "poweroff"])
          }
        }

        // On-Hover Reveal Label
        Column {
          anchors.top: pwrOffBtn.bottom
          anchors.topMargin: 16
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          opacity: offMouse.containsMouse ? 1.0 : 0.0
          y: offMouse.containsMouse ? 0 : 4

          Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
          Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Kapat"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }
      }

      // Button 2: Yeniden Başlat (Reboot)
      Item {
        implicitWidth: 104
        implicitHeight: 160

        Rectangle {
          id: rebootBtn
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          width: 96
          height: 96
          radius: 48
          color: rbtMouse.containsMouse ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.24) : Qt.rgba(24 / 255, 26 / 255, 32 / 255, 0.75)
          border.color: rbtMouse.containsMouse ? Style.accentOrange : Qt.rgba(255, 255, 255, 0.12)
          border.width: rbtMouse.containsMouse ? 1.5 : 1

          scale: rbtMouse.pressed ? 0.94 : (rbtMouse.containsMouse ? 1.10 : 1.0)
          Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          Text {
            anchors.centerIn: parent
            text: "󰜉"
            font.pixelSize: 38
            color: rbtMouse.containsMouse ? Style.accentOrange : Style.textPrimary
            Behavior on color { ColorAnimation { duration: 140 } }
          }

          MouseArea {
            id: rbtMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["systemctl", "reboot"])
          }
        }

        // On-Hover Reveal Label
        Column {
          anchors.top: rebootBtn.bottom
          anchors.topMargin: 16
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          opacity: rbtMouse.containsMouse ? 1.0 : 0.0
          y: rbtMouse.containsMouse ? 0 : 4

          Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
          Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Yeniden Başlat"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }
      }

      // Button 3: Uyku Modu (Suspend)
      Item {
        implicitWidth: 104
        implicitHeight: 160

        Rectangle {
          id: sleepBtn
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          width: 96
          height: 96
          radius: 48
          color: slpMouse.containsMouse ? Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.24) : Qt.rgba(24 / 255, 26 / 255, 32 / 255, 0.75)
          border.color: slpMouse.containsMouse ? Style.accentCyan : Qt.rgba(255, 255, 255, 0.12)
          border.width: slpMouse.containsMouse ? 1.5 : 1

          scale: slpMouse.pressed ? 0.94 : (slpMouse.containsMouse ? 1.10 : 1.0)
          Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          Text {
            anchors.centerIn: parent
            text: "󰤄"
            font.pixelSize: 38
            color: slpMouse.containsMouse ? Style.accentCyan : Style.textPrimary
            Behavior on color { ColorAnimation { duration: 140 } }
          }

          MouseArea {
            id: slpMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["systemctl", "suspend"])
          }
        }

        // On-Hover Reveal Label
        Column {
          anchors.top: sleepBtn.bottom
          anchors.topMargin: 16
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          opacity: slpMouse.containsMouse ? 1.0 : 0.0
          y: slpMouse.containsMouse ? 0 : 4

          Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
          Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Uyku Modu"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }
      }

      // Button 4: Oturumu Kapat (Exit)
      Item {
        implicitWidth: 104
        implicitHeight: 160

        Rectangle {
          id: logoutBtn
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          width: 96
          height: 96
          radius: 48
          color: lgtMouse.containsMouse ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.24) : Qt.rgba(24 / 255, 26 / 255, 32 / 255, 0.75)
          border.color: lgtMouse.containsMouse ? Style.accent : Qt.rgba(255, 255, 255, 0.12)
          border.width: lgtMouse.containsMouse ? 1.5 : 1

          scale: lgtMouse.pressed ? 0.94 : (lgtMouse.containsMouse ? 1.10 : 1.0)
          Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          Text {
            anchors.centerIn: parent
            text: "󰍃"
            font.pixelSize: 38
            color: lgtMouse.containsMouse ? Style.accent : Style.textPrimary
            Behavior on color { ColorAnimation { duration: 140 } }
          }

          MouseArea {
            id: lgtMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["hyprctl", "dispatch", "exit"])
          }
        }

        // On-Hover Reveal Label
        Column {
          anchors.top: logoutBtn.bottom
          anchors.topMargin: 16
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          opacity: lgtMouse.containsMouse ? 1.0 : 0.0
          y: lgtMouse.containsMouse ? 0 : 4

          Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
          Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Oturumu Kapat"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }
      }
    }
  }

  // =========================================================================
  // 3. Subtle Bottom Hint
  // =========================================================================
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 42
    text: "İptal etmek için ESC tuşuna basın veya boşluğa tıklayın"
    font.pixelSize: 12
    font.weight: Font.Normal
    color: Qt.rgba(Style.textMuted.r, Style.textMuted.g, Style.textMuted.b, 0.7)
  }
}
