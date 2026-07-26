import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  // Control Statuses
  property bool wifiConnected: false
  property string wifiSsid: ""
  property string bluetoothStatus: "off"
  property int brightness: 0
  property int volume: 0
  property bool audioMuted: false
  property string keyboardLayout: "TR"
  
  // System metrics
  property int cpuTemp: 0
  property int cpuUsage: 0
  property int ramUsage: 0
  property int gpuTemp: 0
  property int gpuUsage: 0
  property string netSpeed: "0.0 KB/s"
  property string mediaStatus: "None"
  property string mediaTitle: ""
  property string mediaArtist: ""
  property string mediaArtUrl: ""
  property int notificationCount: 0

  // Bar stats visibility
  property bool showCpuUsageOnBar: true
  property bool showCpuTempOnBar: false
  property bool showRamUsageOnBar: true
  property bool showGpuUsageOnBar: false
  property bool showGpuTempOnBar: false
  property bool showNetSpeedOnBar: true
  property int pendingExternalBrightness: -1

  Timer {
    id: ddcutilDebounceTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (service.pendingExternalBrightness >= 0) {
        var val = service.pendingExternalBrightness;
        service.pendingExternalBrightness = -1;
        Quickshell.execDetached(["ddcutil", "setvcp", "10", val.toString()]);
      }
    }
  }

  function setBrightness(pct) {
    pct = Math.max(0, Math.min(100, Math.round(pct)));
    service.brightness = pct;
    // Laptop backlight updates instantly
    Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
    // External monitor (DDC/CI over I2C) updates 300ms after user pauses sliding
    service.pendingExternalBrightness = pct;
    ddcutilDebounceTimer.restart();
  }

  // Background process monitoring system statistics
  Process {
    id: monitorProc
    command: ["/home/excalibur/WorkSpace/projects/OgsShell-qs/monitor"]
    running: true

    stdout: SplitParser {
      onRead: (line) => {
        try {
          var data = JSON.parse(line);
          if (data.wifi_connected !== undefined) {
            service.wifiConnected = data.wifi_connected;
          }
          if (data.wifi_ssid !== undefined) {
            service.wifiSsid = data.wifi_ssid;
          }
          if (data.bluetooth_status !== undefined) {
            service.bluetoothStatus = data.bluetooth_status;
          }
          if (data.brightness !== undefined) {
            service.brightness = data.brightness;
          }
          if (data.volume !== undefined) {
            service.volume = data.volume;
          }
          if (data.audio_muted !== undefined) {
            service.audioMuted = data.audio_muted;
          }
          if (data.keyboard_layout !== undefined) {
            service.keyboardLayout = data.keyboard_layout;
          }
          if (data.cpu_temp !== undefined) {
            service.cpuTemp = data.cpu_temp;
          }
          if (data.cpu_usage !== undefined) {
            service.cpuUsage = data.cpu_usage;
          }
          if (data.ram_usage !== undefined) {
            service.ramUsage = data.ram_usage;
          }
          if (data.media_status !== undefined) {
            service.mediaStatus = data.media_status;
          }
          if (data.media_title !== undefined) {
            service.mediaTitle = data.media_title;
          }
          if (data.media_artist !== undefined) {
            service.mediaArtist = data.media_artist;
          }
          if (data.media_art_url !== undefined) {
            service.mediaArtUrl = data.media_art_url;
          }
          if (data.gpu_usage !== undefined) {
            service.gpuUsage = data.gpu_usage;
          }
          if (data.gpu_temp !== undefined) {
            service.gpuTemp = data.gpu_temp;
          }
          if (data.net_speed !== undefined) {
            service.netSpeed = data.net_speed;
          }
        } catch (e) {
          console.log("Error parsing monitor output: " + e);
        }
      }
    }
  }
}
