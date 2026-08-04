import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: appDashboardWindow
  required property var targetScreen
  required property var monitorGroup

  screen: targetScreen
  visible: monitorGroup.isAppDashboardOpen || (dashboardCard.opacity > 0.01)
  WlrLayershell.layer: WlrLayer.Overlay
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  
  exclusiveZone: -1 // Float over windows
  aboveWindows: true
  focusable: monitorGroup.isAppDashboardOpen
  color: "transparent"
  
  // Background click-catcher to dismiss
  MouseArea {
    anchors.fill: parent
    onClicked: {
      monitorGroup.isAppDashboardOpen = false;
    }
  }
  
  AppDashboard {
    id: dashboardCard
    theme: monitorGroup.theme
    isOpen: monitorGroup.isAppDashboardOpen
    
    anchors.centerIn: parent

    onCloseRequested: {
      monitorGroup.isAppDashboardOpen = false;
    }
  }
}
