import QtQuick
import "../theme"

Item {
  id: root

  property bool checked: false
  property bool enabled: true
  signal toggled(bool isChecked)

  implicitWidth: 38
  implicitHeight: 22

  Rectangle {
    id: track
    anchors.fill: parent
    radius: 11
    color: root.checked ? Style.accent : Style.surfaceVariant
    border.color: root.checked ? Style.accent : Style.appBorder
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: 160; easing.type: Easing.OutQuad }
    }
    Behavior on border.color {
      ColorAnimation { duration: 160; easing.type: Easing.OutQuad }
    }

    Rectangle {
      id: thumb
      width: 16
      height: 16
      radius: 8
      y: 2
      x: root.checked ? (parent.width - width - 3) : 3
      color: root.checked ? Style.bgPrimary : Style.textPrimary

      Behavior on x {
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutCubic
        }
      }

      Behavior on color {
        ColorAnimation { duration: 160; easing.type: Easing.OutQuad }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: {
      root.checked = !root.checked
      root.toggled(root.checked)
    }
  }
}
