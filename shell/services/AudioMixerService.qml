import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  readonly property string binDir: (typeof Quickshell !== "undefined" && Quickshell.env("ROOT_DIR"))
                                     ? Quickshell.env("ROOT_DIR") + "/bin"
                                     : "/home/excalibur/WorkSpace/projects/OgsShell-qs/bin"

  property var sinkList: []
  property var appList: []
  property string defaultSink: ""
  property bool isLoading: false
  property bool isUserDragging: false

  property int mediaVolume: 100
  property bool mediaMuted: false
  property string mediaAppName: ""

  property var pendingVolumeUpdate: null

  Component.onCompleted: {
    // Restore saved audio device on startup
    restoreProcess.running = true;
  }

  Timer {
    id: autoRefreshTimer
    interval: 3000
    running: !service.isUserDragging
    repeat: true
    onTriggered: {
      if (!service.isUserDragging) {
        service.refresh();
      }
    }
  }

  Timer {
    id: volumeThrottleTimer
    interval: 35
    repeat: false
    onTriggered: {
      service.flushPendingVolume();
    }
  }

  function flushPendingVolume() {
    if (service.pendingVolumeUpdate) {
      var update = service.pendingVolumeUpdate;
      service.pendingVolumeUpdate = null;
      if (update.type === "sink") {
        Quickshell.execDetached(["pactl", "set-sink-volume", update.target.toString(), update.pct + "%"]);
      } else if (update.type === "app") {
        Quickshell.execDetached(["pactl", "set-sink-input-volume", update.target.toString(), update.pct + "%"]);
      }
    }
  }

  onIsUserDraggingChanged: {
    if (!isUserDragging) {
      service.flushPendingVolume();
    }
  }

  Process {
    id: restoreProcess
    command: [service.binDir + "/audio_mixer_helper.py", "--restore"]
    running: false
    onExited: {
      service.refresh();
    }
  }

  Process {
    id: refreshProcess
    command: [service.binDir + "/audio_mixer_helper.py", "--json"]
    running: false

    stdout: SplitParser {
      onRead: (line) => {
        try {
          var data = JSON.parse(line);
          if (!service.isUserDragging) {
            if (data.default_sink !== undefined) {
              service.defaultSink = data.default_sink;
            }
            if (data.sinks !== undefined) {
              service.sinkList = data.sinks;
            }
            if (data.apps !== undefined) {
              service.appList = data.apps;
            }
            if (data.media_player !== undefined) {
              service.mediaVolume = (data.media_player.volume !== undefined) ? data.media_player.volume : 100;
              service.mediaMuted = (data.media_player.mute !== undefined) ? data.media_player.mute : false;
              service.mediaAppName = (data.media_player.player_name !== undefined) ? data.media_player.player_name : "";
            }
          }
        } catch (e) {
          console.log("Error parsing audio mixer output: " + e);
        }
        service.isLoading = false;
      }
    }
  }

  function refresh() {
    if (service.isUserDragging) return;
    service.isLoading = true;
    if (refreshProcess.running) {
      refreshProcess.running = false;
    }
    refreshProcess.running = true;
  }

  function setDefaultSink(sinkName) {
    if (!sinkName) return;
    service.defaultSink = sinkName;
    for (var i = 0; i < service.sinkList.length; i++) {
      if (service.sinkList[i].name === sinkName) {
        service.sinkList[i].is_default = true;
      } else {
        service.sinkList[i].is_default = false;
      }
    }

    Quickshell.execDetached([service.binDir + "/audio_mixer_helper.py", "--set-default", sinkName]);
  }

  function setSinkVolume(sinkTarget, pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    for (var i = 0; i < service.sinkList.length; i++) {
      if (service.sinkList[i].name === sinkTarget || service.sinkList[i].index === sinkTarget) {
        service.sinkList[i].volume = pct;
        break;
      }
    }

    service.pendingVolumeUpdate = { type: "sink", target: sinkTarget, pct: pct };
    if (!volumeThrottleTimer.running) {
      volumeThrottleTimer.restart();
    }
  }

  function setSinkMute(sinkTarget) {
    for (var i = 0; i < service.sinkList.length; i++) {
      if (service.sinkList[i].name === sinkTarget || service.sinkList[i].index === sinkTarget) {
        service.sinkList[i].mute = !service.sinkList[i].mute;
        break;
      }
    }

    Quickshell.execDetached(["pactl", "set-sink-mute", sinkTarget.toString(), "toggle"]);
  }

  function setAppVolume(appIndex, pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    for (var i = 0; i < service.appList.length; i++) {
      if (service.appList[i].index === appIndex) {
        service.appList[i].volume = pct;
        break;
      }
    }

    service.pendingVolumeUpdate = { type: "app", target: appIndex, pct: pct };
    if (!volumeThrottleTimer.running) {
      volumeThrottleTimer.restart();
    }
  }

  function setAppMute(appIndex) {
    for (var i = 0; i < service.appList.length; i++) {
      if (service.appList[i].index === appIndex) {
        service.appList[i].mute = !service.appList[i].mute;
        break;
      }
    }

    Quickshell.execDetached(["pactl", "set-sink-input-mute", appIndex.toString(), "toggle"]);
  }

  function setMediaVolume(pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    service.mediaVolume = pct;
    Quickshell.execDetached([service.binDir + "/audio_mixer_helper.py", "--set-media-vol", pct.toString()]);
  }

  function setMediaMute() {
    service.mediaMuted = !service.mediaMuted;
    Quickshell.execDetached([service.binDir + "/audio_mixer_helper.py", "--set-media-mute"]);
  }
}
