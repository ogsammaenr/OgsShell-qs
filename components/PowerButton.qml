import QtQuick

Column {
  id: rootBtn
  spacing: 8
  
  required property string text
  required property string icon
  required property color colorNormal
  required property color colorHover
  required property color borderColor
  required property color textColor

  signal clicked()

  Rectangle {
    id: btnRect
    width: 68
    height: 68
    radius: 34
    
    property bool isHovered: false
    
    color: isHovered ? rootBtn.colorHover : rootBtn.colorNormal
    border.color: rootBtn.borderColor
    border.width: 2
    
    Behavior on color {
      ColorAnimation { duration: 120 }
    }

    Text {
      text: rootBtn.icon
      color: btnRect.isHovered ? "#ffffff" : rootBtn.textColor
      font {
        family: "FiraCode Nerd Font"
        pixelSize: 26
      }
      anchors.centerIn: parent
      
      Behavior on color {
        ColorAnimation { duration: 120 }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: btnRect.isHovered = true
      onExited: btnRect.isHovered = false
      onClicked: rootBtn.clicked()
    }
  }

  Text {
    text: rootBtn.text
    color: "#cbd5e1"
    anchors.horizontalCenter: parent.horizontalCenter
    font {
      family: "JetBrains Mono"
      pixelSize: 11
      weight: Font.Medium
    }
  }
}
