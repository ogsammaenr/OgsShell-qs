import QtQuick
import Quickshell

Rectangle {
  id: root
  required property var group

  signal closeRequested()
  signal workspaceSelected(int wsId)

  width: 860
  height: 510
  radius: 20

  color: group.theme.bg
  border.color: highlightIndex >= 0 ? group.theme.accent : group.theme.border
  border.width: 1.5

  property int highlightIndex: 0

  // Focus item for keyboard events
  focus: true

  // Auto-focus when shown
  onVisibleChanged: {
    if (visible) {
      forceActiveFocus();
      syncActiveWorkspaceHighlight();
    }
  }

  Component.onCompleted: {
    syncActiveWorkspaceHighlight();
  }

  // Pre-defined workspaces list (1 to 10)
  readonly property var workspaceList: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  function getMonitorForWorkspace(wsId) {
    var state = workspaceService.workspaceState;
    if (state && state.workspaces && state.monitors) {
      for (var i = 0; i < state.workspaces.length; i++) {
        var ws = state.workspaces[i];
        if (ws.id === wsId) {
          for (var j = 0; j < state.monitors.length; j++) {
            var m = state.monitors[j];
            if (m.name === ws.monitor || m.id === ws.monitorID) {
              return m;
            }
          }
        }
      }
      for (var k = 0; k < state.monitors.length; k++) {
        if (state.monitors[k].name === group.screen.name) {
          return state.monitors[k];
        }
      }
    }
    return { x: 0, y: 0, width: 1920, height: 1080 };
  }

  function syncActiveWorkspaceHighlight() {
    var state = workspaceService.workspaceState;
    if (state && state.monitors) {
      for (var i = 0; i < state.monitors.length; i++) {
        var m = state.monitors[i];
        if (m.name === group.screen.name || m.focused) {
          if (m.activeWorkspace && m.activeWorkspace.id) {
            var activeId = m.activeWorkspace.id;
            for (var j = 0; j < workspaceList.length; j++) {
              if (workspaceList[j] === activeId) {
                highlightIndex = j;
                return;
              }
            }
          }
        }
      }
    }
    highlightIndex = 0;
  }

  function cycleSelection(delta) {
    var total = workspaceList.length;
    highlightIndex = (highlightIndex + delta + total) % total;
  }

  function cycleCol(delta) {
    var col = highlightIndex % 5;
    if (delta < 0) {
      highlightIndex = (col === 0) ? highlightIndex + 4 : highlightIndex - 1;
    } else {
      highlightIndex = (col === 4) ? highlightIndex - 4 : highlightIndex + 1;
    }
  }

  function cycleRow(delta) {
    if (delta < 0) {
      highlightIndex = (highlightIndex < 5) ? highlightIndex + 5 : highlightIndex - 5;
    } else {
      highlightIndex = (highlightIndex >= 5) ? highlightIndex - 5 : highlightIndex + 5;
    }
  }

  function confirmSelection() {
    console.log("WorkspaceSwitcher: confirmSelection called, highlightIndex =", highlightIndex);
    if (highlightIndex >= 0 && highlightIndex < workspaceList.length) {
      root.workspaceSelected(workspaceList[highlightIndex]);
    }
  }

  // Unified Keyboard navigation handler
  Keys.onPressed: (event) => {
    var key = event.key;
    if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) {
      confirmSelection();
      event.accepted = true;
    } else if (key === Qt.Key_Escape) {
      closeRequested();
      event.accepted = true;
    } else if (key === Qt.Key_Tab) {
      cycleSelection(1);
      event.accepted = true;
    } else if (key === Qt.Key_Backtab) {
      cycleSelection(-1);
      event.accepted = true;
    } else if (key === Qt.Key_H || key === Qt.Key_Left) {
      cycleCol(-1);
      event.accepted = true;
    } else if (key === Qt.Key_L || key === Qt.Key_Right) {
      cycleCol(1);
      event.accepted = true;
    } else if (key === Qt.Key_K || key === Qt.Key_Up) {
      cycleRow(-1);
      event.accepted = true;
    } else if (key === Qt.Key_J || key === Qt.Key_Down) {
      cycleRow(1);
      event.accepted = true;
    } else if (key >= Qt.Key_1 && key <= Qt.Key_9) {
      var num = key - Qt.Key_0;
      workspaceSelected(num);
      event.accepted = true;
    } else if (key === Qt.Key_0) {
      workspaceSelected(10);
      event.accepted = true;
    }
  }

  // Prevent background clicks passing through
  MouseArea {
    anchors.fill: parent
    onPressed: (mouse) => mouse.accepted = true
  }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 14

    // 1. Header Section
    Item {
      width: parent.width
      height: 32

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
          text: "\uf009" // Grid icon
          color: group.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 18 }
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "Çalışma Alanları Genel Bakış"
          color: group.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 16; weight: Font.Bold }
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      // Shortcut Hints Badge
      Rectangle {
        height: 24
        width: hintRow.width + 16
        radius: 12
        color: group.theme.buttonBg
        border.color: group.theme.border
        border.width: 1
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Row {
          id: hintRow
          anchors.centerIn: parent
          spacing: 12

          Text {
            text: "HJKL / Yön Tuşları: Gezin"
            color: group.theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 9 }
          }

          Text {
            text: "Enter: Geç"
            color: group.theme.accent
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
          }

          Text {
            text: "Esc: Kapat"
            color: group.theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 9 }
          }
        }
      }
    }

    // 2. Workspaces Grid (2 Rows x 5 Columns)
    Grid {
      width: parent.width
      height: parent.height - 32 - 14
      columns: 5
      spacing: 12

      Repeater {
        model: root.workspaceList

        delegate: Rectangle {
          id: wsCard
          width: (parent.width - 4 * 12) / 5
          height: (parent.height - 12) / 2
          radius: 12

          readonly property int wsId: modelData
          readonly property bool isHighlighted: (index === root.highlightIndex)

          // Check if this workspace is active on any monitor
          readonly property bool isActiveOnMonitor: {
            var state = workspaceService.workspaceState;
            if (state && state.monitors) {
              for (var i = 0; i < state.monitors.length; i++) {
                if (state.monitors[i].activeWorkspace && state.monitors[i].activeWorkspace.id === wsId) {
                  return true;
                }
              }
            }
            return false;
          }

          // Check clients in this workspace
          readonly property var wsClients: {
            var state = workspaceService.workspaceState;
            var list = [];
            if (state && state.clients) {
              for (var i = 0; i < state.clients.length; i++) {
                var c = state.clients[i];
                if (c.workspace && c.workspace.id === wsId && c.mapped && !c.hidden) {
                  list.push(c);
                }
              }
            }
            return list;
          }

          color: isHighlighted ? Qt.rgba(1, 1, 1, 0.12) : (isActiveOnMonitor ? Qt.rgba(1, 1, 1, 0.06) : group.theme.buttonBg)
          border.color: isHighlighted ? group.theme.accent : (isActiveOnMonitor ? group.theme.accent : group.theme.border)
          border.width: isHighlighted ? 2 : (isActiveOnMonitor ? 1.5 : 1)
          scale: isHighlighted ? 1.04 : 1.0

          Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
          }
          Behavior on color {
            ColorAnimation { duration: 120 }
          }

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Workspace Header Row inside Card
            Item {
              width: parent.width
              height: 18

              Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                  width: 20
                  height: 18
                  radius: 5
                  color: isHighlighted ? group.theme.accent : (isActiveOnMonitor ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.3))

                    Text {
                      text: wsId.toString()
                      color: isHighlighted ? group.theme.textOnAccent : group.theme.textPrimary
                      font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
                      anchors.centerIn: parent
                    }
                }

                Text {
                  text: isActiveOnMonitor ? "Aktif" : ""
                  color: group.theme.accent
                  font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              // Window count badge
              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                visible: wsClients.length > 0

                Text {
                  text: "\uf2d0"
                  color: group.theme.textSecondary
                  font { family: "FiraCode Nerd Font"; pixelSize: 9 }
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: wsClients.length.toString()
                  color: group.theme.textSecondary
                  font { family: "JetBrains Mono"; pixelSize: 9 }
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }

            // Mini Window Layout Preview Box
            Rectangle {
              id: previewBox
              width: parent.width
              height: parent.height - 18 - 6
              radius: 8
              color: Qt.rgba(0, 0, 0, 0.25)
              border.color: isHighlighted ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(255, 255, 255, 0.05)
              border.width: 1
              clip: true

              readonly property var targetMon: root.getMonitorForWorkspace(wsId)
              readonly property real monX: targetMon ? (targetMon.x || 0) : 0
              readonly property real monY: targetMon ? (targetMon.y || 0) : 0
              readonly property real monW: targetMon ? (targetMon.width || 1920) : 1920
              readonly property real monH: targetMon ? (targetMon.height || 1080) : 1080

              // Render mini scaled window rectangles
              Repeater {
                model: wsClients

                delegate: Rectangle {
                  readonly property var clientData: modelData
                  readonly property real relX: Math.max(0, (clientData.at ? clientData.at[0] : 0) - previewBox.monX)
                  readonly property real relY: Math.max(0, (clientData.at ? clientData.at[1] : 0) - previewBox.monY)

                  x: Math.max(0, Math.min(previewBox.width - 12, relX * (previewBox.width / previewBox.monW)))
                  y: Math.max(0, Math.min(previewBox.height - 12, relY * (previewBox.height / previewBox.monH)))
                  width: Math.max(18, Math.min(previewBox.width - x, (clientData.size ? clientData.size[0] : 100) * (previewBox.width / previewBox.monW)))
                  height: Math.max(14, Math.min(previewBox.height - y, (clientData.size ? clientData.size[1] : 100) * (previewBox.height / previewBox.monH)))

                  radius: 4
                  color: Qt.rgba(1, 1, 1, 0.2)
                  border.color: group.theme.accent
                  border.width: 1

                  Column {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    spacing: 1
                    clip: true

                    Text {
                      text: clientData.class ? clientData.class : "app"
                      color: "#ffffff"
                      font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
                      elide: Text.ElideRight
                      anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                      text: clientData.title ? clientData.title : ""
                      color: Qt.rgba(1, 1, 1, 0.7)
                      font { family: "JetBrains Mono"; pixelSize: 6 }
                      elide: Text.ElideRight
                      anchors.horizontalCenter: parent.horizontalCenter
                      visible: parent.height >= 22
                    }
                  }
                }
              }

              // Empty workspace placeholder
              Column {
                anchors.centerIn: parent
                spacing: 4
                visible: wsClients.length === 0

                Text {
                  text: "\uf068"
                  color: group.theme.textSecondary
                  font { family: "FiraCode Nerd Font"; pixelSize: 12 }
                  anchors.horizontalCenter: parent.horizontalCenter
                  opacity: 0.5
                }

                Text {
                  text: "Boş"
                  color: group.theme.textSecondary
                  font { family: "JetBrains Mono"; pixelSize: 8 }
                  anchors.horizontalCenter: parent.horizontalCenter
                  opacity: 0.5
                }
              }
            }
          }

          // Mouse Hover & Click Area
          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
              root.highlightIndex = index;
            }

            onClicked: {
              root.workspaceSelected(wsCard.wsId);
            }
          }
        }
      }
    }
  }
}
