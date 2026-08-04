import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property var clipboardItems: []
  property bool isLoading: false
  property string lineBuffer: ""

  // List Process
  Process {
    id: listProcess
    command: ["sh", "-c", "cliphist list"]
    running: false

    stdout: SplitParser {
      onRead: (line) => {
        service.lineBuffer += line + "\n";
      }
    }

    onRunningChanged: {
      if (!running) {
        var lines = service.lineBuffer.split("\n");
        var list = [];
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line === "") continue;
          var tabIdx = line.indexOf("\t");
          if (tabIdx !== -1) {
            var id = line.substring(0, tabIdx).trim();
            var text = line.substring(tabIdx + 1).trim();
            list.push({
              "id": id,
              "text": text,
              "raw": line
            });
          }
        }
        service.clipboardItems = list;
        service.lineBuffer = "";
        service.isLoading = false;
      }
    }
  }

  function refresh() {
    if (isLoading) return;
    isLoading = true;
    lineBuffer = "";
    listProcess.running = true;
  }

  function copyItem(id) {
    var cmd = "printf '%s' " + JSON.stringify(id) + " | cliphist decode | wl-copy";
    Quickshell.execDetached(["sh", "-c", cmd]);
    
    var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; }", service);
    timer.triggered.connect(() => {
      service.refresh();
      timer.destroy();
    });
  }

  function deleteItem(rawLine) {
    var cmd = "printf '%s' " + JSON.stringify(rawLine) + " | cliphist delete";
    Quickshell.execDetached(["sh", "-c", cmd]);

    var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; }", service);
    timer.triggered.connect(() => {
      service.refresh();
      timer.destroy();
    });
  }

  function clearHistory() {
    Quickshell.execDetached(["cliphist", "wipe"]);
    var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 300; running: true; repeat: false; }", service);
    timer.triggered.connect(() => {
      service.refresh();
      timer.destroy();
    });
  }

  Component.onCompleted: {
    refresh();
  }
}
