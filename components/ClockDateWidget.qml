import QtQuick

Row {
  id: clockDateRow
  property var sysClock: null
  required property bool isBarExpanded
  required property var hoverArea

  anchors.horizontalCenter: parent.horizontalCenter
  height: 18
  spacing: (hoverArea && (hoverArea.containsMouse || isBarExpanded)) ? 10 : 0

  Behavior on spacing {
    NumberAnimation { duration: 150 }
  }

  Text {
    id: clockText
    text: sysClock ? Qt.formatDateTime(sysClock.date, "hh:mm") : "--:--"
    color: "#ffffff"
    font {
      family: "JetBrains Mono"
      pixelSize: 14
      weight: Font.Bold
    }
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    id: separator
    width: 1
    height: 12
    color: "#40ffffff"
    anchors.verticalCenter: parent.verticalCenter
    opacity: (hoverArea && (hoverArea.containsMouse || isBarExpanded)) ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 100 }
    }
  }

  Text {
    id: dateText
    text: sysClock ? Qt.formatDateTime(sysClock.date, "d MMMM dddd") : ""
    color: "#94a3b8" // Slate-400
    font {
      family: "JetBrains Mono"
      pixelSize: 12
    }
    anchors.verticalCenter: parent.verticalCenter
    opacity: (hoverArea && (hoverArea.containsMouse || isBarExpanded)) ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 100 }
    }

    width: (hoverArea && (hoverArea.containsMouse || isBarExpanded)) ? implicitWidth : 0
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutQuad
      }
    }
  }
}
