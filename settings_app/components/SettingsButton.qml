import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string text: ""
  property string iconText: ""
  property bool isAccent: false
  property bool isDanger: false
  property bool isSecondary: true
  property bool enabled: true
  signal clicked()

  implicitWidth: contentLayout.implicitWidth + 22
  implicitHeight: 30
  radius: 7

  color: {
    if (!enabled) return Style.surfaceVariant
    if (mouseArea.pressed) return isAccent ? Qt.darker(Style.accent, 1.15) : Style.surfaceActive
    if (mouseArea.containsMouse) return isAccent ? Qt.lighter(Style.accent, 1.08) : Style.surfaceHover
    if (isAccent) return Style.accent
    if (isDanger) return Qt.alpha(Style.accentRed, 0.16)
    return Style.surfaceVariant
  }

  border.color: {
    if (isAccent) return "transparent"
    if (isDanger) return Qt.alpha(Style.accentRed, 0.45)
    return mouseArea.containsMouse ? Style.borderHover : Style.appBorder
  }
  border.width: 1

  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  RowLayout {
    id: contentLayout
    anchors.centerIn: parent
    spacing: 6

    Text {
      visible: root.iconText !== ""
      text: root.iconText
      font.pixelSize: 13
      color: root.isAccent ? Style.bgPrimary : (root.isDanger ? Style.accentRed : Style.textSecondary)
    }

    Text {
      text: root.text
      font.family: Style.fontText
      font.pixelSize: 12
      font.weight: Font.Medium
      color: root.isAccent ? Style.bgPrimary : (root.isDanger ? Style.accentRed : Style.textPrimary)
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
