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
  // 1. Dark Translucent Backdrop (Dismisses on outside click)
  // =========================================================================
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.72)

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.ArrowCursor
      onClicked: {
        PowerService.close()
      }
    }
  }

  // =========================================================================
  // 2. Central Power & Session Dialog Card
  // =========================================================================
  Rectangle {
    id: dialogCard
    anchors.centerIn: parent
    width: 600
    height: 250
    radius: 22
    color: Qt.rgba(12 / 255, 12 / 255, 14 / 255, 0.94)
    border.color: Style.border
    border.width: 1
    clip: true

    // Catch clicks on card to prevent backdrop dismissal
    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 18
      spacing: 14

      // Header: Title & Subtitle
      Column {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: "Güç ve Oturum"
          color: Style.textPrimary
          font.pixelSize: 15
          font.weight: Font.Bold
          font.letterSpacing: 0.3
        }

        Text {
          text: "Lütfen gerçekleştirmek istediğiniz eylemi seçin"
          color: Style.textMuted
          font.pixelSize: 10
        }
      }

      // =========================================================================
      // 4 Large Action Cards
      // =========================================================================
      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        // Card 1: Kapat (Power Off)
        Rectangle {
          id: pwrOffBtn
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 16
          color: offMouse.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.14) : Style.surface
          border.color: offMouse.containsMouse ? Style.accentRed : Style.border
          border.width: offMouse.containsMouse ? 1.5 : 1

          scale: offMouse.containsMouse ? 1.04 : 1.0
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              width: 44
              height: 44
              radius: 22
              color: Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, offMouse.containsMouse ? 0.28 : 0.16)

              Text {
                anchors.centerIn: parent
                text: "󰐥"
                font.pixelSize: 22
                color: Style.accentRed
              }
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Kapat"
              font.pixelSize: 12
              font.weight: Font.Bold
              color: Style.textPrimary
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Sistemi Kapat"
              font.pixelSize: 9
              color: Style.textMuted
            }
          }

          MouseArea {
            id: offMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["systemctl", "poweroff"])
          }
        }

        // Card 2: Yeniden Başlat (Reboot)
        Rectangle {
          id: rebootBtn
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 16
          color: rbtMouse.containsMouse ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.14) : Style.surface
          border.color: rbtMouse.containsMouse ? Style.accentOrange : Style.border
          border.width: rbtMouse.containsMouse ? 1.5 : 1

          scale: rbtMouse.containsMouse ? 1.04 : 1.0
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              width: 44
              height: 44
              radius: 22
              color: Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, rbtMouse.containsMouse ? 0.28 : 0.16)

              Text {
                anchors.centerIn: parent
                text: "󰜉"
                font.pixelSize: 22
                color: Style.accentOrange
              }
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Yeniden Başlat"
              font.pixelSize: 12
              font.weight: Font.Bold
              color: Style.textPrimary
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Sistemi Başlat"
              font.pixelSize: 9
              color: Style.textMuted
            }
          }

          MouseArea {
            id: rbtMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["systemctl", "reboot"])
          }
        }

        // Card 3: Uyku Modu (Suspend)
        Rectangle {
          id: sleepBtn
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 16
          color: slpMouse.containsMouse ? Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.14) : Style.surface
          border.color: slpMouse.containsMouse ? Style.accentCyan : Style.border
          border.width: slpMouse.containsMouse ? 1.5 : 1

          scale: slpMouse.containsMouse ? 1.04 : 1.0
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              width: 44
              height: 44
              radius: 22
              color: Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, slpMouse.containsMouse ? 0.28 : 0.16)

              Text {
                anchors.centerIn: parent
                text: "󰤄"
                font.pixelSize: 22
                color: Style.accentCyan
              }
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Uyku Modu"
              font.pixelSize: 12
              font.weight: Font.Bold
              color: Style.textPrimary
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Düşük Güç"
              font.pixelSize: 9
              color: Style.textMuted
            }
          }

          MouseArea {
            id: slpMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["systemctl", "suspend"])
          }
        }

        // Card 4: Oturumu Kapat (Exit)
        Rectangle {
          id: logoutBtn
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 16
          color: lgtMouse.containsMouse ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.14) : Style.surface
          border.color: lgtMouse.containsMouse ? Style.accent : Style.border
          border.width: lgtMouse.containsMouse ? 1.5 : 1

          scale: lgtMouse.containsMouse ? 1.04 : 1.0
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              width: 44
              height: 44
              radius: 22
              color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, lgtMouse.containsMouse ? 0.28 : 0.16)

              Text {
                anchors.centerIn: parent
                text: "󰍃"
                font.pixelSize: 22
                color: Style.accent
              }
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Oturumu Kapat"
              font.pixelSize: 12
              font.weight: Font.Bold
              color: Style.textPrimary
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Hyprland Çıkış"
              font.pixelSize: 9
              color: Style.textMuted
            }
          }

          MouseArea {
            id: lgtMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.executeCmd(["hyprctl", "dispatch", "exit"])
          }
        }
      }

      // =========================================================================
      // Bottom Bar: Cancel Button
      // =========================================================================
      RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        Rectangle {
          Layout.preferredHeight: 28
          Layout.preferredWidth: cancelTxt.implicitWidth + 24
          radius: 14
          color: cancelMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant
          border.color: Style.border
          border.width: 1

          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            id: cancelTxt
            anchors.centerIn: parent
            text: "Vazgeç (ESC)"
            color: Style.textSecondary
            font.pixelSize: 10
            font.weight: Font.Medium
          }

          MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: PowerService.close()
          }
        }

        Item { Layout.fillWidth: true }
      }
    }
  }
}
