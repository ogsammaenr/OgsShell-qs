import QtQuick
import QtQuick.Layouts
import "../../.."

Item {
  id: root

  property var ipc
  property string activeTab: "WORLD" // "WORLD" | "POMODORO" | "STOPWATCH" | "ALARMS"

  readonly property int activeIndex: {
    if (activeTab === "WORLD") return 0
    if (activeTab === "POMODORO") return 1
    if (activeTab === "STOPWATCH") return 2
    if (activeTab === "ALARMS") return 3
    return 0
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 12

    // ==========================================
    // Apple-Style Sliding Segmented Control
    // Clean, minimalist typography with continuous spring thumb
    // ==========================================
    Rectangle {
      id: segmentTrack
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      radius: 16
      color: Style.surface
      border.color: Style.border
      border.width: 1

      // Sliding Selection Capsule Thumb
      Rectangle {
        id: selectionThumb
        y: 3
        height: parent.height - 6
        width: (segmentTrack.width - 8) / 4
        x: 4 + (root.activeIndex * width)
        radius: 13
        color: Style.surfaceActive

        Behavior on x {
          SpringAnimation {
            spring: 32.0
            damping: 0.82
            epsilon: 0.01
          }
        }
      }

      // Segment Labels Row
      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 0

        // Tab 0: Saat
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          Text {
            anchors.centerIn: parent
            text: "Saat"
            color: root.activeTab === "WORLD" ? Style.textPrimary : Style.textSecondary
            font.pixelSize: 12
            font.weight: root.activeTab === "WORLD" ? Font.Bold : Font.Medium
          }

          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.activeTab = "WORLD" }
        }

        // Tab 1: Pomodoro
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          Text {
            anchors.centerIn: parent
            text: "Pomodoro"
            color: root.activeTab === "POMODORO" ? Style.textPrimary : Style.textSecondary
            font.pixelSize: 12
            font.weight: root.activeTab === "POMODORO" ? Font.Bold : Font.Medium
          }

          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.activeTab = "POMODORO" }
        }

        // Tab 2: Kronometre
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          Text {
            anchors.centerIn: parent
            text: "Kronometre"
            color: root.activeTab === "STOPWATCH" ? Style.textPrimary : Style.textSecondary
            font.pixelSize: 12
            font.weight: root.activeTab === "STOPWATCH" ? Font.Bold : Font.Medium
          }

          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.activeTab = "STOPWATCH" }
        }

        // Tab 3: Alarmlar
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          Text {
            anchors.centerIn: parent
            text: "Alarmlar"
            color: root.activeTab === "ALARMS" ? Style.textPrimary : Style.textSecondary
            font.pixelSize: 12
            font.weight: root.activeTab === "ALARMS" ? Font.Bold : Font.Medium
          }

          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.activeTab = "ALARMS" }
        }
      }
    }

    // ==========================================
    // Tab Content Canvas (Lazy Loaded via Loaders)
    // ==========================================
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      Loader {
        anchors.fill: parent
        active: root.activeTab === "WORLD"
        visible: active
        sourceComponent: WorldClockTab {}
      }

      Loader {
        anchors.fill: parent
        active: root.activeTab === "POMODORO"
        visible: active
        sourceComponent: PomodoroTab {}
      }

      Loader {
        anchors.fill: parent
        active: root.activeTab === "STOPWATCH"
        visible: active
        sourceComponent: StopwatchTab {}
      }

      Loader {
        anchors.fill: parent
        active: root.activeTab === "ALARMS"
        visible: active
        sourceComponent: AlarmsTab {
          ipc: root.ipc
        }
      }
    }
  }
}
