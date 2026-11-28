import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string title: ""
  property string subtitle: ""
  property string iconText: "󰒓"
  property bool expanded: false

  default property alias content: bodyLayout.data

  Layout.fillWidth: true
  implicitHeight: headerItem.implicitHeight + (expanded ? (bodyLayout.implicitHeight + 1) : 0)
  radius: 10
  color: Style.appCard
  border.color: Style.appBorder
  border.width: 1
  clip: true

  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    Rectangle {
      id: headerItem
      Layout.fillWidth: true
      implicitHeight: root.subtitle !== "" ? 54 : 46
      color: headerMouse.containsMouse ? Style.surfaceHover : "transparent"

      Behavior on color { ColorAnimation { duration: 120 } }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Text {
          text: root.iconText
          font.pixelSize: 15
          color: root.expanded ? Style.accent : Style.textSecondary
          Layout.preferredWidth: 18
          horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1

          Text {
            text: root.title
            font.family: Style.fontText
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Style.textPrimary
            Layout.fillWidth: true
          }

          Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            font.family: Style.fontText
            font.pixelSize: 11
            color: Style.textMuted
            Layout.fillWidth: true
          }
        }

        Text {
          text: "󰅀"
          font.pixelSize: 16
          color: Style.textMuted
          rotation: root.expanded ? 180 : 0
          Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
      }

      MouseArea {
        id: headerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
      }
    }

    Rectangle {
      visible: root.expanded
      Layout.fillWidth: true
      height: 1
      color: Style.appBorder
    }

    ColumnLayout {
      id: bodyLayout
      visible: root.expanded
      Layout.fillWidth: true
      spacing: 0
    }
  }
}
