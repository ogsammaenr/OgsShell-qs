import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string title: ""
  property string subtitle: ""
  property string iconText: ""
  property color iconColor: Style.accentCyan
  property real value: 0
  property real minValue: 0
  property real maxValue: 2000
  property real step: 1
  property string unit: "px"
  property bool showDivider: true

  signal valueModified(real val)

  Layout.fillWidth: true
  implicitHeight: subtitle !== "" ? 56 : 48
  color: "transparent"

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    spacing: 12

    // Optional Left Icon
    Text {
      visible: root.iconText !== ""
      text: root.iconText
      font.pixelSize: 16
      color: root.iconColor
      Layout.alignment: Qt.AlignVCenter
    }

    // Title & Subtitle Column
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Style.textPrimary
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
    }

    // Stepper Input Control
    RowLayout {
      Layout.alignment: Qt.AlignVCenter
      spacing: 4

      // Minus (-) Button
      Rectangle {
        width: 28
        height: 28
        radius: 6
        color: minusMouse.pressed ? Style.surfaceActive : (minusMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
        border.color: minusMouse.containsMouse ? Style.accentCyan : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          text: "−"
          font.pixelSize: 15
          font.weight: Font.Bold
          color: (root.value > root.minValue) ? Style.textPrimary : Style.textMuted
        }

        MouseArea {
          id: minusMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: (root.value > root.minValue) ? Qt.PointingHandCursor : Qt.ArrowCursor
          enabled: root.value > root.minValue
          onClicked: {
            let nextVal = Math.max(root.minValue, root.value - root.step)
            // Round to 2 decimal places to avoid floating point drift
            nextVal = Math.round(nextVal * 100) / 100
            root.value = nextVal
            root.valueModified(nextVal)
          }
        }
      }

      // Value Box
      Rectangle {
        implicitWidth: Math.max(64, valText.implicitWidth + 16)
        height: 28
        radius: 6
        color: Style.appBackground
        border.color: Style.border
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: 2

          Text {
            id: valText
            text: root.value.toString()
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Style.accentCyan
          }

          Text {
            visible: root.unit !== ""
            text: root.unit
            font.pixelSize: 10
            color: Style.textMuted
          }
        }
      }

      // Plus (+) Button
      Rectangle {
        width: 28
        height: 28
        radius: 6
        color: plusMouse.pressed ? Style.surfaceActive : (plusMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
        border.color: plusMouse.containsMouse ? Style.accentCyan : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
          anchors.centerIn: parent
          text: "+"
          font.pixelSize: 15
          font.weight: Font.Bold
          color: (root.value < root.maxValue) ? Style.textPrimary : Style.textMuted
        }

        MouseArea {
          id: plusMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: (root.value < root.maxValue) ? Qt.PointingHandCursor : Qt.ArrowCursor
          enabled: root.value < root.maxValue
          onClicked: {
            let nextVal = Math.min(root.maxValue, root.value + root.step)
            // Round to 2 decimal places to avoid floating point drift
            nextVal = Math.round(nextVal * 100) / 100
            root.value = nextVal
            root.valueModified(nextVal)
          }
        }
      }
    }
  }

  // Subtle bottom divider
  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.iconText !== "" ? 42 : 14
    anchors.rightMargin: 14
    height: 1
    color: Style.border
    opacity: 0.6
    visible: root.showDivider
  }
}
