import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "components/island"
import "components/widgets"
import "components/widgets/controlcenter"

Scope {
  id: rootScope

  // IPC Service instance
  DaemonIPC {
    id: ipcService
  }

  // =========================================================================
  // D-Bus Notification Listener (notify-send / freedesktop notifications)
  // =========================================================================
  NotificationServer {
    id: notifServer
    bodySupported: true
    actionsSupported: true
    imageSupported: true

    onNotification: notif => {
      ipcService.addNotification(
        notif.appName || "System",
        notif.summary || "Notification",
        notif.body || "",
        notif.appIcon || "",
        notif.urgency || "normal"
      )
    }
  }

  // =========================================================================
  // Multi-Monitor Variants: Instances of Island & Backdrop per Screen
  // =========================================================================
  Variants {
    model: Quickshell.screens

    Scope {
      id: screenScope
      required property var modelData

      // 1. Per-Monitor Hyprland State & Tiling Window Inspection
      readonly property var hyprMonitor: {
        let mon = Hyprland.monitorFor(screenScope.modelData)
        if (mon) return mon
        let mons = (Hyprland.monitors && Hyprland.monitors.values) ? Hyprland.monitors.values : []
        for (let i = 0; i < mons.length; i++) {
          if (mons[i].name === screenScope.modelData.name) {
            return mons[i]
          }
        }
        return null
      }

      readonly property var activeWorkspace: hyprMonitor ? hyprMonitor.activeWorkspace : null

      readonly property bool isFocusedMonitor: {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
          return Hyprland.focusedMonitor.name === screenScope.modelData.name
        }
        if (screenScope.hyprMonitor && screenScope.hyprMonitor.focused) {
          return true
        }
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === screenScope.modelData.name
      }

      readonly property bool hasTilingWindows: {
        if (!activeWorkspace) return false
        let curWsId = activeWorkspace.id

        // Check 1: Inspect toplevels on this active workspace directly
        if (activeWorkspace.toplevels && activeWorkspace.toplevels.values) {
          let wsWins = activeWorkspace.toplevels.values
          for (let i = 0; i < wsWins.length; i++) {
            let win = wsWins[i]
            let isFloating = (win.floating === true) || (win.lastIpcObject && win.lastIpcObject.floating === true)
            let isHidden = (win.hidden === true) || (win.lastIpcObject && win.lastIpcObject.hidden === true)
            if (!isFloating && !isHidden) {
              return true
            }
          }
        }

        // Check 2: Inspect all toplevels matching current workspace ID
        let toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : []
        for (let i = 0; i < toplevels.length; i++) {
          let win = toplevels[i]
          let winWsId = win.workspace ? win.workspace.id : (win.lastIpcObject && win.lastIpcObject.workspace ? win.lastIpcObject.workspace.id : null)
          if (winWsId === curWsId) {
            let isFloating = (win.floating === true) || (win.lastIpcObject && win.lastIpcObject.floating === true)
            let isHidden = (win.hidden === true) || (win.lastIpcObject && win.lastIpcObject.hidden === true)
            if (!isFloating && !isHidden) {
              return true
            }
          }
        }
        return false
      }

      // Auto-hide condition: Focus mode is ON, there are tiling windows, and island is not interacting (EXPANDED/TRANSIENT)
      readonly property bool shouldAutoHide: Config.focusMode && hasTilingWindows && (island.stateMode !== "EXPANDED" && island.stateMode !== "TRANSIENT")

      // Precision Hover State (Slim 12px Top Hotspot + Island's exact visual body)
      readonly property bool isHoveredOverall: (topHotspotMouseArea && topHotspotMouseArea.containsMouse) || island.isIslandHovered
      property bool isRevealed: !shouldAutoHide

      onIsHoveredOverallChanged: {
        if (isHoveredOverall) {
          autoHideTimer.stop()
          revealLatchTimer.restart()
          isRevealed = true
        } else {
          if (shouldAutoHide && island.stateMode !== "EXPANDED" && island.stateMode !== "TRANSIENT") {
            if (!revealLatchTimer.running) {
              autoHideTimer.restart()
            }
          }
        }
      }

      onShouldAutoHideChanged: {
        if (!shouldAutoHide) {
          autoHideTimer.stop()
          revealLatchTimer.stop()
          isRevealed = true
        } else if (!isHoveredOverall && island.stateMode !== "EXPANDED" && island.stateMode !== "TRANSIENT") {
          isRevealed = false
        }
      }



      // =========================================================================
      // Reserved Spacer Window: Invisible layer reserving top exclusive zone
      // In Focus Mode, exclusionMode is set to Ignore so tiling windows expand to y=0!
      // =========================================================================
      PanelWindow {
        id: reservedSpacerWindow
        screen: screenScope.modelData
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
          top: true
          left: true
          right: true
        }

        exclusionMode: Config.focusMode ? ExclusionMode.Ignore : ExclusionMode.Auto

        implicitHeight: Config.isNotch ? (Config.notch.idle_height + 5) : (Config.island.top_margin + Config.island.idle_height + 5)

        // Zero click-blocking: completely empty input mask so all clicks pass through to windows below
        mask: Region {}
      }

      // =========================================================================
      // Backdrop Window: Covers screen only when EXPANDED to catch outside clicks
      // =========================================================================
      PanelWindow {
        id: backdropWindow
        screen: screenScope.modelData
        visible: island.stateMode === "EXPANDED"
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        exclusionMode: ExclusionMode.Ignore

        MouseArea {
          anchors.fill: parent
          onClicked: {
            island.collapse()
          }
        }
      }

      // =========================================================================
      // Island Window: Stable, non-reallocating top overlay canvas
      // =========================================================================
      PanelWindow {
        id: islandWindow
        screen: screenScope.modelData
        color: "transparent"
        WlrLayershell.layer: island.stateMode === "EXPANDED" ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: {
          if (island.stateMode === "EXPANDED" && island.expandedActiveTab === "LAUNCHER") {
            return WlrKeyboardFocus.Exclusive
          }
          if (island.stateMode === "EXPANDED") {
            return WlrKeyboardFocus.OnDemand
          }
          return WlrKeyboardFocus.None
        }

        anchors {
          top: true
        }

        exclusionMode: ExclusionMode.Ignore

        // Fixed high-performance GPU canvas (prevents Wayland surface resize roundtrip latency)
        implicitWidth: 1200
        implicitHeight: 560

        // Zero click-blocking: Precision Wayland input mask conforms strictly to island bounds
        mask: Region {
          item: activeInputEnvelope
        }

        // Precision Wayland Input Envelope
        Rectangle {
          id: activeInputEnvelope
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: Math.max(island.width + 40, 320)
          height: {
            if (!screenScope.isRevealed) {
              return screenScope.shouldAutoHide ? 12 : (Config.isNotch ? Config.notch.idle_height : (Config.island.top_margin + Config.island.idle_height))
            }
            if (island.stateMode === "EXPANDED") {
              return Math.max(island.implicitHeight + 30, 360)
            }
            return Config.isNotch ? (Config.notch.hover_height + 6) : (Config.island.top_margin + Config.island.hover_height + 6)
          }
          color: "transparent"
        }

        // Slim 12px Top Edge Reveal Trigger Hotspot (Active only when auto-hide is armed)
        Rectangle {
          id: topHotspot
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: Math.max(island.width + 40, 320)
          height: screenScope.shouldAutoHide ? 12 : 0
          color: "transparent"
          visible: screenScope.shouldAutoHide

          MouseArea {
            id: topHotspotMouseArea
            anchors.fill: parent
            hoverEnabled: true
          }
        }

        DynamicIsland {
          id: island
          ipc: ipcService
          isScreenFocused: screenScope.isFocusedMonitor
          anchors.horizontalCenter: parent.horizontalCenter
          y: screenScope.isRevealed ? (Config.isNotch ? 0 : Config.activeGeometry.top_margin) : (-island.implicitHeight - 12)
          opacity: screenScope.isRevealed ? 1.0 : 0.0
          scale: screenScope.isRevealed ? 1.0 : 0.92

          Behavior on y {
            NumberAnimation {
              duration: screenScope.isRevealed ? 190 : 150
              easing.type: screenScope.isRevealed ? Easing.OutCubic : Easing.InCubic
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: screenScope.isRevealed ? 170 : 130
              easing.type: Easing.OutQuad
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: screenScope.isRevealed ? 190 : 150
              easing.type: Easing.OutCubic
            }
          }
        }

        Connections {
          target: island
          function onStateModeChanged() {
            if (island.stateMode === "EXPANDED") {
              screenScope.isRevealed = true
            } else if (island.stateMode === "IDLE" && screenScope.shouldAutoHide && !screenScope.isHoveredOverall) {
              autoHideTimer.restart()
            }
          }
        }

        PinnedMetricsWidget {
          id: pinnedMetrics
          ipc: ipcService
          islandStateMode: island.stateMode
          anchors.left: island.right
          anchors.leftMargin: 12
          visible: opacity > 0.0 && screenScope.isRevealed
          y: island.y + (Config.isNotch ? Math.round((Config.notch.idle_height - height) / 2) : Math.round((Config.island.top_margin + (Config.island.idle_height - height) / 2)))
        }

        // Reveal Latch Timer: Prevents early dismiss while island is animating down
        Timer {
          id: revealLatchTimer
          interval: 180
          repeat: false
          onTriggered: {
            if (!screenScope.isHoveredOverall && screenScope.shouldAutoHide && island.stateMode !== "EXPANDED" && island.stateMode !== "TRANSIENT") {
              autoHideTimer.restart()
            }
          }
        }

        // Auto-Hide Debounce Timer: Smooth 350ms dismissal after user leaves the island
        Timer {
          id: autoHideTimer
          interval: 350
          repeat: false
          onTriggered: {
            if (!screenScope.isHoveredOverall && screenScope.shouldAutoHide && island.stateMode !== "EXPANDED" && island.stateMode !== "TRANSIENT") {
              screenScope.isRevealed = false
            }
          }
        }
      }



      // =========================================================================
      // Power Overlay Window: Fullscreen Dark Glass Session Modal
      // =========================================================================
      PanelWindow {
        id: powerOverlayWindow
        screen: screenScope.modelData
        visible: PowerService.isPowerMenuOpen
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: PowerService.isPowerMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        exclusionMode: ExclusionMode.Ignore

        PowerOverlay {
          anchors.fill: parent
        }
      }
    }
  }
}
