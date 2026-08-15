import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../.."

Item {
  id: root

  signal backRequested()

  Process {
    id: cmdExec
  }

  function runCmd(args) {
    cmdExec.command = args
    cmdExec.running = true
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
        text: "Güç & Oturum"
        color: Style.textPrimary
        font.pixelSize: 11
        font.weight: Font.DemiBold
        Layout.fillWidth: true
      }
    }

    // Power Actions List
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 8
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: pwrList
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4
        model: [
          { "title": "Ekranı Kilitle", "icon": "🔒", "sub": "Mevcut oturumu koru", "cmd": ["hyprlock"], "danger": false },
          { "title": "Uyku Modu (Suspend)", "icon": "🌙", "sub": "Düşük güç moduna geç", "cmd": ["systemctl", "suspend"], "danger": false },
          { "title": "Yeniden Başlat (Reboot)", "icon": "🔄", "sub": "Sistemi yeniden başlat", "cmd": ["systemctl", "reboot"], "danger": false },
          { "title": "Sistemi Kapat (Poweroff)", "icon": "⏻", "sub": "Bilgisayarı güvenle kapat", "cmd": ["systemctl", "poweroff"], "danger": true },
          { "title": "Oturumu Kapat (Exit)", "icon": "🚪", "sub": "Hyprland oturumunu sonlandır", "cmd": ["hyprctl", "dispatch", "exit"], "danger": true }
        ]

        delegate: Rectangle {
          width: pwrList.width
          height: 32
          radius: 6
          color: pwrHover.containsMouse ? (modelData.danger ? "#331111" : Style.surfaceVariant) : "transparent"
          border.color: pwrHover.containsMouse ? (modelData.danger ? Style.accentRed : Style.border) : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
              text: modelData.icon
              font.pixelSize: 13
            }

            Column {
              Layout.fillWidth: true
              Text {
                text: modelData.title
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: modelData.danger ? Style.accentRed : Style.textPrimary
              }
              Text {
                text: modelData.sub
                font.pixelSize: 8
                color: Style.textMuted
              }
            }

            Text {
              text: "›"
              font.pixelSize: 12
              color: Style.textMuted
            }
          }

          MouseArea {
            id: pwrHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.runCmd(modelData.cmd)
            }
          }
        }
      }
    }
  }
}
