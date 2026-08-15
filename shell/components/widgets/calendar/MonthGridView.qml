import QtQuick
import QtQuick.Layouts
import "../../.."

Item {
  id: root

  required property var ipc
  property int viewYear: new Date().getFullYear()
  property int viewMonth: new Date().getMonth() + 1 // 1-12
  property string selectedDateStr: formatDate(new Date())

  signal dateSelected(string dateStr)
  signal dayDoubleClicked(string dateStr)
  signal dayRightClicked(string dateStr)

  function formatDate(d) {
    let y = d.getFullYear()
    let m = String(d.getMonth() + 1).padStart(2, '0')
    let day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  function prevMonth() {
    if (viewMonth === 1) {
      viewMonth = 12
      viewYear--
    } else {
      viewMonth--
    }
    if (ipc) ipc.requestCalendarMonth(viewYear, viewMonth)
  }

  function nextMonth() {
    if (viewMonth === 12) {
      viewMonth = 1
      viewYear++
    } else {
      viewMonth++
    }
    if (ipc) ipc.requestCalendarMonth(viewYear, viewMonth)
  }

  function jumpToToday() {
    let now = new Date()
    viewYear = now.getFullYear()
    viewMonth = now.getMonth() + 1
    selectedDateStr = formatDate(now)
    if (ipc) ipc.requestCalendarMonth(viewYear, viewMonth)
    root.dateSelected(selectedDateStr)
  }

  Component.onCompleted: {
    if (ipc) ipc.requestCalendarMonth(viewYear, viewMonth)
  }

  readonly property var monthNames: [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
  ]

  readonly property var dayHeaders: ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]

  // =========================================================================
  // Comprehensive Turkey Public Holidays Engine (National & Religious)
  // Ensures holidays are ALWAYS available instantly offline & merged with IPC
  // =========================================================================
  function getHolidaysForYear(year) {
    let holidays = []

    // 1. Static National Holidays (Official)
    let national = [
      { m: 1, d: 1, name: "Yılbaşı", half: false },
      { m: 4, d: 23, name: "Ulusal Egemenlik ve Çocuk Bayramı", half: false },
      { m: 5, d: 1, name: "Emek ve Dayanışma Günü", half: false },
      { m: 5, d: 19, name: "Atatürk'ü Anma, Gençlik ve Spor Bayramı", half: false },
      { m: 7, d: 15, name: "15 Temmuz Demokrasi ve Milli Birlik Günü", half: false },
      { m: 8, d: 30, name: "Zafer Bayramı", half: false },
      { m: 10, d: 28, name: "Cumhuriyet Bayramı Arefesi", half: true },
      { m: 10, d: 29, name: "Cumhuriyet Bayramı", half: false }
    ]

    for (let item of national) {
      let mStr = String(item.m).padStart(2, '0')
      let dStr = String(item.d).padStart(2, '0')
      holidays.push({
        date: `${year}-${mStr}-${dStr}`,
        name: item.name,
        is_half_day: item.half,
        type: "national"
      })
    }

    // 2. Accurate Islamic Religious Holidays (Diyanet Official Table 2024-2035)
    let religiousEves = {
      2024: { ramadan: "2024-04-09", eid: "2024-06-15" },
      2025: { ramadan: "2025-03-29", eid: "2025-06-05" },
      2026: { ramadan: "2026-03-19", eid: "2026-05-26" },
      2027: { ramadan: "2027-03-09", eid: "2027-05-16" },
      2028: { ramadan: "2028-02-26", eid: "2028-05-04" },
      2029: { ramadan: "2029-02-14", eid: "2029-04-23" },
      2030: { ramadan: "2030-02-04", eid: "2030-04-13" },
      2031: { ramadan: "2031-01-24", eid: "2031-04-02" },
      2032: { ramadan: "2032-01-13", eid: "2032-03-21" },
      2033: { ramadan: "2033-01-02", eid: "2033-03-10" },
      2034: { ramadan: "2034-12-12", eid: "2034-02-28" },
      2035: { ramadan: "2035-12-01", eid: "2035-02-17" }
    }

    let entry = religiousEves[year]
    if (entry) {
      // Ramadan Feast (Arefe + 3 days)
      let rEve = new Date(entry.ramadan + "T00:00:00")
      holidays.push({ date: formatDate(rEve), name: "Ramazan Bayramı Arefesi", is_half_day: true, type: "religious" })
      for (let day = 1; day <= 3; day++) {
        let d = new Date(rEve.getTime() + (day * 86400000))
        holidays.push({ date: formatDate(d), name: `Ramazan Bayramı ${day}. Gün`, is_half_day: false, type: "religious" })
      }

      // Eid al-Adha / Kurban Feast (Arefe + 4 days)
      let kEve = new Date(entry.eid + "T00:00:00")
      holidays.push({ date: formatDate(kEve), name: "Kurban Bayramı Arefesi", is_half_day: true, type: "religious" })
      for (let day = 1; day <= 4; day++) {
        let d = new Date(kEve.getTime() + (day * 86400000))
        holidays.push({ date: formatDate(d), name: `Kurban Bayramı ${day}. Gün`, is_half_day: false, type: "religious" })
      }
    }

    return holidays
  }

  // 42 cells matrix generation (6 weeks x 7 days)
  readonly property var daysModel: {
    let firstDayOfMonth = new Date(viewYear, viewMonth - 1, 1)
    let startDayOfWeek = firstDayOfMonth.getDay() // 0 is Sunday
    let offset = startDayOfWeek === 0 ? 6 : startDayOfWeek - 1 // 0 for Monday

    let daysInCurrentMonth = new Date(viewYear, viewMonth, 0).getDate()
    let daysInPrevMonth = new Date(viewYear, viewMonth - 1, 0).getDate()

    let list = []
    let todayStr = formatDate(new Date())

    // Map holidays: Built-in + IPC backend holidays
    let holidayMap = {}
    let builtInHolidays = getHolidaysForYear(viewYear)
    for (let h of builtInHolidays) {
      holidayMap[h.date] = h
    }

    if (ipc && ipc.currentMonthData && ipc.currentMonthData.holidays) {
      for (let h of ipc.currentMonthData.holidays) {
        holidayMap[h.date] = h
      }
    }

    // Map events by dateStr for O(1) lookup
    let eventCountMap = {}
    if (ipc && ipc.currentMonthData && ipc.currentMonthData.events) {
      for (let e of ipc.currentMonthData.events) {
        eventCountMap[e.date] = (eventCountMap[e.date] || 0) + 1
      }
    }

    for (let i = 0; i < 42; i++) {
      let dayNum = 0
      let isCurMonth = false
      let itemDateStr = ""

      if (i < offset) {
        dayNum = daysInPrevMonth - (offset - i - 1)
        let prevM = viewMonth === 1 ? 12 : viewMonth - 1
        let prevY = viewMonth === 1 ? viewYear - 1 : viewYear
        itemDateStr = `${prevY}-${String(prevM).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`
      } else if (i < offset + daysInCurrentMonth) {
        dayNum = i - offset + 1
        isCurMonth = true
        itemDateStr = `${viewYear}-${String(viewMonth).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`
      } else {
        dayNum = i - (offset + daysInCurrentMonth) + 1
        let nextM = viewMonth === 12 ? 1 : viewMonth + 1
        let nextY = viewMonth === 12 ? viewYear + 1 : viewYear
        itemDateStr = `${nextY}-${String(nextM).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`
      }

      list.push({
        "day": dayNum,
        "isCurrentMonth": isCurMonth,
        "dateStr": itemDateStr,
        "isToday": itemDateStr === todayStr,
        "holiday": holidayMap[itemDateStr] || null,
        "eventCount": eventCountMap[itemDateStr] || 0
      })
    }
    return list
  }

  // Selected date holiday details
  readonly property var selectedHoliday: {
    let builtInHolidays = getHolidaysForYear(viewYear)
    for (let h of builtInHolidays) {
      if (h.date === root.selectedDateStr) return h
    }
    if (ipc && ipc.currentMonthData && ipc.currentMonthData.holidays) {
      for (let h of ipc.currentMonthData.holidays) {
        if (h.date === root.selectedDateStr) return h
      }
    }
    return null
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 6

    // ==========================================
    // Top Month Navigation Header
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 26

      Text {
        text: `${root.monthNames[root.viewMonth - 1]} ${root.viewYear}`
        color: Style.textPrimary
        font.pixelSize: 13
        font.weight: Font.DemiBold
        Layout.fillWidth: true
      }

      // Prev Month
      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: prevMouse.containsMouse ? Style.surfaceVariant : "transparent"

        Text {
          anchors.centerIn: parent
          text: "‹"
          color: Style.textPrimary
          font.pixelSize: 15
        }

        MouseArea {
          id: prevMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.prevMonth()
        }
      }

      // Next Month
      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: nextMouse.containsMouse ? Style.surfaceVariant : "transparent"

        Text {
          anchors.centerIn: parent
          text: "›"
          color: Style.textPrimary
          font.pixelSize: 15
        }

        MouseArea {
          id: nextMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.nextMonth()
        }
      }

      // Today Pill Button
      Rectangle {
        Layout.preferredHeight: 22
        Layout.preferredWidth: todayTxt.implicitWidth + 14
        radius: 11
        color: todayMouse.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.border
        border.width: 1

        Text {
          id: todayTxt
          anchors.centerIn: parent
          text: "Bugün"
          color: Style.accent
          font.pixelSize: 10
          font.weight: Font.Medium
        }

        MouseArea {
          id: todayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.jumpToToday()
        }
      }
    }

    // ==========================================
    // Weekday Headers
    // ==========================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 2

      Repeater {
        model: root.dayHeaders
        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: modelData
          color: Style.textMuted
          font.pixelSize: 10
          font.weight: Font.Medium
        }
      }
    }

    // ==========================================
    // 42-Day Matrix (6 rows x 7 cols)
    // ==========================================
    GridLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      columns: 7
      rows: 6
      rowSpacing: 2
      columnSpacing: 2

      Repeater {
        model: root.daysModel

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 8

          readonly property bool isSelected: modelData.dateStr === root.selectedDateStr
          readonly property bool isHoliday: modelData.holiday !== null

          color: {
            if (isSelected) return Style.surfaceActive
            if (cellMouse.containsMouse) return Style.surfaceVariant
            return "transparent"
          }

          border.color: {
            if (isSelected) return Style.accent
            if (modelData.isToday) return Style.accentCyan
            return "transparent"
          }
          border.width: (isSelected || modelData.isToday) ? 1 : 0

          // Day Number Text
          Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: (isHoliday || modelData.eventCount > 0) ? -2 : 0
            text: modelData.day
            font.pixelSize: 11
            font.weight: (modelData.isToday || isSelected || isHoliday) ? Font.DemiBold : Font.Normal
            color: {
              if (isSelected) return Style.textPrimary
              if (isHoliday && modelData.isCurrentMonth) return Style.accentRed
              if (modelData.isCurrentMonth) return Style.textPrimary
              return Style.textMuted
            }
          }

          // Indicator Dots Row (Holiday / Event)
          Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2

            // Public Holiday Dot (Apple Red)
            Rectangle {
              visible: isHoliday
              width: 3
              height: 3
              radius: 1.5
              color: Style.accentRed
            }

            // Event Dot (Apple Cyan)
            Rectangle {
              visible: modelData.eventCount > 0
              width: 3
              height: 3
              radius: 1.5
              color: Style.accentCyan
            }
          }

          MouseArea {
            id: cellMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
              root.selectedDateStr = modelData.dateStr
              root.dateSelected(modelData.dateStr)
              if (mouse.button === Qt.RightButton) {
                root.dayRightClicked(modelData.dateStr)
              }
            }

            onDoubleClicked: mouse => {
              if (mouse.button === Qt.LeftButton) {
                root.selectedDateStr = modelData.dateStr
                root.dayDoubleClicked(modelData.dateStr)
              }
            }
          }
        }
      }
    }

    // ==========================================
    // Selected Day Holiday Banner or Quick Hint
    // ==========================================
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 22
      radius: 6
      color: root.selectedHoliday ? Qt.rgba(1.0, 0.27, 0.23, 0.12) : Style.surface
      border.color: root.selectedHoliday ? Style.accentRed : Style.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Text {
          text: root.selectedHoliday ? (root.selectedHoliday.name + " · Resmi Tatil (Etkinlikler için sağ tık)") : "Etkinlikler: Sağ tık  ·  Yeni Ekle: Çift tık"
          color: root.selectedHoliday ? Style.accentRed : Style.textMuted
          font.pixelSize: 10
          font.weight: root.selectedHoliday ? Font.DemiBold : Font.Normal
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }
    }
  }
}
