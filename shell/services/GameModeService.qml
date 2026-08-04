import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property bool isGameModeActive: false
  property bool isInitialized: false

  onIsGameModeActiveChanged: {
    if (!isInitialized) return;

    // Save state and trigger Hyprland reload to apply or revert lua/profiles/gamemode.lua
    var stateValue = isGameModeActive ? "1" : "0";
    Quickshell.execDetached([
      "sh", "-c",
      "mkdir -p ~/.config/ogsshell/state && echo -n '" + stateValue + "' > ~/.config/ogsshell/state/gamemode && hyprctl reload"
    ]);
  }

  function toggleGameMode() {
    isGameModeActive = !isGameModeActive;
  }

  Process {
    id: stateLoader
    command: ["sh", "-c", "cat ~/.config/ogsshell/state/gamemode 2>/dev/null || echo '0'"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        var val = line.trim();
        service.isGameModeActive = (val === "1" || val === "true");
        service.isInitialized = true;
      }
    }
  }
}
