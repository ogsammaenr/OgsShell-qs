import QtQuick
import QtQuick.Layouts
import ".."
import "../../.."

Item {
  id: root

  property var ipc

  property int newHour: 8
  property int newMinute: 0
  property string newAlarmLabel: "Alarm"
  property var selectedDays: [1, 2, 3, 4, 5] // Default: Hafta İçi (Mon-Fri)
  property bool showAddPanel: false

  function isDaySelected(dayNum) {
    return selectedDays.indexOf(dayNum) !== -1
  }

  function toggleDay(dayNum) {
    let copy = selectedDays.slice()
    let idx = copy.indexOf(dayNum)
    if (idx === -1) {
      copy.push(dayNum)
    } else {
      copy.splice(idx, 1)
    }
    copy.sort((a, b) => a - b)
    selectedDays = copy
  }

  function setPresetDays(type) {
    if (type === "WEEKDAYS") {
      selectedDays = [1, 2, 3, 4, 5]
    } else if (type === "EVERYDAY") {
      selectedDays = [1, 2, 3, 4, 5, 6, 7]
    } else if (type === "ONCE") {
      selectedDays = []
    }
  }

  function formatDaysSummary(days) {
    if (!days || days.length === 0) return "Tek Sefer"
    if (days.length === 7) return "Her gün"
    if (days.length === 5 && days[0] === 1 && days[4] === 5) return "Hafta İçi"
    if (days.length === 2 && days[0] === 6 && days[1] === 7) return "Hafta Sonu"
    
    let dayNames = ["", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
    return days.map(d => dayNames[d] || "").join(", ")
  }

  function submitNewAlarm() {
    let h = Math.max(0, Math.min(23, root.newHour))
    let m = Math.max(0, Math.min(59, root.newMinute))

    let formatted = (h < 10 ? "0" + h : "" + h) + ":" + (m < 10 ? "0" + m : "" + m)
    let label = (sheetLabelInput ? sheetLabelInput.text.trim() : "") || root.newAlarmLabel.trim() || "Alarm"

    console.log("[AlarmsTab] Submitting new alarm:", formatted, label, JSON.stringify(root.selectedDays))

    if (root.ipc) {
      root.ipc.addAlarm(formatted, label, root.selectedDays, "")
      root.ipc.sendAction("get_alarms", {})
    }

    root.showAddPanel = false
    root.newAlarmLabel = "Alarm"
  }

  // ==========================================
  // VIEW 1: Alarms List View (Visible when not adding)
  // ==========================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 5
    visible: !root.showAddPanel

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 12
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: alarmsList
        anchors.fill: parent
        anchors.margins: 6
        model: root.ipc ? root.ipc.alarms : []
        spacing: 4

        delegate: Rectangle {
          width: alarmsList.width
          height: 42
          radius: 8
          color: modelData.enabled ? Style.surfaceVariant : Style.surface
          border.color: modelData.enabled ? Style.border : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            // Time & Repeat Days
            Column {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              spacing: 1

              Row {
                spacing: 6
                Text {
                  text: modelData.time || "00:00"
                  color: modelData.enabled ? Style.textPrimary : Style.textMuted
                  font.pixelSize: 15
                  font.weight: Font.DemiBold
                  font.letterSpacing: -0.3
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: formatDaysSummary(modelData.days)
                  color: Style.textMuted
                  font.pixelSize: 9
                }
              }

              Text {
                text: modelData.label || "Alarm"
                color: Style.textSecondary
                font.pixelSize: 9
                elide: Text.ElideRight
                width: 140
              }
            }

            // Apple iOS Style Toggle Switch
            Rectangle {
              width: 34
              height: 18
              radius: 9
              color: modelData.enabled ? Style.accentGreen : Style.surfaceHover

              Behavior on color { ColorAnimation { duration: 180 } }

              Rectangle {
                width: 14
                height: 14
                radius: 7
                color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
                x: modelData.enabled ? parent.width - width - 2 : 2

                Behavior on x {
                  SpringAnimation { spring: 35; damping: 0.8 }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) {
                    root.ipc.toggleAlarm(modelData.id, !modelData.enabled)
                  }
                }
              }
            }

            // Delete Action
            Rectangle {
              width: 20
              height: 20
              radius: 10
              color: delMouse.containsMouse ? Style.surfaceHover : "transparent"

              Text {
                anchors.centerIn: parent
                text: "✕"
                color: Style.textMuted
                font.pixelSize: 9
              }

              MouseArea {
                id: delMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) {
                    root.ipc.deleteAlarm(modelData.id)
                  }
                }
              }
            }
          }
        }

        // Empty state placeholder
        Item {
          anchors.centerIn: parent
          visible: !root.ipc || !root.ipc.alarms || root.ipc.alarms.length === 0

          Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Kayıtlı alarm bulunmuyor"
              color: Style.textMuted
              font.pixelSize: 11
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Aşağıdaki butondan yeni alarm kurabilirsiniz"
              color: Style.textMuted
              font.pixelSize: 9
              opacity: 0.7
            }
          }
        }
      }
    }

    // Add Alarm Trigger Button
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 28
      radius: 8
      color: addBtnMouse.containsMouse ? Style.surfaceHover : Style.surface
      border.color: Style.border
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: "+ Yeni Alarm Ekle"
        color: Style.textPrimary
        font.pixelSize: 10
        font.weight: Font.DemiBold
      }

      MouseArea {
        id: addBtnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.showAddPanel = true
        }
      }
    }
  }

  // ==========================================
  // VIEW 2: Add Alarm Configuration Sheet (Fully Self-contained)
  // ==========================================
  Rectangle {
    anchors.fill: parent
    radius: 12
    color: Style.surface
    border.color: Style.border
    border.width: 1
    visible: root.showAddPanel

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 4

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Yeni Alarm Kur"
          color: Style.textPrimary
          font.pixelSize: 11
          font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }

        // Close X Button
        Rectangle {
          width: 18
          height: 18
          radius: 9
          color: closeTopMouse.containsMouse ? Style.surfaceHover : "transparent"

          Text {
            anchors.centerIn: parent
            text: "✕"
            color: Style.textMuted
            font.pixelSize: 9
          }

          MouseArea {
            id: closeTopMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showAddPanel = false
          }
        }
      }

      // TimePicker Control
      TimePicker {
        id: alarmTimePicker
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 170
        Layout.preferredHeight: 54
        hour: root.newHour
        minute: root.newMinute
        onTimeChanged: (h, m, str) => {
          root.newHour = h
          root.newMinute = m
        }
      }

      // Editable Label Input Box
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        radius: 6
        color: Style.surfaceVariant

        TextInput {
          id: sheetLabelInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: TextInput.AlignVCenter
          text: root.newAlarmLabel
          color: Style.textPrimary
          font.pixelSize: 10
          selectByMouse: true
          onTextChanged: root.newAlarmLabel = text

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: "Alarm etiketi..."
            color: Style.textMuted
            font.pixelSize: 10
            visible: !sheetLabelInput.text && !sheetLabelInput.activeFocus
          }
        }
      }

      // Repeat Presets Row
      RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 20
          radius: 5
          color: (root.selectedDays.length === 5 && root.selectedDays[0] === 1) ? Style.surfaceActive : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "Hafta İçi"
            color: Style.textPrimary
            font.pixelSize: 9
            font.weight: (root.selectedDays.length === 5 && root.selectedDays[0] === 1) ? Font.DemiBold : Font.Normal
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setPresetDays("WEEKDAYS")
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 20
          radius: 5
          color: root.selectedDays.length === 7 ? Style.surfaceActive : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "Her Gün"
            color: Style.textPrimary
            font.pixelSize: 9
            font.weight: root.selectedDays.length === 7 ? Font.DemiBold : Font.Normal
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setPresetDays("EVERYDAY")
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 20
          radius: 5
          color: root.selectedDays.length === 0 ? Style.surfaceActive : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "Tek Sefer"
            color: Style.textPrimary
            font.pixelSize: 9
            font.weight: root.selectedDays.length === 0 ? Font.DemiBold : Font.Normal
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setPresetDays("ONCE")
          }
        }
      }

      // Individual Day Toggle Pills (Pt, Sa, Ça, Pe, Cu, Ct, Pz)
      RowLayout {
        Layout.fillWidth: true
        spacing: 3

        Repeater {
          model: [
            { num: 1, label: "Pt" },
            { num: 2, label: "Sa" },
            { num: 3, label: "Ça" },
            { num: 4, label: "Pe" },
            { num: 5, label: "Cu" },
            { num: 6, label: "Ct" },
            { num: 7, label: "Pz" }
          ]

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            radius: 5
            readonly property bool isSelected: root.isDaySelected(modelData.num)
            color: isSelected ? Style.accentCyan : Style.surfaceVariant

            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: isSelected ? "#000000" : Style.textPrimary
              font.pixelSize: 9
              font.weight: isSelected ? Font.Bold : Font.Normal
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleDay(modelData.num)
            }
          }
        }
      }

      // Bottom Action Buttons Row
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        // Cancel Button
        Rectangle {
          Layout.preferredWidth: 65
          Layout.preferredHeight: 26
          radius: 6
          color: cancelMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "İptal"
            color: Style.textSecondary
            font.pixelSize: 10
            font.weight: Font.Medium
          }

          MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showAddPanel = false
          }
        }

        // Save Button
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 26
          radius: 6
          color: saveMouse.containsMouse ? Style.accentHover : Style.accent

          Text {
            anchors.centerIn: parent
            text: "Alarmı Kaydet"
            color: "#ffffff"
            font.pixelSize: 10
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: saveMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.submitNewAlarm()
          }
        }
      }
    }
  }
}
