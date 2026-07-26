import QtQuick

Item {
  id: statsRow
  property var screenContext: null
  required property bool isBarExpanded
  required property var hoverArea

  width: parent.width
  height: 18
  visible: hoverArea && hoverArea.containsMouse && !isBarExpanded
  opacity: (hoverArea && hoverArea.containsMouse && !isBarExpanded) ? 1.0 : 0.0

  Behavior on opacity {
    NumberAnimation { duration: 120 }
  }

  // Left side: Hardware Metrics (CPU, Temp, RAM)
  Row {
    id: hardwareGroup
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    // CPU Usage
    Text {
      text: "\uf2db" // CPU Icon
      color: "#38bdf8" // Cyan
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 13
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: screenContext ? screenContext.cpuUsage + "%" : "0%"
      color: "#f8f9fa"
      font {
        family: "JetBrains Mono"
        pixelSize: 11
        weight: Font.Medium
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: "|"
      color: "#20ffffff"
      font.pixelSize: 9
      anchors.verticalCenter: parent.verticalCenter
    }

    // CPU Temp
    Text {
      text: "\uf2c9" // Thermometer Icon
      color: (screenContext && screenContext.cpuTemp > 75) ? "#f87171" : ((screenContext && screenContext.cpuTemp > 60) ? "#fbbf24" : "#4dd1b0")
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 13
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: screenContext ? screenContext.cpuTemp + "°C" : "0°C"
      color: "#f8f9fa"
      font {
        family: "JetBrains Mono"
        pixelSize: 11
        weight: Font.Medium
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: "|"
      color: "#20ffffff"
      font.pixelSize: 9
      anchors.verticalCenter: parent.verticalCenter
    }

    // RAM Usage
    Text {
      text: "\uf538" // RAM Icon
      color: "#a78bfa" // Purple
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 13
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: screenContext ? screenContext.ramUsage + "%" : "0%"
      color: "#f8f9fa"
      font {
        family: "JetBrains Mono"
        pixelSize: 11
        weight: Font.Medium
      }
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  // Right side: System Status Indicators (WiFi, Bluetooth, Brightness, Volume)
  Row {
    id: statusGroup
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10

    // Wi-Fi (Icon only)
    Text {
      text: "\uf1eb" // Wifi Icon
      color: (screenContext && screenContext.wifiConnected) ? "#34d399" : "#64748b"
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 13
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: "|"
      color: "#20ffffff"
      font.pixelSize: 9
      anchors.verticalCenter: parent.verticalCenter
    }

    // Bluetooth (Icon only)
    Text {
      text: "\uf293" // Bluetooth Icon
      color: (screenContext && screenContext.bluetoothStatus === "connected") ? "#60a5fa" : ((screenContext && screenContext.bluetoothStatus === "on") ? "#f8f9fa" : "#64748b")
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 13
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: "|"
      color: "#20ffffff"
      font.pixelSize: 9
      anchors.verticalCenter: parent.verticalCenter
    }

    // Brightness Status
    Row {
      spacing: 3
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: "\uf185" // Sun Icon
        color: "#fbbf24"
        font {
          family: "FiraCode Nerd Font"
          pixelSize: 13
        }
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: screenContext ? screenContext.brightness + "%" : "0%"
        color: "#f8f9fa"
        font {
          family: "JetBrains Mono"
          pixelSize: 11
        }
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      text: "|"
      color: "#20ffffff"
      font.pixelSize: 9
      anchors.verticalCenter: parent.verticalCenter
    }

    // Volume Status
    Row {
      spacing: 3
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: (screenContext && screenContext.audioMuted) ? "\uf026" : ((screenContext && screenContext.volume > 50) ? "\uf028" : "\uf027")
        color: (screenContext && screenContext.audioMuted) ? "#f87171" : "#38bdf8"
        font {
          family: "FiraCode Nerd Font"
          pixelSize: 13
        }
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: (screenContext && screenContext.audioMuted) ? "Mute" : (screenContext ? screenContext.volume + "%" : "0%")
        color: (screenContext && screenContext.audioMuted) ? "#f87171" : "#f8f9fa"
        font {
          family: "JetBrains Mono"
          pixelSize: 11
        }
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
