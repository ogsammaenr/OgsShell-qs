import QtQuick
import Quickshell

Rectangle {
  id: expandedMediaPill
  property var screenContext: null

  signal powerClicked()

  width: 340
  height: 210
  radius: 16
  color: "#180f172a" // 10% opacity slate
  border.color: "#15ffffff"
  border.width: 1

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 14

    Text {
      text: "Şimdi Oynatılıyor"
      color: "#a78bfa"
      font { family: "JetBrains Mono"; pixelSize: 12; weight: Font.Bold }
    }

    // Media Details Card
    Rectangle {
      width: parent.width
      height: 90
      radius: 12
      color: "#200f172a"
      border.color: "#10ffffff"
      border.width: 1

      Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Music Icon / Cover placeholder
        Rectangle {
          width: 66
          height: 66
          radius: 8
          color: (screenContext && screenContext.mediaStatus === "Playing") ? "#3038bdf8" : "#1e293b"
          border.color: (screenContext && screenContext.mediaStatus === "Playing") ? "#4038bdf8" : "#334155"
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Text {
            text: (screenContext && screenContext.mediaStatus === "Playing") ? "\uf144" : "\uf001"
            color: (screenContext && screenContext.mediaStatus === "Playing") ? "#38bdf8" : "#64748b"
            font { family: "FiraCode Nerd Font"; pixelSize: 28 }
            anchors.centerIn: parent
          }
        }

        // Metadata + Controls Column
        Column {
          width: 220
          spacing: 8
          anchors.verticalCenter: parent.verticalCenter

          Column {
            spacing: 2
            width: parent.width

            Text {
              text: (screenContext && screenContext.mediaTitle !== "") ? screenContext.mediaTitle : "Medya Oynatılmıyor"
              color: "#ffffff"
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: (screenContext && screenContext.mediaArtist !== "") ? screenContext.mediaArtist : "Bilinmeyen Sanatçı"
              color: "#94a3b8"
              font { family: "JetBrains Mono"; pixelSize: 9 }
              elide: Text.ElideRight
              width: parent.width
            }
          }

          // Media Action Controls
          Row {
            spacing: 16
            anchors.horizontalCenter: parent.horizontalCenter

            // Prev
            Text {
              text: "\uf048"
              color: "#cbd5e1"
              font { family: "FiraCode Nerd Font"; pixelSize: 14 }
              MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["playerctl", "previous"])
              }
            }

            // Play/Pause
            Text {
              text: (screenContext && screenContext.mediaStatus === "Playing") ? "\uf04c" : "\uf04b"
              color: "#38bdf8"
              font { family: "FiraCode Nerd Font"; pixelSize: 16 }
              MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
              }
            }

            // Next
            Text {
              text: "\uf051"
              color: "#cbd5e1"
              font { family: "FiraCode Nerd Font"; pixelSize: 14 }
              MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["playerctl", "next"])
              }
            }
          }
        }
      }
    }

    // Action buttons row at the bottom of the card
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 24

      // Notification Trigger
      Rectangle {
        width: 38
        height: 38
        radius: 19
        color: (screenContext && screenContext.notificationCount > 0) ? "#22d97a06" : "#1e293b"
        border.color: (screenContext && screenContext.notificationCount > 0) ? "#fbbf24" : "#334155"
        border.width: 1

        Text {
          text: "\uf0f3"
          color: (screenContext && screenContext.notificationCount > 0) ? "#fbbf24" : "#cbd5e1"
          font { family: "FiraCode Nerd Font"; pixelSize: 14 }
          anchors.centerIn: parent
        }

        Rectangle {
          visible: (screenContext && screenContext.notificationCount > 0)
          width: 8
          height: 8
          radius: 4
          color: "#ef4444"
          border.color: "#0f172a"
          border.width: 1
          anchors.top: parent.top
          anchors.right: parent.right
        }

        MouseArea {
          anchors.fill: parent
          onClicked: Quickshell.execDetached(["swaync-client", "-t"])
        }
      }

      // Clipboard Trigger (Dummy)
      Rectangle {
        width: 38
        height: 38
        radius: 19
        color: "#1e293b"
        border.color: "#334155"
        border.width: 1

        Text {
          text: "\uf0ea"
          color: "#cbd5e1"
          font { family: "FiraCode Nerd Font"; pixelSize: 14 }
          anchors.centerIn: parent
        }

        MouseArea {
          anchors.fill: parent
        }
      }

      // Power Menu Placeholder Trigger
      Rectangle {
        width: 38
        height: 38
        radius: 19
        color: "#22ef4444"
        border.color: "#ef4444"
        border.width: 1

        Text {
          text: "\uf011"
          color: "#ef4444"
          font { family: "FiraCode Nerd Font"; pixelSize: 14 }
          anchors.centerIn: parent
        }

        MouseArea {
          anchors.fill: parent
          onClicked: {
            expandedMediaPill.powerClicked();
          }
        }
      }
    }
  }
}
