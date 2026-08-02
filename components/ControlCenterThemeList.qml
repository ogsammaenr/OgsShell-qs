import QtQuick

Column {
  id: themeContent
  width: 332
  height: 362
  spacing: 12

  required property var theme
  required property var themeModel
  signal backClicked()
  signal themeSelected(string themeId)

  property int currentTab: 0 // 0: Themes, 1: Wallpapers

  // Header Row (Back Button + Title + Refresh)
  Item {
    width: parent.width
    height: 24

    Row {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      Text {
        text: "\uf060" // Back arrow
        color: theme.textPrimary
        font { family: "FiraCode Nerd Font"; pixelSize: 14 }
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: themeContent.backClicked()
        }
      }

      Text {
        text: "Görünüm & Duvar Kağıdı"
        color: theme.textPrimary
        font { family: "JetBrains Mono"; pixelSize: 13; weight: Font.Bold }
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // Refresh icon button
    Item {
      width: 24
      height: 24
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right

      Text {
        text: "\uf021" // Refresh icon
        color: theme.textSecondary
        font { family: "FiraCode Nerd Font"; pixelSize: 12 }
        anchors.centerIn: parent
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (currentTab === 0 && typeof themeConfigService !== "undefined") {
            themeConfigService.reloadThemes();
          } else if (currentTab === 1 && typeof wallpaperService !== "undefined") {
            wallpaperService.refresh();
          }
        }
      }
    }
  }

  // Segmented Tab Switch (Temalar / Duvar Kağıtları)
  Rectangle {
    width: parent.width
    height: 30
    radius: 8
    color: theme.buttonBg

    Row {
      anchors.fill: parent
      anchors.margins: 2

      // Tab 0: Temalar
      Rectangle {
        width: parent.width / 2
        height: parent.height
        radius: 6
        color: currentTab === 0 ? theme.accent : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        Row {
          anchors.centerIn: parent
          spacing: 6

          Text {
            text: "\uf53f" // Palette
            color: currentTab === 0 ? theme.textOnAccent : theme.textSecondary
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: "Temalar"
            color: currentTab === 0 ? theme.textOnAccent : theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: currentTab = 0
        }
      }

      // Tab 1: Duvar Kağıtları
      Rectangle {
        width: parent.width / 2
        height: parent.height
        radius: 6
        color: currentTab === 1 ? theme.accent : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        Row {
          anchors.centerIn: parent
          spacing: 6

          Text {
            text: "\uf03e" // Image icon
            color: currentTab === 1 ? theme.textOnAccent : theme.textSecondary
            font { family: "FiraCode Nerd Font"; pixelSize: 11 }
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: "Duvar Kağıdı"
            color: currentTab === 1 ? theme.textOnAccent : theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: currentTab = 1
        }
      }
    }
  }

  // Main Content Area
  Item {
    width: parent.width
    height: 284
    clip: true

    // TAB 0: THEMES GRID
    Item {
      anchors.fill: parent
      visible: currentTab === 0

      Flickable {
        id: themeFlickable
        anchors.fill: parent
        contentHeight: themeGrid.height
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
          id: themeGrid
          columns: 2
          spacing: 12
          width: parent.width - 8

          Repeater {
            model: themeContent.themeModel
            delegate: Rectangle {
              width: 154
              height: 84
              radius: 10
              color: modelData.bg
              border.color: (theme.currentTheme === modelData.id) ? modelData.accent : modelData.border
              border.width: (theme.currentTheme === modelData.id) ? 2.5 : 1
              clip: true

              scale: previewMouse.containsMouse ? 1.03 : 1.0
              Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

              // Mini Top-Bar Mockup
              Rectangle {
                id: miniBar
                width: parent.width - 16
                height: 16
                radius: 4
                color: "transparent"
                border.color: modelData.border
                border.width: 1
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: 4
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2
                  Rectangle { width: 6; height: 2; radius: 1; color: modelData.accent }
                  Rectangle { width: 2.5; height: 2; radius: 1; color: modelData.workspaces[1] }
                  Rectangle { width: 2.5; height: 2; radius: 1; color: modelData.workspaces[2] }
                }

                Rectangle {
                  width: 28
                  height: 8
                  radius: 4
                  color: modelData.bg
                  border.color: modelData.border
                  border.width: 0.5
                  anchors.centerIn: parent
                }

                Row {
                  anchors.right: parent.right
                  anchors.rightMargin: 4
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2
                  Rectangle { width: 2.5; height: 2.5; radius: 1.25; color: modelData.accent }
                  Rectangle { width: 2.5; height: 2.5; radius: 1.25; color: (modelData.textPrimary || modelData.text || "#ffffff") }
                }
              }

              // Theme Name
              Text {
                text: modelData.name
                color: (modelData.textPrimary || modelData.text || "#ffffff")
                font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
                anchors.top: miniBar.bottom
                anchors.topMargin: 7
                anchors.horizontalCenter: parent.horizontalCenter
              }

              // Active Indicator
              Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Rectangle {
                  width: 5
                  height: 5
                  radius: 2.5
                  color: modelData.accent
                }

                Text {
                  text: "\uf00c"
                  color: modelData.accent
                  font { family: "FiraCode Nerd Font"; pixelSize: 8; weight: Font.Bold }
                  visible: (theme.currentTheme === modelData.id)
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: previewMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  themeContent.themeSelected(modelData.id);
                }
              }
            }
          }
        }

        // Sleek Scrollbar
        Rectangle {
          anchors.right: parent.right
          width: 3
          radius: 1.5
          color: theme.accent
          opacity: themeFlickable.moving || themeFlickable.flicking ? 0.6 : 0.2
          visible: themeFlickable.contentHeight > themeFlickable.height
          y: themeFlickable.visibleArea.yPosition * themeFlickable.height
          height: Math.max(20, themeFlickable.visibleArea.heightRatio * themeFlickable.height)
          Behavior on opacity { NumberAnimation { duration: 150 } }
        }
      }
    }

    // TAB 1: WALLPAPER PICKER GRID
    Item {
      anchors.fill: parent
      visible: currentTab === 1

      Column {
        anchors.fill: parent
        spacing: 8

        // Subheader showing Theme Name & Image Count
        Item {
          width: parent.width
          height: 16

          Text {
            text: (theme.currentTheme.charAt(0).toUpperCase() + theme.currentTheme.slice(1)) + " Duvar Kağıtları"
            color: theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: (typeof wallpaperService !== "undefined" ? wallpaperService.wallpaperList.length : 0) + " Görsel"
            color: theme.accent
            font { family: "JetBrains Mono"; pixelSize: 9; weight: Font.Bold }
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Empty state / Loading
        Item {
          width: parent.width
          height: 260
          visible: (typeof wallpaperService === "undefined" || wallpaperService.isLoading || wallpaperService.wallpaperList.length === 0)

          Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
              text: (typeof wallpaperService !== "undefined" && wallpaperService.isLoading) ? "\uf110" : "\uf03e"
              color: theme.accent
              font { family: "FiraCode Nerd Font"; pixelSize: 24 }
              anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
              text: (typeof wallpaperService !== "undefined" && wallpaperService.isLoading) ? "Taranıyor..." : "Duvar kağıdı bulunamadı"
              color: theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
              anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
              text: (typeof wallpaperService !== "undefined" && wallpaperService.targetDir !== "") ? wallpaperService.targetDir : "~/Pictures/Wallpapers"
              color: theme.textSecondary
              font { family: "JetBrains Mono"; pixelSize: 8 }
              anchors.horizontalCenter: parent.horizontalCenter
              elide: Text.ElideMiddle
              width: 300
            }
          }
        }

        // Wallpaper Grid
        Item {
          width: parent.width
          height: 260
          visible: (typeof wallpaperService !== "undefined" && !wallpaperService.isLoading && wallpaperService.wallpaperList.length > 0)

          Flickable {
            id: wallpaperFlickable
            anchors.fill: parent
            contentHeight: wallpaperGrid.height
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds

            Grid {
              id: wallpaperGrid
              columns: 2
              spacing: 10
              width: parent.width - 8

              Repeater {
                model: (typeof wallpaperService !== "undefined") ? wallpaperService.wallpaperList : []
                delegate: Rectangle {
                  width: 155
                  height: 90
                  radius: 8
                  color: theme.buttonBg
                  clip: true

                  property bool isSelected: (typeof wallpaperService !== "undefined" && wallpaperService.currentWallpaper === modelData.path)

                  border.color: isSelected ? theme.accent : theme.border
                  border.width: isSelected ? 2.5 : 1

                  scale: wallMouse.containsMouse ? 1.03 : 1.0
                  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }

                  // Wallpaper Thumbnail Image
                  Image {
                    anchors.fill: parent
                    source: "file://" + modelData.path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(160, 90)
                  }

                  // Bottom Gradient Text Overlay
                  Rectangle {
                    width: parent.width
                    height: 24
                    anchors.bottom: parent.bottom
                    color: "#c0000000"

                    Text {
                      text: modelData.name
                      color: "#ffffff"
                      font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
                      anchors.left: parent.left
                      anchors.leftMargin: 6
                      anchors.right: parent.right
                      anchors.rightMargin: 6
                      anchors.verticalCenter: parent.verticalCenter
                      elide: Text.ElideRight
                    }
                  }

                  // Selected Checkmark Badge
                  Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: theme.accent
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    visible: isSelected

                    Text {
                      text: "\uf00c"
                      color: theme.textOnAccent
                      font { family: "FiraCode Nerd Font"; pixelSize: 9; weight: Font.Bold }
                      anchors.centerIn: parent
                    }
                  }

                  MouseArea {
                    id: wallMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (typeof wallpaperService !== "undefined") {
                        wallpaperService.setWallpaper(modelData.path);
                      }
                    }
                  }
                }
              }
            }
          }

          // Custom Scrollbar for Wallpapers
          Rectangle {
            anchors.right: parent.right
            width: 3
            radius: 1.5
            color: theme.accent
            opacity: wallpaperFlickable.moving || wallpaperFlickable.flicking ? 0.6 : 0.2
            visible: wallpaperFlickable.contentHeight > wallpaperFlickable.height
            y: wallpaperFlickable.visibleArea.yPosition * wallpaperFlickable.height
            height: Math.max(20, wallpaperFlickable.visibleArea.heightRatio * wallpaperFlickable.height)
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }
      }
    }
  }
}
