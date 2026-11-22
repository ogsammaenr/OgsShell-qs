import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property var detailItem: null

  Component.onCompleted: {
    if (ipc) {
      ipc.requestClipboardHistory(50, "")
      ipc.requestPinnedClipboardItems()
    }
  }

  function openDetail(item) {
    root.detailItem = item
  }

  function closeDetail() {
    root.detailItem = null
  }

  // ==========================================
  // VIEW 1: Clipboard History List
  // ==========================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 10
    visible: root.detailItem === null

    CCViewHeader {
      title: "Pano Geçmişi"
      subtitle: "Sol tık kopyala · Sağ tık incele"
      onBackRequested: root.backRequested()

      Rectangle {
        visible: clipList.count > 0
        Layout.preferredHeight: 24
        Layout.preferredWidth: clearClipTxt.implicitWidth + 16
        radius: 12
        color: wipeHover.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Text {
          id: clearClipTxt
          anchors.centerIn: parent
          text: "Temizle"
          font.family: Style.fontDisplay
          font.pixelSize: 10
          font.weight: Font.Medium
          color: wipeHover.containsMouse ? Style.textPrimary : Style.textMuted
        }

        MouseArea {
          id: wipeHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.clearClipboardHistory()
          }
        }
      }
    }

    // Continuous Clipboard List Surface
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      ListView {
        id: clipList
        anchors.fill: parent
        anchors.margins: 5
        spacing: 2
        reuseItems: true
        cacheBuffer: 60
        boundsBehavior: Flickable.StopAtBounds
        model: (ipc && ipc.clipboardHistory) ? ipc.clipboardHistory : []

        delegate: Rectangle {
          width: clipList.width
          height: 48
          radius: 10
          color: modelData.is_pinned
            ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.10)
            : (itemMouseArea.containsMouse ? Style.surfaceHover : "transparent")

          Behavior on color { ColorAnimation { duration: 130 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 10

            // Left Vector Icon Badge
            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 14
              color: modelData.is_pinned
                ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.22)
                : Style.surfaceVariant

              Text {
                anchors.centerIn: parent
                text: modelData.is_pinned ? "󰐃" : "󰅍"
                font.pixelSize: 13
                color: modelData.is_pinned ? Style.accent : Style.textSecondary
              }
            }

            // Text Preview Column
            Column {
              Layout.fillWidth: true
              spacing: 1

              Text {
                width: parent.width
                text: {
                  let str = (modelData.content || modelData.preview || "").trim().replace(/\n/g, " ")
                  return str.length > 0 ? str : "Boş Metin"
                }
                font.family: Style.fontText
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Style.textPrimary
                elide: Text.ElideRight
              }

              Text {
                text: `${(modelData.content || modelData.preview || "").length} karakter`
                font.family: Style.fontText
                font.pixelSize: 9
                color: Style.textMuted
              }
            }

            // Pin / Unpin Button
            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: pinHover.containsMouse ? Style.surfaceHover : "transparent"

              Text {
                anchors.centerIn: parent
                text: modelData.is_pinned ? "󰐃" : "󰐄"
                font.pixelSize: 12
                color: modelData.is_pinned ? Style.accent : Style.textMuted
              }

              MouseArea {
                id: pinHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) {
                    if (modelData.is_pinned) ipc.unpinClipboardItem(modelData.id)
                    else ipc.pinClipboardItem(modelData.id, modelData.preview, "")
                  }
                }
              }
            }

            // Delete Action
            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 12
              color: delHover.containsMouse
                ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.22)
                : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.pixelSize: 11
                color: delHover.containsMouse ? Style.accentRed : Style.textMuted
              }

              MouseArea {
                id: delHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) ipc.deleteClipboardItem(modelData.id)
                }
              }
            }
          }

          MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            anchors.rightMargin: 60
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                root.openDetail(modelData)
              } else {
                if (ipc) {
                  ipc.copyClipboardItem(modelData.id, modelData.content || modelData.preview || "")
                  root.backRequested()
                }
              }
            }
          }
        }

        // Empty State
        Item {
          anchors.centerIn: parent
          visible: clipList.count === 0
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰅍"
              font.pixelSize: 22
              color: Style.textMuted
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Pano geçmişi boş"
              font.family: Style.fontText
              color: Style.textMuted
              font.pixelSize: 11
            }
          }
        }
      }
    }
  }

  // ==========================================
  // VIEW 2: Full Text Reading Sheet
  // ==========================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 10
    visible: root.detailItem !== null

    CCViewHeader {
      title: "Metin Önizleme"
      subtitle: `${(root.detailItem && (root.detailItem.content || root.detailItem.preview)) ? (root.detailItem.content || root.detailItem.preview).length : 0} karakter`
      onBackRequested: root.closeDetail()

      // Copy Action Pill in Header
      Rectangle {
        Layout.preferredHeight: 26
        Layout.preferredWidth: copyHdrRow.implicitWidth + 16
        radius: 13
        color: copyBtnHover.containsMouse
          ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.30)
          : Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.20)

        Row {
          id: copyHdrRow
          anchors.centerIn: parent
          spacing: 5
          Text { anchors.verticalCenter: parent.verticalCenter; text: "󰆏"; font.pixelSize: 11; color: Style.accent }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Kopyala"
            font.family: Style.fontDisplay
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Style.accent
          }
        }

        MouseArea {
          id: copyBtnHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc && root.detailItem) {
              ipc.copyClipboardItem(root.detailItem.id, root.detailItem.content || root.detailItem.preview || "")
              root.closeDetail()
              root.backRequested()
            }
          }
        }
      }
    }

    // Continuous Text Sheet
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 12
        contentWidth: width
        contentHeight: fullTextEdit.implicitHeight + 12
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
          id: fullTextEdit
          width: flick.width
          text: root.detailItem ? (root.detailItem.content || root.detailItem.preview || "") : ""
          font.family: Style.fontText
          font.pixelSize: 12
          color: Style.textPrimary
          wrapMode: TextEdit.WrapAnywhere
          readOnly: true
          selectByMouse: true
        }
      }
    }
  }
}
