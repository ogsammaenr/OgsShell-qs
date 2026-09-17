pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  visible: false

  Process {
    id: proc

    onExited: (code, status) => {
      console.log("[SettingsService] Script process exited with code:", code, "status:", status)
    }

    stdout: SplitParser {
      onRead: data => console.log("[SettingsService STDOUT]", data)
    }

    stderr: SplitParser {
      onRead: data => console.warn("[SettingsService STDERR]", data)
    }
  }

  function executeCommand(subcommand, extraArgs) {
    let home = Quickshell.env("HOME") || "/home/excalibur"
    let pUser = home + "/.config/ogsShell/ogsshell.sh"
    let p1 = home + "/Workspace/projects/OgsShell-qs/scripts/ogsshell.sh"
    let p2 = "/home/excalibur/Workspace/projects/OgsShell-qs/scripts/ogsshell.sh"
    let extra = extraArgs ? (" " + extraArgs) : ""
    let bashCmd = "if [ -x '" + pUser + "' ]; then '" + pUser + "' " + subcommand + extra + "; " +
      "elif [ -x '" + p1 + "' ]; then '" + p1 + "' " + subcommand + extra + "; " +
      "elif [ -x '" + p2 + "' ]; then '" + p2 + "' " + subcommand + extra + "; " +
      "else echo '[SettingsService ERROR] ogsshell.sh not found'; exit 1; fi"

    console.log("[SettingsService] Executing ogsshell command: " + subcommand)
    proc.running = false
    proc.command = ["/usr/bin/bash", "-c", bashCmd]
    proc.running = true
  }

  function open(category) {
    console.log("[SettingsService] open() called with category:", category || "default")
    executeCommand("open_settings")
  }

  function close() {
    console.log("[SettingsService] close() called. Terminating settings_app...")
    proc.running = false
    proc.command = ["/usr/bin/pkill", "-f", "quickshell.*settings_app"]
    proc.running = true
  }

  function toggle(category) {
    console.log("[SettingsService] toggle() called with category:", category || "default")
    executeCommand("toggle_settings")
  }
}
