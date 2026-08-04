import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"

PanelWindow {
  id: switcherWindow
  required property var targetScreen
  required property var monitorGroup

  screen: targetScreen
  visible: monitorGroup.isWorkspaceSwitcherOpen || (switcherCard.opacity > 0.01)
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: monitorGroup.isWorkspaceSwitcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusiveZone: -1 // Float over windows
  aboveWindows: true
  focusable: monitorGroup.isWorkspaceSwitcherOpen
  color: "transparent"

  onVisibleChanged: {
    if (visible && monitorGroup.isWorkspaceSwitcherOpen) {
      switcherCard.forceActiveFocus();
    }
  }

  Connections {
    target: monitorGroup
    function onIsWorkspaceSwitcherOpenChanged() {
      if (monitorGroup.isWorkspaceSwitcherOpen) {
        switcherCard.forceActiveFocus();
      }
    }
  }

  function cycleSelection(delta) {
    switcherCard.cycleSelection(delta);
  }

  function confirmSelection() {
    switcherCard.confirmSelection();
  }

  // Background click-catcher to dismiss
  MouseArea {
    anchors.fill: parent
    onClicked: {
      monitorGroup.isWorkspaceSwitcherOpen = false;
    }
  }

  WorkspaceSwitcher {
    id: switcherCard
    group: monitorGroup
    anchors.centerIn: parent

    opacity: monitorGroup.isWorkspaceSwitcherOpen ? 1.0 : 0.0
    scale: monitorGroup.isWorkspaceSwitcherOpen ? 1.0 : 0.85

    Behavior on opacity {
      NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
      NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    onCloseRequested: {
      monitorGroup.isWorkspaceSwitcherOpen = false;
    }

    onWorkspaceSelected: (wsId) => {
      console.log("WorkspaceSwitcherWindow: Switching to workspace " + wsId);
      monitorGroup.isWorkspaceSwitcherOpen = false;
      Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId.toString() + " })"]);
    }
  }
}
