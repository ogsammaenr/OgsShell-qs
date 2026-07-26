import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  signal toggleControlCenter(string targetMonitor, string page)
  signal toggleTimeManager(string targetMonitor)
  signal toggleCalendar(string targetMonitor)
  signal toggleAppLauncher(string targetMonitor)
  signal toggleAppDashboard(string targetMonitor)

  function getFocusedMonitorName() {
    var state = workspaceService.workspaceState;
    if (state && state.monitors) {
      for (var i = 0; i < state.monitors.length; i++) {
        var m = state.monitors[i];
        if (m.focused) {
          return m.name;
        }
      }
    }
    return "";
  }

  Process {
    id: ipcListener
    command: ["sh", "-c", "PIPE=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ogsshell-ipc\"; [ -p \"$PIPE\" ] || mkfifo \"$PIPE\"; exec tail -f \"$PIPE\""]
    running: true

    stdout: SplitParser {
      onRead: (line) => {
        var cmd = line.trim();
        if (cmd === "") return;

        var focusedMonitor = service.getFocusedMonitorName();

        if (cmd.startsWith("control_center")) {
          var parts = cmd.split(":");
          var page = parts.length > 1 ? parts[1] : "";
          service.toggleControlCenter(focusedMonitor, page);
        } else if (cmd === "time_manager") {
          service.toggleTimeManager(focusedMonitor);
        } else if (cmd === "calendar") {
          service.toggleCalendar(focusedMonitor);
        } else if (cmd === "app_launcher") {
          service.toggleAppLauncher(focusedMonitor);
        } else if (cmd === "app_dashboard") {
          service.toggleAppDashboard(focusedMonitor);
        }
      }
    }
  }
}
