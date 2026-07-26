import QtQuick

Rectangle {
  id: expandedStatsCol
  property var screenContext: null

  width: 330
  height: 210
  radius: 16
  color: "#180f172a" // 10% opacity slate
  border.color: "#15ffffff"
  border.width: 1

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    Text {
      text: "Sistem Kaynakları"
      color: "#38bdf8"
      font { family: "JetBrains Mono"; pixelSize: 12; weight: Font.Bold }
    }

    // CPU usage indicator
    Column {
      width: parent.width
      spacing: 4
      Item {
        width: parent.width
        height: 14
        Text {
          text: "CPU"
          color: "#cbd5e1"
          font.pixelSize: 10
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: screenContext ? (screenContext.cpuUsage + "% (" + screenContext.cpuTemp + "°C)") : "0% (0°C)"
          color: "#f8f9fa"
          font { family: "JetBrains Mono"; pixelSize: 10 }
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }
      // Custom Progress Bar
      Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: "#1e293b"
        Rectangle {
          width: parent.width * (screenContext ? (screenContext.cpuUsage / 100.0) : 0.0)
          height: parent.height
          radius: 3
          color: "#38bdf8"
          Behavior on width { NumberAnimation { duration: 200 } }
        }
      }
    }

    // RAM usage indicator
    Column {
      width: parent.width
      spacing: 4
      Item {
        width: parent.width
        height: 14
        Text {
          text: "RAM"
          color: "#cbd5e1"
          font.pixelSize: 10
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: screenContext ? (screenContext.ramUsage + "%") : "0%"
          color: "#f8f9fa"
          font { family: "JetBrains Mono"; pixelSize: 10 }
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }
      // Custom Progress Bar
      Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: "#1e293b"
        Rectangle {
          width: parent.width * (screenContext ? (screenContext.ramUsage / 100.0) : 0.0)
          height: parent.height
          radius: 3
          color: (typeof group !== "undefined" && group && group.theme) ? group.theme.accent : "#88c0d0"
          Behavior on width { NumberAnimation { duration: 200 } }
        }
      }
    }

    // Divider
    Rectangle {
      width: parent.width
      height: 1
      color: "#10ffffff"
    }

    // Quick Status Info (Wifi, BT, brightness, volume)
    Grid {
      columns: 2
      spacing: 8
      width: parent.width
      rowSpacing: 10

      // WiFi status
      Row {
        spacing: 8
        width: 145
        Text {
          text: "\uf1eb"
          color: (screenContext && screenContext.wifiConnected) ? "#34d399" : "#64748b"
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
        }
        Text {
          text: (screenContext && screenContext.wifiConnected) ? (screenContext.wifiSsid !== "" ? screenContext.wifiSsid : "Bağlı") : "Bağlantı Yok"
          color: "#cbd5e1"
          font.pixelSize: 10
          elide: Text.ElideRight
          width: 110
        }
      }

      // BT status
      Row {
        spacing: 8
        width: 145
        Text {
          text: "\uf293"
          color: (screenContext && screenContext.bluetoothStatus === "connected") ? "#60a5fa" : ((screenContext && screenContext.bluetoothStatus === "on") ? "#ffffff" : "#64748b")
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
        }
        Text {
          text: (screenContext && screenContext.bluetoothStatus === "connected") ? "Cihaz Bağlı" : ((screenContext && screenContext.bluetoothStatus === "on") ? "Açık" : "Kapalı")
          color: "#cbd5e1"
          font.pixelSize: 10
        }
      }

      // Brightness status
      Row {
        spacing: 8
        width: 145
        Text {
          text: "\uf185"
          color: "#fbbf24"
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
        }
        Text {
          text: screenContext ? ("Parlaklık: " + screenContext.brightness + "%") : "Parlaklık: 0%"
          color: "#cbd5e1"
          font.pixelSize: 10
        }
      }

      // Volume status
      Row {
        spacing: 8
        width: 145
        Text {
          text: (screenContext && screenContext.audioMuted) ? "\uf026" : "\uf028"
          color: (screenContext && screenContext.audioMuted) ? "#f87171" : "#38bdf8"
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
        }
        Text {
          text: (screenContext && screenContext.audioMuted) ? "Sessiz" : (screenContext ? ("Ses: " + screenContext.volume + "%") : "Ses: 0%")
          color: "#cbd5e1"
          font.pixelSize: 10
        }
      }
    }
  }
}
