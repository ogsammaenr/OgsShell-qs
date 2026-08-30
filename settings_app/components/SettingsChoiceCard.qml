import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string title: ""
  property string subtitle: ""
  property string iconText: ""
  property string badgeText: ""
  property bool isSelected: false
  signal clicked()

  Layout.fillWidth: true
  implicitHeight: cardLayout.implicitHeight + 24
  radius: 12

  color: isSelected ? Qt.rgba(0.53, 0.77, 0.98, 0.08) : (mouseArea.containsMouse ? Style.surfaceHover : Style.appCard)
  border.color: isSelected ? Style.accentCyan : (mouseArea.containsMouse ? Style.accentBlue : Style.appBorder)
  border.width: isSelected ? 2 : 1

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  RowLayout {
    id: cardLayout
    anchors.fill: parent
    anchors.margins: 14
    spacing: 14

    // Left Icon Container
    Rectangle {
      width: 42
      height: 42
      radius: 10
      color: root.isSelected ? Qt.rgba(0.53, 0.77, 0.98, 0.18) : Style.surfaceVariant
      border.color: root.isSelected ? Style.accentCyan : "transparent"
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: root.iconText
        font.pixelSize: 20
        color: root.isSelected ? Style.accentCyan : Style.textPrimary
      }
    }

    // Texts Column
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: root.title
          font.pixelSize: 13
          font.weight: Font.Bold
          color: root.isSelected ? Style.accentCyan : Style.textPrimary
        }

        Rectangle {
          visible: root.badgeText !== ""
          implicitWidth: badgeTextItem.implicitWidth + 10
          implicitHeight: 18
          radius: 9
          color: root.isSelected ? Qt.rgba(0.53, 0.77, 0.98, 0.2) : Style.surfaceVariant
          border.color: root.isSelected ? Style.accentCyan : Style.appBorder
          border.width: 1

          Text {
            id: badgeTextItem
            anchors.centerIn: parent
            text: root.badgeText
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.isSelected ? Style.accentCyan : Style.textMuted
          }
        }
      }

      Text {
        text: root.subtitle
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }
    }

    // Selection Radio Indicator
    Rectangle {
      width: 20
      height: 20
      radius: 10
      color: "transparent"
      border.color: root.isSelected ? Style.accentCyan : Style.textMuted
      border.width: root.isSelected ? 2 : 1

      Rectangle {
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: 5
        color: Style.accentCyan
        visible: root.isSelected
      }
    }
  }
}
