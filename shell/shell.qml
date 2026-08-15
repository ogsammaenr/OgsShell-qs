import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "components/island"

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

      // =========================================================================
      // Reserved Spacer Window: Invisible layer reserving top exclusive zone
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

        exclusionMode: ExclusionMode.Auto

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
        WlrLayershell.keyboardFocus: island.stateMode === "EXPANDED" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
          top: true
        }

        exclusionMode: ExclusionMode.Ignore

        // Fixed high-performance GPU canvas (prevents Wayland surface resize roundtrip latency)
        implicitWidth: 540
        implicitHeight: 360

        // Zero click-blocking: Wayland input region strictly conforms to island's dynamic shape
        mask: Region {
          item: island
        }

        DynamicIsland {
          id: island
          ipc: ipcService
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: Config.isNotch ? 0 : Config.activeGeometry.top_margin
        }
      }
    }
  }
}
