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
  radius: 10

  color: isSelected ? Qt.alpha(Style.accent, 0.10) : (mouseArea.containsMouse ? Style.surfaceHover : Style.appCard)
  border.color: isSelected ? Style.accent : (mouseArea.containsMouse ? Style.borderHover : Style.appBorder)
  border.width: 1

  Behavior on color { ColorAnimation { duration: 140 } }
  Behavior on border.color { ColorAnimation { duration: 140 } }

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
    anchors.margins: 12
    spacing: 12

    Rectangle {
      width: 36
      height: 36
      radius: 8
      color: root.isSelected ? Qt.alpha(Style.accent, 0.18) : Style.surfaceVariant

      Text {
        anchors.centerIn: parent
        text: root.iconText
        font.pixelSize: 16
        color: root.isSelected ? Style.accent : Style.textSecondary
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: root.title
          font.family: Style.fontText
          font.pixelSize: 13
          font.weight: Font.DemiBold
          color: root.isSelected ? Style.accent : Style.textPrimary
        }

        Rectangle {
          visible: root.badgeText !== ""
          implicitWidth: badgeTextItem.implicitWidth + 10
          implicitHeight: 17
          radius: 4
          color: root.isSelected ? Qt.alpha(Style.accent, 0.16) : Style.surfaceVariant

          Text {
            id: badgeTextItem
            anchors.centerIn: parent
            text: root.badgeText
            font.family: Style.fontText
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.isSelected ? Style.accent : Style.textMuted
          }
        }
      }

      Text {
        text: root.subtitle
        font.family: Style.fontText
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }
    }

    Rectangle {
      width: 16
      height: 16
      radius: 8
      color: "transparent"
      border.color: root.isSelected ? Style.accent : Style.textMuted
      border.width: root.isSelected ? 1.5 : 1

      Rectangle {
        anchors.centerIn: parent
        width: 8
        height: 8
        radius: 4
        color: Style.accent
        visible: root.isSelected
      }
    }
  }
}
