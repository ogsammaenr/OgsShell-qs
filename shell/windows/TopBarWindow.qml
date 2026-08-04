import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: win
  required property var targetScreen
  required property var monitorGroup

  screen: targetScreen
  WlrLayershell.layer: WlrLayer.Top

  anchors {
    top: true
    left: true
    right: true
  }
  
  // Window height is fixed to screen height to avoid Wayland surface resize glitches,
  // while utilizing dynamic input masks for click pass-through.
  implicitHeight: win.screen ? win.screen.height : 1080
  
  // Exclusive zone bound dynamically to shellConfigService barHeight + 4px top margin
  exclusiveZone: (typeof shellConfigService !== "undefined") ? (shellConfigService.barHeight + 4) : 34
  
  aboveWindows: true
  color: "transparent"

  // Restrict window input region to the union of containers or flat bar
  mask: Region {
    Region { item: (typeof gameModeService !== "undefined" && gameModeService.isGameModeActive) ? flatBarBg : null }
    Region { item: leftWorkspaceBar.visible ? leftWorkspaceBar : null }
    Region { item: (systemStatsIsland.visible && systemStatsIsland.opacity > 0) ? systemStatsIsland : null }
    Region { item: islandContainer.visible ? islandContainer : null }
    Region { item: rightMediaNotifIsland.visible ? rightMediaNotifIsland.container : null }
    Region { item: (rightMediaNotifIsland.subNotificationsList && rightMediaNotifIsland.subNotificationsList.visible) ? rightMediaNotifIsland.subNotificationsList : null }
    Region { item: monitorGroup.isMediaManagerOpen ? dismissMouseArea : null }
  }

  // Transparent wrapper covering the whole width to serve as input mask source
  Item {
    id: inputMaskContainer
    anchors.fill: parent

    // Flat bar strip for Game Mode
    Rectangle {
      id: flatBarBg
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: (typeof shellConfigService !== "undefined") ? shellConfigService.barHeight : 32
      color: monitorGroup.theme.bg
      border.color: monitorGroup.theme.border
      border.width: 1
      opacity: (typeof gameModeService !== "undefined" && gameModeService.isGameModeActive) ? 1.0 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 180 }
      }
    }

    // Full screen mouse area to dismiss media manager on click outside
    MouseArea {
      id: dismissMouseArea
      anchors.fill: parent
      visible: monitorGroup.isMediaManagerOpen
      onClicked: {
        monitorGroup.isMediaManagerOpen = false;
      }
    }

    // A. Left Wall Workspace Bar
    LeftWorkspaceBar {
      id: leftWorkspaceBar
      visible: (typeof shellConfigService === "undefined" || shellConfigService.showWorkspaces)
      screen: win.screen
      theme: monitorGroup.theme
      anchors.top: parent.top
      anchors.topMargin: 2
      anchors.left: parent.left
      anchors.leftMargin: -12
    }

    // System Stats Island on the left of the Center Island
    SystemStatsIsland {
      id: systemStatsIsland
      visible: (typeof shellConfigService === "undefined" || shellConfigService.showSysStats)
      group: win.monitorGroup
      anchors.right: islandContainer.left
      anchors.rightMargin: 12
      anchors.verticalCenter: islandContainer.verticalCenter
    }

    // B. Center Floating Island Container
    CenterHudIsland {
      id: islandContainer
      visible: (typeof shellConfigService === "undefined" || shellConfigService.showCenterHud)
      group: win.monitorGroup
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 2
    }

    // C. Right Wall Media & Notification Island
    RightMediaNotifIsland {
      id: rightMediaNotifIsland
      visible: (typeof shellConfigService === "undefined" || shellConfigService.showMedia)
      group: win.monitorGroup
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
    }
  }
}
