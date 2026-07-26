import QtQuick
import Quickshell

Row {
  id: root
  required property var screenContext
  required property bool isHovered
  required property var theme

  signal volumeClickRequested()
  signal volumeScrollRequested()
  signal brightnessClickRequested()
  signal brightnessScrollRequested()

  spacing: 10
  anchors.verticalCenter: parent.verticalCenter
  clip: true

  width: isHovered ? implicitWidth : 0
  opacity: isHovered ? 1.0 : 0.0

  Behavior on width {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }
  Behavior on opacity {
    NumberAnimation { duration: 150 }
  }

  // Volume Info Section
  Item {
    width: volRow.width
    height: 24
    anchors.verticalCenter: parent.verticalCenter

    Row {
      id: volRow
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: root.screenContext.audioMuted ? "\uf026" : (root.screenContext.volume > 50 ? "\uf028" : (root.screenContext.volume > 0 ? "\uf027" : "\uf026"))
        color: root.screenContext.audioMuted ? "#ef4444" : root.theme.accent
        font { family: "FiraCode Nerd Font"; pixelSize: 10 }
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: root.screenContext.volume + "%"
        color: root.theme.textSecondary
        font { family: "JetBrains Mono"; pixelSize: 9 }
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton
      
      onClicked: {
        root.volumeClickRequested();
      }

      onWheel: (wheel) => {
        if (wheel.angleDelta.y > 0) {
          var newVol = Math.min(100, root.screenContext.volume + 2);
          root.screenContext.volume = newVol;
          Quickshell.execDetached(["amixer", "sset", "Master", newVol + "%"]);
        } else {
          var newVol = Math.max(0, root.screenContext.volume - 2);
          root.screenContext.volume = newVol;
          Quickshell.execDetached(["amixer", "sset", "Master", newVol + "%"]);
        }
        root.volumeScrollRequested();
      }
    }
  }

  // Brightness Info Section
  Item {
    width: brightRow.width
    height: 24
    anchors.verticalCenter: parent.verticalCenter

    Row {
      id: brightRow
      spacing: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: "\uf185" // Sun icon
        color: root.theme.accent
        font { family: "FiraCode Nerd Font"; pixelSize: 10 }
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: root.screenContext.brightness + "%"
        color: root.theme.textSecondary
        font { family: "JetBrains Mono"; pixelSize: 9 }
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton

      onClicked: {
        root.brightnessClickRequested();
      }

      onWheel: (wheel) => {
        if (wheel.angleDelta.y > 0) {
          var newBright = Math.min(100, root.screenContext.brightness + 5);
          root.screenContext.setBrightness(newBright);
        } else {
          var newBright = Math.max(0, root.screenContext.brightness - 5);
          root.screenContext.setBrightness(newBright);
        }
        root.brightnessScrollRequested();
      }
    }
  }
}
