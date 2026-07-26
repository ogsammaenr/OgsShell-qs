import QtQuick

Column {
  id: passwordContent
  width: 332
  height: 362
  spacing: 16

  required property var theme
  required property string ssid
  signal backClicked()

  // Expose input focus
  property alias inputFocus: passInput.focus

  // Helper method to clear the input field
  function clearInput() {
    passInput.text = "";
  }

  Row {
    width: parent.width
    height: 24
    spacing: 12
    
    Text {
      text: "\uf060" // Back arrow
      color: theme.textPrimary
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.verticalCenter: parent.verticalCenter
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: passwordContent.backClicked()
      }
    }
    
    Text {
      text: passwordContent.ssid + " Şifresi"
      color: theme.textPrimary
      font { family: "JetBrains Mono"; pixelSize: 12; weight: Font.Bold }
      elide: Text.ElideRight
      width: parent.width - 40
      anchors.verticalCenter: parent.verticalCenter
    }
  }
  
  // Password Box Container
  Rectangle {
    width: parent.width
    height: 40
    radius: 8
    color: theme.buttonBg
    border.color: passInput.activeFocus ? theme.accent : "#20ffffff"
    border.width: 1
    
    TextInput {
      id: passInput
      anchors.fill: parent
      anchors.margins: 10
      color: theme.textPrimary
      echoMode: TextInput.Password
      font { family: "JetBrains Mono"; pixelSize: 11 }
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      
      Text {
        text: "Şifre girin..."
        color: "#40ffffff"
        font: parent.font
        visible: parent.text.length === 0 && !parent.activeFocus
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
      }
      
      onAccepted: {
        networkManagerService.connectToWifi(passwordContent.ssid, passInput.text);
      }
    }
  }
  
  // Error / Status Message
  Text {
    text: networkManagerService.isConnecting ? "Bağlanıyor..." : networkManagerService.connectionError
    color: networkManagerService.connectionError !== "" ? theme.red : theme.textSecondary
    font { family: "JetBrains Mono"; pixelSize: 10 }
    horizontalAlignment: Text.AlignHCenter
    width: parent.width
  }
  
  Row {
    spacing: 12
    width: parent.width
    height: 36
    
    // Cancel Button
    Rectangle {
      width: (parent.width - 12) / 2
      height: parent.height
      radius: 8
      color: "#15ffffff"
      
      Text {
        text: "İptal"
        color: theme.textPrimary
        font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
        anchors.centerIn: parent
      }
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: passwordContent.backClicked()
      }
    }
    
    // Connect Button
    Rectangle {
      width: (parent.width - 12) / 2
      height: parent.height
      radius: 8
      color: theme.accent
      
      Text {
        text: "Bağlan"
        color: "#ffffff"
        font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
        anchors.centerIn: parent
      }
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          networkManagerService.connectToWifi(passwordContent.ssid, passInput.text);
        }
      }
    }
  }
}
