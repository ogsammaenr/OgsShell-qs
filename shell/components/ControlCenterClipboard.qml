import QtQuick

Column {
  id: clipboardContent
  width: 332
  height: 362
  spacing: 12

  required property var theme
  signal backClicked()

  // Local helper timer for showing copied indicator checkmark
  property string copiedClipId: ""
  Timer {
    id: clipCopiedTimer
    interval: 1000
    running: false
    repeat: false
    onTriggered: {
      clipboardContent.copiedClipId = "";
    }
  }

  // Header Item (Back Button + Title + Clear All)
  Item {
    width: parent.width
    height: 24
    
    Text {
      id: clipBackBtn
      text: "\uf060" // Back arrow
      color: theme.textPrimary
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: clipboardContent.backClicked()
      }
    }
    
    Text {
      text: "Pano Geçmişi"
      color: theme.textPrimary
      font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Bold }
      anchors.left: clipBackBtn.right
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    // Clear All Button (Trash)
    Text {
      text: "\uf2ed Hepsini Sil"
      color: clearMouse.containsMouse ? theme.red : theme.textSecondary
      font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      MouseArea {
        id: clearMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          clipboardService.clearHistory();
        }
      }
      
      Behavior on color { ColorAnimation { duration: 150 } }
    }
  }

  // Empty Clipboard State
  Column {
    width: parent.width
    height: 326
    spacing: 12
    visible: clipboardService.clipboardItems.length === 0
    
    Item { width: 1; height: 50 } // spacer
    
    Text {
      text: "\uf0ea" // Clipboard icon
      color: theme.textSecondary
      font { family: "FiraCode Nerd Font"; pixelSize: 32 }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      opacity: 0.3
    }
    
    Text {
      text: "Pano Geçmişi Boş"
      color: theme.textSecondary
      font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      opacity: 0.5
    }
  }

  // Scrollable Clipboard Items List
  Item {
    width: parent.width
    height: 326
    clip: true
    visible: clipboardService.clipboardItems.length > 0
    
    Flickable {
      id: clipFlickable
      anchors.fill: parent
      contentHeight: clipCol.height
      clip: true
      interactive: true
      boundsBehavior: Flickable.StopAtBounds
      
      Column {
        id: clipCol
        width: parent.width - 8
        spacing: 8
        
        Repeater {
          model: clipboardService.clipboardItems
          delegate: Rectangle {
            width: clipCol.width
            height: 44
            radius: 8
            color: theme.buttonBg
            
            Item {
              anchors.fill: parent
              anchors.margins: 10
              
              // Copy Indicator / Icon
              Text {
                id: indicatorIcon
                text: clipboardContent.copiedClipId === modelData.id ? "\uf00c" : "\uf0ea"
                color: clipboardContent.copiedClipId === modelData.id ? theme.green : theme.textSecondary
                font { family: "FiraCode Nerd Font"; pixelSize: 12 }
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                
                Behavior on color { ColorAnimation { duration: 150 } }
              }
              
              // Clipboard Text Preview
              Text {
                text: modelData.text
                color: theme.textPrimary
                font { family: "JetBrains Mono"; pixelSize: 9 }
                elide: Text.ElideRight
                anchors.left: indicatorIcon.right
                anchors.leftMargin: 10
                anchors.right: deleteBtn.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
              }
              
              // Delete Single Item Button
              Text {
                id: deleteBtn
                text: "\uf2ed" // Trash icon
                color: deleteMouse.containsMouse ? theme.red : "#20ffffff"
                font { family: "FiraCode Nerd Font"; pixelSize: 11 }
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                
                MouseArea {
                  id: deleteMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    clipboardService.deleteItem(modelData.raw);
                  }
                }
                
                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
            
            // Main Click Area to Copy
            MouseArea {
              anchors.fill: parent
              width: parent.width - 32
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                clipboardService.copyItem(modelData.id);
                clipboardContent.copiedClipId = modelData.id;
                clipCopiedTimer.restart();
              }
            }
          }
        }
      }
    }
    
    // Custom Scrollbar for Clipboard List
    Rectangle {
      id: clipScrollbar
      anchors.right: parent.right
      width: 3
      radius: 1.5
      color: theme.accent
      opacity: clipFlickable.moving || clipFlickable.flicking ? 0.6 : 0.2
      visible: clipFlickable.contentHeight > clipFlickable.height
      y: clipFlickable.visibleArea.yPosition * clipFlickable.height
      height: Math.max(20, clipFlickable.visibleArea.heightRatio * clipFlickable.height)
      Behavior on opacity { NumberAnimation { duration: 150 } }
    }
  }
}
