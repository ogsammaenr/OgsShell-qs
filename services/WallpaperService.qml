import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property string activeTheme: "nord"
  property var wallpaperList: []
  property string currentWallpaper: ""
  property bool isLoading: false
  property string lineBuffer: ""
  property string targetDir: ""

  onActiveThemeChanged: {
    refreshTimer.restart();
  }

  // Listen to themeConfigService activeThemeConfig changes
  Connections {
    target: (typeof themeConfigService !== "undefined") ? themeConfigService : null
    function onActiveThemeConfigChanged() {
      refreshTimer.restart();
    }
  }

  // Timer to debounce refresh and ensure folder resolution is up-to-date
  Timer {
    id: refreshTimer
    interval: 50
    repeat: false
    onTriggered: {
      service.refresh();
      service.restoreWallpaper();
    }
  }

  // Monitor reconnection / screen change listener to automatically re-apply wallpaper to new outputs
  Connections {
    target: Quickshell
    function onScreensChanged() {
      reapplyWallpaperTimer.restart();
    }
  }

  Timer {
    id: reapplyWallpaperTimer
    interval: 800
    repeat: false
    onTriggered: {
      service.restoreWallpaper();
    }
  }

  function getFolderForTheme(themeId) {
    if (typeof themeConfigService !== "undefined" && themeConfigService.activeThemeConfig && themeConfigService.activeThemeConfig.folder) {
      return themeConfigService.activeThemeConfig.folder;
    }
    if (!themeId) return "Nord";
    if (themeId === "catppuccin") return "Catppuccin";
    if (themeId === "nord") return "Nord";
    if (themeId === "gruvbox") return "Gruvbox";
    if (themeId === "monochrome") return "Monochrome";
    return themeId.charAt(0).toUpperCase() + themeId.slice(1);
  }

  readonly property string helperBin: "/home/excalibur/WorkSpace/projects/OgsShell-qs/services/wallpaper_helper"

  // Process for scanning wallpaper JSON output from C helper binary
  Process {
    id: scanProcess
    running: false
    stdout: SplitParser {
      onRead: (line) => {
        service.lineBuffer += line + "\n";
      }
    }

    onRunningChanged: {
      if (!running) {
        try {
          var data = JSON.parse(service.lineBuffer.trim());
          if (Array.isArray(data)) {
            service.wallpaperList = data;
          }
        } catch (e) {
          console.log("Error parsing wallpaper helper JSON: " + e);
        }
        service.lineBuffer = "";
        service.isLoading = false;

        service.loadSavedWallpaperPath();
      }
    }
  }

  Process {
    id: readSavedProc
    running: false
    stdout: SplitParser {
      onRead: (line) => {
        var savedPath = line.trim();
        if (savedPath !== "") {
          service.currentWallpaper = savedPath;
        }
      }
    }
  }

  function loadSavedWallpaperPath() {
    var home = Quickshell.env("HOME") || "/home/excalibur";
    var stateFile = home + "/.config/ogsshell/state/wallpaper_" + activeTheme;
    var legacyFile = home + "/.config/ogsshell/wallpaper_" + activeTheme;
    if (readSavedProc.running) {
      readSavedProc.running = false;
    }
    readSavedProc.command = ["sh", "-c", "cat " + stateFile + " 2>/dev/null || cat " + legacyFile + " 2>/dev/null || true"];
    readSavedProc.running = true;
  }

  function refresh() {
    var folder = getFolderForTheme(activeTheme);
    var home = Quickshell.env("HOME") || "/home/excalibur";
    service.targetDir = home + "/Pictures/Wallpapers/" + folder;
    service.isLoading = true;
    service.lineBuffer = "";
    service.wallpaperList = [];

    if (scanProcess.running) {
      scanProcess.running = false;
    }

    scanProcess.command = [helperBin, "--scan", folder];
    scanProcess.running = true;
  }

  function restoreWallpaper() {
    var folder = getFolderForTheme(activeTheme);
    Quickshell.execDetached([helperBin, "--restore", activeTheme, folder]);
  }

  function setWallpaper(path) {
    if (!path) return;
    service.currentWallpaper = path;
    Quickshell.execDetached([helperBin, "--set", activeTheme, path]);
  }

  Component.onCompleted: {
    refresh();
    restoreWallpaper();
  }
}
