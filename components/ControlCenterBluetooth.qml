import QtQuick

Column {
  id: bluetoothContent
  width: 332
  height: 362
  spacing: 12

  required property var theme
  required property var screenContext
  signal backClicked()

  // Header Item (Back Button + Title + Switch + Refresh)
  Item {
    width: parent.width
    height: 24
    
    Text {
      id: btBackBtn
      text: "\uf060" // Back arrow
      color: theme.textPrimary
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: bluetoothContent.backClicked()
      }
    }
    
    Text {
      text: "Bluetooth Cihazları"
      color: theme.textPrimary
      font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Bold }
      anchors.left: btBackBtn.right
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    // Refresh Button
    Text {
      id: btRefreshBtn
      text: "\uf021" // Refresh
      color: bluetoothService.isScanning ? theme.accent : theme.textSecondary
      font { family: "FiraCode Nerd Font"; pixelSize: 13 }
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
        running: bluetoothService.isScanning
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          bluetoothService.refresh();
        }
      }
    }

    // Small Bluetooth Toggle Switch
    Rectangle {
      id: btHeaderSwitch
      width: 32
      height: 16
      radius: 8
      color: (screenContext.bluetoothStatus === "connected" || screenContext.bluetoothStatus === "on") ? theme.accent : theme.buttonBg
      anchors.right: btRefreshBtn.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      
      Behavior on color { ColorAnimation { duration: 150 } }
      
      Rectangle {
        width: 10
        height: 10
        radius: 5
        color: "#ffffff"
        anchors.verticalCenter: parent.verticalCenter
        x: (screenContext.bluetoothStatus === "connected" || screenContext.bluetoothStatus === "on") ? 19 : 3
        
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          var isOn = (screenContext.bluetoothStatus === "connected" || screenContext.bluetoothStatus === "on");
          bluetoothService.togglePower(!isOn);
        }
      }
    }
  }

  // Divider
  Rectangle {
    width: parent.width
    height: 1
    color: "#10ffffff"
  }

  // Empty state (If Bluetooth is turned off)
  Column {
    width: parent.width
    height: 310
    spacing: 12
    visible: (screenContext.bluetoothStatus === "off")
    
    Item { width: 1; height: 40 } // spacer
    
    Text {
      text: "\uf293"
      color: theme.textSecondary
      font { family: "FiraCode Nerd Font"; pixelSize: 32 }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      opacity: 0.3
    }
    
    Text {
      text: "Bluetooth Kapalı"
      color: theme.textSecondary
      font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      opacity: 0.5
    }
  }

  // Empty list state (Bluetooth on but no devices found)
  Column {
    width: parent.width
    height: 310
    spacing: 12
    visible: (screenContext.bluetoothStatus !== "off") && (bluetoothService.deviceList.length === 0)
    
    Item { width: 1; height: 40 } // spacer
    
    Text {
      text: "\uf293"
      color: theme.textSecondary
      font { family: "FiraCode Nerd Font"; pixelSize: 32 }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      opacity: 0.3
    }
    
    Text {
      text: bluetoothService.isScanning ? "Cihazlar taranıyor..." : "Cihaz bulunamadı"
      color: theme.textSecondary
      font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      opacity: 0.5
    }
  }

  // Scrollable Devices List
  Item {
    width: parent.width
    height: 310
    clip: true
    visible: (screenContext.bluetoothStatus !== "off") && (bluetoothService.deviceList.length > 0)
    
    Flickable {
      id: btFlickable
      anchors.fill: parent
      contentHeight: btCol.height
      clip: true
      interactive: true
      boundsBehavior: Flickable.StopAtBounds
      
      Column {
        id: btCol
        width: parent.width - 8
        spacing: 8
        
        Repeater {
          model: bluetoothService.deviceList
          delegate: Rectangle {
            width: btCol.width
            height: 48
            radius: 8
            color: modelData.connected ? "#15ffffff" : theme.buttonBg
            border.color: modelData.connected ? theme.accent : "transparent"
            border.width: modelData.connected ? 1 : 0
            
            Item {
              anchors.fill: parent
              anchors.margins: 10
              
              // Bluetooth Icon / Connection status
              Text {
                id: btStatusIcon
                text: modelData.connected ? "\uf293" : (modelData.paired ? "\uf0c1" : "\uf293") // BT or Link icon
                color: modelData.connected ? theme.accent : (modelData.paired ? theme.textPrimary : theme.textSecondary)
                font { family: "FiraCode Nerd Font"; pixelSize: 12 }
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }
              
              // Device Name & MAC Address
              Column {
                anchors.left: btStatusIcon.right
                anchors.leftMargin: 10
                anchors.right: btActionIcons.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                  text: modelData.name
                  color: theme.textPrimary
                  font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
                  elide: Text.ElideRight
                  width: parent.width
                }
                
                Text {
                  text: modelData.mac
                  color: theme.textSecondary
                  font { family: "JetBrains Mono"; pixelSize: 7 }
                }
              }

              // Action Icons (Trust, Untrust, Delete) or Pair Button on the right
              Row {
                id: btActionIcons
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Trust/Untrust icon (only visible when paired)
                Text {
                  visible: modelData.paired
                  text: modelData.trusted ? "\uf023" : "\uf09c" // Lock/Unlock
                  color: trustMouse.containsMouse ? theme.accent : (modelData.trusted ? theme.accent : theme.textSecondary)
                  font { family: "FiraCode Nerd Font"; pixelSize: 11 }
                  anchors.verticalCenter: parent.verticalCenter

                  MouseArea {
                    id: trustMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      bluetoothService.trustDevice(modelData.mac, !modelData.trusted);
                    }
                  }
                }

                // Delete / Unpair icon (only visible when paired)
                Text {
                  visible: modelData.paired
                  text: "\uf1f8" // Trash
                  color: unpairMouse.containsMouse ? theme.red : theme.textSecondary
                  font { family: "FiraCode Nerd Font"; pixelSize: 11 }
                  anchors.verticalCenter: parent.verticalCenter

                  MouseArea {
                    id: unpairMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      bluetoothService.removeDevice(modelData.mac);
                    }
                  }
                }

                // Pair Button (only visible when NOT paired)
                Rectangle {
                  visible: !modelData.paired
                  width: 54
                  height: 20
                  radius: 4
                  color: pairMouse.containsMouse ? theme.accent : "transparent"
                  border.color: theme.accent
                  border.width: 1
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    text: "Eşleştir"
                    color: pairMouse.containsMouse ? "#000000" : theme.accent
                    font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
                    anchors.centerIn: parent
                  }

                  MouseArea {
                    id: pairMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      bluetoothService.pairDevice(modelData.mac);
                    }
                  }
                }
              }
            }
            
            // Click Area to Connect / Disconnect / Pair
            MouseArea {
              anchors.fill: parent
              width: parent.width - 60 // Leave space for action icons on the right
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!modelData.paired) {
                  bluetoothService.pairDevice(modelData.mac);
                } else if (modelData.connected) {
                  bluetoothService.disconnectDevice(modelData.mac);
                } else {
                  bluetoothService.connectDevice(modelData.mac);
                }
              }
            }
          }
        }
      }
    }
    
    // Custom Scrollbar for Bluetooth List
    Rectangle {
      id: btScrollbar
      anchors.right: parent.right
      width: 3
      radius: 1.5
      color: theme.accent
      opacity: btFlickable.moving || btFlickable.flicking ? 0.6 : 0.2
      visible: btFlickable.contentHeight > btFlickable.height
      y: btFlickable.visibleArea.yPosition * btFlickable.height
      height: Math.max(20, btFlickable.visibleArea.heightRatio * btFlickable.height)
      Behavior on opacity { NumberAnimation { duration: 150 } }
    }
  }
}
