import Quickshell
import QtQuick

Item {
  id: service

  // Global Time Manager states & timers
  property int stopwatchTime: 0
  property bool stopwatchRunning: false
  
  property int pomodoroTime: 1500
  property bool pomodoroRunning: false
  property string pomodoroState: "Work"
  property int pomodoroWorkDuration: 25
  property int pomodoroBreakDuration: 5

  Timer {
    id: globalStopwatchTimer
    interval: 10
    running: service.stopwatchRunning
    repeat: true
    property double lastTime: 0.0
    onTriggered: {
      var now = Date.now();
      if (lastTime > 0.0) {
        service.stopwatchTime += (now - lastTime);
      }
      lastTime = now;
    }
    onRunningChanged: {
      if (running) {
        lastTime = Date.now();
      } else {
        lastTime = 0.0;
      }
    }
  }

  Timer {
    id: globalPomodoroTimer
    interval: 1000
    running: service.pomodoroRunning
    repeat: true
    onTriggered: {
      if (service.pomodoroTime > 0) {
        service.pomodoroTime--;
      } else {
        if (service.pomodoroState === "Work") {
          service.pomodoroState = "Break";
          service.pomodoroTime = service.pomodoroBreakDuration * 60;
        } else {
          service.pomodoroState = "Work";
          service.pomodoroTime = service.pomodoroWorkDuration * 60;
        }
        Quickshell.execDetached(["notify-send", "Pomodoro", service.pomodoroState === "Work" ? "Çalışma süresi başladı!" : "Mola süresi başladı!"]);
      }
    }
  }
}
