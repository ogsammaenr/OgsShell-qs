import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property var appList: []
  property bool isLoading: false

  signal scanFinished()

  function refresh() {
    if (isLoading) return;
    isLoading = true;
    scanProc.running = true;
  }

  Process {
    id: scanProc
    command: ["/home/excalibur/WorkSpace/projects/OgsShell-qs/services/app_launcher_helper"]
    running: false

    stdout: SplitParser {
      onRead: (line) => {
        try {
          var data = JSON.parse(line);
          if (Array.isArray(data)) {
            service.appList = data;
          }
        } catch (e) {
          console.log("Error parsing launcher JSON: " + e);
        }
      }
    }

    onRunningChanged: {
      if (!running) {
        service.isLoading = false;
        service.scanFinished();
      }
    }
  }

  Component.onCompleted: {
    refresh();
  }
}
