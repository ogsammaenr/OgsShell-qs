import QtQuick
import QtQuick.Layouts
import ".."
import "../../.."

Item {
  id: root

  required property var ipc
  property string selectedDateStr: {
    let d = new Date()
    let y = d.getFullYear()
    let m = String(d.getMonth() + 1).padStart(2, '0')
    let day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  property bool showDayDetailsModal: false
  property bool showEventCreatorModal: false
  property string newEventTitle: ""
  property string newEventTime: "12:00"
  property int newEventReminderMin: 15

  // ==========================================
  // Main Content Area
  // ==========================================
  Item {
    anchors.fill: parent

    // View 1: Month Grid View (Primary Full Calendar)
    MonthGridView {
      id: monthGrid
      anchors.fill: parent
      ipc: root.ipc
      visible: !root.showDayDetailsModal && !root.showEventCreatorModal
      onDateSelected: dateStr => {
        root.selectedDateStr = dateStr
      }
      onDayRightClicked: dateStr => {
        root.selectedDateStr = dateStr
        root.showDayDetailsModal = true
      }
      onDayDoubleClicked: dateStr => {
        root.selectedDateStr = dateStr
        root.newEventTitle = ""
        root.newEventTime = "12:00"
        root.showEventCreatorModal = true
      }
    }

    // View 2: Day Details Sheet (Lazy Loaded via Loader)
    Loader {
      id: dayDetailLoader
      anchors.fill: parent
      active: root.showDayDetailsModal && !root.showEventCreatorModal
      visible: active
      sourceComponent: DayDetailView {
        ipc: root.ipc
        selectedDateStr: root.selectedDateStr
        onCloseRequested: root.showDayDetailsModal = false
      }
    }

    // ==========================================
    // Modal Sheet: Double-Click Event Creator
    // ==========================================
    Rectangle {
      id: eventCreatorModal
      anchors.fill: parent
      radius: 14
      color: Style.surface
      border.color: Style.border
      border.width: 1
      visible: root.showEventCreatorModal

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Header
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Yeni Etkinlik Ekle"
            color: Style.textPrimary
            font.pixelSize: 12
            font.weight: Font.DemiBold
          }

          Item { Layout.fillWidth: true }

          Rectangle {
            Layout.preferredHeight: 20
            Layout.preferredWidth: dateBadgeTxt.implicitWidth + 12
            radius: 10
            color: Style.surfaceVariant

            Text {
              id: dateBadgeTxt
              anchors.centerIn: parent
              text: root.selectedDateStr
              color: Style.accentCyan
              font.pixelSize: 10
              font.weight: Font.Medium
            }
          }
        }

        // Title Input Card
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 32
          radius: 8
          color: Style.surfaceVariant

          TextInput {
            id: modalTitleInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Style.textPrimary
            font.pixelSize: 11
            selectByMouse: true
            text: root.newEventTitle
            onTextChanged: root.newEventTitle = text

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              text: "Etkinlik başlığı girin..."
              color: Style.textMuted
              font.pixelSize: 11
              visible: !modalTitleInput.text && !modalTitleInput.activeFocus
            }
          }
        }

        // Time Picker
        TimePicker {
          id: modalTimePicker
          Layout.alignment: Qt.AlignHCenter
          Layout.preferredWidth: 180
          Layout.preferredHeight: 64
          hour: 12
          minute: 0
          onTimeChanged: (h, m, str) => {
            root.newEventTime = str
          }
        }

        // Reminder Selector
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 28
          radius: 8
          color: Style.surfaceVariant

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text { text: "Hatırlatma:"; color: Style.textSecondary; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Text {
              text: root.newEventReminderMin + " dk önce"
              color: Style.accentCyan
              font.pixelSize: 10
              font.weight: Font.Medium
            }
          }

          TapHandler {
            onTapped: {
              if (root.newEventReminderMin === 15) root.newEventReminderMin = 30
              else if (root.newEventReminderMin === 30) root.newEventReminderMin = 60
              else root.newEventReminderMin = 15
            }
          }
        }

        Item { Layout.fillHeight: true }

        // Action Buttons
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          // Cancel Button
          Rectangle {
            Layout.preferredWidth: 80
            Layout.preferredHeight: 32
            radius: 10
            color: cancelHover.hovered ? Style.surfaceHover : Style.surfaceVariant

            HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.showEventCreatorModal = false }

            Text {
              anchors.centerIn: parent
              text: "İptal"
              color: Style.textSecondary
              font.pixelSize: 11
              font.weight: Font.Medium
            }
          }

          // Save / Add Button
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 10
            color: saveHover.hovered ? Style.accentHover : Style.accent

            HoverHandler { id: saveHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                let title = root.newEventTitle.trim()
                if (title.length > 0 && root.ipc) {
                  root.ipc.addCalendarEvent(title, root.selectedDateStr, root.newEventTime, root.newEventReminderMin)
                }
                root.showEventCreatorModal = false
              }
            }

            Text {
              anchors.centerIn: parent
              text: "Etkinliği Kaydet"
              color: "#ffffff"
              font.pixelSize: 11
              font.weight: Font.DemiBold
            }
          }
        }
      }
    }
  }
}
