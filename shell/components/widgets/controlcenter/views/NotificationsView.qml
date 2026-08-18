import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property var detailNotification: null
  property bool showDetailModal: false

  function openDetail(notif) {
    if (!notif) return
    detailNotification = notif
    showDetailModal = true
    if (ipc && notif.id && !notif.read) {
      ipc.markNotificationRead(notif.id)
    }
  }

  function closeDetail() {
    showDetailModal = false
    detailNotification = null
  }

  function formatTime(timestamp) {
    if (!timestamp) return ""
    let d = new Date(timestamp)
    let hh = String(d.getHours()).padStart(2, '0')
    let mm = String(d.getMinutes()).padStart(2, '0')
    return `${hh}:${mm}`
  }

  Component.onCompleted: {
    if (ipc) {
      ipc.requestNotifications()
      ipc.sendAction("get_dnd_state", {})
    }
  }

  // =========================================================================
  // 1. PRIMARY VIEW: Notifications List & Action Header
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 6
    visible: !root.showDetailModal

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
        text: "Bildirim Merkezi"
        color: Style.textPrimary
        font.pixelSize: 13
        font.weight: Font.Bold
        Layout.fillWidth: true
      }

      // DND Toggle Pill
      Rectangle {
        Layout.preferredHeight: 22
        Layout.preferredWidth: dndTxt.implicitWidth + 14
        radius: 11
        color: (ipc && ipc.dndEnabled) ? Style.accentRed : Style.surfaceVariant

        Text {
          id: dndTxt
          anchors.centerIn: parent
          text: (ipc && ipc.dndEnabled) ? "🔕 DND Açık" : "🔔 DND"
          font.pixelSize: 10
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
        Layout.preferredHeight: 22
        Layout.preferredWidth: clearTxt.implicitWidth + 14
        radius: 6
        color: clearHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          id: clearTxt
          anchors.centerIn: parent
          text: "Temizle"
          font.pixelSize: 10
          font.weight: Font.Medium
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
          id: delegateCard
          width: notifList.width
          height: 48
          radius: 6
          color: cardMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant
          border.color: cardMouse.containsMouse ? Style.borderHover : (modelData.read ? "transparent" : Style.accentCyan)
          border.width: modelData.read ? 0 : 1

          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on border.color { ColorAnimation { duration: 120 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // App / Notification Icon
            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 14
              color: Style.surfaceActive

              Text {
                anchors.centerIn: parent
                text: "💬"
                font.pixelSize: 13
              }
            }

            // Notification Info Text Stack
            Column {
              Layout.fillWidth: true
              spacing: 1

              RowLayout {
                width: parent.width
                spacing: 4

                Text {
                  text: modelData.app_name || "Sistem"
                  font.pixelSize: 10
                  font.weight: Font.Bold
                  color: Style.accentCyan
                  elide: Text.ElideRight
                }

                Item { Layout.fillWidth: true }

                Text {
                  visible: !!modelData.timestamp
                  text: root.formatTime(modelData.timestamp)
                  font.pixelSize: 10
                  color: Style.textMuted
                }
              }

              Text {
                text: modelData.summary || "Bildirim"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Style.textPrimary
                elide: Text.ElideRight
                width: parent.width - 28
              }

              Text {
                text: (modelData.body && modelData.body.length > 0) ? modelData.body : "Sağ tıkla detayları gör"
                font.pixelSize: 10
                color: Style.textMuted
                elide: Text.ElideRight
                width: parent.width - 28
              }
            }

            // Delete item button
            Rectangle {
              Layout.preferredWidth: 22
              Layout.preferredHeight: 22
              radius: 11
              color: delNotifHover.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.25) : "transparent"

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 11
                color: delNotifHover.containsMouse ? Style.accentRed : Style.textMuted
              }

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

          // Main MouseArea: Right-click (or Left-click) opens full notification detail view
          MouseArea {
            id: cardMouse
            anchors.fill: parent
            anchors.rightMargin: 32 // Keep delete button clickable
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              root.openDetail(modelData)
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
            font.pixelSize: 11
          }
        }
      }
    }
  }

  // =========================================================================
  // 2. DETAIL MODAL VIEW: Full Text & Inspection Sheet
  // =========================================================================
  Rectangle {
    id: detailModal
    anchors.fill: parent
    radius: 10
    color: Style.bgPrimary
    border.color: Style.border
    border.width: 1
    visible: root.showDetailModal
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 8

      // Modal Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Back / Close Button
        Rectangle {
          width: 24
          height: 24
          radius: 12
          color: detBackHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "‹"
            font.pixelSize: 16
            font.weight: Font.Bold
            color: Style.textPrimary
          }

          MouseArea {
            id: detBackHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeDetail()
          }
        }

        Text {
          text: root.detailNotification ? (root.detailNotification.app_name || "Bildirim Detayı") : "Bildirim Detayı"
          font.pixelSize: 13
          font.weight: Font.Bold
          color: Style.accentCyan
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          visible: !!(root.detailNotification && root.detailNotification.timestamp)
          text: root.formatTime(root.detailNotification ? root.detailNotification.timestamp : 0)
          font.pixelSize: 11
          color: Style.textMuted
        }
      }

      // Summary / Title Card
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: summaryTxt.implicitHeight + 14
        radius: 6
        color: Style.surfaceVariant

        Text {
          id: summaryTxt
          anchors.fill: parent
          anchors.margins: 8
          text: root.detailNotification ? (root.detailNotification.summary || "Başlık Yok") : ""
          font.pixelSize: 12
          font.weight: Font.Bold
          color: Style.textPrimary
          wrapMode: Text.Wrap
        }
      }

      // Scrollable Full Body Text
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 8
        color: Style.surfaceVariant
        border.color: Style.border
        border.width: 1
        clip: true

        Flickable {
          id: bodyFlick
          anchors.fill: parent
          anchors.margins: 8
          contentWidth: width
          contentHeight: bodyTextEdit.implicitHeight + 16
          boundsBehavior: Flickable.StopAtBounds

          TextEdit {
            id: bodyTextEdit
            width: bodyFlick.width
            text: {
              if (!root.detailNotification) return ""
              let b = root.detailNotification.body
              if (b && b.trim().length > 0) return b
              return "Bu bildirim için ek metin içeriği bulunmuyor."
            }
            font.pixelSize: 12
            color: (root.detailNotification && root.detailNotification.body && root.detailNotification.body.trim().length > 0) ? Style.textPrimary : Style.textMuted
            wrapMode: TextEdit.WrapAnywhere
            readOnly: true
            selectByMouse: true
          }
        }
      }

      // Bottom Action Bar
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Close Button
        Rectangle {
          Layout.preferredWidth: 84
          Layout.preferredHeight: 30
          radius: 6
          color: detCloseHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "Kapat"
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Style.textSecondary
          }

          MouseArea {
            id: detCloseHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeDetail()
          }
        }

        // Delete Notification Button
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          radius: 6
          color: detDelHover.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.30) : Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.18)
          border.color: Style.accentRed
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Bildirimi Sil"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.accentRed
          }

          MouseArea {
            id: detDelHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (ipc && root.detailNotification) {
                ipc.deleteNotification(root.detailNotification.id)
                root.closeDetail()
              }
            }
          }
        }
      }
    }
  }
}
