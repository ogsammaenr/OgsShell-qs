import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  readonly property string binDir: (typeof Quickshell !== "undefined" && Quickshell.env("ROOT_DIR"))
                                     ? Quickshell.env("ROOT_DIR") + "/bin"
                                     : "/home/excalibur/WorkSpace/projects/OgsShell-qs/bin"

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
      syncProc.command = [service.binDir + "/theme_sync_helper", service.activeTheme];
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
