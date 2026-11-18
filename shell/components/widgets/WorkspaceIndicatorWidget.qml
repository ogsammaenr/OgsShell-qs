import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "../.."

Item {
  id: root

  property var screen: null
  property var hyprMonitor: null

  readonly property int activeWsId: (hyprMonitor && hyprMonitor.activeWorkspace) ? hyprMonitor.activeWorkspace.id : -1

  // Track which workspaces currently host at least one window
  readonly property var occupiedWorkspaceMap: {
    let map = ({})
    if (Hyprland.workspaces && Hyprland.workspaces.values) {
      let allWs = Hyprland.workspaces.values
      for (let i = 0; i < allWs.length; i++) {
        let ws = allWs[i]
        if (ws && ws.id > 0 && ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0) {
          map[ws.id] = true
        }
      }
    }
    if (Hyprland.toplevels && Hyprland.toplevels.values) {
      let toplevels = Hyprland.toplevels.values
      for (let j = 0; j < toplevels.length; j++) {
        let win = toplevels[j]
        let wsId = win.workspace ? win.workspace.id : (win.lastIpcObject && win.lastIpcObject.workspace ? win.lastIpcObject.workspace.id : -1)
        if (wsId > 0) {
          map[wsId] = true
        }
      }
    }
    return map
  }

  // Per-monitor isolated workspace list sorted ascending by ID
  readonly property var monitorWorkspaces: {
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
      if (root.activeWsId > 0 && !list.includes(root.activeWsId)) {
        list.push(root.activeWsId)
        list.sort((a, b) => a - b)
      }
      return list
    }

    if (root.activeWsId > 0) {
      let base = Math.floor((root.activeWsId - 1) / 5) * 5 + 1
      return [base, base + 1, base + 2, base + 3, base + 4]
    }
    return [1, 2, 3, 4, 5]
  }

  Process {
    id: wsSwitchProc
    property int pendingWsId: -1
    property bool triedLegacy: false

    onExited: (code, status) => {
      if (code !== 0 && !triedLegacy && pendingWsId > 0) {
        triedLegacy = true
        command = ["hyprctl", "dispatch", "workspace", "" + pendingWsId]
        running = true
      }
    }
  }

  function switchToWorkspace(wsId) {
    if (!wsId || wsId <= 0 || wsId === root.activeWsId) return
    wsSwitchProc.running = false
    wsSwitchProc.pendingWsId = wsId
    wsSwitchProc.triedLegacy = false
    wsSwitchProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId + " })"]
    wsSwitchProc.running = true
  }

  function switchWorkspaceStep(delta) {
    let list = root.monitorWorkspaces
    if (!list || list.length === 0) return
    let idx = list.indexOf(root.activeWsId)
    if (idx === -1) idx = 0
    let nextIdx = Math.max(0, Math.min(list.length - 1, idx + delta))
    let targetId = list[nextIdx]
    if (targetId && targetId !== root.activeWsId) {
      root.switchToWorkspace(targetId)
    }
  }

  implicitWidth: dotsRow.implicitWidth
  implicitHeight: 14
  width: implicitWidth
  height: implicitHeight

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
      if (event.angleDelta.y > 0) {
        root.switchWorkspaceStep(-1)
      } else if (event.angleDelta.y < 0) {
        root.switchWorkspaceStep(1)
      }
    }
  }

  Row {
    id: dotsRow
    anchors.centerIn: parent
    spacing: 0

    Repeater {
      model: root.monitorWorkspaces

      Item {
        id: wsSlot
        required property int modelData

        readonly property bool isActive: root.activeWsId === modelData
        readonly property bool isOccupied: !!root.occupiedWorkspaceMap[modelData]

        width: wsShape.width + 6
        height: 14

        Rectangle {
          id: wsShape
          anchors.centerIn: parent
          width: wsSlot.isActive ? 20 : 6
          height: 6
          radius: 3
          scale: wsHover.hovered ? 1.15 : 1.0
          color: {
            if (wsSlot.isActive) return Style.accent
            if (wsHover.hovered) return wsSlot.isOccupied ? Style.accent : Qt.alpha(Style.accent, 0.78)
            return wsSlot.isOccupied ? Qt.alpha(Style.textPrimary, 0.52) : Qt.alpha(Style.textPrimary, 0.22)
          }

          Behavior on width {
            SpringAnimation {
              spring: 28.0
              damping: 0.78
              epsilon: 0.01
            }
          }

          Behavior on color {
            ColorAnimation {
              duration: 180
              easing.type: Easing.OutQuad
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: 140
              easing.type: Easing.OutCubic
            }
          }
        }

        HoverHandler {
          id: wsHover
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          acceptedButtons: Qt.LeftButton
          onTapped: {
            root.switchToWorkspace(wsSlot.modelData)
          }
        }
      }
    }
  }
}
