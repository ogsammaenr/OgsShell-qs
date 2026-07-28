import Quickshell
import QtQuick

Rectangle {
  id: workspaceContainer
  required property var screen
  required property var theme

  readonly property var defaultWorkspaces: [
    { "id": 1, "name": "1", "windows": 0 },
    { "id": 2, "name": "2", "windows": 0 },
    { "id": 3, "name": "3", "windows": 0 },
    { "id": 4, "name": "4", "windows": 0 }
  ]

  // Filter workspaces for this monitor
  property var localWorkspaces: {
    if (!screen || !workspaceService.workspaceState || !workspaceService.workspaceState.workspaces) {
      return defaultWorkspaces;
    }
    var list = [];
    var workspaces = workspaceService.workspaceState.workspaces;
    for (var i = 0; i < workspaces.length; i++) {
      if (workspaces[i].monitor === screen.name || !workspaces[i].monitor) {
        list.push(workspaces[i]);
      }
    }
    if (list.length === 0) {
      if (workspaces.length > 0) return workspaces;
      return defaultWorkspaces;
    }
    return list;
  }

  // Find active workspace ID for this monitor
  property int activeWorkspaceId: {
    if (!screen || !workspaceService.workspaceState || !workspaceService.workspaceState.monitors) return 1;
    var monitors = workspaceService.workspaceState.monitors;
    for (var i = 0; i < monitors.length; i++) {
      var m = monitors[i];
      if ((m.name === screen.name || m.id === screen.id) && m.activeWorkspace && m.activeWorkspace.id !== undefined) {
        return Number(m.activeWorkspace.id);
      }
    }
    for (var j = 0; j < monitors.length; j++) {
      if (monitors[j].focused && monitors[j].activeWorkspace && monitors[j].activeWorkspace.id !== undefined) {
        return Number(monitors[j].activeWorkspace.id);
      }
    }
    return (localWorkspaces.length > 0 && localWorkspaces[0].id !== undefined) ? Number(localWorkspaces[0].id) : 1;
  }

  width: workspaceRow.width + 32
  height: 30
  radius: height / 2

  color: (typeof gameModeService !== "undefined" && gameModeService.isGameModeActive) ? "transparent" : theme.bg
  border.color: (typeof gameModeService !== "undefined" && gameModeService.isGameModeActive) ? "transparent" : theme.border
  border.width: 1

  // Smooth width animation as workspaces are active/inactive
  Behavior on width {
    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
  }

  // Row of workspaces
  Row {
    id: workspaceRow
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: 22
    spacing: 8

    Repeater {
      model: workspaceContainer.localWorkspaces

      Rectangle {
        id: dotItem
        readonly property bool isActive: Number(modelData.id) === Number(workspaceContainer.activeWorkspaceId)
        readonly property bool isHovered: dotMouse.containsMouse
        readonly property bool isPressed: dotMouse.pressed
        
        width: isActive ? 16 : 5
        height: 5
        radius: 2.5

        // Color based on active status and hover
        color: isActive 
          ? theme.accent 
          : (isHovered 
              ? ((modelData.windows > 0) ? "#c0ffffff" : "#60ffffff")
              : ((modelData.windows > 0) ? "#80ffffff" : "#30ffffff"))

        opacity: isPressed ? 0.6 : 1.0

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 80 } }
        Behavior on width {
          NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        MouseArea {
          id: dotMouse
          anchors.fill: parent
          anchors.margins: -8
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            var target = (modelData.id !== undefined) ? modelData.id.toString() : modelData.name;
            Quickshell.execDetached(["sh", "-c", "hyprctl dispatch workspace " + target]);
          }
        }
      }
    }
  }
}
