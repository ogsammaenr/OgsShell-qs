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

  function appGlyph(appName) {
    let n = (appName || "").toLowerCase()
    if (n.indexOf("discord") !== -1 || n.indexOf("vesktop") !== -1) return "󰙯"
    if (n.indexOf("telegram") !== -1) return "󰀨"
    if (n.indexOf("spotify") !== -1) return "󰓇"
    if (n.indexOf("firefox") !== -1 || n.indexOf("zen") !== -1 || n.indexOf("chrome") !== -1) return "󰖟"
    if (n.indexOf("mail") !== -1 || n.indexOf("thunderbird") !== -1) return "󰇮"
    if (n.indexOf("capture") !== -1 || n.indexOf("screenshot") !== -1 || n.indexOf("ocr") !== -1) return "󰄀"
    return "󰂚"
  }

  Component.onCompleted: {
    if (ipc) {
      ipc.requestNotifications()
      ipc.sendAction("get_dnd_state", {})
    }
  }

  // =========================================================================
  // 1. PRIMARY VIEW: Notifications List
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 10
    visible: !root.showDetailModal

    CCViewHeader {
      title: "Bildirimler"
      onBackRequested: root.backRequested()

      // DND Toggle Capsule (Pure Vector Nerd Font)
      Rectangle {
        id: dndPill
        readonly property bool isDnd: !!(ipc && ipc.dndEnabled)
        Layout.preferredHeight: 24
        Layout.preferredWidth: dndRow.implicitWidth + 16
        radius: 12
        color: dndPill.isDnd
          ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.20)
          : (dndHover.containsMouse ? Style.surfaceHover : Style.surface)
        border.color: dndPill.isDnd
          ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.35)
          : Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
          id: dndRow
          anchors.centerIn: parent
          spacing: 5

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: dndPill.isDnd ? "󰂛" : "󰂚"
            font.pixelSize: 11
            color: dndPill.isDnd ? Style.accentRed : Style.textSecondary
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: dndPill.isDnd ? "Sessizde" : "Rahatsız Etme"
            font.family: Style.fontDisplay
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: dndPill.isDnd ? Style.accentRed : Style.textSecondary
          }
        }

        MouseArea {
          id: dndHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.toggleDND()
          }
        }
      }

      // Clear All Capsule
      Rectangle {
        visible: notifList.count > 0
        Layout.preferredHeight: 24
        Layout.preferredWidth: clearTxt.implicitWidth + 16
        radius: 12
        color: clearHover.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Text {
          id: clearTxt
          anchors.centerIn: parent
          text: "Temizle"
          font.family: Style.fontDisplay
          font.pixelSize: 10
          font.weight: Font.Medium
          color: clearHover.containsMouse ? Style.textPrimary : Style.textMuted
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

    // Continuous Notifications List Surface
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      ListView {
        id: notifList
        anchors.fill: parent
        anchors.margins: 5
        spacing: 2
        reuseItems: true
        cacheBuffer: 60
        boundsBehavior: Flickable.StopAtBounds
        model: (ipc && ipc.notifications) ? ipc.notifications : []

        delegate: Rectangle {
          id: delegateCard
          width: notifList.width
          height: 52
          radius: 10
          color: cardMouse.containsMouse ? Style.surfaceHover : "transparent"

          Behavior on color { ColorAnimation { duration: 130 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            // Subtle Unread Dot + Vector App Badge
            Item {
              Layout.preferredWidth: 30
              Layout.preferredHeight: 30

              Rectangle {
                anchors.centerIn: parent
                width: 28
                height: 28
                radius: 14
                color: !modelData.read
                  ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.18)
                  : Style.surfaceVariant

                Text {
                  anchors.centerIn: parent
                  text: root.appGlyph(modelData.app_name)
                  font.pixelSize: 13
                  color: !modelData.read ? Style.accent : Style.textSecondary
                }
              }

              Rectangle {
                visible: !modelData.read
                anchors.top: parent.top
                anchors.right: parent.right
                width: 7
                height: 7
                radius: 3.5
                color: Style.accent
              }
            }

            // Notification Info Stack
            Column {
              Layout.fillWidth: true
              spacing: 1

              RowLayout {
                width: parent.width
                spacing: 6

                Text {
                  text: modelData.app_name || "Sistem"
                  font.family: Style.fontDisplay
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                  color: !modelData.read ? Style.accent : Style.textMuted
                  elide: Text.ElideRight
                }

                Item { Layout.fillWidth: true }

                Text {
                  visible: !!modelData.timestamp
                  text: root.formatTime(modelData.timestamp)
                  font.family: Style.fontText
                  font.pixelSize: 9
                  color: Style.textMuted
                }
              }

              Text {
                width: parent.width
                text: modelData.summary || "Bildirim"
                font.family: Style.fontDisplay
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Style.textPrimary
                elide: Text.ElideRight
              }

              Text {
                visible: !!(modelData.body && modelData.body.length > 0)
                width: parent.width
                text: modelData.body || ""
                font.family: Style.fontText
                font.pixelSize: 10
                color: Style.textSecondary
                elide: Text.ElideRight
              }
            }

            // Minimal Delete Action
            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: delNotifHover.containsMouse
                ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.22)
                : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅖"
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

          MouseArea {
            id: cardMouse
            anchors.fill: parent
            anchors.rightMargin: 34
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openDetail(modelData)
          }
        }

        // Empty State
        Item {
          anchors.centerIn: parent
          visible: notifList.count === 0
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰂚"
              font.pixelSize: 22
              color: Style.textMuted
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Yeni bildirim yok"
              font.family: Style.fontText
              color: Style.textMuted
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }

  // =========================================================================
  // 2. DETAIL SHEET: Full Notification Reading View
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 10
    visible: root.showDetailModal

    CCViewHeader {
      title: root.detailNotification ? (root.detailNotification.app_name || "Bildirim") : "Bildirim"
      subtitle: (root.detailNotification && root.detailNotification.timestamp) ? root.formatTime(root.detailNotification.timestamp) : ""
      onBackRequested: root.closeDetail()

      // Delete Action Button in Header
      Rectangle {
        Layout.preferredHeight: 26
        Layout.preferredWidth: 26
        radius: 13
        color: detDelHover.containsMouse
          ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24)
          : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "󰩺"
          font.pixelSize: 13
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

    // Single Continuous Reading Sheet
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
          Layout.fillWidth: true
          text: root.detailNotification ? (root.detailNotification.summary || "Başlık Yok") : ""
          font.family: Style.fontDisplay
          font.pixelSize: 13
          font.weight: Font.DemiBold
          color: Style.textPrimary
          wrapMode: Text.Wrap
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Style.borderSubtle
        }

        Flickable {
          id: bodyFlick
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentWidth: width
          contentHeight: bodyTextEdit.implicitHeight + 8
          boundsBehavior: Flickable.StopAtBounds
          clip: true

          TextEdit {
            id: bodyTextEdit
            width: bodyFlick.width
            text: {
              if (!root.detailNotification) return ""
              let b = root.detailNotification.body
              if (b && b.trim().length > 0) return b
              return "Bu bildirim için ek içerik bulunmuyor."
            }
            font.family: Style.fontText
            font.pixelSize: 12
            color: (root.detailNotification && root.detailNotification.body && root.detailNotification.body.trim().length > 0)
              ? Style.textSecondary
              : Style.textMuted
            wrapMode: TextEdit.WrapAnywhere
            readOnly: true
            selectByMouse: true
          }
        }
      }
    }
  }
}
