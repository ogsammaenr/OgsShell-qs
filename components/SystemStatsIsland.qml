import Quickshell
import QtQuick

Rectangle {
  id: statsIsland
  required property var group

  property bool isPinned: false
  readonly property bool isExpanded: hoverArea.containsMouse || isPinned

  readonly property bool cpuVisible: Boolean(systemStatsService && (systemStatsService.showCpuUsageOnBar || systemStatsService.showCpuTempOnBar))
  readonly property bool ramVisible: Boolean(systemStatsService && systemStatsService.showRamUsageOnBar)
  readonly property bool gpuVisible: Boolean(systemStatsService && (systemStatsService.showGpuUsageOnBar || systemStatsService.showGpuTempOnBar))
  readonly property bool netVisible: Boolean(systemStatsService && systemStatsService.showNetSpeedOnBar)

  visible: cpuVisible || ramVisible || gpuVisible || netVisible
  
  height: 30
  radius: 15
  color: group.theme.bg
  border.color: isPinned ? group.theme.accent : group.theme.border
  border.width: 1

  opacity: (group.isControlCenterOpen || group.isTimeManagerOpen || group.isCalendarOpen) ? 0.0 : 1.0
  scale: (group.isControlCenterOpen || group.isTimeManagerOpen || group.isCalendarOpen) ? 0.85 : 1.0
  
  Behavior on opacity {
    NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
  }
  Behavior on scale {
    NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
  }
  Behavior on border.color {
    ColorAnimation { duration: 150 }
  }
  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  // Smooth width transition based on the content row's size
  width: contentRow.width + 24
  Behavior on width {
    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        statsIsland.isPinned = !statsIsland.isPinned;
      }
    }
  }

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: statsIsland.isExpanded ? 12 : 8
    
    Behavior on spacing {
      NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    // CPU Stat Block (Wrapped to prevent Row anchor warnings)
    Item {
      id: cpuBlock
      width: cpuRow.width
      height: 28
      visible: statsIsland.cpuVisible
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: cpuRow
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: "\uf2db" // CPU icon
          color: group.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
          scale: statsIsland.isExpanded ? 1.1 : 1.0
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        Text {
          text: systemStatsService.cpuUsage + "%"
          color: group.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          id: cpuDetail
          width: statsIsland.isExpanded ? (cpuTempText.implicitWidth + 4) : 0
          height: parent.height
          clip: true
          opacity: statsIsland.isExpanded ? 1.0 : 0.0
          visible: opacity > 0.01 && (systemStatsService.showCpuTempOnBar || statsIsland.isExpanded)
          
          Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

          Text {
            id: cpuTempText
            text: "(" + systemStatsService.cpuTemp + "°C)"
            color: (systemStatsService.cpuTemp > 75) ? group.theme.red : ((systemStatsService.cpuTemp > 60) ? "#fbbf24" : group.theme.green)
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.4)
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          if (mouse.button === Qt.MiddleButton) {
            systemStatsService.showCpuUsageOnBar = false;
            systemStatsService.showCpuTempOnBar = false;
          }
        }
      }
    }

    // Divider 1
    Rectangle {
      width: 1
      height: 12
      color: "#20ffffff"
      anchors.verticalCenter: parent.verticalCenter
      visible: cpuBlock.visible && (ramBlock.visible || gpuBlock.visible || netBlock.visible)
    }

    // RAM Stat Block (Wrapped to prevent Row anchor warnings)
    Item {
      id: ramBlock
      width: ramRow.width
      height: 28
      visible: statsIsland.ramVisible
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: ramRow
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: "\uf538" // RAM icon
          color: group.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
          scale: statsIsland.isExpanded ? 1.1 : 1.0
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        Text {
          text: systemStatsService.ramUsage + "%"
          color: group.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          id: ramDetail
          width: statsIsland.isExpanded ? 40 : 0
          height: parent.height
          clip: true
          opacity: statsIsland.isExpanded ? 1.0 : 0.0
          visible: opacity > 0.01

          Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

          Rectangle {
            width: 32
            height: 6
            radius: 3
            color: group.theme.buttonBg
            border.color: "#15ffffff"
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4

            Rectangle {
              width: parent.width * (systemStatsService.ramUsage / 100.0)
              height: parent.height
              radius: 3
              color: group.theme.accent
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          if (mouse.button === Qt.MiddleButton) {
            systemStatsService.showRamUsageOnBar = false;
          }
        }
      }
    }

    // Divider 2
    Rectangle {
      width: 1
      height: 12
      color: "#20ffffff"
      anchors.verticalCenter: parent.verticalCenter
      visible: ramBlock.visible && (gpuBlock.visible || netBlock.visible)
    }

    // GPU Stat Block (Wrapped to prevent Row anchor warnings)
    Item {
      id: gpuBlock
      width: gpuRow.width
      height: 28
      visible: statsIsland.gpuVisible
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: gpuRow
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: "\uf530" // GPU Icon
          color: group.theme.green
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
          scale: statsIsland.isExpanded ? 1.1 : 1.0
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        Text {
          text: systemStatsService.gpuUsage + "%"
          color: group.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          id: gpuDetail
          width: statsIsland.isExpanded ? (gpuTempText.implicitWidth + 4) : 0
          height: parent.height
          clip: true
          opacity: statsIsland.isExpanded ? 1.0 : 0.0
          visible: opacity > 0.01 && (systemStatsService.showGpuTempOnBar || statsIsland.isExpanded)

          Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

          Text {
            id: gpuTempText
            text: "(" + systemStatsService.gpuTemp + "°C)"
            color: (systemStatsService.gpuTemp > 75) ? group.theme.red : ((systemStatsService.gpuTemp > 60) ? "#fbbf24" : group.theme.green)
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.4)
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          if (mouse.button === Qt.MiddleButton) {
            systemStatsService.showGpuUsageOnBar = false;
            systemStatsService.showGpuTempOnBar = false;
          }
        }
      }
    }

    // Divider 3
    Rectangle {
      width: 1
      height: 12
      color: "#20ffffff"
      anchors.verticalCenter: parent.verticalCenter
      visible: gpuBlock.visible && netBlock.visible
    }

    // Network Stat Block (Wrapped to prevent Row anchor warnings)
    Item {
      id: netBlock
      width: netRow.width
      height: 28
      visible: statsIsland.netVisible
      anchors.verticalCenter: parent.verticalCenter

      Row {
        id: netRow
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Text {
          text: "\uf0ec" // Network icon
          color: "#e2e8f0"
          font { family: "FiraCode Nerd Font"; pixelSize: 12 }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
          scale: statsIsland.isExpanded ? 1.1 : 1.0
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        Item {
          id: netDetailLabel
          width: statsIsland.isExpanded ? (netLabelText.implicitWidth + 2) : 0
          height: parent.height
          clip: true
          opacity: statsIsland.isExpanded ? 1.0 : 0.0
          visible: opacity > 0.01

          Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

          Text {
            id: netLabelText
            text: "Ağ:"
            color: group.theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.4)
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Text {
          text: systemStatsService.netSpeed
          color: group.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
          style: Text.Outline
          styleColor: Qt.rgba(0, 0, 0, 0.4)
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          if (mouse.button === Qt.MiddleButton) {
            systemStatsService.showNetSpeedOnBar = false;
          }
        }
      }
    }
  }
}
