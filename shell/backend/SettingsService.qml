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

  function executeScript(scriptName, extraArgs) {
    let home = Quickshell.env("HOME") || "/home/excalibur"
    let p1 = home + "/WorkSpace/projects/OgsShell-qs/scripts/" + scriptName
    let p2 = "/home/excalibur/WorkSpace/projects/OgsShell-qs/scripts/" + scriptName
    let extra = extraArgs ? (" " + extraArgs) : ""
    let bashCmd = "if [ -f '" + p1 + "' ]; then bash '" + p1 + "'" + extra + "; " +
      "elif [ -f '" + p2 + "' ]; then bash '" + p2 + "'" + extra + "; " +
      "else echo '[SettingsService ERROR] Script not found: " + scriptName + "'; exit 1; fi"

    console.log("[SettingsService] Executing script: " + scriptName)
    proc.running = false
    proc.command = ["/usr/bin/bash", "-c", bashCmd]
    proc.running = true
  }

  function open(category) {
    console.log("[SettingsService] open() called with category:", category || "default")
    executeScript("open_settings_app.sh")
  }

  function close() {
    console.log("[SettingsService] close() called. Terminating settings_app...")
    proc.running = false
    proc.command = ["/usr/bin/pkill", "-f", "quickshell.*settings_app"]
    proc.running = true
  }

  function toggle(category) {
    console.log("[SettingsService] toggle() called with category:", category || "default")
    executeScript("toggle_settings.sh")
  }
}
