import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property string title: ""
  property string subtitle: ""
  property string iconText: ""
  property color iconColor: Style.textSecondary
  property real value: 0
  property real minValue: 0
  property real maxValue: 2000
  property real step: 1
  property string unit: "px"
  property bool showDivider: true

  signal valueModified(real val)

  Layout.fillWidth: true
  implicitHeight: subtitle !== "" ? 54 : 44
  color: "transparent"

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    spacing: 12

    Text {
      visible: root.iconText !== ""
      text: root.iconText
      font.pixelSize: 15
      color: root.iconColor
      Layout.preferredWidth: 18
      horizontalAlignment: Text.AlignHCenter
      Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        font.family: Style.fontText
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Style.textPrimary
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        font.family: Style.fontText
        font.pixelSize: 11
        color: Style.textMuted
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
    }

    // Minimalist Segmented Stepper
    Rectangle {
      Layout.alignment: Qt.AlignVCenter
      implicitWidth: stepperRow.implicitWidth
      implicitHeight: 28
      radius: 7
      color: Style.appBackground
      border.color: Style.appBorder
      border.width: 1

      RowLayout {
        id: stepperRow
        anchors.fill: parent
        spacing: 0

        Rectangle {
          width: 26
          height: 28
          radius: 7
          color: minusMouse.pressed ? Style.surfaceActive : (minusMouse.containsMouse ? Style.surfaceHover : "transparent")

          Behavior on color { ColorAnimation { duration: 100 } }

          Text {
            anchors.centerIn: parent
            text: "−"
            font.family: Style.fontText
            font.pixelSize: 14
            font.weight: Font.Medium
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
              nextVal = Math.round(nextVal * 100) / 100
              root.value = nextVal
              root.valueModified(nextVal)
            }
          }
        }

        Rectangle {
          width: 1
          height: 14
          color: Style.appBorder
        }

        Item {
          implicitWidth: Math.max(54, valRow.implicitWidth + 14)
          height: 28

          RowLayout {
            id: valRow
            anchors.centerIn: parent
            spacing: 2

            Text {
              text: root.value.toString()
              font.family: Style.fontDisplay
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: Style.textPrimary
            }

            Text {
              visible: root.unit !== ""
              text: root.unit
              font.family: Style.fontText
              font.pixelSize: 10
              color: Style.textMuted
            }
          }
        }

        Rectangle {
          width: 1
          height: 14
          color: Style.appBorder
        }

        Rectangle {
          width: 26
          height: 28
          radius: 7
          color: plusMouse.pressed ? Style.surfaceActive : (plusMouse.containsMouse ? Style.surfaceHover : "transparent")

          Behavior on color { ColorAnimation { duration: 100 } }

          Text {
            anchors.centerIn: parent
            text: "+"
            font.family: Style.fontText
            font.pixelSize: 14
            font.weight: Font.Medium
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
              nextVal = Math.round(nextVal * 100) / 100
              root.value = nextVal
              root.valueModified(nextVal)
            }
          }
        }
      }
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: root.iconText !== "" ? 44 : 14
    anchors.rightMargin: 14
    height: 1
    color: Style.appBorder
    opacity: 0.7
    visible: root.showDivider
  }
}
