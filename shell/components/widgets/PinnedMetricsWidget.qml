import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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
  readonly property real netRx: (ipc && ipc.net && ipc.net.rx_bytes_sec !== undefined) ? ipc.net.rx_bytes_sec : 0
  readonly property real netTx: (ipc && ipc.net && ipc.net.tx_bytes_sec !== undefined) ? ipc.net.tx_bytes_sec : 0
  readonly property real netTotal: netRx + netTx

  function formatSpeed(bytes) {
    if (!bytes || bytes <= 0) return "0 B/s"
    if (bytes < 1024) return `${Math.round(bytes)} B/s`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(bytes >= 100 * 1024 ? 0 : 1)} KB/s`
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB/s`
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB/s`
  }

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

  // Ambient Elevation Glow
  RectangularGlow {
    anchors.fill: parent
    glowRadius: (Config.shadowsEnabled && Config.shadowPinnedMetrics) ? 12 : 0
    spread: 0.1
    color: Qt.rgba(0, 0, 0, (Config.shadowsEnabled && Config.shadowPinnedMetrics) ? 0.45 : 0)
    cornerRadius: 14 + glowRadius
    visible: glowRadius > 0 && (Config.shadowsEnabled && Config.shadowPinnedMetrics)
    z: -1
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
        font.pixelSize: Config.pinnedMetricsIconSize
        color: Style.accentCyan
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.cpuTemp > 0 ? `CPU %${Math.round(root.cpuVal)} ${Math.round(root.cpuTemp)}°C` : `CPU %${Math.round(root.cpuVal)}`
        font.pixelSize: Config.pinnedMetricsSize
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
      font.pixelSize: Config.pinnedMetricsSize
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
        font.pixelSize: Config.pinnedMetricsIconSize
        color: Style.accentGreen
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: `RAM %${Math.round(root.ramVal)}`
        font.pixelSize: Config.pinnedMetricsSize
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
      font.pixelSize: Config.pinnedMetricsSize
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
        font.pixelSize: Config.pinnedMetricsIconSize
        color: Style.accentOrange
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.gpuTemp > 0 ? `GPU %${Math.round(root.gpuVal)} ${Math.round(root.gpuTemp)}°C` : `GPU %${Math.round(root.gpuVal)}`
        font.pixelSize: Config.pinnedMetricsSize
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
      font.pixelSize: Config.pinnedMetricsSize
      color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
      style: Text.Outline
      styleColor: Qt.rgba(0, 0, 0, 0.90)
      anchors.verticalCenter: parent.verticalCenter
    }

    // ==========================================
    // Metric 4: Network Telemetry
    // ==========================================
    Row {
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: "󰛳"
        font.pixelSize: Config.pinnedMetricsIconSize
        color: Style.accentSecondary
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: `NET ${root.formatSpeed(root.netTotal)}`
        font.pixelSize: Config.pinnedMetricsSize
        font.weight: Font.Bold
        color: Style.textPrimary
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.90)
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
