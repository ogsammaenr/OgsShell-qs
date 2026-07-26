import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: calendarWindow
  required property var targetScreen
  required property var monitorGroup

  screen: targetScreen
  visible: monitorGroup.isCalendarOpen || (calendarInstance.opacity > 0.01)
  WlrLayershell.layer: WlrLayer.Overlay
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  
  exclusiveZone: -1 // Float over windows
  aboveWindows: true
  color: "transparent"
  
  MouseArea {
    anchors.fill: parent
    onClicked: {
      monitorGroup.isCalendarOpen = false;
    }
  }
  
  CalendarWidget {
    id: calendarInstance
    theme: monitorGroup.theme
    isOpen: monitorGroup.isCalendarOpen
    apiHolidays: root.apiHolidays
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    
    anchors.topMargin: 2
    width: monitorGroup.isCalendarOpen ? 300 : 80
    height: monitorGroup.isCalendarOpen ? 300 : 28
    opacity: monitorGroup.isCalendarOpen ? 1.0 : 0.0
    scale: monitorGroup.isCalendarOpen ? 1.0 : 0.8
    
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
  }
}
