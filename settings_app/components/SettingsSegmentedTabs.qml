import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  // Each item: { "id": "...", "label": "...", "icon": "...", "dotColor": "" (optional) }
  property var tabs: []
  property string activeId: ""
  signal tabSelected(string tabId)

  readonly property int activeIndex: {
    for (let i = 0; i < tabs.length; i++) {
      if (tabs[i].id === activeId) return i
    }
    return 0
  }

  Layout.fillWidth: true
  implicitHeight: 38
  radius: 9
  color: Style.surfaceVariant
  border.color: Style.appBorder
  border.width: 1

  readonly property real segWidth: tabs.length > 0 ? ((width - 6) / tabs.length) : 0

  // Smooth Sliding Capsule Thumb
  Rectangle {
    visible: root.tabs.length > 0
    y: 3
    x: 3 + (root.activeIndex * root.segWidth)
    width: root.segWidth
    height: parent.height - 6
    radius: 7
    color: Style.appCard
    border.color: Style.appBorder
    border.width: 1

    Behavior on x {
      NumberAnimation {
        duration: 260
        easing.type: Easing.OutQuart
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 3
    spacing: 0

    Repeater {
      model: root.tabs

      delegate: Item {
        required property var modelData
        required property int index
        readonly property bool isActive: root.activeId === modelData.id

        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
          anchors.centerIn: parent
          spacing: 7

          Text {
            visible: !!(modelData.icon && modelData.icon.length > 0)
            text: modelData.icon || ""
            font.pixelSize: 13
            color: isActive ? Style.accent : Style.textMuted
            Behavior on color { ColorAnimation { duration: 140 } }
          }

          Text {
            text: modelData.label || ""
            font.family: Style.fontText
            font.pixelSize: 12
            font.weight: isActive ? Font.DemiBold : Font.Medium
            color: isActive ? Style.textPrimary : Style.textMuted
            Behavior on color { ColorAnimation { duration: 140 } }
          }

          Rectangle {
            visible: !!(modelData.dotColor && modelData.dotColor.toString().length > 0)
            width: 6
            height: 6
            radius: 3
            color: modelData.dotColor || "transparent"
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.tabSelected(modelData.id)
        }
      }
    }
  }
}
