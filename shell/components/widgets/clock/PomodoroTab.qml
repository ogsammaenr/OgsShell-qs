import QtQuick
import QtQuick.Layouts
import "../../.."

Item {
  id: root

  property bool showSettingsView: false

  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // ==========================================
    // Phase Segment Selector (Çalışma / Mola)
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 28
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1
      visible: !root.showSettingsView

      RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2

        // Work Phase
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 12
          color: ClockManager.pomodoroPhase === "work" ? Style.surfaceActive : "transparent"

          Text {
            anchors.centerIn: parent
            text: "Çalışma (" + ClockManager.pomodoroWorkMinutes + " dk)"
            color: ClockManager.pomodoroPhase === "work" ? Style.textPrimary : Style.textSecondary
            font.pixelSize: 10
            font.weight: ClockManager.pomodoroPhase === "work" ? Font.DemiBold : Font.Normal
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ClockManager.setPomodoroPhase("work")
          }
        }

        // Break Phase
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 12
          color: ClockManager.pomodoroPhase === "break" ? Style.surfaceActive : "transparent"

          Text {
            anchors.centerIn: parent
            text: "Mola (" + ClockManager.pomodoroBreakMinutes + " dk)"
            color: ClockManager.pomodoroPhase === "break" ? Style.textPrimary : Style.textSecondary
            font.pixelSize: 10
            font.weight: ClockManager.pomodoroPhase === "break" ? Font.DemiBold : Font.Normal
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ClockManager.setPomodoroPhase("break")
          }
        }
      }
    }

    // ==========================================
    // View 1: Main Timer & Target Stack Canvas
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1
      visible: !root.showSettingsView

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        Item { Layout.fillHeight: true }

        // Hero Countdown Display
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: ClockManager.pomodoroFormattedTime
          color: Style.textPrimary
          font.pixelSize: 40
          font.weight: Font.DemiBold
          font.letterSpacing: -0.5
        }

        // Subtitle Status Label
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: {
            if (ClockManager.pomodoroRunning) {
              return ClockManager.pomodoroPhase === "work" ? "Odaklanma Seansı" : "Mola Süresi"
            }
            if (ClockManager.pomodoroRemainingSec < ClockManager.pomodoroTotalSec && ClockManager.pomodoroRemainingSec > 0) {
              return "Duraklatıldı"
            }
            return ClockManager.pomodoroPhase === "work" ? "Çalışmaya Başlamaya Hazır" : "Molaya Başlamaya Hazır"
          }
          color: ClockManager.pomodoroRunning ? Style.accentOrange : Style.textSecondary
          font.pixelSize: 11
          font.weight: Font.Normal
        }

        // Minimalist Keyline Progress Bar
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 3
          radius: 1.5
          color: Style.surfaceVariant

          Rectangle {
            height: parent.height
            width: Math.max(3, parent.width * ClockManager.pomodoroProgress)
            radius: 1.5
            color: ClockManager.pomodoroPhase === "work" ? Style.accentOrange : Style.accentCyan

            Behavior on width {
              NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }
          }
        }

        Item { Layout.preferredHeight: 4 }

        // ==========================================
        // Visual Target Stack (Hedef Stack Göstergesi)
        // ==========================================
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          // Stack Header Info
          RowLayout {
            Layout.fillWidth: true

            Text {
              text: "Hedef Seanslar"
              color: Style.textSecondary
              font.pixelSize: 10
              font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            Text {
              text: {
                if (ClockManager.pomodoroCompletedSessions >= ClockManager.pomodoroTargetSessions) {
                  return "🎉 Hedef Tamamlandı (" + ClockManager.pomodoroCompletedSessions + "/" + ClockManager.pomodoroTargetSessions + ")"
                }
                return ClockManager.pomodoroCompletedSessions + " / " + ClockManager.pomodoroTargetSessions + " Seans"
              }
              color: ClockManager.pomodoroCompletedSessions >= ClockManager.pomodoroTargetSessions ? Style.accentGreen : Style.textPrimary
              font.pixelSize: 10
              font.weight: Font.DemiBold
            }
          }

          // Horizontal Session Stack Slots
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 12
            spacing: 4

            Repeater {
              model: ClockManager.pomodoroTargetSessions

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 4

                readonly property bool isFilled: index < ClockManager.pomodoroCompletedSessions
                readonly property bool isCurrentActive: index === ClockManager.pomodoroCompletedSessions && ClockManager.pomodoroRunning && ClockManager.pomodoroPhase === "work"

                color: {
                  if (isFilled) return Style.accentOrange
                  if (isCurrentActive) return Qt.rgba(1.0, 0.62, 0.04, 0.25)
                  return Style.surfaceVariant
                }

                border.color: {
                  if (isFilled) return Style.accentOrange
                  if (isCurrentActive) return Style.accentOrange
                  return Style.border
                }
                border.width: 1

                Behavior on color {
                  ColorAnimation { duration: 200 }
                }

                // Checkmark in filled slot
                Text {
                  anchors.centerIn: parent
                  text: "✓"
                  color: "#000000"
                  font.pixelSize: 8
                  font.weight: Font.Bold
                  visible: isFilled
                }
              }
            }
          }
        }

        Item { Layout.fillHeight: true }
      }
    }

    // ==========================================
    // View 2: Duration & Target Configuration Panel
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1
      visible: root.showSettingsView

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
          text: "Pomodoro Süre ve Hedef Ayarları"
          color: Style.textPrimary
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        // 1. Work Duration Stepper
        RowLayout {
          Layout.fillWidth: true
          Text { text: "Çalışma"; color: Style.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 80 }

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: decWorkMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
            Text { anchors.centerIn: parent; text: "−"; color: Style.textPrimary; font.pixelSize: 13; font.weight: Font.Bold }
            MouseArea {
              id: decWorkMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClockManager.setWorkMinutes(ClockManager.pomodoroWorkMinutes - 5)
            }
          }

          Text {
            text: ClockManager.pomodoroWorkMinutes + " dk"
            color: Style.textPrimary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: incWorkMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
            Text { anchors.centerIn: parent; text: "+"; color: Style.textPrimary; font.pixelSize: 13; font.weight: Font.Bold }
            MouseArea {
              id: incWorkMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClockManager.setWorkMinutes(ClockManager.pomodoroWorkMinutes + 5)
            }
          }
        }

        // 2. Break Duration Stepper
        RowLayout {
          Layout.fillWidth: true
          Text { text: "Mola"; color: Style.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 80 }

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: decBreakMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
            Text { anchors.centerIn: parent; text: "−"; color: Style.textPrimary; font.pixelSize: 13; font.weight: Font.Bold }
            MouseArea {
              id: decBreakMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClockManager.setBreakMinutes(ClockManager.pomodoroBreakMinutes - 1)
            }
          }

          Text {
            text: ClockManager.pomodoroBreakMinutes + " dk"
            color: Style.textPrimary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: incBreakMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
            Text { anchors.centerIn: parent; text: "+"; color: Style.textPrimary; font.pixelSize: 13; font.weight: Font.Bold }
            MouseArea {
              id: incBreakMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClockManager.setBreakMinutes(ClockManager.pomodoroBreakMinutes + 1)
            }
          }
        }

        // 3. Target Sessions Stepper
        RowLayout {
          Layout.fillWidth: true
          Text { text: "Hedef"; color: Style.textSecondary; font.pixelSize: 11; Layout.preferredWidth: 80 }

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: decTargetMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
            Text { anchors.centerIn: parent; text: "−"; color: Style.textPrimary; font.pixelSize: 13; font.weight: Font.Bold }
            MouseArea {
              id: decTargetMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClockManager.setTargetSessions(ClockManager.pomodoroTargetSessions - 1)
            }
          }

          Text {
            text: ClockManager.pomodoroTargetSessions + " Seans"
            color: Style.accentOrange
            font.pixelSize: 11
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            radius: 6
            color: incTargetMouse.containsMouse ? Style.surfaceActive : Style.surfaceVariant
            Text { anchors.centerIn: parent; text: "+"; color: Style.textPrimary; font.pixelSize: 13; font.weight: Font.Bold }
            MouseArea {
              id: incTargetMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: ClockManager.setTargetSessions(ClockManager.pomodoroTargetSessions + 1)
            }
          }
        }

        Item { Layout.fillHeight: true }
      }
    }

    // ==========================================
    // Action Controls (iOS Minimalist Layout)
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Reset / Stop Action Button
      Rectangle {
        Layout.preferredWidth: 80
        Layout.preferredHeight: 32
        radius: 10
        color: resetMouse.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.border
        border.width: 1
        visible: !root.showSettingsView

        Text {
          anchors.centerIn: parent
          text: "Sıfırla"
          color: Style.textSecondary
          font.pixelSize: 11
          font.weight: Font.Medium
        }

        MouseArea {
          id: resetMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: ClockManager.resetPomodoro()
        }
      }

      // Settings Toggle Button
      Rectangle {
        Layout.preferredWidth: root.showSettingsView ? undefined : 80
        Layout.fillWidth: root.showSettingsView
        Layout.preferredHeight: 32
        radius: 10
        color: setMouse.containsMouse ? Style.surfaceHover : (root.showSettingsView ? Style.surfaceActive : Style.surface)
        border.color: Style.border
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: root.showSettingsView ? "Tamam" : "Ayarlar"
          color: Style.textPrimary
          font.pixelSize: 11
          font.weight: Font.Medium
        }

        MouseArea {
          id: setMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.showSettingsView = !root.showSettingsView
        }
      }

      // Primary Start / Pause / Resume Button
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: 10
        color: ClockManager.pomodoroRunning ? Style.surfaceActive : Style.accentOrange
        visible: !root.showSettingsView

        Text {
          anchors.centerIn: parent
          text: {
            if (ClockManager.pomodoroRunning) return "Duraklat"
            if (ClockManager.pomodoroRemainingSec < ClockManager.pomodoroTotalSec && ClockManager.pomodoroRemainingSec > 0) return "Devam Et"
            return "Başlat"
          }
          color: ClockManager.pomodoroRunning ? Style.textPrimary : "#000000"
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: ClockManager.togglePomodoro()
        }
      }
    }
  }
}
