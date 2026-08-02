import Quickshell
import Quickshell.Io
import QtQuick
import "services"
import "windows"

ShellRoot {
  id: root

  property bool isPowerMenuOpen: false
  property string activeTheme: "nord" // Switch between: "catppuccin", "nord", "gruvbox", "monochrome"

  onActiveThemeChanged: {
    Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.config/ogsshell/state && echo -n '" + activeTheme + "' > ~/.config/ogsshell/state/theme"]);
  }

  Process {
    id: themeLoader
    command: ["sh", "-c", "cat ~/.config/ogsshell/state/theme 2>/dev/null || cat ~/.config/ogsshell/theme 2>/dev/null || true"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        var themeName = line.trim();
        if (themeName !== "") {
          root.activeTheme = themeName;
        }
      }
    }
  }

  // Public Holidays fetched once at startup
  property var apiHolidays: []

  function fetchHolidays() {
    var year = new Date().getFullYear();
    var url = "https://date.nager.at/api/v4/Holidays/TR" + year;
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            var data = JSON.parse(xhr.responseText);
            root.apiHolidays = data;
          } catch(e) {
            console.log("Error parsing holidays JSON: " + e);
          }
        } else {
          console.log("Error fetching holidays: status " + xhr.status);
        }
      }
    }
    xhr.open("GET", url);
    xhr.send();
  }

  Component.onCompleted: {
    fetchHolidays();
  }

  // System Clock service
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // Global Services
  WorkspaceService {
    id: workspaceService
  }

  SystemStatsService {
    id: systemStatsService
  }

  TimeService {
    id: timeService
  }

  NetworkManagerService {
    id: networkManagerService
  }

  ClipboardService {
    id: clipboardService
  }

  BluetoothService {
    id: bluetoothService
  }

  ShellIpcService {
    id: shellIpcService
  }

  AppLauncherService {
    id: appLauncherService
  }

  ThemeConfigService {
    id: themeConfigService
    activeTheme: root.activeTheme
  }

  WallpaperService {
    id: wallpaperService
    activeTheme: root.activeTheme
  }

  ThemeSyncService {
    id: themeSyncService
    activeTheme: root.activeTheme
  }

  GameModeService {
    id: gameModeService
  }

  AudioMixerService {
    id: audioMixerService
  }

  // Monitor-specific Window Groups
  Variants {
    model: Quickshell.screens
    MonitorGroup {}
  }

  // Global Power Menu Overlay Window
  PowerMenuWindow {}
}
