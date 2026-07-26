import QtQuick
import Quickshell

Rectangle {
  id: root
  required property var screenContext
  required property var theme
  required property bool isOpen

  signal openPowerMenu()
  signal themeCycleRequested()

  property bool isSelectingTheme: false
  signal themeSelected(string themeName)

  property bool isSelectingNetwork: false
  property string selectedSsid: ""
  property bool isEnteringPassword: selectedSsid !== ""

  property bool isSelectingClipboard: false
  property string copiedClipId: ""

  property bool isSelectingBluetooth: false

  onIsOpenChanged: {
    if (!isOpen) {
      isSelectingTheme = false;
      isSelectingNetwork = false;
      isSelectingClipboard = false;
      isSelectingBluetooth = false;
      selectedSsid = "";
      copiedClipId = "";
    }
  }

  Timer {
    id: clipCopiedTimer
    interval: 1000
    running: false
    repeat: false
    onTriggered: {
      root.copiedClipId = "";
    }
  }



  readonly property var themeModel: (typeof themeConfigService !== "undefined" && themeConfigService.themeList && themeConfigService.themeList.length > 0)
    ? themeConfigService.themeList
    : [
        {
          "id": "catppuccin",
          "name": "Catppuccin",
          "folder": "Catppuccin",
          "bg": "#1e1e2e",
          "border": "#30cba6f7",
          "accent": "#cba6f7",
          "text": "#cdd6f4",
          "workspaces": ["#cba6f7", "#a6adc8", "#313244"]
        },
        {
          "id": "nord",
          "name": "Nord Night",
          "folder": "Nord",
          "bg": "#2e3440",
          "border": "#3088c0d0",
          "accent": "#88c0d0",
          "text": "#eceff4",
          "workspaces": ["#88c0d0", "#d8dee9", "#4c566a"]
        },
        {
          "id": "gruvbox",
          "name": "Retro Gruvbox",
          "folder": "Gruvbox",
          "bg": "#282828",
          "border": "#30fabd2f",
          "accent": "#fabd2f",
          "text": "#fbf1c7",
          "workspaces": ["#fabd2f", "#bdae93", "#504945"]
        },
        {
          "id": "monochrome",
          "name": "Monochrome",
          "folder": "Monochrome",
          "bg": "#181818",
          "border": "#40ffffff",
          "accent": "#e0e0e0",
          "text": "#ffffff",
          "workspaces": ["#ffffff", "#a0a0a0", "#333333"]
        }
      ]

  radius: 16
  clip: true

  color: theme.bg
  border.color: theme.border
  border.width: 1

  // Disable clicks passing through the panel card
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onPressed: (mouse) => mouse.accepted = true
  }

  Column {
    id: mainContent
    width: 332
    height: 362
    anchors.centerIn: parent
    spacing: 12
    visible: opacity > 0.01
    opacity: (root.isOpen && !root.isSelectingTheme && !root.isSelectingNetwork && !root.isSelectingClipboard && !root.isSelectingBluetooth) ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    // 0. Time & Date Header Section
    Item {
      width: parent.width
      height: 48
      anchors.horizontalCenter: parent.horizontalCenter
      
      Row {
        anchors.centerIn: parent
        spacing: 12
        
        Text {
          text: clock ? Qt.formatDateTime(clock.date, "hh:mm") : "--:--"
          color: root.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 26; weight: Font.ExtraBold }
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1
          
          Text {
            text: clock ? Qt.formatDateTime(clock.date, "d MMMM dddd") : ""
            color: root.theme.accent
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
          }
          
          Text {
            text: clock ? Qt.formatDateTime(clock.date, "yyyy") : ""
            color: root.theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 7 }
          }
        }
      }
    }

    // Faint Separator Line
    Rectangle {
      width: parent.width
      height: 1
      color: "#15ffffff"
    }

    // 1. Top System Stats Bar (Minimal Bullet Row)
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: topStatsRow.width
      height: 16

      Row {
        id: topStatsRow
        spacing: 7
        height: 16

        // CPU Usage
        Row {
          spacing: 5
          Text {
            text: "\uf2db" // CPU icon
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.cpuUsage + "%"
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Bullet Separator 1
        Text {
          text: "\u2022"
          color: "#30ffffff"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }

        // CPU Temp
        Row {
          spacing: 5
          Text {
            text: "\uf2c9" // Thermometer
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.cpuTemp + "°C"
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Bullet Separator 2
        Text {
          text: "\u2022"
          color: "#30ffffff"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }

        // RAM Usage
        Row {
          spacing: 5
          Text {
            text: "\uf538" // Memory icon
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.ramUsage + "%"
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Bullet Separator 3
        Text {
          text: "\u2022"
          color: "#30ffffff"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }

        // GPU Usage
        Row {
          spacing: 5
          Text {
            text: "\uf530" // GPU icon
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.gpuUsage + "%"
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Bullet Separator 4
        Text {
          text: "\u2022"
          color: "#30ffffff"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }

        // GPU Temp
        Row {
          spacing: 5
          Text {
            text: "\uf2c9" // Thermometer
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.gpuTemp + "°C"
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Bullet Separator 5
        Text {
          text: "\u2022"
          color: "#30ffffff"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }

        // Network Speed
        Row {
          spacing: 5
          Text {
            text: "\uf0ec" // Net icon
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.netSpeed
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          screenContext.showCpuUsageOnBar = true;
          screenContext.showCpuTempOnBar = true;
          screenContext.showRamUsageOnBar = true;
          screenContext.showGpuUsageOnBar = true;
          screenContext.showGpuTempOnBar = true;
          screenContext.showNetSpeedOnBar = true;
        }
      }
    }

    // Faint Separator Line
    Rectangle {
      width: parent.width
      height: 1
      color: "#15ffffff"
    }

    // 2. WiFi & Bluetooth Toggles (Flat, Borderless pills)
    Row {
      width: parent.width
      spacing: 12
      height: 44

      // WiFi Button
      Rectangle {
        width: (parent.width - 12) / 2
        height: parent.height
        radius: 10
        color: networkManagerService.wifiConnected ? root.theme.accent : root.theme.buttonBg

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
              networkManagerService.toggleWifi(!networkManagerService.wifiConnected);
            } else {
              root.isSelectingNetwork = true;
              networkManagerService.refresh();
            }
          }
        }

        Row {
          anchors.centerIn: parent
          spacing: 8
          Text {
            text: "\uf1eb" // Wifi icon
            color: networkManagerService.wifiConnected ? "#ffffff" : root.theme.textSecondary
            font { family: "FiraCode Nerd Font"; pixelSize: 13 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
              text: "Wi-Fi"
              color: networkManagerService.wifiConnected ? "#ffffff" : root.theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            }
            Text {
              text: networkManagerService.wifiConnected ? (networkManagerService.wifiSsid ? networkManagerService.wifiSsid : "Bağlı") : "Kapalı"
              color: networkManagerService.wifiConnected ? "#d0ffffff" : root.theme.textSecondary
              font { family: "JetBrains Mono"; pixelSize: 7 }
              elide: Text.ElideRight
              width: 90
            }
          }
        }
      }

      // Bluetooth Button
      Rectangle {
        width: (parent.width - 12) / 2
        height: parent.height
        radius: 10
        color: (root.screenContext.bluetoothStatus === "connected" || root.screenContext.bluetoothStatus === "on") ? root.theme.accent : root.theme.buttonBg

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
              bluetoothService.togglePower(root.screenContext.bluetoothStatus === "off");
            } else {
              root.isSelectingBluetooth = true;
              bluetoothService.refresh();
            }
          }
        }

        Row {
          anchors.centerIn: parent
          spacing: 8
          Text {
            text: "\uf293" // Bluetooth icon
            color: (root.screenContext.bluetoothStatus === "connected" || root.screenContext.bluetoothStatus === "on") ? "#ffffff" : root.theme.textSecondary
            font { family: "FiraCode Nerd Font"; pixelSize: 13 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
              text: "Bluetooth"
              color: (root.screenContext.bluetoothStatus === "connected" || root.screenContext.bluetoothStatus === "on") ? "#ffffff" : root.theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            }
            Text {
              text: root.screenContext.bluetoothStatus === "connected" ? "Bağlı" : (root.screenContext.bluetoothStatus === "on" ? "Açık" : "Kapalı")
              color: (root.screenContext.bluetoothStatus === "connected" || root.screenContext.bluetoothStatus === "on") ? "#d0ffffff" : root.theme.textSecondary
              font { family: "JetBrains Mono"; pixelSize: 7 }
            }
          }
        }
      }
    }

    // 3. Action Buttons Row (Notifications, Clipboard, Keyboard, Theme, Power)
    Row {
      width: parent.width
      spacing: 10
      height: 40

      // Notifications Button
      Rectangle {
        width: (parent.width - 40) / 5
        height: parent.height
        radius: 8
        color: root.theme.buttonBg

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(["swaync-client", "-t"]);
          }
        }

        Text {
          text: "\uf0f3" // Bell
          color: root.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 15 }
          anchors.centerIn: parent
        }
      }

      // Clipboard Button
      Rectangle {
        width: (parent.width - 40) / 5
        height: parent.height
        radius: 8
        color: root.isSelectingClipboard ? root.theme.accent : root.theme.buttonBg

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.isSelectingClipboard = true;
            clipboardService.refresh();
          }
        }

        Text {
          text: "\uf0ea" // Clipboard
          color: root.isSelectingClipboard ? "#ffffff" : root.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 15 }
          anchors.centerIn: parent
        }
      }

      // Keyboard Layout Button
      Rectangle {
        width: (parent.width - 40) / 5
        height: parent.height
        radius: 8
        color: root.theme.buttonBg

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
          }
        }

        Row {
          anchors.centerIn: parent
          spacing: 3
          Text {
            text: "\uf11c" // Keyboard
            color: root.theme.accent
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: root.screenContext.keyboardLayout
            color: root.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      // Theme Switcher Button
      Rectangle {
        width: (parent.width - 40) / 5
        height: parent.height
        radius: 8
        color: root.theme.buttonBg

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.isSelectingTheme = true;
          }
        }

        Text {
          text: "\uf53f" // Palette icon
          color: root.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 15 }
          anchors.centerIn: parent
        }
      }

      // Power Menu Button
      Rectangle {
        width: (parent.width - 40) / 5
        height: parent.height
        radius: 8
        color: root.theme.buttonBg

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.openPowerMenu();
          }
        }

        Text {
          text: "\uf011" // Power
          color: root.theme.red
          font { family: "FiraCode Nerd Font"; pixelSize: 15 }
          anchors.centerIn: parent
        }
      }
    }

    // 4. Sliders Column (Volume & Brightness - Unified Pill-Sliders)
    Column {
      width: parent.width
      spacing: 8

      // Volume Slider Pill
      Rectangle {
        id: volTrack
        height: 24
        radius: 12
        color: root.theme.buttonBg
        width: parent.width
        clip: true

        Rectangle {
          height: parent.height
          width: parent.width * (root.screenContext.volume / 100.0)
          radius: parent.radius
          color: root.theme.accent
          opacity: 0.85

          Behavior on width {
            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          function updateVol(mouse) {
            var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
            root.screenContext.volume = pct;
            Quickshell.execDetached(["amixer", "sset", "Master", pct + "%"]);
          }
          onPositionChanged: (mouse) => { if (pressed) updateVol(mouse) }
          onPressed: (mouse) => updateVol(mouse)
        }

        // Icon inside the bar
        Text {
          text: root.screenContext.audioMuted ? "\uf026" : (root.screenContext.volume > 50 ? "\uf028" : (root.screenContext.volume > 0 ? "\uf027" : "\uf026"))
          color: "#e0ffffff"
          font { family: "FiraCode Nerd Font"; pixelSize: 11 }
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          enabled: false
        }

        // Percentage text inside the bar
        Text {
          text: root.screenContext.audioMuted ? "Sessiz" : root.screenContext.volume + "%"
          color: "#e0ffffff"
          font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          enabled: false
        }
      }

      // Brightness Slider Pill
      Rectangle {
        id: brightTrack
        height: 24
        radius: 12
        color: root.theme.buttonBg
        width: parent.width
        clip: true

        Rectangle {
          height: parent.height
          width: parent.width * (root.screenContext.brightness / 100.0)
          radius: parent.radius
          color: root.theme.accent
          opacity: 0.85

          Behavior on width {
            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          function updateBright(mouse) {
            var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
            root.screenContext.setBrightness(pct);
          }
          onPositionChanged: (mouse) => { if (pressed) updateBright(mouse) }
          onPressed: (mouse) => updateBright(mouse)
        }

        // Icon inside the bar
        Text {
          text: "\uf185" // Sun
          color: "#e0ffffff"
          font { family: "FiraCode Nerd Font"; pixelSize: 11 }
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          enabled: false
        }

        // Percentage text inside the bar
        Text {
          text: root.screenContext.brightness + "%"
          color: "#e0ffffff"
          font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          enabled: false
        }
      }
    }

    // Faint Separator Line
    Rectangle {
      width: parent.width
      height: 1
      color: "#15ffffff"
    }

    // 5. HUD Media Player Widget (Borderless Integrated layout)
    Item {
      width: parent.width
      height: 40

      // Track Info (Left)
      Column {
        width: parent.width - 100
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
          text: root.screenContext.mediaTitle !== "" ? root.screenContext.mediaTitle : "Medya Çalmıyor"
          color: root.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
          elide: Text.ElideRight
          width: parent.width
        }
        Text {
          text: root.screenContext.mediaArtist !== "" ? root.screenContext.mediaArtist : "Sanatçı Yok"
          color: root.theme.textSecondary
          font { family: "JetBrains Mono"; pixelSize: 8 }
          elide: Text.ElideRight
          width: parent.width
        }
      }

      // Media Buttons Row (Right)
      Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: 16

        // Prev
        Text {
          text: "\uf048" // Prev
          color: root.theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 11 }
          anchors.verticalCenter: parent.verticalCenter
          
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["playerctl", "previous"])
          }
        }

        // Play/Pause
        Text {
          text: root.screenContext.mediaStatus === "Playing" ? "\uf04c" : "\uf04b" // Pause / Play
          color: root.theme.accent
          font { family: "FiraCode Nerd Font"; pixelSize: 13 }
          anchors.verticalCenter: parent.verticalCenter
          
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Quickshell.execDetached(["playerctl", "play-pause"]);
              root.screenContext.mediaStatus = (root.screenContext.mediaStatus === "Playing") ? "Paused" : "Playing";
            }
          }
        }

        // Next
        Text {
          text: "\uf051" // Next
          color: root.theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 11 }
          anchors.verticalCenter: parent.verticalCenter
          
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["playerctl", "next"])
          }
        }
      }
    }
  }

  // 2. Theme Selection Panel (Modular component)
  ControlCenterThemeList {
    id: themeContent
    theme: root.theme
    themeModel: root.themeModel
    visible: opacity > 0.01
    opacity: (root.isOpen && root.isSelectingTheme && !root.isSelectingNetwork && !root.isSelectingClipboard && !root.isSelectingBluetooth) ? 1.0 : 0.0
    anchors.centerIn: parent

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    onBackClicked: {
      root.isSelectingTheme = false;
    }
    onThemeSelected: (themeId) => {
      root.themeSelected(themeId);
    }
  }

  // 3. Wi-Fi Connections List Panel (Modular component)
  ControlCenterWifiList {
    id: networkContent
    theme: root.theme
    visible: opacity > 0.01
    opacity: (root.isOpen && root.isSelectingNetwork && !root.isEnteringPassword && !root.isSelectingClipboard && !root.isSelectingBluetooth) ? 1.0 : 0.0
    anchors.centerIn: parent

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    onBackClicked: {
      root.isSelectingNetwork = false;
    }
    onConnectPasswordRequested: (ssid) => {
      root.selectedSsid = ssid;
      passwordContent.clearInput();
      passwordContent.inputFocus = true;
    }
  }

  // 4. Wi-Fi Password Input Panel (Modular component)
  ControlCenterWifiPassword {
    id: passwordContent
    theme: root.theme
    ssid: root.selectedSsid
    visible: opacity > 0.01
    opacity: (root.isOpen && root.isSelectingNetwork && root.isEnteringPassword && !root.isSelectingClipboard && !root.isSelectingBluetooth) ? 1.0 : 0.0
    anchors.centerIn: parent

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    onBackClicked: {
      root.selectedSsid = "";
    }
  }

  // 5. Clipboard History Panel (Modular component)
  ControlCenterClipboard {
    id: clipboardContent
    theme: root.theme
    visible: opacity > 0.01
    opacity: (root.isOpen && root.isSelectingClipboard && !root.isSelectingBluetooth) ? 1.0 : 0.0
    anchors.centerIn: parent

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    onBackClicked: {
      root.isSelectingClipboard = false;
    }
  }

  // 6. Bluetooth Devices Panel (Modular component)
  ControlCenterBluetooth {
    id: bluetoothContent
    theme: root.theme
    screenContext: root.screenContext
    visible: opacity > 0.01
    opacity: (root.isOpen && root.isSelectingBluetooth) ? 1.0 : 0.0
    anchors.centerIn: parent

    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }

    onBackClicked: {
      root.isSelectingBluetooth = false;
    }
  }
}

