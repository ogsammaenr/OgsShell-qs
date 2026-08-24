import QtQuick
import "../theme"

Item {
  id: root

  property bool checked: false
  property bool enabled: true
  signal toggled(bool isChecked)

  implicitWidth: 42
  implicitHeight: 24

  Rectangle {
    id: track
    anchors.fill: parent
    radius: 12
    color: root.checked ? Style.accentCyan : Style.surfaceVariant
    border.color: root.checked ? Style.accentCyan : Style.border
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: 180; easing.type: Easing.OutQuad }
    }
    Behavior on border.color {
      ColorAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    Rectangle {
      id: thumb
      width: 18
      height: 18
      radius: 9
      y: 2
      x: root.checked ? (parent.width - width - 3) : 3
      color: root.checked ? "#11111B" : Style.textPrimary

      Behavior on x {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Behavior on color {
        ColorAnimation { duration: 180; easing.type: Easing.OutQuad }
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
