import QtQuick
import Quickshell

Rectangle {
  id: root
  required property var theme
  required property bool isOpen

  signal closeRequested()

  // Signals to notify parent shell.qml of user actions (prevents binding breakage)
  signal stopwatchToggleRequested()
  signal stopwatchResetRequested()

  signal pomodoroToggleRequested()
  signal pomodoroSkipRequested()
  signal pomodoroWorkDurationAdjust(int newVal)
  signal pomodoroBreakDurationAdjust(int newVal)

  radius: 16
  clip: true
  color: theme.bg
  border.color: theme.border
  border.width: 1

  property string activeTab: "clock" // "clock", "stopwatch", "pomodoro"

  // Disable click propagation
  MouseArea {
    anchors.fill: parent
    onPressed: (mouse) => mouse.accepted = true
  }

  // 1. Clock Tab Logic
  property var currentTime: new Date()
  Timer {
    interval: 100
    running: root.isOpen && root.activeTab === "clock"
    repeat: true
    onTriggered: {
      currentTime = new Date();
    }
  }

  // 2. Stopwatch Tab Logic (State synced from shell.qml)
  property int stopwatchTime: 0
  property bool stopwatchRunning: false

  function formatStopwatch(ms) {
    var min = Math.floor(ms / 60000);
    var sec = Math.floor((ms % 60000) / 1000);
    var cent = Math.floor((ms % 1000) / 10);
    return (min < 10 ? "0" : "") + min + ":" +
           (sec < 10 ? "0" : "") + sec + "." +
           (cent < 10 ? "0" : "") + cent;
  }

  // 3. Pomodoro Tab Logic (State synced from shell.qml)
  property int pomodoroTime: 1500
  property bool pomodoroRunning: false
  property string pomodoroState: "Work"
  property int pomodoroWorkDuration: 25
  property int pomodoroBreakDuration: 5

  function formatPomodoro(s) {
    var min = Math.floor(s / 60);
    var sec = s % 60;
    return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
  }

  Column {
    id: mainContent
    width: 288
    height: 208
    anchors.centerIn: parent
    spacing: 16
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    // A. Main Content Display Area (Switches based on activeTab)
    Item {
      width: parent.width
      height: 140

      // Tab 1: Digital Clock View
      Column {
        anchors.centerIn: parent
        visible: root.activeTab === "clock"
        spacing: 8

        Text {
          text: Qt.formatDateTime(root.currentTime, "hh:mm:ss")
          color: theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 42; weight: Font.Bold }
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          text: Qt.formatDateTime(root.currentTime, "d MMMM yyyy dddd")
          color: theme.textSecondary
          font { family: "JetBrains Mono"; pixelSize: 12 }
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }

      // Tab 2: Stopwatch View
      Column {
        anchors.centerIn: parent
        visible: root.activeTab === "stopwatch"
        spacing: 12

        Text {
          text: root.formatStopwatch(root.stopwatchTime)
          color: theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 38; weight: Font.Bold }
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
          spacing: 16
          anchors.horizontalCenter: parent.horizontalCenter

          // Start / Pause
          Rectangle {
            width: 80
            height: 30
            radius: 6
            color: root.stopwatchRunning ? "#22f97316" : "#2222c55e"
            border.color: root.stopwatchRunning ? "#f97316" : "#22c55e"
            border.width: 1

            Text {
              text: root.stopwatchRunning ? "Durdur" : "Başlat"
              color: root.stopwatchRunning ? "#f97316" : "#22c55e"
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              anchors.centerIn: parent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.stopwatchToggleRequested();
              }
            }
          }

          // Reset
          Rectangle {
            width: 80
            height: 30
            radius: 6
            color: "#22ef4444"
            border.color: "#ef4444"
            border.width: 1

            Text {
              text: "Sıfırla"
              color: "#ef4444"
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              anchors.centerIn: parent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.stopwatchResetRequested();
              }
            }
          }
        }
      }

      // Tab 3: Pomodoro View
      Column {
        anchors.centerIn: parent
        visible: root.activeTab === "pomodoro"
        spacing: 8

        Text {
          text: root.pomodoroState === "Work" ? "Çalışma Zamanı" : "Mola Zamanı"
          color: root.pomodoroState === "Work" ? theme.accent : "#22c55e"
          font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          text: root.formatPomodoro(root.pomodoroTime)
          color: theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 32; weight: Font.Bold }
          anchors.horizontalCenter: parent.horizontalCenter
        }

        // Duration Adjusters (only visible when not running)
        Row {
          spacing: 12
          anchors.horizontalCenter: parent.horizontalCenter
          visible: !root.pomodoroRunning

          Row {
            spacing: 6
            Text { text: "Çalışma:"; color: theme.textSecondary; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
            
            Rectangle {
              width: 14; height: 14; radius: 3; color: "#20ffffff"
              Text { text: "-"; color: theme.textPrimary; font.pixelSize: 10; anchors.centerIn: parent }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.pomodoroWorkDuration > 1) {
                    root.pomodoroWorkDurationAdjust(root.pomodoroWorkDuration - 1);
                  }
                }
              }
            }
            
            Text {
              text: root.pomodoroWorkDuration + "m"
              color: theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
              anchors.verticalCenter: parent.verticalCenter
            }
            
            Rectangle {
              width: 14; height: 14; radius: 3; color: "#20ffffff"
              Text { text: "+"; color: theme.textPrimary; font.pixelSize: 10; anchors.centerIn: parent }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.pomodoroWorkDurationAdjust(root.pomodoroWorkDuration + 1);
                }
              }
            }
          }

          Text { text: "|"; color: "#20ffffff"; anchors.verticalCenter: parent.verticalCenter }

          Row {
            spacing: 6
            Text { text: "Mola:"; color: theme.textSecondary; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
            
            Rectangle {
              width: 14; height: 14; radius: 3; color: "#20ffffff"
              Text { text: "-"; color: theme.textPrimary; font.pixelSize: 10; anchors.centerIn: parent }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.pomodoroBreakDuration > 1) {
                    root.pomodoroBreakDurationAdjust(root.pomodoroBreakDuration - 1);
                  }
                }
              }
            }
            
            Text {
              text: root.pomodoroBreakDuration + "m"
              color: theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
              anchors.verticalCenter: parent.verticalCenter
            }
            
            Rectangle {
              width: 14; height: 14; radius: 3; color: "#20ffffff"
              Text { text: "+"; color: theme.textPrimary; font.pixelSize: 10; anchors.centerIn: parent }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.pomodoroBreakDurationAdjust(root.pomodoroBreakDuration + 1);
                }
              }
            }
          }
        }

        // Space when running to maintain layout alignment
        Item {
          width: 1; height: 14
          visible: root.pomodoroRunning
        }

        Row {
          spacing: 16
          anchors.horizontalCenter: parent.horizontalCenter

          // Start / Pause
          Rectangle {
            width: 80
            height: 30
            radius: 6
            color: root.pomodoroRunning ? "#22f97316" : "#2222c55e"
            border.color: root.pomodoroRunning ? "#f97316" : "#22c55e"
            border.width: 1

            Text {
              text: root.pomodoroRunning ? "Durdur" : "Başlat"
              color: root.pomodoroRunning ? "#f97316" : "#22c55e"
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              anchors.centerIn: parent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.pomodoroToggleRequested();
              }
            }
          }

          // Reset/Skip
          Rectangle {
            width: 80
            height: 30
            radius: 6
            color: "#223b82f6"
            border.color: "#3b82f6"
            border.width: 1

            Text {
              text: "Atla"
              color: "#3b82f6"
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              anchors.centerIn: parent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.pomodoroSkipRequested();
              }
            }
          }
        }
      }
    }

    // Faint Separator
    Rectangle {
      width: parent.width
      height: 1
      color: "#15ffffff"
    }

    // B. Navigation Buttons Row
    Row {
      width: parent.width
      height: 36
      spacing: 8

      property real btnWidth: (width - 16) / 3

      // Tab button: Clock
      Rectangle {
        width: parent.btnWidth
        height: parent.height
        radius: 8
        color: root.activeTab === "clock" ? theme.accent : theme.buttonBg

        Text {
          text: "Saat"
          color: root.activeTab === "clock" ? theme.textOnAccent : theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          anchors.centerIn: parent
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.activeTab = "clock"; }
        }
      }

      // Tab button: Stopwatch
      Rectangle {
        width: parent.btnWidth
        height: parent.height
        radius: 8
        color: root.activeTab === "stopwatch" ? theme.accent : theme.buttonBg

        Text {
          text: "Kronometre"
          color: root.activeTab === "stopwatch" ? theme.textOnAccent : theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          anchors.centerIn: parent
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.activeTab = "stopwatch"; }
        }
      }

      // Tab button: Pomodoro
      Rectangle {
        width: parent.btnWidth
        height: parent.height
        radius: 8
        color: root.activeTab === "pomodoro" ? theme.accent : theme.buttonBg

        Text {
          text: "Pomodoro"
          color: root.activeTab === "pomodoro" ? theme.textOnAccent : theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          anchors.centerIn: parent
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.activeTab = "pomodoro"; }
        }
      }
    }
  }
}
