import QtQuick
import QtQuick.Shapes
import Quickshell.Hyprland
import "../.."

Item {
  id: root

  property var screen: null
  property var hyprMonitor: null
  property var hudService: null
  property int radius: 14
  property color cornerColor: "#000000"
  // "ALL" | "TOP_LEFT" | "TOP_RIGHT" | "BOTTOM_LEFT" | "BOTTOM_RIGHT"
  property string cornerMode: "ALL"
  property bool topLeft: true
  property bool topRight: true
  property bool bottomLeft: true
  property bool bottomRight: true

  readonly property bool showTopLeft: (cornerMode === "ALL" || cornerMode === "TOP_LEFT") && topLeft && radius > 0
  readonly property bool showTopRight: (cornerMode === "ALL" ? (topRight && !Config.cornerTrayEnabled) : (cornerMode === "TOP_RIGHT")) && radius > 0
  readonly property bool showBottomLeft: (cornerMode === "ALL" || cornerMode === "BOTTOM_LEFT") && bottomLeft && radius > 0
  readonly property bool showBottomRight: (cornerMode === "ALL" || cornerMode === "BOTTOM_RIGHT") && bottomRight && radius > 0

  // Reflect corner HUD expanded state for dynamic Wayland layer-shell tiering
  readonly property bool isExpanded: (tlCornerHudLoader.item && tlCornerHudLoader.item.isExpanded) ? true : false

  // Workspace Tracking Isolated to this Screen & Monitor (active only for TOP_LEFT / ALL)
  readonly property int currentWsId: (showTopLeft && hyprMonitor && hyprMonitor.activeWorkspace) ? hyprMonitor.activeWorkspace.id : -1
  property int lastWsId: -1
  property bool isReady: false

  Timer {
    id: startupReadyTimer
    interval: 1000
    repeat: false
    running: root.showTopLeft
    onTriggered: {
      root.lastWsId = root.currentWsId
      root.isReady = true
    }
  }

  readonly property var monitorWorkspaces: {
    if (!root.showTopLeft) return []
    let list = []
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      let allWs = Hyprland.workspaces.values
      for (let i = 0; i < allWs.length; i++) {
        let ws = allWs[i]
        let matches = false
        if (ws.monitor && root.screen && ws.monitor.name === root.screen.name) {
          matches = true
        } else if (ws.monitor && root.hyprMonitor && ws.monitor.id === root.hyprMonitor.id) {
          matches = true
        }
        if (matches && ws.id > 0) {
          list.push(ws.id)
        }
      }
    }
    list.sort((a, b) => a - b)

    if (list.length > 0) {
      if (root.currentWsId > 0 && !list.includes(root.currentWsId)) {
        list.push(root.currentWsId)
        list.sort((a, b) => a - b)
      }
      return list
    }

    if (root.currentWsId > 0) {
      let base = Math.floor((root.currentWsId - 1) / 5) * 5 + 1
      return [base, base + 1, base + 2, base + 3, base + 4]
    }
    return [1, 2, 3, 4, 5]
  }

  onCurrentWsIdChanged: {
    if (!root.showTopLeft || !root.isReady) return
    if (currentWsId > 0 && currentWsId !== lastWsId) {
      lastWsId = currentWsId
      let scrName = root.screen ? root.screen.name : ""
      if (tlCornerHudLoader.item) {
        tlCornerHudLoader.item.showWorkspaceHUD(currentWsId, scrName, root.monitorWorkspaces)
      }
    }
  }

  // Top-Left Dynamic Corner Island HUD (Loaded only when TOP_LEFT / ALL)
  Loader {
    id: tlCornerHudLoader
    active: root.showTopLeft
    anchors.top: parent.top
    anchors.left: parent.left
    sourceComponent: CornerIslandHUD {
      radius: root.radius
      cornerColor: root.cornerColor
      hudService: root.hudService
    }
  }

  // Top-Right Inverted Corner Cutout (CurveRenderer: zero offscreen MSAA FBO)
  Shape {
    id: trCorner
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.radius
    height: root.radius
    visible: root.showTopRight
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.cornerColor
      strokeColor: "transparent"
      strokeWidth: 0
      startX: root.radius
      startY: 0

      PathLine { x: 0; y: 0 }
      PathArc {
        x: root.radius
        y: root.radius
        radiusX: root.radius
        radiusY: root.radius
        direction: PathArc.Clockwise
      }
      PathLine { x: root.radius; y: 0 }
    }
  }

  // Bottom-Left Inverted Corner Cutout
  Shape {
    id: blCorner
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: root.radius
    height: root.radius
    visible: root.showBottomLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.cornerColor
      strokeColor: "transparent"
      strokeWidth: 0
      startX: 0
      startY: root.radius

      PathLine { x: 0; y: 0 }
      PathArc {
        x: root.radius
        y: root.radius
        radiusX: root.radius
        radiusY: root.radius
        direction: PathArc.Counterclockwise
      }
      PathLine { x: 0; y: root.radius }
    }
  }

  // Bottom-Right Inverted Corner Cutout
  Shape {
    id: brCorner
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: root.radius
    height: root.radius
    visible: root.showBottomRight
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.cornerColor
      strokeColor: "transparent"
      strokeWidth: 0
      startX: root.radius
      startY: root.radius

      PathLine { x: root.radius; y: 0 }
      PathArc {
        x: 0
        y: root.radius
        radiusX: root.radius
        radiusY: root.radius
        direction: PathArc.Clockwise
      }
      PathLine { x: root.radius; y: root.radius }
    }
  }
}
