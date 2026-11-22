import QtQuick
import QtQuick.Layouts
import "../../../.."

Rectangle {
  id: segRoot

  // Each item: { label: string, icon?: string, iconColor?: color, dotColor?: color, showDot?: bool, badge?: string }
  property var items: []
  property int currentIndex: 0

  signal selected(int index)

  readonly property int itemCount: items ? items.length : 0
  readonly property real segmentWidth: itemCount > 0 ? (width - 4) / itemCount : 0

  Layout.fillWidth: true
  Layout.preferredHeight: 30
  radius: 15
  color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.06)
  border.color: Style.borderSubtle
  border.width: 1

  // Spring-Animated Sliding Selection Thumb
  Rectangle {
    id: slidingThumb
    visible: segRoot.itemCount > 0 && segRoot.currentIndex >= 0 && segRoot.currentIndex < segRoot.itemCount
    y: 2
    height: parent.height - 4
    width: Math.max(0, segRoot.segmentWidth)
    x: 2 + segRoot.currentIndex * segRoot.segmentWidth
    radius: height / 2
    color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14)
    border.color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.08)
    border.width: 1

    Behavior on x {
      SpringAnimation {
        spring: 28.0
        damping: 0.78
        epsilon: 0.01
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 2
    spacing: 0

    Repeater {
      model: segRoot.items

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property bool isSelected: index === segRoot.currentIndex

        Row {
          anchors.centerIn: parent
          spacing: 5

          Text {
            visible: !!(modelData.icon && modelData.icon.length > 0)
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.icon || ""
            font.pixelSize: 12
            color: modelData.iconColor ? modelData.iconColor : (isSelected ? Style.textPrimary : Style.textMuted)

            Behavior on color { ColorAnimation { duration: 150 } }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label || ""
            font.family: Style.fontDisplay
            font.pixelSize: 11
            font.weight: isSelected ? Font.DemiBold : Font.Medium
            color: isSelected ? Style.textPrimary : Style.textMuted

            Behavior on color { ColorAnimation { duration: 150 } }
          }

          Rectangle {
            visible: !!modelData.showDot
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: 5
            radius: 2.5
            color: modelData.dotColor ? modelData.dotColor : Style.accentGreen
          }

          Rectangle {
            visible: !!(modelData.badge && String(modelData.badge).length > 0)
            anchors.verticalCenter: parent.verticalCenter
            width: badgeTxt.implicitWidth + 8
            height: 14
            radius: 7
            color: isSelected
              ? Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14)
              : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.07)

            Text {
              id: badgeTxt
              anchors.centerIn: parent
              text: modelData.badge ? String(modelData.badge) : ""
              font.family: Style.fontDisplay
              font.pixelSize: 9
              font.weight: Font.DemiBold
              color: isSelected ? Style.textPrimary : Style.textMuted
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (segRoot.currentIndex !== index) {
              segRoot.currentIndex = index
              segRoot.selected(index)
            }
          }
        }
      }
    }
  }
}
