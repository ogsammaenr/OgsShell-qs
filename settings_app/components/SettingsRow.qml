import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string iconText: ""
  property color iconColor: Style.textSecondary
  property string title: ""
  property string subtitle: ""
  property bool showDivider: true
  property bool clickable: false
  signal clicked()

  default property alias content: rightSlot.data

  Layout.fillWidth: true
  implicitHeight: subtitle !== "" ? 54 : 44

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

    Text {
      visible: root.iconText !== ""
      text: root.iconText
      font.pixelSize: 15
      color: root.iconColor
      Layout.preferredWidth: 18
      horizontalAlignment: Text.AlignHCenter
      Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        font.family: Style.fontText
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Style.textPrimary
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        font.family: Style.fontText
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
    }

    RowLayout {
      id: rightSlot
      Layout.alignment: Qt.AlignVCenter
      spacing: 8
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.iconText !== "" ? 44 : 14
    anchors.rightMargin: 14
    height: 1
    color: Style.appBorder
    opacity: 0.7
    visible: root.showDivider
  }
}
