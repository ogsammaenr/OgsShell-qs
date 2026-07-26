import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property bool ethernetConnected: false
  property string ethernetDevice: ""
  property bool wifiConnected: false
  property string wifiSsid: ""
  property var wifiList: []
  property var savedConnections: []
  property bool isScanning: false
  property bool isConnecting: false
  property string connectionError: ""

  property string lineBuffer: ""

  // Post-Connection Polling Timer to guarantee immediate UI updates during IP handshake
  Timer {
    id: postConnectTimer
    interval: 1000
    running: false
    repeat: true
    property int triggerCount: 0
    
    onTriggered: {
      service.refresh();
      triggerCount++;
      if (triggerCount >= 4) {
        running = false;
      }
    }
  }

  // Scan Process
  Process {
    id: scanProcess
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE,DEVICE device; echo \"===WIFI===\"; nmcli -t -f SSID,SIGNAL,ACTIVE,SECURITY device wifi list --rescan yes; echo \"===SAVED===\"; nmcli -t -f NAME connection show"]
    running: false

    stdout: SplitParser {
      onRead: (line) => {
        service.lineBuffer += line + "\n";
      }
    }

    onRunningChanged: {
      if (!running) {
        // Strip carriage returns for robust cross-platform newline splitting
        var cleanBuffer = service.lineBuffer.replace(/\r/g, "");
        var wifiParts = cleanBuffer.split("===WIFI===\n");
        var devLines = [];
        var wifiLines = [];
        var savedLines = [];

        if (wifiParts.length >= 1) {
          devLines = wifiParts[0].split("\n");
        }

        if (wifiParts.length >= 2) {
          var remaining = wifiParts[1].split("===SAVED===\n");
          wifiLines = remaining[0].split("\n");
          if (remaining.length >= 2) {
            savedLines = remaining[1].split("\n");
          }
        }

        // 1. Parse ethernet/wifi devices status
        var ethConn = false;
        var wifiConn = false;
        var ethDev = "";
        for (var i = 0; i < devLines.length; i++) {
          var devParts = devLines[i].split(":");
          if (devParts.length >= 2) {
            if (devParts[0] === "ethernet") {
              var currentDev = devParts[2] || "";
              var currentState = devParts[1] || "";
              if (currentState === "connected") {
                ethConn = true;
                ethDev = currentDev; // Prioritize the active device
              } else if (ethDev === "") {
                ethDev = currentDev; // Fallback to first available interface
              }
            }
            if (devParts[0] === "wifi" && devParts[1] === "connected") {
              wifiConn = true;
            }
          }
        }
        service.ethernetDevice = ethDev;
        service.ethernetConnected = ethConn;
        service.wifiConnected = wifiConn;

        // 2. Parse saved connections list
        var savedList = [];
        for (var k = 0; k < savedLines.length; k++) {
          var sLine = savedLines[k].trim();
          if (sLine !== "") {
            savedList.push(sLine);
          }
        }
        service.savedConnections = savedList;

        // 3. Parse available wifi list
        var newList = [];
        var seenSsids = {};
        var activeSsidFound = false;

        for (var j = 0; j < wifiLines.length; j++) {
          var wLine = wifiLines[j].trim();
          if (wLine === "") continue;
          
          // Replace escaped colons with a temporary placeholder
          var cleanLine = wLine.replace(/\\:/g, "\uE000");
          var wifiParts = cleanLine.split(":");
          
          if (wifiParts.length >= 4) {
            var ssid = wifiParts[0].replace(/\uE000/g, ":").trim();
            if (ssid === "") continue;
            var signal = parseInt(wifiParts[1]) || 0;
            var active = wifiParts[2] === "*" || wifiParts[2] === "yes";
            var secure = wifiParts[3] !== "--" && wifiParts[3] !== "";
            
            if (active) {
              service.wifiSsid = ssid;
              service.wifiConnected = true;
              activeSsidFound = true;
            }

            if (seenSsids[ssid] !== undefined) {
              var idx = seenSsids[ssid];
              if (signal > newList[idx].signal) {
                newList[idx].signal = signal;
                newList[idx].active = newList[idx].active || active;
              }
              continue;
            }

            seenSsids[ssid] = newList.length;
            newList.push({
              "ssid": ssid,
              "signal": signal,
              "active": active,
              "secure": secure
            });
          }
        }
        
        if (!activeSsidFound) {
          service.wifiSsid = "";
        }
        service.wifiList = newList;

        service.lineBuffer = "";
        service.isScanning = false;
      }
    }
  }

  // Connect Process
  Process {
    id: connectProcess
    running: false

    stderr: SplitParser {
      onRead: (line) => {
        if (line.trim() !== "") {
          service.connectionError = line.replace("Error:", "").trim();
        }
      }
    }
    
    onRunningChanged: {
      if (!running) {
        service.isConnecting = false;
        if (service.connectionError === "") {
          service.connectionSucceeded();
          postConnectTimer.triggerCount = 0;
          postConnectTimer.running = true;
          service.refresh();
        }
      }
    }
  }

  // Disconnect Process
  Process {
    id: disconnectProcess
    running: false
    
    onRunningChanged: {
      if (!running) {
        postConnectTimer.triggerCount = 0;
        postConnectTimer.running = true;
        service.refresh();
      }
    }
  }

  function refresh() {
    if (isScanning) return;
    isScanning = true;
    lineBuffer = "";
    scanProcess.running = true;
  }

  function connectToWifi(ssid, password) {
    if (isConnecting) return;
    isConnecting = true;
    connectionError = "";
    
    var cmd = ["nmcli", "device", "wifi", "connect", ssid];
    if (password && password !== "") {
      cmd.push("password", password);
    }
    
    connectProcess.command = cmd;
    connectProcess.running = true;
  }

  function disconnectWifi() {
    disconnectProcess.command = ["nmcli", "device", "disconnect", "wlan0"];
    disconnectProcess.running = true;
  }

  function connectEthernet() {
    if (ethernetDevice === "") return;
    disconnectProcess.command = ["nmcli", "device", "connect", ethernetDevice];
    disconnectProcess.running = true;
  }

  function disconnectEthernet() {
    if (ethernetDevice === "") return;
    disconnectProcess.command = ["nmcli", "device", "disconnect", ethernetDevice];
    disconnectProcess.running = true;
  }

  function toggleWifi(turnOn) {
    Quickshell.execDetached(["nmcli", "radio", "wifi", turnOn ? "on" : "off"]);
    postConnectTimer.triggerCount = 0;
    postConnectTimer.running = true;
  }

  Component.onCompleted: {
    refresh();
  }
}
