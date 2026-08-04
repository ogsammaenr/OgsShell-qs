import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: appLauncherWindow
  required property var targetScreen
  required property var monitorGroup

  screen: targetScreen
  visible: monitorGroup.isAppLauncherOpen || (launcherCard.opacity > 0.01)
  WlrLayershell.layer: WlrLayer.Overlay
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  
  exclusiveZone: -1 // Float over windows
  aboveWindows: true
  focusable: monitorGroup.isAppLauncherOpen
  color: "transparent"
  
  // Background click-catcher to dismiss
  MouseArea {
    anchors.fill: parent
    onClicked: {
      monitorGroup.isAppLauncherOpen = false;
    }
  }
  
  AppLauncher {
    id: launcherCard
    theme: monitorGroup.theme
    monitorGroup: appLauncherWindow.monitorGroup
    isOpen: monitorGroup.isAppLauncherOpen
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 2

    onCloseRequested: {
      monitorGroup.isAppLauncherOpen = false;
    }
  }
}
