import QtQuick
import QtQuick.Layouts
import "../../.."

Item {
  id: root

  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // ==========================================
    // Hero Stopwatch Digital Counter Card
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 70
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1

      Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: ClockManager.stopwatchFormattedTime
          color: Style.textPrimary
          font.pixelSize: 42
          font.weight: Font.DemiBold
          font.letterSpacing: -0.5
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: ClockManager.stopwatchRunning ? "Sayaç Çalışıyor" : (ClockManager.stopwatchElapsedMs > 0 ? "Duraklatıldı" : "Hazır")
          color: ClockManager.stopwatchRunning ? Style.accentGreen : Style.textSecondary
          font.pixelSize: 10
          font.weight: Font.Normal
        }
      }
    }

    // ==========================================
    // Lap Times Minimalist List
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 12
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: lapsListView
        anchors.fill: parent
        anchors.margins: 8
        model: ClockManager.stopwatchLaps
        spacing: 2

        header: Item {
          width: parent.width
          height: 20
          visible: ClockManager.stopwatchLaps.length > 0
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            Text { text: "Tur"; color: Style.textMuted; font.pixelSize: 9; Layout.preferredWidth: 45 }
            Text { text: "Tur Zamanı"; color: Style.textMuted; font.pixelSize: 9; Layout.fillWidth: true }
            Text { text: "Toplam"; color: Style.textMuted; font.pixelSize: 9 }
          }
        }

        delegate: Item {
          width: lapsListView.width
          height: 24

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            Text {
              text: "Tur " + modelData.lapNumber
              color: Style.textSecondary
              font.pixelSize: 10
              font.weight: Font.Medium
              Layout.preferredWidth: 45
            }
            Text {
              text: "+" + modelData.lapFormatted
              color: Style.accentGreen
              font.pixelSize: 10
              Layout.fillWidth: true
            }
            Text {
              text: modelData.totalFormatted
              color: Style.textPrimary
              font.pixelSize: 10
              font.weight: Font.Medium
            }
          }

          // Subtle hairline separator
          Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Style.border
          }
        }

        // Empty state placeholder
        Item {
          anchors.centerIn: parent
          visible: ClockManager.stopwatchLaps.length === 0
          Text {
            anchors.centerIn: parent
            text: "Tur kaydetmek için 'Tur' butonuna basın"
            color: Style.textMuted
            font.pixelSize: 10
          }
        }
      }
    }

    // ==========================================
    // Control Action Buttons (Apple Dual Buttons)
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Left Button: Reset / Lap
      Rectangle {
        Layout.preferredWidth: 90
        Layout.preferredHeight: 32
        radius: 10
        color: lapHover.hovered ? Style.surfaceHover : Style.surface
        border.color: Style.border
        border.width: 1
        opacity: (ClockManager.stopwatchRunning || ClockManager.stopwatchElapsedMs > 0) ? 1.0 : 0.4

        HoverHandler { id: lapHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (ClockManager.stopwatchRunning) {
              ClockManager.lapStopwatch()
            } else if (ClockManager.stopwatchElapsedMs > 0) {
              ClockManager.resetStopwatch()
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: ClockManager.stopwatchRunning ? "Tur" : "Sıfırla"
          color: Style.textPrimary
          font.pixelSize: 11
          font.weight: Font.Medium
        }
      }

      // Right Button: Start / Stop
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: 10
        color: ClockManager.stopwatchRunning ? Style.accentRed : Style.accentGreen

        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: ClockManager.toggleStopwatch() }

        Text {
          anchors.centerIn: parent
          text: ClockManager.stopwatchRunning ? "Durdur" : "Başlat"
          color: "#000000"
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }
      }
    }
  }
}
