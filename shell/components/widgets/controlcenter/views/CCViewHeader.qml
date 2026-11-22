import QtQuick
import QtQuick.Layouts
import "../../../.."

RowLayout {
  id: headerRoot

  property string title: ""
  property string subtitle: ""
  default property alias actions: actionsRow.data

  signal backRequested()

  Layout.fillWidth: true
  Layout.preferredHeight: 28
  spacing: 8

  // Circular Apple-style Back Button
  Rectangle {
    Layout.preferredWidth: 26
    Layout.preferredHeight: 26
    radius: 13
    color: backHover.containsMouse ? Style.surfaceHover : Style.surface
    border.color: Style.borderSubtle
    border.width: 1

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
      anchors.centerIn: parent
      text: "󰅁"
      font.pixelSize: 15
      color: Style.textPrimary
    }

    MouseArea {
      id: backHover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: headerRoot.backRequested()
    }
  }

  // Title & Optional Subtitle
  Column {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    spacing: 0

    Text {
      width: parent.width
      text: headerRoot.title
      font.family: Style.fontDisplay
      font.pixelSize: 13
      font.weight: Font.DemiBold
      color: Style.textPrimary
      elide: Text.ElideRight
    }

    Text {
      visible: headerRoot.subtitle.length > 0
      width: parent.width
      text: headerRoot.subtitle
      font.family: Style.fontText
      font.pixelSize: 10
      color: Style.textMuted
      elide: Text.ElideRight
    }
  }

  // Trailing Action Controls Slot
  RowLayout {
    id: actionsRow
    spacing: 6
    Layout.alignment: Qt.AlignVCenter
  }
}
