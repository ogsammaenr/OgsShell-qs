import QtQuick

Column {
  id: networkContent
  width: 332
  height: 362
  spacing: 12

  required property var theme
  signal backClicked()
  signal connectPasswordRequested(string ssid)

  // Header Item (Back Button + Title + Switch + Refresh)
  Item {
    width: parent.width
    height: 24
    
    Text {
      id: backBtn
      text: "\uf060" // Back arrow
      color: theme.textPrimary
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: networkContent.backClicked()
      }
    }
    
    Text {
      text: "Ağ ve Bağlantılar"
      color: theme.textPrimary
      font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Bold }
      anchors.left: backBtn.right
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    // Refresh Button
    Text {
      id: refreshBtn
      text: "\uf021" // Refresh
      color: networkManagerService.isScanning ? theme.accent : theme.textSecondary
      font { family: "FiraCode Nerd Font"; pixelSize: 13 }
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
        running: networkManagerService.isScanning
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          networkManagerService.refresh();
        }
      }
    }

    // Small Wi-Fi Toggle Switch (Radio style)
    Rectangle {
      id: wifiHeaderSwitch
      width: 32
      height: 16
      radius: 8
      color: networkManagerService.wifiConnected ? theme.accent : theme.buttonBg
      anchors.right: refreshBtn.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      
      Behavior on color { ColorAnimation { duration: 150 } }
      
      Rectangle {
        width: 10
        height: 10
        radius: 5
        color: networkManagerService.wifiConnected ? theme.textOnAccent : theme.textPrimary
        anchors.verticalCenter: parent.verticalCenter
        x: networkManagerService.wifiConnected ? 19 : 3
        
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
      }
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          networkManagerService.toggleWifi(!networkManagerService.wifiConnected);
        }
      }
    }
  }

  // Connecting State Screen
  Column {
    width: parent.width
    height: 322
    spacing: 12
    visible: networkManagerService.isConnecting
    
    Item { width: 1; height: 50 } // spacer
    
    Text {
      text: "\uf254" // Hourglass loading icon
      color: theme.accent
      font { family: "FiraCode Nerd Font"; pixelSize: 32 }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
      
      RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1500
        loops: Animation.Infinite
        running: networkManagerService.isConnecting
      }
    }
    
    Text {
      text: "Bağlantı kuruluyor..."
      color: theme.textPrimary
      font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
      horizontalAlignment: Text.AlignHCenter
      width: parent.width
    }
  }

  // Scrollable connections list
  Item {
    width: parent.width
    height: 322
    clip: true
    visible: !networkManagerService.isConnecting
    
    Flickable {
      id: netFlickable
      anchors.fill: parent
      contentHeight: netCol.height
      clip: true
      interactive: true
      boundsBehavior: Flickable.StopAtBounds
      
      Column {
        id: netCol
        width: parent.width - 8
        spacing: 8
        
        // 1. Wired Connection (Ethernet)
        Rectangle {
          width: parent.width
          height: 40
          radius: 8
          color: theme.buttonBg
          border.color: networkManagerService.ethernetConnected ? theme.accent : "transparent"
          border.width: networkManagerService.ethernetConnected ? 1.5 : 0
          
          MouseArea {
            anchors.fill: parent
            cursorShape: networkManagerService.ethernetDevice !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              if (networkManagerService.ethernetDevice === "") return;
              if (networkManagerService.ethernetConnected) {
                networkManagerService.disconnectEthernet();
              } else {
                networkManagerService.connectEthernet();
              }
            }
          }
          
          Item {
            anchors.fill: parent
            anchors.margins: 10
            
            Text {
              id: ethIcon
              text: "\uf796" // Ethernet icon
              color: networkManagerService.ethernetConnected ? theme.accent : theme.textSecondary
              font { family: "FiraCode Nerd Font"; pixelSize: 14 }
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
              text: "Kablolu Ağ (Ethernet)"
              color: theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              anchors.left: ethIcon.right
              anchors.leftMargin: 10
              anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
              text: networkManagerService.ethernetConnected ? "Bağlı" : (networkManagerService.ethernetDevice !== "" ? "Bağlantı Yok" : "Kullanılamaz")
              color: networkManagerService.ethernetConnected ? theme.green : theme.textSecondary
              font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
        
        // Separator line
        Rectangle {
          width: parent.width
          height: 1
          color: "#10ffffff"
          visible: networkManagerService.wifiConnected
        }
        
        // 2. Wi-Fi List
        Repeater {
          model: networkManagerService.wifiList
          delegate: Rectangle {
            width: netCol.width
            height: 40
            radius: 8
            color: modelData.active ? "#15ffffff" : theme.buttonBg
            border.color: modelData.active ? theme.accent : "transparent"
            border.width: modelData.active ? 1.5 : 0
            
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.active) {
                  networkManagerService.disconnectWifi();
                } else {
                  var isSaved = networkManagerService.savedConnections.indexOf(modelData.ssid) !== -1;
                  if (modelData.secure && !isSaved) {
                    networkContent.connectPasswordRequested(modelData.ssid);
                  } else {
                    networkManagerService.connectToWifi(modelData.ssid, "");
                  }
                }
              }
            }
            
            Item {
              anchors.fill: parent
              anchors.margins: 10
              
              Text {
                id: wifiIcon
                text: modelData.active ? "\uf1eb" : (modelData.secure ? "\uf023" : "\uf1eb")
                color: modelData.active ? theme.accent : theme.textSecondary
                font { family: "FiraCode Nerd Font"; pixelSize: 13 }
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }
              
              Text {
                text: modelData.ssid
                color: theme.textPrimary
                font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
                elide: Text.ElideRight
                anchors.left: wifiIcon.right
                anchors.leftMargin: 10
                anchors.right: statusRow.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
              }
              
              Row {
                id: statusRow
                spacing: 6
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                
                Text {
                  text: modelData.signal + "%"
                  color: theme.textSecondary
                  font { family: "JetBrains Mono"; pixelSize: 9 }
                  anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                  text: modelData.active ? "\uf00c" : ""
                  color: theme.accent
                  font { family: "FiraCode Nerd Font"; pixelSize: 10 }
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }
      }
    }
    
    // Custom Scrollbar for Network List
    Rectangle {
      id: netScrollbar
      anchors.right: parent.right
      width: 3
      radius: 1.5
      color: theme.accent
      opacity: netFlickable.moving || netFlickable.flicking ? 0.6 : 0.2
      visible: netFlickable.contentHeight > netFlickable.height
      y: netFlickable.visibleArea.yPosition * netFlickable.height
      height: Math.max(20, netFlickable.visibleArea.heightRatio * netFlickable.height)
      Behavior on opacity { NumberAnimation { duration: 150 } }
    }
  }
}
