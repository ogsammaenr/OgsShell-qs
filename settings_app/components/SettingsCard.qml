import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  default property alias content: contentLayout.data
  property int spacing: 0
  property int innerPadding: 0

  Layout.fillWidth: true
  implicitHeight: contentLayout.implicitHeight + (innerPadding * 2)

  radius: 12
  color: Style.appCard
  border.color: Style.appBorder
  border.width: 1
  clip: true

  ColumnLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: root.innerPadding
    spacing: root.spacing
  }
}
