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
  property real maxValue: 100
  property real step: 1
  property string unit: ""
  property string prefix: ""
  property int decimals: 0
  property bool showDivider: true

  signal valueModified(real val)

  property bool _dragging: false
  property real _dragValue: 0
  readonly property real displayValue: _dragging ? _dragValue : value

  readonly property real clampedRatio: {
    let span = Math.max(0.0001, maxValue - minValue)
    return Math.max(0.0, Math.min(1.0, (displayValue - minValue) / span))
  }

  function formatValue(v) {
    let s = decimals > 0 ? Number(v).toFixed(decimals) : Math.round(v).toString()
    return prefix + s + (unit.length > 0 ? (" " + unit) : "")
  }

  function applyRaw(raw) {
    let stepped = Math.round((raw - minValue) / step) * step + minValue
    let clamped = Math.max(minValue, Math.min(maxValue, stepped))
    let factor = Math.pow(10, Math.max(decimals, 2))
    clamped = Math.round(clamped * factor) / factor
    let prev = root._dragging ? root._dragValue : root.value
    root._dragValue = clamped
    if (clamped !== prev) {
      root.valueModified(clamped)
    }
  }

  Layout.fillWidth: true
  implicitHeight: col.implicitHeight + 22
  color: "transparent"

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    anchors.topMargin: 11
    anchors.bottomMargin: 11
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Text {
        visible: root.iconText !== ""
        text: root.iconText
        font.pixelSize: 15
        color: root.iconColor
        Layout.preferredWidth: 18
        horizontalAlignment: Text.AlignHCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

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

      Rectangle {
        implicitWidth: Math.max(54, valBadge.implicitWidth + 14)
        implicitHeight: 24
        radius: 6
        color: Style.appBackground
        border.color: Style.appBorder
        border.width: 1

        Text {
          id: valBadge
          anchors.centerIn: parent
          text: root.formatValue(root.displayValue)
          font.family: Style.fontDisplay
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Style.textPrimary
        }
      }
    }

    // Sleek Interactive Track
    Item {
      id: trackHit
      Layout.fillWidth: true
      Layout.leftMargin: root.iconText !== "" ? 28 : 0
      implicitHeight: 20

      Rectangle {
        id: trackBg
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3
        color: Style.appBackground
        border.color: Style.appBorder
        border.width: 1

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: Math.max(6, parent.width * root.clampedRatio)
          radius: 3
          color: Style.accent

          Behavior on width {
            enabled: !sliderMouse.pressed
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
          }
        }
      }

      Rectangle {
        id: thumb
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, (parent.width - width) * root.clampedRatio))
        color: Style.textPrimary
        border.color: Style.bgPrimary
        border.width: 2
        scale: sliderMouse.pressed ? 1.15 : (sliderMouse.containsMouse ? 1.08 : 1.0)

        Behavior on scale { NumberAnimation { duration: 100 } }
        Behavior on x {
          enabled: !sliderMouse.pressed
          NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
        }
      }

      MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function setFromX(mx) {
          let ratio = Math.max(0, Math.min(1, mx / Math.max(1, width)))
          root.applyRaw(root.minValue + ratio * (root.maxValue - root.minValue))
        }

        onPressed: mouse => {
          root._dragging = true
          setFromX(mouse.x)
        }
        onPositionChanged: mouse => { if (pressed) setFromX(mouse.x) }
        onReleased: root._dragging = false
        onCanceled: root._dragging = false
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
