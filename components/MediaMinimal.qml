import QtQuick
import Quickshell

Item {
  id: mediaMinimalContainer
  property var screenContext: null
  required property bool isHovered
  required property var theme

  // Animate the container's total width and opacity based on hover state
  width: isHovered ? 180 : 0
  height: parent ? parent.height : 38 // Fill the full height of the parent bar!
  opacity: isHovered ? 1.0 : 0.0
  clip: true

  Behavior on width {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }
  Behavior on opacity {
    NumberAnimation { duration: 120 }
  }

  // Click anywhere on the media info to play/pause
  MouseArea {
    anchors.fill: parent
    onClicked: {
      Quickshell.execDetached(["playerctl", "play-pause"])
    }
  }

  Row {
    anchors.fill: parent
    spacing: 6

    Text {
      id: musicIcon
      text: (screenContext && screenContext.mediaStatus === "Playing") ? "\uf144" : "\uf001"
      color: (screenContext && screenContext.mediaStatus === "Playing") ? theme.accent : theme.textSecondary
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 12
      }
      anchors.verticalCenter: parent.verticalCenter
      
      Behavior on color {
        ColorAnimation { duration: 120 }
      }
    }

    Text {
      id: mediaText
      text: {
        if (!screenContext) return "Medya Çalmıyor"
        if (screenContext.mediaTitle !== "") {
          if (screenContext.mediaArtist !== "") {
            return screenContext.mediaArtist + " - " + screenContext.mediaTitle
          }
          return screenContext.mediaTitle
        }
        return "Medya Çalmıyor"
      }
      color: theme.textSecondary
      font {
        family: "JetBrains Mono"
        pixelSize: 10
      }
      elide: Text.ElideRight
      width: 160
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
