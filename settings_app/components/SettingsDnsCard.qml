import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string title: ""
  property string dnsIps: ""
  property bool isSelected: false
  signal clicked()

  Layout.fillWidth: true
  implicitHeight: 50
  radius: 10

  color: isSelected ? Qt.alpha(Style.accent, 0.10) : (mouseArea.containsMouse ? Style.surfaceHover : Style.appCard)
  border.color: isSelected ? Style.accent : (mouseArea.containsMouse ? Style.borderHover : Style.appBorder)
  border.width: 1

  Behavior on color { ColorAnimation { duration: 140 } }
  Behavior on border.color { ColorAnimation { duration: 140 } }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    spacing: 12

    Rectangle {
      width: 16
      height: 16
      radius: 8
      color: "transparent"
      border.color: root.isSelected ? Style.accent : Style.textMuted
      border.width: root.isSelected ? 1.5 : 1
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        anchors.centerIn: parent
        width: 8
        height: 8
        radius: 4
        color: Style.accent
        visible: root.isSelected
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        font.family: Style.fontText
        font.pixelSize: 13
        font.weight: root.isSelected ? Font.DemiBold : Font.Medium
        color: root.isSelected ? Style.accent : Style.textPrimary
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
      }

      Text {
        text: root.dnsIps
        font.family: Style.fontText
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
