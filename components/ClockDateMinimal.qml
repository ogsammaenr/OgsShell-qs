import QtQuick

Row {
  id: clockDateRow
  property var sysClock: null
  required property bool isHovered
  required property var theme

  signal clockClicked()
  signal dateClicked()

  spacing: isHovered ? 12 : 0
  anchors.verticalCenter: parent.verticalCenter

  Behavior on spacing {
    NumberAnimation { duration: 150 }
  }

  Text {
    id: clockText
    text: sysClock ? Qt.formatDateTime(sysClock.date, "hh:mm") : "--:--"
    color: theme.textPrimary
    font {
      family: "JetBrains Mono"
      pixelSize: clockDateRow.isHovered ? 16 : 13
      weight: Font.Bold
    }
    anchors.verticalCenter: parent.verticalCenter

    Behavior on font.pixelSize {
      NumberAnimation { duration: 150 }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: clockDateRow.clockClicked()
    }
  }

  Rectangle {
    id: separator
    width: 1
    height: clockDateRow.isHovered ? 14 : 10
    color: theme.textSecondary
    opacity: clockDateRow.isHovered ? 0.3 : 0.0
    anchors.verticalCenter: parent.verticalCenter

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }
    Behavior on height {
      NumberAnimation { duration: 150 }
    }
  }

  Text {
    id: dateText
    text: sysClock ? Qt.formatDateTime(sysClock.date, "d MMMM dddd") : ""
    color: theme.textSecondary
    font {
      family: "JetBrains Mono"
      pixelSize: clockDateRow.isHovered ? 12 : 11
    }
    anchors.verticalCenter: parent.verticalCenter
    opacity: clockDateRow.isHovered ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }
    Behavior on font.pixelSize {
      NumberAnimation { duration: 150 }
    }

    width: clockDateRow.isHovered ? implicitWidth : 0
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutQuad
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: clockDateRow.isHovered
      cursorShape: Qt.PointingHandCursor
      onClicked: clockDateRow.dateClicked()
    }
  }
}
