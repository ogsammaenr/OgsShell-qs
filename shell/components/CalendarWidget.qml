import QtQuick
import Quickshell

Rectangle {
  id: root
  required property var theme
  required property bool isOpen

  property var apiHolidays: [] // Fetched once from shell.qml

  property string hoveredHoliday: ""

  radius: 16
  clip: true
  color: theme.bg
  border.color: theme.border
  border.width: 1

  // Month & Year state
  property int currentMonth: new Date().getMonth()
  property int currentYear: new Date().getFullYear()

  property var monthNames: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
  property var dayNames: ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]

  property var gridDays: []

  // Fixed public holidays in Turkey
  property var fixedHolidays: [
    { month: 1, day: 1, name: "Yılbaşı" },
    { month: 4, day: 23, name: "Ulusal Egemenlik ve Çocuk Bayramı" },
    { month: 5, day: 1, name: "Emek ve Dayanışma Günü" },
    { month: 5, day: 19, name: "Atatürk'ü Anma, Gençlik ve Spor Bayramı" },
    { month: 7, day: 15, name: "Demokrasi ve Milli Birlik Günü" },
    { month: 8, day: 30, name: "Zafer Bayramı" },
    { month: 10, day: 29, name: "Cumhuriyet Bayramı" }
  ]

  function generateCalendar() {
    var firstDayOfMonth = new Date(currentYear, currentMonth, 1);
    var startDayIndex = firstDayOfMonth.getDay() - 1;
    if (startDayIndex < 0) startDayIndex = 6; // Sunday is index 6

    var daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
    var daysInPrevMonth = new Date(currentYear, currentMonth, 0).getDate();

    var tempDays = [];

    // Prev month padding
    for (var i = startDayIndex - 1; i >= 0; i--) {
      var d = daysInPrevMonth - i;
      var prevMonth = currentMonth - 1;
      var prevYear = currentYear;
      if (prevMonth < 0) {
        prevMonth = 11;
        prevYear--;
      }
      tempDays.push({
        day: d,
        month: prevMonth,
        year: prevYear,
        isCurrentMonth: false
      });
    }

    // Current month
    for (var d = 1; d <= daysInMonth; d++) {
      tempDays.push({
        day: d,
        month: currentMonth,
        year: currentYear,
        isCurrentMonth: true
      });
    }

    // Next month padding
    var remainingCells = 42 - tempDays.length;
    for (var d = 1; d <= remainingCells; d++) {
      var nextMonth = currentMonth + 1;
      var nextYear = currentYear;
      if (nextMonth > 11) {
        nextMonth = 0;
        nextYear++;
      }
      tempDays.push({
        day: d,
        month: nextMonth,
        year: nextYear,
        isCurrentMonth: false
      });
    }

    gridDays = tempDays;
  }

  function getHolidayName(d, m, y) {
    // 1. Check API holidays (matches date string "YYYY-MM-DD")
    var dateString = y + "-" + (m + 1 < 10 ? "0" : "") + (m + 1) + "-" + (d < 10 ? "0" : "") + d;
    for (var i = 0; i < apiHolidays.length; i++) {
      if (apiHolidays[i].date === dateString) {
        return apiHolidays[i].localName;
      }
    }

    // 2. Check local fixed holidays
    for (var j = 0; j < fixedHolidays.length; j++) {
      if (fixedHolidays[j].month === (m + 1) && fixedHolidays[j].day === d) {
        return fixedHolidays[j].name;
      }
    }

    return "";
  }

  onCurrentMonthChanged: generateCalendar()
  onCurrentYearChanged: generateCalendar()
  onIsOpenChanged: {
    if (isOpen) {
      currentMonth = new Date().getMonth();
      currentYear = new Date().getFullYear();
      generateCalendar();
    }
  }

  Component.onCompleted: generateCalendar()

  // Prevent event propagation
  MouseArea {
    anchors.fill: parent
    onPressed: (mouse) => mouse.accepted = true
  }

  Column {
    id: mainContent
    width: 288
    height: 268
    anchors.centerIn: parent
    spacing: 12
    opacity: root.isOpen ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    // Header: Navigation & Month Title
    Row {
      width: parent.width
      height: 24

      // Prev Month Button
      Rectangle {
        width: 24
        height: 24
        radius: 6
        color: prevMouse.containsMouse ? "#15ffffff" : "transparent"
        Text {
          text: "\uf053"
          color: theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 10 }
          anchors.centerIn: parent
        }
        MouseArea {
          id: prevMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.currentMonth === 0) {
              root.currentMonth = 11;
              root.currentYear--;
            } else {
              root.currentMonth--;
            }
          }
        }
      }

      // Title
      Text {
        width: parent.width - 48
        text: root.monthNames[root.currentMonth] + " " + root.currentYear
        color: theme.textPrimary
        font { family: "JetBrains Mono"; pixelSize: 13; weight: Font.Bold }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      // Next Month Button
      Rectangle {
        width: 24
        height: 24
        radius: 6
        color: nextMouse.containsMouse ? "#15ffffff" : "transparent"
        Text {
          text: "\uf054"
          color: theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 10 }
          anchors.centerIn: parent
        }
        MouseArea {
          id: nextMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.currentMonth === 11) {
              root.currentMonth = 0;
              root.currentYear++;
            } else {
              root.currentMonth++;
            }
          }
        }
      }
    }

    // Days of the Week Row
    Row {
      width: parent.width
      height: 18

      Repeater {
        model: root.dayNames
        delegate: Text {
          width: parent.width / 7
          text: modelData
          color: theme.textSecondary
          font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    // Days Grid
    Grid {
      columns: 7
      rows: 6
      spacing: 2
      width: parent.width
      height: 168

      Repeater {
        model: root.gridDays
        delegate: Rectangle {
          width: parent.width / 7
          height: 26
          radius: 6
          
          property bool isToday: modelData.day === new Date().getDate() &&
                                 modelData.month === new Date().getMonth() &&
                                 modelData.year === new Date().getFullYear()

          property string holidayName: root.getHolidayName(modelData.day, modelData.month, modelData.year)
          property bool isHoliday: holidayName !== ""

          color: isToday ? theme.accent : "transparent"
          border.color: isHoliday ? "#55ef4444" : "transparent"
          border.width: isHoliday ? 1 : 0

          Text {
            text: modelData.day
            color: isToday ? "#ffffff" : (isHoliday ? "#ef4444" : (modelData.isCurrentMonth ? theme.textPrimary : theme.textSecondary))
            font {
              family: "JetBrains Mono"
              pixelSize: 10
              weight: isToday || isHoliday ? Font.Bold : Font.Normal
            }
            anchors.centerIn: parent
          }

          // Small red dot at the bottom for holidays
          Rectangle {
            width: 3
            height: 3
            radius: 1.5
            color: "#ef4444"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            visible: isHoliday && !isToday
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: isHoliday ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: {
              if (isHoliday) {
                root.hoveredHoliday = holidayName;
              }
            }
            onExited: {
              root.hoveredHoliday = "";
            }
          }
        }
      }
    }

    // Bottom Separator Line
    Rectangle {
      width: parent.width
      height: 1
      color: "#15ffffff"
    }

    // Bottom Status Area
    Item {
      width: parent.width
      height: 20

      Text {
        text: root.hoveredHoliday !== "" ? root.hoveredHoliday : ""
        color: "#ef4444"
        font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
        anchors.centerIn: parent
        visible: root.hoveredHoliday !== ""
      }

      Text {
        text: "Bugün: " + Qt.formatDateTime(new Date(), "d MMMM yyyy")
        color: theme.textSecondary
        font { family: "JetBrains Mono"; pixelSize: 10 }
        anchors.centerIn: parent
        visible: root.hoveredHoliday === ""
      }
    }
  }
}
