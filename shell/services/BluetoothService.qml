import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  readonly property string binDir: (typeof Quickshell !== "undefined" && Quickshell.env("ROOT_DIR"))
                                     ? Quickshell.env("ROOT_DIR") + "/bin"
                                     : "/home/excalibur/WorkSpace/projects/OgsShell-qs/bin"

  property bool isScanning: false
  property var deviceList: []
  property bool isConnecting: false
  property string connectionError: ""

  // Scan Process
  Process {
    id: scanProcess
    command: [service.binDir + "/bluetooth_helper.sh"]
    running: false

    stdout: SplitParser {
      onRead: (line) => {
        var cleanLine = line.trim();
        if (cleanLine === "") return;
        var parts = cleanLine.split("|");
        if (parts.length >= 5) {
          var mac = parts[0].trim();
          var name = parts[1].trim();
          var paired = parts[2].indexOf("yes") !== -1;
          var trusted = parts[3].indexOf("yes") !== -1;
          var connected = parts[4].indexOf("yes") !== -1;

          if (mac !== "") {
            var deviceObj = {
              "mac": mac,
              "name": name !== "" ? name : mac,
              "paired": paired,
              "trusted": trusted,
              "connected": connected
            };

            // Create a copy of current list
            var currentList = [];
            for (var i = 0; i < service.deviceList.length; i++) {
              currentList.push(service.deviceList[i]);
            }

            var foundIndex = -1;
            for (var j = 0; j < currentList.length; j++) {
              if (currentList[j].mac === mac) {
                foundIndex = j;
                break;
              }
            }

            if (foundIndex !== -1) {
              currentList[foundIndex] = deviceObj;
            } else {
              currentList.push(deviceObj);
            }
            service.deviceList = currentList;
          }
        }
      }
    }

    stderr: SplitParser {
      onRead: (line) => {
        console.log("Bluetooth Scan stderr: " + line);
      }
    }

    onRunningChanged: {
      if (!running) {
        console.log("Bluetooth Scan process finished. Parsing completed. Total devices: " + service.deviceList.length);
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
          service.connectionError = line.trim();
        }
      }
    }

    onRunningChanged: {
      if (!running) {
        console.log("Bluetooth connectProcess finished. Command: " + JSON.stringify(connectProcess.command) + ", error: " + service.connectionError);
        service.isConnecting = false;
        service.refresh();
      }
    }
  }

  // Action methods
  // Initiates scanning process
  function refresh() {
    console.log("Bluetooth refresh() triggered. isScanning = " + isScanning);
    if (isScanning) return;
    isScanning = true;
    deviceList = []; // Clear list to get fresh results
    scanProcess.running = true;
  }

  // Toggles the bluetooth power state
  // On toggle power, waits a second then refreshes the devices list
  function togglePower(turnOn) {
    Quickshell.execDetached(["bluetoothctl", "power", turnOn ? "on" : "off"]);
    var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 1000; running: true; repeat: false; }", service);
    timer.triggered.connect(() => {
      service.refresh();
      timer.destroy();
    });
  }

  // Non-interactively pairs with a bluetooth device using a registered local agent
  function pairDevice(mac) {
    console.log("Bluetooth pairDevice(" + mac + ") triggered.");
    if (isConnecting) return;
    isConnecting = true;
    connectionError = "";
    connectProcess.command = ["sh", "-c", "printf 'agent NoInputNoOutput\\ndefault-agent\\npair " + mac + "\\ntrust " + mac + "\\n' | bluetoothctl"];
    connectProcess.running = true;
  }

  // Connects to a paired bluetooth device
  function connectDevice(mac) {
    console.log("Bluetooth connectDevice(" + mac + ") triggered.");
    if (isConnecting) return;
    isConnecting = true;
    connectionError = "";
    connectProcess.command = ["sh", "-c", "printf 'agent NoInputNoOutput\\ndefault-agent\\nconnect " + mac + "\\n' | bluetoothctl"];
    connectProcess.running = true;
  }

  // Disconnects from a connected bluetooth device
  function disconnectDevice(mac) {
    console.log("Bluetooth disconnectDevice(" + mac + ") triggered.");
    if (isConnecting) return;
    isConnecting = true;
    connectionError = "";
    connectProcess.command = ["sh", "-c", "printf 'agent NoInputNoOutput\\ndefault-agent\\ndisconnect " + mac + "\\n' | bluetoothctl"];
    connectProcess.running = true;
  }

  // Local controller commands to trust/untrust a device
  function trustDevice(mac, trust) {
    Quickshell.execDetached(["bluetoothctl", trust ? "trust" : "untrust", mac]);
    var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; }", service);
    timer.triggered.connect(() => {
      service.refresh();
      timer.destroy();
    });
  }

  // Removes a paired device
  function removeDevice(mac) {
    Quickshell.execDetached(["bluetoothctl", "remove", mac]);
    var timer = Qt.createQmlObject("import QtQuick; Timer { interval: 500; running: true; repeat: false; }", service);
    timer.triggered.connect(() => {
      service.refresh();
      timer.destroy();
    });
  }

  Component.onCompleted: {
    refresh();
  }
}
