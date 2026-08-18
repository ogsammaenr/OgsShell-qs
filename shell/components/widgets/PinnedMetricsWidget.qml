import QtQuick
import QtQuick.Layouts
import "../.."

Item {
  id: root

  // IPC Service Reference
  required property var ipc
  property string islandStateMode: "IDLE"

  // Telemetry properties from DaemonIPC
  readonly property real cpuVal: (ipc && ipc.cpu && ipc.cpu.cpu_percent !== undefined) ? ipc.cpu.cpu_percent : 0
  readonly property real cpuTemp: (ipc && ipc.cpu && ipc.cpu.cpu_temp !== undefined) ? ipc.cpu.cpu_temp : -1
  readonly property real ramVal: (ipc && ipc.ram && ipc.ram.ram_percent !== undefined) ? ipc.ram.ram_percent : 0
  readonly property real gpuVal: (ipc && ipc.gpu && ipc.gpu.gpu_percent !== undefined && ipc.gpu.gpu_percent >= 0) ? ipc.gpu.gpu_percent : 0
  readonly property real gpuTemp: (ipc && ipc.gpu && ipc.gpu.gpu_temp !== undefined) ? ipc.gpu.gpu_temp : -1

  // Pinned Visibility State (Transparent HUD fades during EXPANDED mode)
  readonly property bool isPinned: Config.showPinnedSystemMetrics
  readonly property bool shouldShow: isPinned && islandStateMode !== "EXPANDED"

  implicitWidth: metricsRow.implicitWidth + 12
  implicitHeight: 28

  opacity: shouldShow ? 1.0 : 0.0
  scale: shouldShow ? 1.0 : 0.88
  visible: opacity > 0.0

  Behavior on opacity {
    NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
  }

  Behavior on scale {
    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
  }

  // 100% Transparent Canvas with Zero Click-Blocking background
  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.width: 0
  }

  Row {
    id: metricsRow
    anchors.centerIn: parent
    spacing: 8

    // ==========================================
    // Metric 1: CPU Telemetry & Temperature
    // ==========================================
    Row {
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: "󰻠"
        font.pixelSize: 13
        color: Style.accentCyan
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.cpuTemp > 0 ? `CPU %${Math.round(root.cpuVal)} ${Math.round(root.cpuTemp)}°C` : `CPU %${Math.round(root.cpuVal)}`
        font.pixelSize: 11
        font.weight: Font.Bold
        color: Style.textPrimary
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // High-Contrast Dot Separator
    Text {
      text: "•"
      font.pixelSize: 11
      color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
      style: Text.Outline
      styleColor: Qt.rgba(0, 0, 0, 0.90)
      anchors.verticalCenter: parent.verticalCenter
    }

    // ==========================================
    // Metric 2: RAM Telemetry
    // ==========================================
    Row {
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: "󰍛"
        font.pixelSize: 13
        color: Style.accentGreen
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: `RAM %${Math.round(root.ramVal)}`
        font.pixelSize: 11
        font.weight: Font.Bold
        color: Style.textPrimary
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // High-Contrast Dot Separator
    Text {
      text: "•"
      font.pixelSize: 11
      color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
      style: Text.Outline
      styleColor: Qt.rgba(0, 0, 0, 0.90)
      anchors.verticalCenter: parent.verticalCenter
    }

    // ==========================================
    // Metric 3: GPU Telemetry & Temperature
    // ==========================================
    Row {
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: "󰢮"
        font.pixelSize: 13
        color: Style.accentOrange
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.gpuTemp > 0 ? `GPU %${Math.round(root.gpuVal)} ${Math.round(root.gpuTemp)}°C` : `GPU %${Math.round(root.gpuVal)}`
        font.pixelSize: 11
        font.weight: Font.Bold
        color: Style.textPrimary
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
