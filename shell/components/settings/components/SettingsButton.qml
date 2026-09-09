import QtQuick
import QtQuick.Layouts
import "../../../theme"

Rectangle {
  id: root

  property string text: ""
  property string iconText: ""
  property bool loading: false
  property bool isAccent: false
  property bool isDanger: false
  property bool isSecondary: true
  property bool enabled: !loading
  signal clicked()

  implicitWidth: contentLayout.implicitWidth + 24
  implicitHeight: 32
  radius: 8

  color: {
    if (!enabled) return Style.surfaceVariant
    if (mouseArea.pressed) return isAccent ? Qt.darker(Style.accentCyan, 1.2) : Style.surfaceActive
    if (mouseArea.containsMouse) return isAccent ? Qt.lighter(Style.accentCyan, 1.1) : Style.surfaceHover
    if (isAccent) return Style.accentCyan
    if (isDanger) return Style.accentRed
    return Style.surfaceVariant
  }

  border.color: isAccent ? "transparent" : (mouseArea.containsMouse ? Style.accentCyan : Style.border)
  border.width: 1

  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  RowLayout {
    id: contentLayout
    anchors.centerIn: parent
    spacing: 6

    Text {
      id: btnIcon
      visible: root.iconText !== ""
      text: root.iconText
      font.pixelSize: 13
      color: root.isAccent ? "#11111B" : (root.isDanger ? "#FFFFFF" : Style.textPrimary)

      RotationAnimation on rotation {
        running: root.loading
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 800
        onRunningChanged: {
          if (!running) {
            btnIcon.rotation = 0
          }
        }
      }
    }

    Text {
      text: root.text
      font.pixelSize: 12
      font.weight: Font.Medium
      color: root.isAccent ? "#11111B" : (root.isDanger ? "#FFFFFF" : Style.textPrimary)
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}
