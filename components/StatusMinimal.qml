import QtQuick

Row {
  id: statusMinimalRow
  property var screenContext: null
  required property bool isHovered
  required property var theme

  spacing: 12
  anchors.verticalCenter: parent.verticalCenter
  clip: true

  // Animate the row's total width and opacity based on hover state
  width: isHovered ? implicitWidth : 0
  opacity: isHovered ? 1.0 : 0.0

  Behavior on width {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }
  Behavior on opacity {
    NumberAnimation { duration: 120 }
  }

  // WiFi button/icon
  Text {
    id: wifiIcon
    text: "\uf1eb"
    color: (screenContext && screenContext.wifiConnected) ? theme.green : theme.textSecondary
    font {
      family: "FiraCode Nerd Font"
      pixelSize: 12
    }
    anchors.verticalCenter: parent.verticalCenter
    
    // Smooth color animation
    Behavior on color {
      ColorAnimation { duration: 120 }
    }
  }

  // Bluetooth button/icon
  Text {
    id: btIcon
    text: "\uf293"
    color: (screenContext && screenContext.bluetoothStatus === "connected") ? theme.accent : ((screenContext && screenContext.bluetoothStatus === "on") ? theme.textPrimary : theme.textSecondary)
    font {
      family: "FiraCode Nerd Font"
      pixelSize: 12
    }
    anchors.verticalCenter: parent.verticalCenter

    // Smooth color animation
    Behavior on color {
      ColorAnimation { duration: 120 }
    }
  }
}
