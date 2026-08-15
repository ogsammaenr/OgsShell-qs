import QtQuick
import QtQuick.Layouts
import ".."
import "../../.."

Item {
  id: root

  required property var ipc
  property string selectedDateStr: ""
  signal closeRequested()

  function getHolidayForDateStr(dateStr) {
    if (!dateStr || dateStr.length < 10) return null
    let parts = dateStr.split("-")
    let y = parseInt(parts[0])
    let m = parseInt(parts[1])
    let d = parseInt(parts[2])

    // 1. Static National Holidays
    let national = {
      "01-01": "Yılbaşı",
      "04-23": "Ulusal Egemenlik ve Çocuk Bayramı",
      "05-01": "Emek ve Dayanışma Günü",
      "05-19": "Atatürk'ü Anma, Gençlik ve Spor Bayramı",
      "07-15": "15 Temmuz Demokrasi ve Milli Birlik Günü",
      "08-30": "Zafer Bayramı",
      "10-28": "Cumhuriyet Bayramı Arefesi",
      "10-29": "Cumhuriyet Bayramı"
    }

    let mdKey = String(m).padStart(2, '0') + "-" + String(d).padStart(2, '0')
    if (national[mdKey]) {
      return { date: dateStr, name: national[mdKey], is_half_day: (mdKey === "10-28"), type: "national" }
    }

    // 2. Religious Holidays
    let religiousEves = {
      2024: { ramadan: "2024-04-09", eid: "2024-06-15" },
      2025: { ramadan: "2025-03-29", eid: "2025-06-05" },
      2026: { ramadan: "2026-03-19", eid: "2026-05-26" },
      2027: { ramadan: "2027-03-09", eid: "2027-05-16" },
      2028: { ramadan: "2028-02-26", eid: "2028-05-04" },
      2029: { ramadan: "2029-02-14", eid: "2029-04-23" },
      2030: { ramadan: "2030-02-04", eid: "2030-04-13" }
    }

    let entry = religiousEves[y]
    if (entry) {
      function checkFeast(eveStr, feastName, daysCount) {
        let eveDate = new Date(eveStr + "T00:00:00")
        let curDate = new Date(dateStr + "T00:00:00")
        let diffDays = Math.round((curDate.getTime() - eveDate.getTime()) / 86400000)
        if (diffDays === 0) {
          return { date: dateStr, name: `${feastName} Arefesi`, is_half_day: true, type: "religious" }
        }
        if (diffDays >= 1 && diffDays <= daysCount) {
          return { date: dateStr, name: `${feastName} ${diffDays}. Gün`, is_half_day: false, type: "religious" }
        }
        return null
      }

      let rResult = checkFeast(entry.ramadan, "Ramazan Bayramı", 3)
      if (rResult) return rResult

      let kResult = checkFeast(entry.eid, "Kurban Bayramı", 4)
      if (kResult) return kResult
    }

    // 3. IPC backend holidays
    if (ipc && ipc.currentMonthData && ipc.currentMonthData.holidays) {
      for (let h of ipc.currentMonthData.holidays) {
        if (h.date === dateStr) return h
      }
    }

    return null
  }

  readonly property var holidayForDate: getHolidayForDateStr(root.selectedDateStr)

  readonly property var eventsForDate: {
    if (!ipc || !ipc.currentMonthData || !ipc.currentMonthData.events) return []
    let list = []
    for (let e of ipc.currentMonthData.events) {
      if (e.date === root.selectedDateStr) {
        list.push(e)
      }
    }
    return list
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // ==========================================
    // Selected Date & Holiday Header Banner
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back / Close Button
      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: backHover.hovered ? Style.surfaceHover : Style.surfaceVariant

        HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.closeRequested() }

        Text {
          anchors.centerIn: parent
          text: "‹"
          font.pixelSize: 16
          font.weight: Font.Bold
          color: Style.textPrimary
        }
      }

      Text {
        text: root.selectedDateStr || "Tarih Seçilmedi"
        color: Style.textPrimary
        font.pixelSize: 12
        font.weight: Font.DemiBold
        Layout.fillWidth: true
      }

      // Holiday Pill Tag
      Rectangle {
        visible: root.holidayForDate !== null
        Layout.preferredHeight: 20
        Layout.preferredWidth: holidayTxt.implicitWidth + 12
        radius: 10
        color: Qt.rgba(1.0, 0.27, 0.23, 0.15)
        border.color: Style.accentRed
        border.width: 1

        Text {
          id: holidayTxt
          anchors.centerIn: parent
          text: root.holidayForDate ? root.holidayForDate.name : ""
          color: Style.accentRed
          font.pixelSize: 10
          font.weight: Font.DemiBold
        }
      }

      // Close Button
      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: closeHover.hovered ? Style.surfaceHover : "transparent"

        HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.closeRequested() }

        Text {
          anchors.centerIn: parent
          text: "✕"
          font.pixelSize: 10
          color: Style.textMuted
        }
      }
    }

    // ==========================================
    // Events List View (Scrollable)
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
        id: eventsList
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6
        model: root.eventsForDate

        // Empty state placeholder
        Item {
          anchors.centerIn: parent
          visible: eventsList.count === 0

          Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Etkinlik veya hatırlatıcı yok"
              color: Style.textMuted
              font.pixelSize: 11
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Aşağıdan hızlıca ekleyebilirsiniz"
              color: Style.textMuted
              font.pixelSize: 10
              opacity: 0.7
            }
          }
        }

        delegate: Rectangle {
          width: eventsList.width
          height: 34
          radius: 8
          color: modelData.completed ? Style.surface : Style.surfaceVariant
          border.color: modelData.completed ? "transparent" : Style.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            // Completed Checkbox
            Rectangle {
              width: 16
              height: 16
              radius: 5
              color: modelData.completed ? Style.accentGreen : Style.surfaceHover
              border.color: modelData.completed ? Style.accentGreen : Style.textMuted
              border.width: 1

              Text {
                anchors.centerIn: parent
                visible: modelData.completed
                text: "✓"
                font.pixelSize: 10
                color: "#000000"
                font.weight: Font.Bold
              }

              TapHandler {
                onTapped: {
                  if (ipc) {
                    ipc.toggleCalendarEvent(modelData.id, !modelData.completed)
                  }
                }
              }
            }

            // Event Title
            Text {
              text: modelData.title
              color: modelData.completed ? Style.textMuted : Style.textPrimary
              font.pixelSize: 11
              font.strikeout: modelData.completed
              font.weight: modelData.completed ? Font.Normal : Font.Medium
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            // Time Tag
            Text {
              visible: modelData.time && modelData.time.length > 0
              text: modelData.time
              color: Style.accentCyan
              font.pixelSize: 10
              font.weight: Font.Medium
            }

            // Delete Action Button
            Rectangle {
              width: 20
              height: 20
              radius: 10
              color: delHover.hovered ? Style.surfaceActive : "transparent"

              HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  if (ipc) {
                    ipc.deleteCalendarEvent(modelData.id)
                  }
                }
              }

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 10
                color: Style.textMuted
              }
            }
          }
        }
      }
    }

    // ==========================================
    // Quick Add Bar
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      radius: 10
      color: Style.surface
      border.color: Style.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        // Title Input
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 24
          radius: 6
          color: Style.surfaceVariant

          TextInput {
            id: titleInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: Style.textPrimary
            font.pixelSize: 11
            selectByMouse: true

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              text: "Yeni etkinlik başlığı..."
              color: Style.textMuted
              font.pixelSize: 11
              visible: !titleInput.text && !titleInput.activeFocus
            }

            onAccepted: root.addNewEvent()
          }
        }

        // Compact Time Picker Button & Popover
        TimePicker {
          id: quickTimePicker
          Layout.preferredWidth: 68
          Layout.preferredHeight: 24
          compact: true
          hour: 12
          minute: 0
        }

        // Add Button
        Rectangle {
          Layout.preferredWidth: 48
          Layout.preferredHeight: 24
          radius: 6
          color: addHover.hovered ? Style.accentHover : Style.accent

          HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.addNewEvent() }

          Text {
            anchors.centerIn: parent
            text: "Ekle"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: "#ffffff"
          }
        }
      }
    }
  }

  function addNewEvent() {
    let t = titleInput.text.trim()
    if (!t || !root.selectedDateStr) return

    let timeVal = quickTimePicker.timeString || "12:00"
    if (ipc) {
      ipc.addCalendarEvent(t, root.selectedDateStr, timeVal, 15)
    }
    titleInput.text = ""
  }
}
