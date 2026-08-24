import QtQuick
import QtQuick.Layouts
import "../../../theme"

Rectangle {
  id: root

  property string iconText: ""
  property color iconColor: Style.accentCyan
  property string title: ""
  property string subtitle: ""
  property bool showDivider: true
  property bool clickable: false
  signal clicked()

  default property alias content: rightSlot.data

  Layout.fillWidth: true
  implicitHeight: subtitle !== "" ? 56 : 48

  color: clickable && mouseArea.containsMouse ? Style.surfaceHover : "transparent"

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.clickable
    hoverEnabled: true
    cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    spacing: 12

    // Optional Left Glyph Icon
    Text {
      visible: root.iconText !== ""
      text: root.iconText
      font.pixelSize: 17
      color: root.iconColor
      Layout.alignment: Qt.AlignVCenter
    }

    // Title & Subtitle Column
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Style.textPrimary
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
    }

    // Right Slot Container (for Toggles, Badges, Buttons, Dropdowns)
    RowLayout {
      id: rightSlot
      Layout.alignment: Qt.AlignVCenter
      spacing: 8
    }
  }

  // Subtle bottom divider
  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.iconText !== "" ? 42 : 14
    anchors.rightMargin: 14
    height: 1
    color: Style.border
    opacity: 0.6
    visible: root.showDivider
  }
}
