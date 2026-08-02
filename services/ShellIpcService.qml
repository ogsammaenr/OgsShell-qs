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
  signal toggleWorkspaceSwitcher(string targetMonitor, string action)

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
        } else if (cmd.startsWith("workspace_switcher")) {
          var wsParts = cmd.split(":");
          var action = wsParts.length > 1 ? wsParts[1] : "next";
          service.toggleWorkspaceSwitcher(focusedMonitor, action);
        } else if (cmd.startsWith("gamemode")) {
          var gParts = cmd.split(":");
          var subCmd = gParts.length > 1 ? gParts[1] : "toggle";
          if (typeof gameModeService !== "undefined") {
            if (subCmd === "on" || subCmd === "enable" || subCmd === "1") {
              gameModeService.isGameModeActive = true;
            } else if (subCmd === "off" || subCmd === "disable" || subCmd === "0") {
              gameModeService.isGameModeActive = false;
            } else {
              gameModeService.toggleGameMode();
            }
          }
        }
      }
    }
  }
}
