import QtQuick
import QtQuick.Layouts
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  // Full detail view state
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
  // VIEW 1: Main Clipboard History List
  // ==========================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 8
    visible: root.detailItem === null

    // Header Row
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back Button
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
        text: "Pano Geçmişi"
        color: Style.textPrimary
        font.pixelSize: 13
        font.weight: Font.Bold
        Layout.fillWidth: true
      }

      Text {
        text: "Sağ tık: Oku"
        color: Style.textMuted
        font.pixelSize: 10
      }

      // Clear All Button
      Rectangle {
        Layout.preferredHeight: 24
        Layout.preferredWidth: 64
        radius: 6
        color: wipeHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "Temizle"
          font.pixelSize: 11
          font.weight: Font.Medium
          color: Style.textSecondary
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

    // Pinned & Recent Items List
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 10
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: clipList
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6
        reuseItems: true
        cacheBuffer: 60
        model: (ipc && ipc.clipboardHistory) ? ipc.clipboardHistory : []

        delegate: Rectangle {
          width: clipList.width
          height: 52
          radius: 8
          color: itemMouseArea.containsMouse ? Style.surfaceHover : Style.surfaceVariant
          border.color: modelData.is_pinned ? Style.accentCyan : Style.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            // Left Icon Badge
            Rectangle {
              width: 30
              height: 30
              radius: 15
              color: modelData.is_pinned ? Style.accentCyan : Style.surfaceActive

              Text {
                anchors.centerIn: parent
                text: modelData.is_pinned ? "★" : "󰅍"
                font.pixelSize: 14
                color: modelData.is_pinned ? "#000000" : Style.textPrimary
              }
            }

            // Text Content Column
            Column {
              Layout.fillWidth: true
              spacing: 2
              Layout.alignment: Qt.AlignVCenter

              Text {
                text: {
                  let str = (modelData.content || modelData.preview || "").trim().replace(/\n/g, " ")
                  return str.length > 0 ? str : "Boş Metin"
                }
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Style.textPrimary
                elide: Text.ElideRight
                width: clipList.width - 130
              }

              Text {
                text: {
                  let len = (modelData.content || modelData.preview || "").length
                  return `${len} karakter • Sağ tıkla oku`
                }
                font.pixelSize: 10
                color: Style.textMuted
              }
            }

            // Pin / Favorite Action
            Rectangle {
              width: 26
              height: 26
              radius: 13
              color: pinHover.containsMouse ? Style.surfaceActive : "transparent"

              Text {
                anchors.centerIn: parent
                text: modelData.is_pinned ? "★" : "☆"
                font.pixelSize: 14
                color: modelData.is_pinned ? Style.accentCyan : Style.textMuted
              }

              MouseArea {
                id: pinHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) {
                    if (modelData.is_pinned) {
                      ipc.unpinClipboardItem(modelData.id)
                    } else {
                      ipc.pinClipboardItem(modelData.id, modelData.preview, "")
                    }
                  }
                }
              }
            }

            // Delete Action
            Rectangle {
              width: 26
              height: 26
              radius: 13
              color: delHover.containsMouse ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.25) : "transparent"

              Text {
                anchors.centerIn: parent
                text: "✕"
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

          // Main Mouse Area: Left click to copy, Right click to open full view
          MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            anchors.rightMargin: 64 // Keep pin and delete clickable
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

        // Empty State Placeholder
        Item {
          anchors.centerIn: parent
          visible: clipList.count === 0
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Pano Geçmişi Boş"
              color: Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.DemiBold
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Kopyaladığınız metinler burada listelenecektir."
              color: Style.textMuted
              font.pixelSize: 10
            }
          }
        }
      }
    }
  }

  // ==========================================
  // VIEW 2: Full Text Reading Modal (Right-Click Detail)
  // ==========================================
  Rectangle {
    anchors.fill: parent
    radius: 10
    color: Style.surface
    border.color: Style.border
    border.width: 1
    visible: root.detailItem !== null

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
          text: "Tam Metin Önizleme"
          font.pixelSize: 13
          font.weight: Font.Bold
          color: Style.textPrimary
          Layout.fillWidth: true
        }

        Text {
          text: `${(root.detailItem && (root.detailItem.content || root.detailItem.preview)) ? (root.detailItem.content || root.detailItem.preview).length : 0} Karakter`
          font.pixelSize: 11
          color: Style.textMuted
        }
      }

      // Scrollable Text Display Area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 8
        color: Style.surfaceVariant
        border.color: Style.border
        border.width: 1
        clip: true

        Flickable {
          id: flick
          anchors.fill: parent
          anchors.margins: 8
          contentWidth: width
          contentHeight: fullTextEdit.implicitHeight + 16
          boundsBehavior: Flickable.StopAtBounds

          TextEdit {
            id: fullTextEdit
            width: flick.width
            text: root.detailItem ? (root.detailItem.content || root.detailItem.preview || "") : ""
            font.pixelSize: 12
            color: Style.textPrimary
            wrapMode: TextEdit.WrapAnywhere
            readOnly: true
            selectByMouse: true
          }
        }
      }

      // Bottom Action Buttons
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Close Button
        Rectangle {
          Layout.preferredWidth: 84
          Layout.preferredHeight: 30
          radius: 6
          color: closeBtnHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "Kapat"
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Style.textSecondary
          }

          MouseArea {
            id: closeBtnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeDetail()
          }
        }

        // Copy to Clipboard Primary Button
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          radius: 6
          color: copyBtnHover.containsMouse ? Style.accentHover : Style.accent

          Text {
            anchors.centerIn: parent
            text: "Panoya Kopyala"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#ffffff"
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
    }
  }
}
