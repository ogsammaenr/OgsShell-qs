import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "components/island"
import "components/widgets"
import "components/widgets/controlcenter"
import "components/corners"
import "components/bottomnotch"
import "components/capture"
import "components/inspector"

Scope {
  id: rootScope
  // ogsammaenr
  // Global Typography Fonts
  FontLoader {
    id: fontNotoSansDisplay
    source: Qt.resolvedUrl("assets/fonts/NotoSansDisplay.ttf")
    onStatusChanged: {
      if (status === FontLoader.Ready) console.log("[Typography] Loaded font:", name, "from assets/fonts/NotoSansDisplay.ttf")
      else if (status === FontLoader.Error) console.warn("[Typography] Failed to load assets/fonts/NotoSansDisplay.ttf")
    }
  }
  FontLoader { id: fontOutfit; source: Qt.resolvedUrl("assets/fonts/Outfit.ttf") }
  FontLoader { id: fontInter; source: Qt.resolvedUrl("assets/fonts/Inter.ttf") }
  FontLoader { id: fontPlusJakarta; source: Qt.resolvedUrl("assets/fonts/PlusJakartaSans.ttf") }

  // IPC Service instance
  DaemonIPC {
    id: ipcService
  }

  // Bottom Notch, Snipping, Window Inspector & App IPC Signals Listener
  Connections {
    target: ipcService
    function onAppToggleRequested(payload) {
      if (payload && (payload.app === "bottom_notch" || payload.app === "command_runner" || payload.app === "runner")) {
        BottomNotchService.toggle(payload.subview || "");
      } else if (payload && (payload.app === "snipping" || payload.app === "snip" || payload.app === "capture")) {
        if (SnippingService.isOpen) {
          SnippingService.close();
        } else {
          ipcService.freezeScreen(payload.subview || "SS");
        }
      } else if (payload && (payload.app === "inspector" || payload.app === "window_inspector")) {
        WindowInspectorService.toggle();
      }
    }
    function onAppOpenRequested(payload) {
      if (payload && (payload.app === "bottom_notch" || payload.app === "command_runner" || payload.app === "runner")) {
        BottomNotchService.open(payload.subview || "");
      } else if (payload && (payload.app === "snipping" || payload.app === "snip" || payload.app === "capture")) {
        ipcService.freezeScreen(payload.subview || "SS");
      } else if (payload && (payload.app === "inspector" || payload.app === "window_inspector")) {
        WindowInspectorService.open();
      }
    }
    function onAppCloseRequested(payload) {
      if (payload && (payload.app === "bottom_notch" || payload.app === "command_runner" || payload.app === "runner")) {
        BottomNotchService.close();
      } else if (payload && (payload.app === "snipping" || payload.app === "snip" || payload.app === "capture")) {
        SnippingService.close();
      } else if (payload && (payload.app === "inspector" || payload.app === "window_inspector")) {
        WindowInspectorService.close();
      }
    }
    function onScreenFrozen(payload) {
      SnippingService.openWithPayload(payload);
    }
  }

  // Global Audio Feedback Service (Volume Change Sound Pop)
  AudioFeedbackService {
    id: audioFeedbackService
  }

  // Global Corner Island HUD Service (Volume, Workspace, CapsLock, Mic, Clipboard OSD)
  CornerHUDService {
    id: cornerHudService
    ipc: ipcService
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
      let urgStr = "normal";
      if (typeof notif.urgency === "number") {
        if (notif.urgency === 0) urgStr = "low";
        else if (notif.urgency === 2) urgStr = "critical";
        else urgStr = "normal";
      } else if (typeof notif.urgency === "string" && notif.urgency.trim().length > 0) {
        urgStr = notif.urgency.trim().toLowerCase();
      }

      ipcService.addNotification(
        notif.appName || "System",
        notif.summary || "Notification",
        notif.body || "",
        notif.appIcon || "",
        urgStr
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
        visible: !Config.focusMode
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
          top: true
          left: true
          right: true
        }

        exclusionMode: Config.focusMode ? ExclusionMode.Ignore : ExclusionMode.Auto

        implicitHeight: Config.isNotch ? (Config.notchIdleHeight + 5) : (Config.islandTopMargin + Config.islandIdleHeight + 5)

        // Zero click-blocking: completely empty input mask so all clicks pass through to windows below
        mask: Region {}
      }

      // =========================================================================
      // Backdrop Window (Lazy Loaded): Covers screen only when EXPANDED to catch outside clicks
      // =========================================================================
      LazyLoader {
        id: backdropLoader
        active: (island.stateMode === "EXPANDED") || (topRightTrayHud && topRightTrayHud.isExpanded) || (BottomNotchService.isOpen && screenScope.isFocusedMonitor)

        PanelWindow {
          id: backdropWindow
          screen: screenScope.modelData
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
              if (topRightTrayHud && topRightTrayHud.isExpanded) {
                if (topRightTrayHud.isMenuOpen) {
                  topRightTrayHud.closeMenu()
                } else {
                  topRightTrayHud.collapse()
                }
              }
              if (BottomNotchService.isOpen) {
                BottomNotchService.close()
              }
            }
          }
        }
      }

      // =========================================================================
      // Unified Top Overlay Window: Hosts DynamicIsland, PinnedMetrics, Top-Left
      // CornerIslandHUD, and Top-Right Tray/Corner in ONE EGL surface per monitor
      // (Eliminates 4 redundant NVIDIA EGL PanelWindow contexts across 2 monitors)
      // =========================================================================
      PanelWindow {
        id: islandWindow
        screen: screenScope.modelData
        color: "transparent"
        WlrLayershell.layer: (island.stateMode === "EXPANDED"
          || (topLeftCornerHud && topLeftCornerHud.isExpanded)
          || (topRightTrayHud && topRightTrayHud.isExpanded)) ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: {
          if (island.stateMode === "EXPANDED" && (island.expandedActiveTab === "LAUNCHER" || island.expandedActiveTab === "KEYRING")) {
            return WlrKeyboardFocus.Exclusive
          }
          if (island.stateMode === "EXPANDED") {
            return WlrKeyboardFocus.OnDemand
          }
          return WlrKeyboardFocus.None
        }

        anchors {
          top: true
          left: true
          right: true
        }

        exclusionMode: ExclusionMode.Ignore

        // Fixed GPU canvas covering max expanded island (440px) + top corners/tray
        implicitHeight: 470

        // Precision Multi-Region Wayland Input Mask: Only Island & Top-Right Tray receive clicks
        mask: Region {
          Region {
            item: activeInputEnvelope
          }
          Region {
            item: activeTrayInputEnvelope
          }
        }

        // Precision Wayland Input Envelope for Dynamic Island
        Rectangle {
          id: activeInputEnvelope
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: {
            if (SnippingService.isOpen || !screenScope.isRevealed) {
              return topHotspot.width
            }
            return island.width + (Config.isNotch ? 10 : 0)
          }
          height: {
            if (SnippingService.isOpen || !screenScope.isRevealed) {
              return screenScope.shouldAutoHide ? 12 : 0
            }
            return Math.max(screenScope.shouldAutoHide ? 12 : 0, Math.round(island.y + island.height + (island.extraStackHeight || 0)))
          }
          color: "transparent"
        }

        // Precision Wayland Input Envelope for Top-Right Tray HUD
        Item {
          id: activeTrayInputEnvelope
          anchors.top: parent.top
          anchors.right: parent.right
          readonly property bool trayActive: Config.screenCornersEnabled && (Config.screenCornersRadius > 0) && Config.cornerTrayEnabled && !SnippingService.isOpen
          width: trayActive && topRightTrayHud
            ? (topRightTrayHud.isExpanded ? (topRightTrayHud.isMenuOpen ? Math.max(topRightTrayHud.width, 155) : topRightTrayHud.width) : Math.max(topRightTrayHud.radius + 12, 28))
            : 0
          height: trayActive && topRightTrayHud
            ? (topRightTrayHud.isExpanded ? (topRightTrayHud.isMenuOpen ? (topRightTrayHud.height + 72) : topRightTrayHud.height) : Math.max(topRightTrayHud.radius + 12, 28))
            : 0
        }

        // Top-Left Corner Cutout & Dynamic OSD HUD (Click-through)
        ScreenCorners {
          id: topLeftCornerHud
          anchors.top: parent.top
          anchors.left: parent.left
          width: 380
          height: 90
          visible: Config.screenCornersEnabled && (Config.screenCornersRadius > 0) && Config.screenCornerTopLeft
          screen: screenScope.modelData
          hyprMonitor: screenScope.hyprMonitor
          radius: Config.screenCornersRadius
          cornerColor: Config.screenCornersColor
          cornerMode: "TOP_LEFT"
          hudService: cornerHudService
        }

        // Top-Right Static Corner Cutout (Only when Tray HUD is disabled)
        ScreenCorners {
          anchors.top: parent.top
          anchors.right: parent.right
          width: Config.screenCornersRadius
          height: Config.screenCornersRadius
          visible: Config.screenCornersEnabled && (Config.screenCornersRadius > 0) && Config.screenCornerTopRight && !Config.cornerTrayEnabled
          radius: Config.screenCornersRadius
          cornerColor: Config.screenCornersColor
          cornerMode: "TOP_RIGHT"
        }

        // Top-Right Interactive System Tray HUD
        TopRightTrayHUD {
          id: topRightTrayHud
          parentWindow: islandWindow
          anchors.top: parent.top
          anchors.right: parent.right
          visible: Config.screenCornersEnabled && (Config.screenCornersRadius > 0) && Config.cornerTrayEnabled
          radius: Config.screenCornersRadius
          cornerColor: Config.screenCornersColor
        }

        // Slim 12px Top Edge Reveal Trigger Hotspot (Active only when auto-hide is armed)
        Rectangle {
          id: topHotspot
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: Math.max(island.width + 40, 320)
          height: screenScope.shouldAutoHide ? 12 : 0
          color: "transparent"
          visible: screenScope.shouldAutoHide && !SnippingService.isOpen

          MouseArea {
            id: topHotspotMouseArea
            anchors.fill: parent
            hoverEnabled: true
          }
        }

        DynamicIsland {
          id: island
          ipc: ipcService
          audioFeedback: audioFeedbackService
          screen: screenScope.modelData
          hyprMonitor: screenScope.hyprMonitor
          isScreenFocused: screenScope.isFocusedMonitor
          anchors.horizontalCenter: parent.horizontalCenter
          y: SnippingService.isOpen ? (-island.implicitHeight - 24) : (screenScope.isRevealed ? (Config.isNotch ? 0 : Config.islandTopMargin) : (-island.implicitHeight - 12))
          opacity: SnippingService.isOpen ? 0.0 : (screenScope.isRevealed ? 1.0 : 0.0)
          scale: screenScope.isRevealed ? 1.0 : 0.92

          Behavior on y {
            NumberAnimation {
              duration: screenScope.isRevealed ? 240 : 180
              easing.type: screenScope.isRevealed ? Easing.OutCubic : Easing.InCubic
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: screenScope.isRevealed ? 220 : 160
              easing.type: Easing.OutQuad
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: screenScope.isRevealed ? 240 : 180
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
          visible: opacity > 0.0 && screenScope.isRevealed && !SnippingService.isOpen
          y: island.y + (Config.isNotch ? Math.round((Config.notchIdleHeight - height) / 2) : Math.round((Config.islandTopMargin + (Config.islandIdleHeight - height) / 2)))
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
      // Bottom Corners Strip Window: Single thin 14px window for both bottom corners
      // (Replaces fullscreen 1920x1080 window AND avoids separate BL/BR EGL contexts)
      // =========================================================================
      LazyLoader {
        active: Config.screenCornersEnabled && (Config.screenCornersRadius > 0) && (Config.screenCornerBottomLeft || Config.screenCornerBottomRight)

        PanelWindow {
          id: bottomCornersWindow
          screen: screenScope.modelData
          color: "transparent"
          WlrLayershell.layer: WlrLayer.Top
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

          anchors {
            bottom: true
            left: true
            right: true
          }

          implicitHeight: Config.screenCornersRadius
          exclusionMode: ExclusionMode.Ignore
          mask: Region {}

          ScreenCorners {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: Config.screenCornersRadius
            height: Config.screenCornersRadius
            visible: Config.screenCornerBottomLeft
            radius: Config.screenCornersRadius
            cornerColor: Config.screenCornersColor
            cornerMode: "BOTTOM_LEFT"
          }

          ScreenCorners {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: Config.screenCornersRadius
            height: Config.screenCornersRadius
            visible: Config.screenCornerBottomRight
            radius: Config.screenCornersRadius
            cornerColor: Config.screenCornersColor
            cornerMode: "BOTTOM_RIGHT"
          }
        }
      }

      // =========================================================================
      // Power Overlay Window (Lazy Loaded): Fullscreen Dark Glass Session Modal
      // =========================================================================
      LazyLoader {
        active: PowerService.isPowerMenuOpen

        PanelWindow {
          id: powerOverlayWindow
          screen: screenScope.modelData
          color: "transparent"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

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

      // =========================================================================
      // Bottom Command Notch Window (Lazy Loaded & Compact Centered Surface)
      // =========================================================================
      LazyLoader {
        active: BottomNotchService.isOpen && screenScope.isFocusedMonitor

        PanelWindow {
          id: bottomNotchWindow
          screen: screenScope.modelData
          color: "transparent"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

          anchors {
            bottom: true
          }

          exclusionMode: ExclusionMode.Ignore

          implicitWidth: 640
          implicitHeight: 400

          mask: Region {
            item: activeBottomInputEnvelope
          }

          Rectangle {
            id: activeBottomInputEnvelope
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: bottomNotch.width + 16
            height: bottomNotch.height + 10
            color: "transparent"
          }

          BottomCommandNotch {
            id: bottomNotch
            ipc: ipcService
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
      }

      // =========================================================================
      // Snipping & Freeze Overlay Window (Lazy Loaded): 0 MB RAM when idle
      // =========================================================================
      LazyLoader {
        active: SnippingService.isOpen

        SnippingOverlay {
          id: snippingOverlayWindow
          screen: screenScope.modelData
          monitorName: screenScope.modelData.name
          hyprMonitor: screenScope.hyprMonitor
          ipc: ipcService
          isFocusedScreen: screenScope.isFocusedMonitor
        }
      }

      // =========================================================================
      // Window Inspector Overlay (Lazy Loaded): 0 MB RAM when idle
      // =========================================================================
      LazyLoader {
        active: WindowInspectorService.isOpen

        WindowInspectorOverlay {
          id: inspectorOverlayWindow
          screen: screenScope.modelData
          monitorName: screenScope.modelData.name
          hyprMonitor: screenScope.hyprMonitor
          ipc: ipcService
          isFocusedScreen: screenScope.isFocusedMonitor
        }
      }
    }
  }
}
