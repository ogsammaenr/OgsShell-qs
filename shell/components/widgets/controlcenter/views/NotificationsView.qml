import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  Component.onCompleted: {
    if (ipc) {
      ipc.requestNotifications()
      ipc.sendAction("get_dnd_state", {})
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
        text: "Bildirim Merkezi"
        color: Style.textPrimary
        font.pixelSize: 11
        font.weight: Font.DemiBold
        Layout.fillWidth: true
      }

      // DND Toggle Pill
      Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: dndTxt.implicitWidth + 12
        radius: 10
        color: (ipc && ipc.dndEnabled) ? Style.accentRed : Style.surfaceVariant

        Text {
          id: dndTxt
          anchors.centerIn: parent
          text: (ipc && ipc.dndEnabled) ? "🔕 DND Açık" : "🔔 DND"
          font.pixelSize: 8
          font.weight: Font.Medium
          color: (ipc && ipc.dndEnabled) ? "#ffffff" : Style.textSecondary
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.toggleDND()
          }
        }
      }

      // Clear All Button
      Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: clearTxt.implicitWidth + 10
        radius: 5
        color: clearHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          id: clearTxt
          anchors.centerIn: parent
          text: "Temizle"
          font.pixelSize: 8
          color: Style.textMuted
        }

        MouseArea {
          id: clearHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.clearNotifications()
          }
        }
      }
    }

    // Notifications List
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 8
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: notifList
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4
        reuseItems: true
        cacheBuffer: 60
        model: (ipc && ipc.notifications) ? ipc.notifications : []

        delegate: Rectangle {
          width: notifList.width
          height: 38
          radius: 6
          color: Style.surfaceVariant

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
              text: "💬"
              font.pixelSize: 11
            }

            Column {
              Layout.fillWidth: true
              spacing: 1

              RowLayout {
                width: parent.width
                Text {
                  text: modelData.app_name || "Sistem"
                  font.pixelSize: 8
                  font.weight: Font.Bold
                  color: Style.accentCyan
                }
                Item { Layout.fillWidth: true }
              }

              Text {
                text: modelData.summary || "Bildirim"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: Style.textPrimary
                elide: Text.ElideRight
                width: 180
              }

              Text {
                visible: modelData.body && modelData.body.length > 0
                text: modelData.body || ""
                font.pixelSize: 8
                color: Style.textMuted
                elide: Text.ElideRight
                width: 180
              }
            }

            // Delete item
            Rectangle {
              width: 18
              height: 18
              radius: 9
              color: delNotifHover.containsMouse ? Style.surfaceActive : "transparent"

              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 8; color: Style.textMuted }

              MouseArea {
                id: delNotifHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) ipc.deleteNotification(modelData.id)
                }
              }
            }
          }
        }

        // Empty state
        Item {
          anchors.centerIn: parent
          visible: notifList.count === 0
          Text {
            anchors.centerIn: parent
            text: "Yeni bildirim bulunmuyor"
            color: Style.textMuted
            font.pixelSize: 9
          }
        }
      }
    }
  }
}
