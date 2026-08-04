import Quickshell
import QtQuick
import "../components"

PanelWindow {
  id: powerMenuWin
  screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

  Theme {
    id: theme
    currentTheme: root.activeTheme
  }

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  visible: root.isPowerMenuOpen
  aboveWindows: true
  focusable: true
  color: "transparent"

  // Dark backdrop covering the entire screen
  Rectangle {
    id: powerBackdrop
    anchors.fill: parent
    color: "#cc000000"

    // Click outside the power menu to close it
    MouseArea {
      anchors.fill: parent
      onClicked: {
        root.isPowerMenuOpen = false;
      }
    }
  }

  // Center Power Menu Card
  Rectangle {
    id: powerCard
    anchors.centerIn: parent
    width: 540
    height: 200
    radius: 28
    color: theme.bg
    border.color: theme.border
    border.width: 1.5

    MouseArea {
      anchors.fill: parent
    }

    Column {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 20

      Text {
        text: "Sistem Güç Seçenekleri"
        color: theme.textPrimary
        anchors.horizontalCenter: parent.horizontalCenter
        font {
          family: "JetBrains Mono"
          pixelSize: 18
          weight: Font.Bold
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 24

        // Shutdown Button
        PowerButton {
          text: "Kapat"
          icon: "\uf011"
          colorNormal: "#22ef4444"
          colorHover: "#ef4444"
          borderColor: "#ef4444"
          textColor: "#ef4444"
          onClicked: {
            root.isPowerMenuOpen = false;
            Quickshell.execDetached(["systemctl", "poweroff"]);
          }
        }

        // Reboot Button
        PowerButton {
          text: "Yeniden Başlat"
          icon: "\uf01e"
          colorNormal: "#22f97316"
          colorHover: "#f97316"
          borderColor: "#f97316"
          textColor: "#f97316"
          onClicked: {
            root.isPowerMenuOpen = false;
            Quickshell.execDetached(["systemctl", "reboot"]);
          }
        }

        // Exit Session Button
        PowerButton {
          text: "Çıkış Yap"
          icon: "\uf08b"
          colorNormal: "#22eab308"
          colorHover: "#eab308"
          borderColor: "#eab308"
          textColor: "#eab308"
          onClicked: {
            root.isPowerMenuOpen = false;
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
          }
        }

        // Suspend Button
        PowerButton {
          text: "Uyku"
          icon: "\uf186"
          colorNormal: "#2206b6d4"
          colorHover: "#06b6d4"
          borderColor: "#06b6d4"
          textColor: "#06b6d4"
          onClicked: {
            root.isPowerMenuOpen = false;
            Quickshell.execDetached(["systemctl", "suspend"]);
          }
        }
      }
    }
  }
}
