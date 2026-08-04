import QtQuick
import Quickshell

Row {
  id: actionButtonsRow
  property var screenContext: null

  spacing: 10
  anchors.verticalCenter: parent.verticalCenter
  width: 140

  // Notification Button
  Rectangle {
    width: 36
    height: 36
    radius: 18
    color: (screenContext && screenContext.notificationCount > 0) ? "#22d97a06" : "#1e293b"
    border.color: (screenContext && screenContext.notificationCount > 0) ? "#fbbf24" : "#334155"
    border.width: 1

    Text {
      text: "\uf0f3"
      color: (screenContext && screenContext.notificationCount > 0) ? "#fbbf24" : "#cbd5e1"
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.centerIn: parent
    }

    Rectangle {
      visible: (screenContext && screenContext.notificationCount > 0)
      width: 8
      height: 8
      radius: 4
      color: "#ef4444"
      border.color: "#0f172a"
      border.width: 1
      anchors.top: parent.top
      anchors.right: parent.right
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        Quickshell.execDetached(["swaync-client", "-t"]);
      }
    }
  }

  // Clipboard Button
  Rectangle {
    width: 36
    height: 36
    radius: 18
    color: "#1e293b"
    border.color: "#334155"
    border.width: 1

    Text {
      text: "\uf0ea"
      color: "#cbd5e1"
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.centerIn: parent
    }

    MouseArea {
      anchors.fill: parent
    }
  }

  // Power Button (Shelved for now)
  Rectangle {
    width: 36
    height: 36
    radius: 18
    color: "#22ef4444"
    border.color: "#ef4444"
    border.width: 1

    Text {
      text: "\uf011"
      color: "#ef4444"
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.centerIn: parent
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        console.log("Power button clicked (Power menu is currently shelved).");
      }
    }
  }
}
