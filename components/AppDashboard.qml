import Quickshell
import QtQuick

Rectangle {
  id: dashboardCard
  width: 900
  height: 650
  radius: 24
  
  property bool isOpen: false
  required property var theme
  signal closeRequested()
  
  // Scale and opacity transitions
  scale: isOpen ? 1.0 : 0.95
  opacity: isOpen ? 1.0 : 0.0
  visible: opacity > 0.001
  
  Behavior on scale {
    NumberAnimation { duration: 250; easing.type: Easing.OutBack }
  }
  Behavior on opacity {
    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
  }
  
  color: theme.bg
  border.color: theme.border
  border.width: 1
  clip: true
  
  // Tab/category variables
  readonly property var categoriesList: ["Tümü", "Geliştirme", "İnternet", "Grafik", "Multimedya", "Oyunlar", "Ofis", "Sistem", "Ayarlar", "Araçlar", "Diğer"]
  property string selectedCategory: "Tümü"
  property int selectedIndex: 0
  
  ListModel {
    id: dashboardModel
  }
  
  function filterDashboardApps() {
    dashboardModel.clear();
    var q = dashboardSearchInput.text.trim().toLowerCase();
    for (var i = 0; i < appLauncherService.appList.length; i++) {
      var app = appLauncherService.appList[i];
      if (selectedCategory !== "Tümü" && app.category !== selectedCategory) {
        continue;
      }
      if (q !== "") {
        var nameMatch = app.name.toLowerCase().indexOf(q) !== -1;
        var keyMatch = app.search_keys && app.search_keys.toLowerCase().indexOf(q) !== -1;
        if (!nameMatch && !keyMatch) {
          continue;
        }
      }
      dashboardModel.append(app);
    }
    // Cap selectedIndex
    if (selectedIndex >= dashboardModel.count) {
      selectedIndex = Math.max(0, dashboardModel.count - 1);
    }
  }
  
  onSelectedCategoryChanged: {
    selectedIndex = 0;
    filterDashboardApps();
  }
  
  onIsOpenChanged: {
    if (isOpen) {
      selectedCategory = "Tümü";
      dashboardSearchInput.text = "";
      selectedIndex = 0;
      filterDashboardApps();
      dashboardSearchInput.forceActiveFocus();
    }
  }
  
  // Keyboard management
  focus: isOpen
  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_Escape) {
      closeRequested();
      event.accepted = true;
      return;
    }
    
    // Grid columns (5 columns fit in 640px width with 120px cell width)
    var cols = 5; 
    
    if (event.key === Qt.Key_Right) {
      if (dashboardModel.count > 0) {
        selectedIndex = (selectedIndex + 1) % dashboardModel.count;
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Left) {
      if (dashboardModel.count > 0) {
        selectedIndex = (selectedIndex - 1 + dashboardModel.count) % dashboardModel.count;
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      if (dashboardModel.count > 0) {
        if (selectedIndex + cols < dashboardModel.count) {
          selectedIndex += cols;
        } else {
          // Wrap around or cap to bottom row same column
          var bottomRowTarget = selectedIndex % cols;
          if (bottomRowTarget < dashboardModel.count) {
            selectedIndex = bottomRowTarget;
          }
        }
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      if (dashboardModel.count > 0) {
        if (selectedIndex - cols >= 0) {
          selectedIndex -= cols;
        } else {
          // Go to last row same column if possible
          var rem = dashboardModel.count % cols;
          var lastRowIndex = dashboardModel.count - (rem === 0 ? cols : rem) + (selectedIndex % cols);
          if (lastRowIndex >= dashboardModel.count) lastRowIndex -= cols;
          selectedIndex = Math.max(0, lastRowIndex);
        }
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Return) {
      if (dashboardModel.count > 0 && selectedIndex >= 0 && selectedIndex < dashboardModel.count) {
        var item = dashboardModel.get(selectedIndex);
        if (item.desktop_path) {
          Quickshell.execDetached([ "/home/excalibur/WorkSpace/projects/OgsShell-qs/services/app_launcher_helper", "--launch", item.desktop_path ]);
        }
        Quickshell.execDetached(item.exec.split(" "));
        closeRequested();
      }
      event.accepted = true;
    } else if (event.key === Qt.Key_Tab) {
      // Tab cycles through categories
      var idx = categoriesList.indexOf(selectedCategory);
      selectedCategory = categoriesList[(idx + 1) % categoriesList.length];
      event.accepted = true;
    } else if (event.key === Qt.Key_Backtab) {
      var idx = categoriesList.indexOf(selectedCategory);
      selectedCategory = categoriesList[(idx - 1 + categoriesList.length) % categoriesList.length];
      event.accepted = true;
    }
  }

  Row {
    anchors.fill: parent

    // 1. LEFT SIDEBAR: Categories list
    Rectangle {
      width: 220
      height: parent.height
      color: theme.buttonBg // slightly lighter background than main card
      opacity: 0.85
      
      Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Sidebar Title
        Text {
          text: "Kategoriler"
          color: theme.accent
          font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Bold }
        }

        // List of categories (Dikey Tab Bar)
        Column {
          width: parent.width
          spacing: 6

          Repeater {
            model: dashboardCard.categoriesList
            
            delegate: Rectangle {
              width: parent.width
              height: 36
              radius: 10
              color: dashboardCard.selectedCategory === modelData ? theme.accent : "transparent"
              opacity: dashboardCard.selectedCategory === modelData ? 1.0 : (catMouseArea.containsMouse ? 0.8 : 0.6)

              Text {
                text: modelData
                color: dashboardCard.selectedCategory === modelData ? theme.bg : theme.textPrimary
                font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
              }

              MouseArea {
                id: catMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  dashboardCard.selectedCategory = modelData;
                }
              }
            }
          }
        }
      }
    }

    // Vertical separator
    Rectangle {
      width: 1
      height: parent.height
      color: theme.border
    }

    // 2. RIGHT CONTENT: App grid
    Column {
      width: parent.width - 221
      height: parent.height
      spacing: 16
      padding: 24

      // Top Row: Title & Search bar
      Row {
        width: parent.width - 48
        spacing: 24

        Text {
          text: "Uygulama Kütüphanesi"
          color: theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 18; weight: Font.Bold }
          anchors.verticalCenter: parent.verticalCenter
        }

        // Search Input Pill
        Rectangle {
          width: 300
          height: 36
          radius: 18
          color: theme.buttonBg
          border.color: dashboardSearchInput.activeFocus ? theme.accent : "transparent"
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // Search Icon/Indicator
            Text {
              text: ""
              color: theme.textSecondary
              font { family: "JetBrains Mono"; pixelSize: 12 }
              anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
              id: dashboardSearchInput
              width: parent.width - 24
              color: theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 10 }
              anchors.verticalCenter: parent.verticalCenter
              verticalAlignment: TextInput.AlignVCenter
              selectByMouse: true
              
              onTextChanged: dashboardCard.filterDashboardApps()

              Text {
                text: "Uygulama ara..."
                color: theme.textSecondary
                font: parent.font
                visible: parent.text === ""
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }
      }

      // Main Grid area
      GridView {
        id: appGrid
        width: parent.width - 48
        height: parent.height - 100
        cellWidth: 124
        cellHeight: 120
        clip: true
        model: dashboardModel
        
        delegate: Rectangle {
          width: 114
          height: 110
          radius: 16
          color: index === dashboardCard.selectedIndex ? theme.accent : (delegateMouse.containsMouse ? theme.buttonBg : "transparent")
          opacity: index === dashboardCard.selectedIndex ? 1.0 : (delegateMouse.containsMouse ? 0.9 : 0.8)

          Behavior on color {
            ColorAnimation { duration: 100 }
          }

          Column {
            anchors.centerIn: parent
            spacing: 8
            width: parent.width - 16

            // Icon
            Item {
              width: 48
              height: 48
              anchors.horizontalCenter: parent.horizontalCenter

              Image {
                anchors.fill: parent
                source: model.icon ? "file://" + model.icon : ""
                visible: model.icon !== ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 128
                sourceSize.height: 128
                mipmap: true
                smooth: true
                cache: true
              }

              // Fallback text icon
              Rectangle {
                anchors.fill: parent
                radius: 12
                color: index === dashboardCard.selectedIndex ? theme.bg : theme.buttonBg
                visible: model.icon === ""
                Text {
                  text: model.name.charAt(0).toUpperCase()
                  color: index === dashboardCard.selectedIndex ? theme.accent : theme.textPrimary
                  font { family: "JetBrains Mono"; pixelSize: 16; weight: Font.Bold }
                  anchors.centerIn: parent
                }
              }
            }

            // Name
            Text {
              text: model.name
              color: index === dashboardCard.selectedIndex ? theme.bg : theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
              anchors.horizontalCenter: parent.horizontalCenter
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              width: parent.width
              wrapMode: Text.Wrap
              maximumLineCount: 2
            }
          }

          MouseArea {
            id: delegateMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: dashboardCard.selectedIndex = index
            onClicked: {
              if (model.desktop_path) {
                Quickshell.execDetached([ "/home/excalibur/WorkSpace/projects/OgsShell-qs/services/app_launcher_helper", "--launch", model.desktop_path ]);
              }
              Quickshell.execDetached(model.exec.split(" "));
              dashboardCard.closeRequested();
            }
          }
        }
      }
    }
  }
}
