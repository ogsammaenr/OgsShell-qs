import QtQuick
import QtQuick.Layouts
import "../../.."

Item {
  id: root

  property bool showConfigPanel: false

  ColumnLayout {
    anchors.fill: parent
    spacing: 10

    // ==========================================
    // View 1: Apple Minimalist Detailed Clock Canvas
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1
      visible: !root.showConfigPanel

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        Item { Layout.fillHeight: true }

        // Primary Time Display with Tabular Figures
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 2

          Text {
            text: ClockManager.currentDisplayTime
            color: Style.textPrimary
            font.pixelSize: 46
            font.weight: Font.DemiBold
            font.letterSpacing: -0.5
          }

          Text {
            visible: ClockManager.showSeconds
            text: ":" + ClockManager.currentDisplaySeconds
            color: Style.accentCyan
            font.pixelSize: 22
            font.weight: Font.Normal
            Layout.alignment: Qt.AlignBaseline
          }
        }

        // Subtitle Date
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: ClockManager.currentFullDate
          color: Style.textSecondary
          font.pixelSize: 12
          font.weight: Font.Normal
        }

        Item { Layout.preferredHeight: 6 }

        // Minimalist Location & Timezone Label
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 8

          Text {
            text: ClockManager.selectedCity + " (" + ClockManager.selectedCountry + ")"
            color: Style.textPrimary
            font.pixelSize: 11
            font.weight: Font.Medium
          }

          Rectangle {
            width: 3
            height: 3
            radius: 1.5
            color: Style.textMuted
            Layout.alignment: Qt.AlignVCenter
          }

          Text {
            text: ClockManager.currentUtcOffsetStr
            color: Style.accentCyan
            font.pixelSize: 11
            font.weight: Font.Medium
          }
        }

        Item { Layout.fillHeight: true }
      }
    }

    // ==========================================
    // View 2: Location & Timezone Settings Panel
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1
      visible: root.showConfigPanel

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
          text: "Konum ve Zaman Dilimi"
          color: Style.textPrimary
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        // Clean Timezone Presets (2x2 Grid)
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 6
          columnSpacing: 6

          // Istanbul
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: ClockManager.selectedCity === "İstanbul" ? Style.surfaceActive : Style.surfaceVariant
            border.color: ClockManager.selectedCity === "İstanbul" ? Style.accent : "transparent"
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 8
              Text { text: "İstanbul"; color: Style.textPrimary; font.pixelSize: 11; font.weight: Font.Medium }
              Item { Layout.fillWidth: true }
              Text { text: "UTC+3"; color: Style.textMuted; font.pixelSize: 10 }
            }

            TapHandler {
              onTapped: {
                ClockManager.setLocation("İstanbul", "Türkiye", 3)
              }
            }
          }

          // London
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: ClockManager.selectedCity === "Londra" ? Style.surfaceActive : Style.surfaceVariant
            border.color: ClockManager.selectedCity === "Londra" ? Style.accent : "transparent"
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 8
              Text { text: "Londra"; color: Style.textPrimary; font.pixelSize: 11; font.weight: Font.Medium }
              Item { Layout.fillWidth: true }
              Text { text: "UTC+1"; color: Style.textMuted; font.pixelSize: 10 }
            }

            TapHandler {
              onTapped: {
                ClockManager.setLocation("Londra", "İngiltere", 1)
              }
            }
          }

          // New York
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: ClockManager.selectedCity === "New York" ? Style.surfaceActive : Style.surfaceVariant
            border.color: ClockManager.selectedCity === "New York" ? Style.accent : "transparent"
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 8
              Text { text: "New York"; color: Style.textPrimary; font.pixelSize: 11; font.weight: Font.Medium }
              Item { Layout.fillWidth: true }
              Text { text: "UTC-4"; color: Style.textMuted; font.pixelSize: 10 }
            }

            TapHandler {
              onTapped: {
                ClockManager.setLocation("New York", "ABD", -4)
              }
            }
          }

          // Tokyo
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: ClockManager.selectedCity === "Tokyo" ? Style.surfaceActive : Style.surfaceVariant
            border.color: ClockManager.selectedCity === "Tokyo" ? Style.accent : "transparent"
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 8
              Text { text: "Tokyo"; color: Style.textPrimary; font.pixelSize: 11; font.weight: Font.Medium }
              Item { Layout.fillWidth: true }
              Text { text: "UTC+9"; color: Style.textMuted; font.pixelSize: 10 }
            }

            TapHandler {
              onTapped: {
                ClockManager.setLocation("Tokyo", "Japonya", 9)
              }
            }
          }
        }

        // Toggles Row: 24h & Seconds
        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 6
            color: Style.surfaceVariant

            Text {
              anchors.centerIn: parent
              text: ClockManager.is24HourFormat ? "24-Saat Formatı" : "12-Saat (AM/PM)"
              color: Style.textPrimary
              font.pixelSize: 10
            }

            TapHandler { onTapped: ClockManager.is24HourFormat = !ClockManager.is24HourFormat }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 6
            color: Style.surfaceVariant

            Text {
              anchors.centerIn: parent
              text: ClockManager.showSeconds ? "Saniye Açık" : "Saniye Kapalı"
              color: Style.textPrimary
              font.pixelSize: 10
            }

            TapHandler { onTapped: ClockManager.showSeconds = !ClockManager.showSeconds }
          }
        }
      }
    }

    // ==========================================
    // Action Button
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      radius: 10
      color: btnHover.hovered ? Style.surfaceHover : (root.showConfigPanel ? Style.surfaceActive : Style.surface)
      border.color: Style.border
      border.width: 1

      HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
      TapHandler { onTapped: root.showConfigPanel = !root.showConfigPanel }

      Text {
        anchors.centerIn: parent
        text: root.showConfigPanel ? "Tamam" : "Konum ve Saat Ayarları"
        color: Style.textPrimary
        font.pixelSize: 11
        font.weight: Font.Medium
      }
    }
  }
}
