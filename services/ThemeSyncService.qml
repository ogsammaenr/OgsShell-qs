import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property string activeTheme: "nord"

  onActiveThemeChanged: {
    syncTimer.restart();
  }

  // Debounce timer to prevent rapid theme triggers
  Timer {
    id: syncTimer
    interval: 50
    repeat: false
    onTriggered: {
      if (syncProc.running) {
        syncProc.running = false;
      }
      syncProc.command = ["/home/excalibur/WorkSpace/projects/OgsShell-qs/services/theme_sync_helper", service.activeTheme];
      syncProc.running = true;
    }
  }

  Process {
    id: syncProc
    running: false
  }

  Component.onCompleted: {
    syncTimer.restart();
  }
}
