import QtQuick
import QtQuick.Layouts
import "../.."

Item {
  id: root

  property int hour: 12
  property int minute: 0
  property bool compact: false
  property bool showPopup: false

  readonly property string timeString: {
    let h = Math.max(0, Math.min(23, root.hour))
    let m = Math.max(0, Math.min(59, root.minute))
    return (h < 10 ? "0" + h : "" + h) + ":" + (m < 10 ? "0" + m : "" + m)
  }

  signal timeChanged(int h, int m, string timeStr)

  function setHour(h) {
    if (h < 0) h = 23
    else if (h > 23) h = 0
    root.hour = h
    root.timeChanged(root.hour, root.minute, root.timeString)
  }

  function setMinute(m) {
    if (m < 0) m = 59
    else if (m > 59) m = 0
    root.minute = m
    root.timeChanged(root.hour, root.minute, root.timeString)
  }

  function adjustHour(delta) {
    let next = root.hour + delta
    if (next < 0) next = 23
    else if (next > 23) next = 0
    root.setHour(next)
  }

  function adjustMinute(delta) {
    let next = root.minute + delta
    if (next < 0) next = 59
    else if (next > 59) next = 0
    root.setMinute(next)
  }

  function setTime(h, m) {
    root.hour = Math.max(0, Math.min(23, h))
    root.minute = Math.max(0, Math.min(59, m))
    root.timeChanged(root.hour, root.minute, root.timeString)
  }

  // ==========================================
  // VIEW 1: Standalone Standard Full Time Picker
  // ==========================================
  ColumnLayout {
    id: fullPickerLayout
    anchors.fill: parent
    spacing: 3
    visible: !root.compact

    // Digital Dual-Tile Control Row
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 6

      // Hour Segment Block
      Rectangle {
        Layout.preferredWidth: 56
        Layout.preferredHeight: 34
        radius: 8
        color: hourMainMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
        border.color: hourMainMouse.containsMouse ? Style.accentCyan : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 1
          spacing: 0

          // Top indicator
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "▲"
            font.pixelSize: 6
            color: Style.textMuted
            opacity: hourMainMouse.containsMouse ? 0.9 : 0.35
          }

          // Digit Value
          Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.hour < 10 ? "0" + root.hour : "" + root.hour
            font.pixelSize: 14
            font.weight: Font.Bold
            color: Style.textPrimary
          }

          // Bottom indicator
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "▼"
            font.pixelSize: 6
            color: Style.textMuted
            opacity: hourMainMouse.containsMouse ? 0.9 : 0.35
          }
        }

        // Full Interactive Mouse & Wheel Area
        MouseArea {
          id: hourMainMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.adjustHour(1)
            else if (wheel.angleDelta.y < 0) root.adjustHour(-1)
          }

          onClicked: mouse => {
            if (mouse.y < height / 2) {
              root.adjustHour(1)
            } else {
              root.adjustHour(-1)
            }
          }
        }
      }

      // Colon Separator
      Text {
        text: ":"
        font.pixelSize: 15
        font.weight: Font.Bold
        color: Style.accentCyan
        Layout.alignment: Qt.AlignVCenter
      }

      // Minute Segment Block
      Rectangle {
        Layout.preferredWidth: 56
        Layout.preferredHeight: 34
        radius: 8
        color: minMainMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
        border.color: minMainMouse.containsMouse ? Style.accentCyan : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 1
          spacing: 0

          // Top indicator
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "▲"
            font.pixelSize: 6
            color: Style.textMuted
            opacity: minMainMouse.containsMouse ? 0.9 : 0.35
          }

          // Digit Value
          Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.minute < 10 ? "0" + root.minute : "" + root.minute
            font.pixelSize: 14
            font.weight: Font.Bold
            color: Style.textPrimary
          }

          // Bottom indicator
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "▼"
            font.pixelSize: 6
            color: Style.textMuted
            opacity: minMainMouse.containsMouse ? 0.9 : 0.35
          }
        }

        // Full Interactive Mouse & Wheel Area (Step by 1 minute)
        MouseArea {
          id: minMainMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.adjustMinute(1)
            else if (wheel.angleDelta.y < 0) root.adjustMinute(-1)
          }

          onClicked: mouse => {
            if (mouse.y < height / 2) {
              root.adjustMinute(1)
            } else {
              root.adjustMinute(-1)
            }
          }
        }
      }
    }

    // Quick Minute Preset Chips (:00, :15, :30, :45)
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 4

      Repeater {
        model: [0, 15, 30, 45]

        Rectangle {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 16
          radius: 4
          readonly property bool isActive: root.minute === modelData
          color: isActive ? Style.accentCyan : (chipHover.hovered ? Style.surfaceHover : Style.surfaceVariant)
          border.color: isActive ? Style.accentCyan : Style.border
          border.width: 1

          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            text: ":" + (modelData === 0 ? "00" : modelData)
            font.pixelSize: 8
            font.weight: isActive ? Font.Bold : Font.Medium
            color: isActive ? "#000000" : Style.textSecondary
          }

          HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.setMinute(modelData) }
        }
      }
    }
  }

  // ==========================================
  // VIEW 2: Compact Pill & Inline Popover (For tight toolbars)
  // ==========================================
  Rectangle {
    id: compactPill
    anchors.fill: parent
    visible: root.compact
    radius: 6
    color: root.showPopup ? Style.surfaceActive : (compactHover.hovered ? Style.surfaceHover : Style.surfaceVariant)
    border.color: root.showPopup ? Style.accentCyan : Style.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 6
      anchors.rightMargin: 6
      spacing: 4

      Text {
        text: "🕒"
        font.pixelSize: 9
      }

      Text {
        text: root.timeString
        color: Style.textPrimary
        font.pixelSize: 10
        font.weight: Font.DemiBold
      }
    }

    HoverHandler { id: compactHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.showPopup = !root.showPopup }
  }

  // Compact Floating Popover
  Rectangle {
    id: compactPopover
    visible: root.compact && root.showPopup
    z: 100
    anchors.bottom: compactPill.top
    anchors.bottomMargin: 6
    anchors.horizontalCenter: compactPill.horizontalCenter
    width: 160
    height: 94
    radius: 12
    color: Style.surface
    border.color: Style.border
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 6

      // Digits Row
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 6

        // Hour block
        Rectangle {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 30
          radius: 6
          color: popHourMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
          border.color: Style.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: root.hour < 10 ? "0" + root.hour : "" + root.hour
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Style.textPrimary
          }

          MouseArea {
            id: popHourMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onWheel: wheel => {
              if (wheel.angleDelta.y > 0) root.adjustHour(1)
              else if (wheel.angleDelta.y < 0) root.adjustHour(-1)
            }
            onClicked: mouse => {
              if (mouse.y < height / 2) root.adjustHour(1)
              else root.adjustHour(-1)
            }
          }
        }

        Text {
          text: ":"
          font.pixelSize: 14
          font.weight: Font.Bold
          color: Style.accentCyan
        }

        // Minute block (Step by 1 minute)
        Rectangle {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 30
          radius: 6
          color: popMinMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
          border.color: Style.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: root.minute < 10 ? "0" + root.minute : "" + root.minute
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Style.textPrimary
          }

          MouseArea {
            id: popMinMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onWheel: wheel => {
              if (wheel.angleDelta.y > 0) root.adjustMinute(1)
              else if (wheel.angleDelta.y < 0) root.adjustMinute(-1)
            }
            onClicked: mouse => {
              if (mouse.y < height / 2) root.adjustMinute(1)
              else root.adjustMinute(-1)
            }
          }
        }
      }

      // Presets
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        Repeater {
          model: [0, 15, 30, 45]

          Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 18
            radius: 5
            readonly property bool isActive: root.minute === modelData
            color: isActive ? Style.accentCyan : Style.surfaceVariant

            Text {
              anchors.centerIn: parent
              text: ":" + (modelData === 0 ? "00" : modelData)
              font.pixelSize: 8
              font.weight: isActive ? Font.Bold : Font.Normal
              color: isActive ? "#000000" : Style.textPrimary
            }

            TapHandler {
              onTapped: {
                root.setMinute(modelData)
                root.showPopup = false
              }
            }
          }
        }
      }

      // Confirm / Close
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 18
        radius: 4
        color: closePopHover.hovered ? Style.accentHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "Tamam"
          font.pixelSize: 8
          font.weight: Font.DemiBold
          color: Style.textPrimary
        }

        HoverHandler { id: closePopHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.showPopup = false }
      }
    }
  }
}
