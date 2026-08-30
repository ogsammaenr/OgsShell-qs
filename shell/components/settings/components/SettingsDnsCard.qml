import QtQuick
import QtQuick.Layouts
import "../../../theme"

Rectangle {
  id: root

  property string title: ""
  property string dnsIps: ""
  property bool isSelected: false
  signal clicked()

  Layout.fillWidth: true
  implicitHeight: 52
  radius: 10

  color: isSelected ? Style.surfaceActive : (mouseArea.containsMouse ? Style.surfaceHover : Style.appCard)
  border.color: isSelected ? Style.accentCyan : Style.appBorder
  border.width: isSelected ? 1.5 : 1

  Behavior on color { ColorAnimation { duration: 140 } }
  Behavior on border.color { ColorAnimation { duration: 140 } }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 14

    // Left Radio Checkmark Circle
    Rectangle {
      width: 18
      height: 18
      radius: 9
      color: "transparent"
      border.color: root.isSelected ? Style.accentCyan : Style.border
      border.width: 2
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: 5
        color: Style.accentCyan
        visible: root.isSelected
      }
    }

    // Title & IPs Column (Strict Left Alignment)
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        font.pixelSize: 13
        font.weight: root.isSelected ? Font.Bold : Font.Medium
        color: root.isSelected ? Style.accentCyan : Style.textPrimary
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
      }

      Text {
        text: root.dnsIps
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
