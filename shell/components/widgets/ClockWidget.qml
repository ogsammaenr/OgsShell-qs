import QtQuick
import "../.."

Item {
  id: root

  property bool hoverMode: false

  // Signals emitted for time click (Clock App) vs date click (Calendar App)
  signal timeClicked(string targetTab)
  signal dateClicked()
  signal clicked(string targetTab) // Backward compatibility

  readonly property bool isLiveActivity: ClockManager.activeLiveActivity !== "none"

  implicitWidth: Math.max(timeContainer.width, dateText.implicitWidth)
  implicitHeight: 32

  // ==========================================
  // Primary Time Container (Glides vertically on hover)
  // ==========================================
  Item {
    id: timeContainer
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: root.hoverMode ? -8 : 0

    width: rowContent.implicitWidth
    height: rowContent.implicitHeight

    Behavior on anchors.verticalCenterOffset {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutCubic
      }
    }

    HoverHandler {
      id: timeHover
      cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
      onTapped: {
        root.timeClicked(ClockManager.liveActivityTargetTab)
        root.clicked(ClockManager.liveActivityTargetTab)
      }
    }

    Row {
      id: rowContent
      anchors.centerIn: parent
      spacing: 6

      // Animated Live Pulse Indicator Dot (Visible ONLY when a Live Activity is active)
      Item {
        id: dotContainer
        width: (root.hoverMode || !root.isLiveActivity) ? 0 : 6
        height: 6
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        visible: root.isLiveActivity

        Behavior on width {
          NumberAnimation {
            duration: Config.animation.duration_compact
            easing.type: Easing.OutCubic
          }
        }

        // Live Pulse Dot
        Rectangle {
          width: 6
          height: 6
          radius: 3
          color: ClockManager.liveActivityColor
          anchors.centerIn: parent
          opacity: (root.hoverMode || !root.isLiveActivity) ? 0.0 : 1.0
          scale: (root.hoverMode || !root.isLiveActivity) ? 0.0 : 1.0

          Behavior on opacity { NumberAnimation { duration: 180 } }
          Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 200 } }

          SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: !root.hoverMode && root.isLiveActivity
            PropertyAnimation { from: 0.4; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
            PropertyAnimation { from: 1.0; to: 0.4; duration: 1500; easing.type: Easing.InOutQuad }
          }
        }
      }

      // Single Continuous Time / Live Timer Text Element
      Text {
        id: timeText
        anchors.verticalCenter: parent.verticalCenter
        text: root.isLiveActivity ? ClockManager.liveActivityTitle : ClockManager.currentDisplayTime
        color: root.isLiveActivity ? ClockManager.liveActivityColor : Style.textPrimary
        font.pixelSize: root.hoverMode ? 17 : 13
        font.weight: root.hoverMode ? Font.Bold : Font.DemiBold
        font.letterSpacing: root.hoverMode ? 0.5 : 0.3

        Behavior on font.pixelSize {
          NumberAnimation {
            duration: Config.animation.duration_compact
            easing.type: Easing.OutCubic
          }
        }
      }
    }
  }

  // ==========================================
  // Date / Subtitle Text (Slides in from below on hover)
  // Clicking the date opens the Calendar & Event App!
  // ==========================================
  Text {
    id: dateText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: timeContainer.bottom
    anchors.topMargin: root.hoverMode ? 2 : 4
    text: root.isLiveActivity ? ClockManager.liveActivitySubtitle : ClockManager.currentDisplayDate
    color: dateHover.hovered ? Style.textPrimary : Style.textMuted
    font.pixelSize: 11
    font.weight: Font.Medium
    font.letterSpacing: 0.3
    opacity: root.hoverMode ? 1.0 : 0.0
    scale: root.hoverMode ? 1.0 : 0.85
    visible: opacity > 0.0

    Behavior on color { ColorAnimation { duration: 150 } }

    Behavior on opacity {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutQuad
      }
    }

    Behavior on anchors.topMargin {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutCubic
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutCubic
      }
    }

    HoverHandler {
      id: dateHover
      cursorShape: Qt.PointingHandCursor
      enabled: root.hoverMode
    }

    TapHandler {
      enabled: root.hoverMode
      onTapped: {
        root.dateClicked()
      }
    }
  }
}
