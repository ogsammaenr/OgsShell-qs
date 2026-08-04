import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  readonly property string binDir: (typeof Quickshell !== "undefined" && Quickshell.env("ROOT_DIR"))
                                     ? Quickshell.env("ROOT_DIR") + "/bin"
                                     : "/home/excalibur/WorkSpace/projects/OgsShell-qs/bin"

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
    command: [service.binDir + "/app_launcher_helper"]
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
