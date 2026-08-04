import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property int barHeight: 34
  property real islandWidthScale: 1.0
  property bool showWorkspaces: true
  property bool showSysStats: true
  property bool showCenterHud: true
  property bool showMedia: true
  property bool showPomodoro: true
  property bool compactMode: false
  property int cornerRadius: 12

  property string lineBuffer: ""

  Process {
    id: configLoaderProcess
    command: ["sh", "-c", "cat ~/.config/ogsshell/config.json 2>/dev/null || true"]
    running: false

    stdout: SplitParser {
      onRead: (line) => {
        service.lineBuffer += line + "\n";
      }
    }

    onRunningChanged: {
      if (!running) {
        if (service.lineBuffer.trim() !== "") {
          try {
            var cfg = JSON.parse(service.lineBuffer.trim());
            if (cfg.bar_height !== undefined) service.barHeight = Math.max(20, Math.min(64, Number(cfg.bar_height)));
            if (cfg.island_width_scale !== undefined) service.islandWidthScale = Math.max(0.5, Math.min(2.0, Number(cfg.island_width_scale) / 100.0));
            if (cfg.show_workspaces !== undefined) service.showWorkspaces = Boolean(cfg.show_workspaces);
            if (cfg.show_sys_stats !== undefined) service.showSysStats = Boolean(cfg.show_sys_stats);
            if (cfg.show_center_hud !== undefined) service.showCenterHud = Boolean(cfg.show_center_hud);
            if (cfg.show_media !== undefined) service.showMedia = Boolean(cfg.show_media);
            if (cfg.show_pomodoro !== undefined) service.showPomodoro = Boolean(cfg.show_pomodoro);
            if (cfg.compact_mode !== undefined) service.compactMode = Boolean(cfg.compact_mode);
            if (cfg.corner_radius !== undefined) service.cornerRadius = Number(cfg.corner_radius);
          } catch (e) {
            console.log("[ShellConfigService] Failed to parse config JSON: " + e);
          }
        }
        service.lineBuffer = "";
      }
    }
  }

  function reloadConfig() {
    service.lineBuffer = "";
    configLoaderProcess.running = true;
  }

  Component.onCompleted: {
    reloadConfig();
  }
}
