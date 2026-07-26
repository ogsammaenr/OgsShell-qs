import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: controlCenterWindow
  required property var targetScreen
  required property var monitorGroup

  property alias isSelectingNetwork: controlCenterCard.isSelectingNetwork
  property alias isSelectingBluetooth: controlCenterCard.isSelectingBluetooth
  property alias isSelectingTheme: controlCenterCard.isSelectingTheme
  property alias isSelectingClipboard: controlCenterCard.isSelectingClipboard

  screen: targetScreen
  visible: monitorGroup.isControlCenterOpen || (controlCenterCard.opacity > 0.01)
  WlrLayershell.layer: WlrLayer.Overlay
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  
  exclusiveZone: -1 // Float over windows
  aboveWindows: true
  focusable: controlCenterCard.isEnteringPassword
  color: "transparent"
  
  // Background click-catcher to dismiss
  MouseArea {
    anchors.fill: parent
    onClicked: {
      monitorGroup.isControlCenterOpen = false;
    }
  }
  
  ControlCenter {
    id: controlCenterCard
    screenContext: systemStatsService
    theme: monitorGroup.theme
    isOpen: monitorGroup.isControlCenterOpen
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    
    anchors.topMargin: 2
    width: monitorGroup.isControlCenterOpen ? 360 : 80
    height: monitorGroup.isControlCenterOpen ? 390 : 28
    opacity: monitorGroup.isControlCenterOpen ? 1.0 : 0.0
    scale: monitorGroup.isControlCenterOpen ? 1.0 : 0.8
    
    Behavior on width {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    Behavior on height {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    Behavior on opacity {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }

    onOpenPowerMenu: {
      monitorGroup.isControlCenterOpen = false;
      root.isPowerMenuOpen = true;
    }

    onThemeSelected: (themeName) => {
      root.activeTheme = themeName;
    }
  }

  Connections {
    target: networkManagerService
    ignoreUnknownSignals: true
    function onConnectionSucceeded() {
      controlCenterCard.selectedSsid = "";
    }
  }
}
