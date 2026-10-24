import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../.."
import "../../backend"
import "../../theme"

PanelWindow {
  id: root

  property string monitorName: ""
  property var hyprMonitor: null
  property var ipc: null
  property bool isFocusedScreen: true

  // Multi-Monitor Geometry Awareness
  readonly property real monitorGlobalX: hyprMonitor ? hyprMonitor.x : 0
  readonly property real monitorGlobalY: hyprMonitor ? hyprMonitor.y : 0

  // Tracked Hovered Window
  property var hoveredWindow: null
  property bool isCopiedFeedback: false

  visible: WindowInspectorService.isOpen
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  // Keep keyboard focus None so Super+Alt release (bindr) is reliably caught by Hyprland
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore

  onVisibleChanged: {
    if (!visible) {
      hoveredWindow = null;
      isCopiedFeedback = false;
    }
  }

  // Timer to dismiss overlay smoothly after copy feedback
  Timer {
    id: dismissTimer
    interval: 220
    repeat: false
    onTriggered: {
      WindowInspectorService.close();
      root.isCopiedFeedback = false;
    }
  }

  // Dismiss on Escape key
  Shortcut {
    sequence: "Escape"
    enabled: WindowInspectorService.isOpen
    onActivated: WindowInspectorService.close()
  }

  // 1. Fullscreen Hover & Click Detection Area
  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: (root.hoveredWindow !== null) ? Qt.PointingHandCursor : Qt.ArrowCursor

    onPositionChanged: mouse => {
      if (!WindowInspectorService.isOpen || root.isCopiedFeedback) return;
      root.updateHoveredWindow(mouse.x, mouse.y);
    }

    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        WindowInspectorService.close();
        return;
      }
      if (root.hoveredWindow && root.hoveredWindow.className && !root.isCopiedFeedback) {
        let cls = root.hoveredWindow.className;
        if (root.ipc && typeof root.ipc.copyClipboardItem === "function") {
          root.ipc.copyClipboardItem("", cls);
        }
        WindowInspectorService.notifyCopied(cls);
        root.isCopiedFeedback = true;
        dismissTimer.restart();
      }
    }
  }

  // 2. Active Window Subtle Accent Highlight (Gentle Tiling Border)
  Rectangle {
    id: windowHighlight
    visible: root.hoveredWindow !== null
    x: root.hoveredWindow ? root.hoveredWindow.localX : 0
    y: root.hoveredWindow ? root.hoveredWindow.localY : 0
    width: root.hoveredWindow ? root.hoveredWindow.width : 0
    height: root.hoveredWindow ? root.hoveredWindow.height : 0
    color: root.isCopiedFeedback ? Qt.rgba(166/255, 227/255, 161/255, 0.04) : Qt.rgba(137/255, 180/255, 250/255, 0.02)
    radius: 12
    border.width: 1.5
    border.color: root.isCopiedFeedback ? "#a6e3a1" : Qt.rgba(137/255, 180/255, 250/255, 0.40)

    Behavior on border.color {
      ColorAnimation { duration: 150 }
    }
    Behavior on color {
      ColorAnimation { duration: 150 }
    }
  }

  // 3. Apple HIG Style Floating Capsule Badge (Positioned directly ABOVE window top-left)
  Item {
    id: badgeContainer
    visible: root.hoveredWindow !== null && (root.hoveredWindow.className || "").length > 0

    readonly property real badgeHeight: 30
    readonly property real gap: 8
    readonly property real idealY: root.hoveredWindow ? (root.hoveredWindow.localY - badgeHeight - gap) : 0

    // Position directly above the window. If window is touching the screen ceiling, fallback gracefully inside.
    readonly property real targetX: {
      if (!root.hoveredWindow) return 0;
      return Math.max(8, Math.min(root.width - width - 8, root.hoveredWindow.localX + 8));
    }

    readonly property real targetY: {
      if (!root.hoveredWindow) return 0;
      if (idealY >= 8) {
        return idealY;
      }
      return Math.max(8, Math.min(root.height - badgeHeight - 8, root.hoveredWindow.localY + gap));
    }

    x: targetX
    y: targetY

    Behavior on x {
      SpringAnimation { spring: 28.0; damping: 0.78; epsilon: 0.01 }
    }
    Behavior on y {
      SpringAnimation { spring: 28.0; damping: 0.78; epsilon: 0.01 }
    }

    width: badgePill.width
    height: badgeHeight

    opacity: visible ? 1.0 : 0.0
    scale: visible ? 1.0 : 0.90

    Behavior on opacity {
      NumberAnimation { duration: 140 }
    }
    Behavior on scale {
      SpringAnimation { spring: 28.0; damping: 0.78; epsilon: 0.01 }
    }

    // Soft Ambient Glow Drop Shadow
    RectangularGlow {
      anchors.fill: badgePill
      glowRadius: 10
      spread: 0.18
      color: root.isCopiedFeedback ? Qt.rgba(166/255, 227/255, 161/255, 0.28) : Qt.rgba(0, 0, 0, 0.60)
      cornerRadius: badgePill.radius + glowRadius
      z: -1
    }

    // Modern Capsule Pill
    Rectangle {
      id: badgePill
      width: badgeLayout.implicitWidth + 24
      height: 30
      radius: height * 0.5 // Complete Pill Shape

      color: root.isCopiedFeedback ? "#183226" : "#0d0f17"
      border.width: 1
      border.color: root.isCopiedFeedback ? "#a6e3a1" : Qt.rgba(255/255, 255/255, 255/255, 0.18)

      Behavior on color {
        ColorAnimation { duration: 140 }
      }
      Behavior on border.color {
        ColorAnimation { duration: 140 }
      }

      RowLayout {
        id: badgeLayout
        anchors.centerIn: parent
        spacing: 7

        // Status Indicator Dot
        Rectangle {
          width: 6
          height: 6
          radius: 3
          color: root.isCopiedFeedback ? "#a6e3a1" : "#89b4fa"

          Behavior on color {
            ColorAnimation { duration: 140 }
          }
        }

        // App Class Text
        Text {
          text: root.isCopiedFeedback ? ("Kopyalandı: " + (root.hoveredWindow ? root.hoveredWindow.className : ""))
                                      : (root.hoveredWindow ? root.hoveredWindow.className : "")
          font.family: "Noto Sans Display, Plus Jakarta Sans, Inter, Sans-Serif"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          font.letterSpacing: 0.35
          color: root.isCopiedFeedback ? "#a6e3a1" : "#cdd6f4"

          Behavior on color {
            ColorAnimation { duration: 140 }
          }
        }

        // Mini Copy Hint Indicator
        Text {
          visible: !root.isCopiedFeedback
          text: "📋"
          font.pixelSize: 10
          opacity: 0.65
        }
      }
    }
  }

  // 4. Window Detection Logic via Hyprland.toplevels
  function updateHoveredWindow(localX, localY) {
    let globalX = Math.round(root.monitorGlobalX + localX);
    let globalY = Math.round(root.monitorGlobalY + localY);

    let currentWsId = (root.hyprMonitor && root.hyprMonitor.activeWorkspace) ? root.hyprMonitor.activeWorkspace.id : null;
    let toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
    let found = null;

    // Search from topmost (reverse order)
    for (let i = toplevels.length - 1; i >= 0; i--) {
      let win = toplevels[i];
      if (!win) continue;

      let isHidden = (win.hidden === true) || (win.lastIpcObject && win.lastIpcObject.hidden === true);
      if (isHidden) continue;

      // Filter by active workspace only if both currentWsId and winWsId are known
      let winWsId = win.workspace ? win.workspace.id : (win.lastIpcObject && win.lastIpcObject.workspace ? win.lastIpcObject.workspace.id : null);
      if (currentWsId !== null && winWsId !== null && winWsId !== currentWsId) {
        continue;
      }

      let at = (win.lastIpcObject && win.lastIpcObject.at) ? win.lastIpcObject.at : (win.at || [win.x, win.y]);
      let size = (win.lastIpcObject && win.lastIpcObject.size) ? win.lastIpcObject.size : (win.size || [win.width, win.height]);
      if (!at || !size) continue;

      let wx = at[0];
      let wy = at[1];
      let ww = size[0];
      let wh = size[1];

      if (globalX >= wx && globalX <= wx + ww && globalY >= wy && globalY <= wy + wh) {
        let cls = (win.lastIpcObject && win.lastIpcObject.class) ? win.lastIpcObject.class : (win.initialClass || win.class || "");
        if (cls.length > 0) {
          found = {
            globalX: wx,
            globalY: wy,
            width: ww,
            height: wh,
            localX: wx - root.monitorGlobalX,
            localY: wy - root.monitorGlobalY,
            className: cls
          };
          break;
        }
      }
    }

    root.hoveredWindow = found;
  }
}
