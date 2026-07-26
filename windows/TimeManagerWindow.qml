import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: timeManagerWindow
  required property var targetScreen
  required property var monitorGroup

  screen: targetScreen
  visible: monitorGroup.isTimeManagerOpen || (timeManagerInstance.opacity > 0.01)
  WlrLayershell.layer: WlrLayer.Overlay
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  
  exclusiveZone: -1 // Float over windows
  aboveWindows: true
  color: "transparent"
  
  MouseArea {
    anchors.fill: parent
    onClicked: {
      monitorGroup.isTimeManagerOpen = false;
    }
  }
  
  TimeManager {
    id: timeManagerInstance
    theme: monitorGroup.theme
    isOpen: monitorGroup.isTimeManagerOpen
    
    stopwatchTime: timeService.stopwatchTime
    stopwatchRunning: timeService.stopwatchRunning
    
    pomodoroTime: timeService.pomodoroTime
    pomodoroRunning: timeService.pomodoroRunning
    pomodoroState: timeService.pomodoroState
    pomodoroWorkDuration: timeService.pomodoroWorkDuration
    pomodoroBreakDuration: timeService.pomodoroBreakDuration
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    
    anchors.topMargin: 2
    width: monitorGroup.isTimeManagerOpen ? 340 : 80
    height: monitorGroup.isTimeManagerOpen ? 240 : 28
    opacity: monitorGroup.isTimeManagerOpen ? 1.0 : 0.0
    scale: monitorGroup.isTimeManagerOpen ? 1.0 : 0.8
    
    Behavior on width {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    Behavior on height {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    Behavior on opacity {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    
    onStopwatchToggleRequested: {
      timeService.stopwatchRunning = !timeService.stopwatchRunning;
    }
    onStopwatchResetRequested: {
      timeService.stopwatchRunning = false;
      timeService.stopwatchTime = 0;
    }
    onPomodoroToggleRequested: {
      timeService.pomodoroRunning = !timeService.pomodoroRunning;
    }
    onPomodoroSkipRequested: {
      timeService.pomodoroRunning = false;
      if (timeService.pomodoroState === "Work") {
        timeService.pomodoroState = "Break";
        timeService.pomodoroTime = timeService.pomodoroBreakDuration * 60;
      } else {
        timeService.pomodoroState = "Work";
        timeService.pomodoroTime = timeService.pomodoroWorkDuration * 60;
      }
    }
    onPomodoroWorkDurationAdjust: (val) => {
      timeService.pomodoroWorkDuration = val;
      if (timeService.pomodoroState === "Work") {
        timeService.pomodoroTime = val * 60;
      }
    }
    onPomodoroBreakDurationAdjust: (val) => {
      timeService.pomodoroBreakDuration = val;
      if (timeService.pomodoroState === "Break") {
        timeService.pomodoroTime = val * 60;
      }
    }
  }
}
