import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property int activeTab: 0 // 0: Themes, 1: Wallpapers

  Component.onCompleted: {
    if (ipc) {
      ipc.requestThemeState()
      ipc.requestAvailableThemes()
      ipc.requestThemeWallpapers(currentActiveThemeId)
    }
  }

  onCurrentActiveThemeIdChanged: {
    if (ipc) {
      ipc.requestThemeWallpapers(currentActiveThemeId)
    }
  }

  // Fallback 6 shared preset themes list matching shared/themes/themes.json
  readonly property var fallbackThemes: [
    {
      "id": "nord",
      "name": "Nord",
      "author": "Arctic Ice Studio",
      "colors": { "bg": "#2e3440", "surface": "#3b4252", "card_bg": "#3b4252", "fg": "#eceff4", "accent": "#88c0d0", "border": "#88c0d0", "cyan": "#88c0d0" }
    },
    {
      "id": "catppuccin",
      "name": "Catppuccin Macchiato",
      "author": "Catppuccin Org",
      "colors": { "bg": "#24273a", "surface": "#363a4f", "card_bg": "#363a4f", "fg": "#cad3f5", "accent": "#c6a0f6", "border": "#c6a0f6", "cyan": "#8aadf4" }
    },
    {
      "id": "everforest",
      "name": "Everforest Dark",
      "author": "sainnhe",
      "colors": { "bg": "#2d353b", "surface": "#343f44", "card_bg": "#343f44", "fg": "#d3c6aa", "accent": "#a7c080", "border": "#a7c080", "cyan": "#83c092" }
    },
    {
      "id": "tokyonight",
      "name": "Tokyo Night",
      "author": "folke",
      "colors": { "bg": "#1a1b26", "surface": "#24283b", "card_bg": "#24283b", "fg": "#c0caf5", "accent": "#7aa2f7", "border": "#7aa2f7", "cyan": "#7dcfff" }
    },
    {
      "id": "gruvbox",
      "name": "Gruvbox Dark",
      "author": "morhetz",
      "colors": { "bg": "#282828", "surface": "#3c3836", "card_bg": "#3c3836", "fg": "#ebdbb2", "accent": "#fe8019", "border": "#fe8019", "cyan": "#689d6a" }
    },
    {
      "id": "monochrome",
      "name": "Monochrome Minimal",
      "author": "ogsShell",
      "colors": { "bg": "#121212", "surface": "#1e1e1e", "card_bg": "#1e1e1e", "fg": "#f0f0f0", "accent": "#e0e0e0", "border": "#e0e0e0", "cyan": "#ffffff" }
    }
  ]

  readonly property var activeThemesList: (ipc && ipc.availableThemes && ipc.availableThemes.length > 0) ? ipc.availableThemes : fallbackThemes
  readonly property string currentActiveThemeId: (ipc && ipc.currentTheme && ipc.currentTheme.id) ? ipc.currentTheme.id : "everforest"
  readonly property string currentActiveThemeName: (ipc && ipc.currentTheme && ipc.currentTheme.name) ? ipc.currentTheme.name : "Everforest Dark"
  readonly property var activeWallpapersList: (ipc && ipc.themeWallpapers) ? ipc.themeWallpapers : []
  readonly property string activeWallpaperPath: (ipc && ipc.activeWallpaper) ? ipc.activeWallpaper : ""

  function getBaseFileName(path) {
    if (!path) return ""
    let parts = path.split("/")
    return parts[parts.length - 1]
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 6

    // =========================================================================
    // 1. Header Bar: Navigation, Title & Active Theme Pill
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: backHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant
        border.color: backHover.containsMouse ? Style.borderHover : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "‹"
          font.pixelSize: 16
          font.weight: Font.Bold
          color: Style.textPrimary
        }

        MouseArea {
          id: backHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.backRequested()
        }
      }

      // Title & Subtitle Stack
      Column {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: root.activeTab === 0 ? "Tema Galerisi" : "Duvar Kağıtları"
          color: Style.textPrimary
          font.pixelSize: 13
          font.weight: Font.Bold
        }

        Text {
          text: root.activeTab === 0 ? "Sistem ve uygulama renk temaları" : (root.currentActiveThemeName + " havuzu")
          color: Style.textMuted
          font.pixelSize: 10
        }
      }

      // Active Theme Chip
      Rectangle {
        height: 24
        radius: 12
        color: Style.surfaceHover
        border.color: Style.accentCyan
        border.width: 1
        implicitWidth: activeChipRow.implicitWidth + 16

        Row {
          id: activeChipRow
          anchors.centerIn: parent
          spacing: 6

          Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Style.accentCyan
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: root.currentActiveThemeName
            color: Style.textPrimary
            font.pixelSize: 10
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }

    // =========================================================================
    // 2. Segmented Tab Switcher (Temalar vs Duvar Kağıtları)
    // =========================================================================
    Rectangle {
      Layout.fillWidth: true
      height: 30
      radius: 8
      color: Style.surfaceVariant
      border.color: Style.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 4

        // Tab 0: Temalar
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: root.activeTab === 0 ? Style.surfaceActive : (tab0Hover.containsMouse ? Style.surfaceHover : "transparent")
          border.color: root.activeTab === 0 ? Style.accentCyan : "transparent"
          border.width: root.activeTab === 0 ? 1 : 0

          Behavior on color { ColorAnimation { duration: 150 } }

          Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
              text: "🎨"
              font.pixelSize: 12
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: "Temalar"
              color: root.activeTab === 0 ? Style.textPrimary : Style.textMuted
              font.pixelSize: 11
              font.weight: root.activeTab === 0 ? Font.Bold : Font.Medium
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: tab0Hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activeTab = 0
          }
        }

        // Tab 1: Duvar Kağıtları
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: root.activeTab === 1 ? Style.surfaceActive : (tab1Hover.containsMouse ? Style.surfaceHover : "transparent")
          border.color: root.activeTab === 1 ? Style.accentCyan : "transparent"
          border.width: root.activeTab === 1 ? 1 : 0

          Behavior on color { ColorAnimation { duration: 150 } }

          Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
              text: "🖼️"
              font.pixelSize: 12
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: "Duvar Kağıtları"
              color: root.activeTab === 1 ? Style.textPrimary : Style.textMuted
              font.pixelSize: 11
              font.weight: root.activeTab === 1 ? Font.Bold : Font.Medium
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: tab1Hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.activeTab = 1
              if (ipc) {
                ipc.requestThemeWallpapers(root.currentActiveThemeId)
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. TAB 0 CONTENT: 2-Column Responsive Theme Cards Grid
    // =========================================================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.activeTab === 0
      radius: 10
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      GridView {
        id: themesGrid
        anchors.fill: parent
        anchors.margins: 6
        cellWidth: Math.floor(themesGrid.width / 2)
        cellHeight: 90
        boundsBehavior: Flickable.StopAtBounds

        model: root.activeThemesList

        delegate: Item {
          width: themesGrid.cellWidth
          height: themesGrid.cellHeight

          readonly property var themeItem: modelData
          readonly property var themeColors: themeItem.colors || ({})
          readonly property bool isActive: root.currentActiveThemeId === themeItem.id

          readonly property color thmBg: themeColors.bg ? themeColors.bg : "#1e1e2e"
          readonly property color thmSurface: themeColors.surface ? themeColors.surface : (themeColors.card_bg ? themeColors.card_bg : "#313244")
          readonly property color thmFg: themeColors.fg ? themeColors.fg : "#cdd6f4"
          readonly property color thmAccent: themeColors.accent ? themeColors.accent : "#89b4fa"
          readonly property color thmCyan: themeColors.cyan ? themeColors.cyan : thmAccent

          Rectangle {
            id: cardRect
            anchors.fill: parent
            anchors.margins: 3
            radius: 8
            color: isActive ? Style.surfaceActive : (cardMouseArea.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
            border.color: isActive ? Style.accentCyan : (cardMouseArea.containsMouse ? Style.borderHover : Style.border)
            border.width: isActive ? 1.5 : 1

            scale: cardMouseArea.containsMouse ? 1.015 : 1.0

            Behavior on scale {
              NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
              anchors.fill: parent
              anchors.margins: 6
              spacing: 8

              // Mini Window Mockup
              Rectangle {
                Layout.preferredWidth: 64
                Layout.fillHeight: true
                radius: 6
                color: thmBg
                border.color: thmAccent
                border.width: 1
                clip: true

                Column {
                  anchors.fill: parent
                  anchors.margins: 3
                  spacing: 3

                  // Mockup Window Header
                  Row {
                    width: parent.width
                    spacing: 2
                    Rectangle { width: 4; height: 4; radius: 2; color: "#ff5f56" }
                    Rectangle { width: 4; height: 4; radius: 2; color: "#ffbd2e" }
                    Rectangle { width: 4; height: 4; radius: 2; color: "#27c93f" }
                  }

                  // Mockup Content Cards
                  Rectangle {
                    width: parent.width
                    height: 12
                    radius: 3
                    color: thmSurface
                    Rectangle {
                      anchors.left: parent.left
                      anchors.leftMargin: 3
                      anchors.verticalCenter: parent.verticalCenter
                      width: 14
                      height: 3
                      radius: 1.5
                      color: thmAccent
                    }
                  }

                  Rectangle {
                    width: parent.width
                    height: 16
                    radius: 3
                    color: thmSurface
                    Row {
                      anchors.centerIn: parent
                      spacing: 3
                      Rectangle { width: 6; height: 6; radius: 3; color: thmCyan }
                      Rectangle { width: 18; height: 3; radius: 1.5; color: thmFg; opacity: 0.8 }
                    }
                  }
                }
              }

              // Theme Info & Color Swatches
              ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 4

                  Text {
                    text: themeItem.name || themeItem.id
                    color: Style.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Rectangle {
                    visible: isActive
                    width: 14
                    height: 14
                    radius: 7
                    color: Style.accentCyan

                    Text {
                      anchors.centerIn: parent
                      text: "✓"
                      color: "#000000"
                      font.pixelSize: 9
                      font.weight: Font.Bold
                    }
                  }
                }

                Text {
                  text: themeItem.author ? ("by " + themeItem.author) : "ogsShell"
                  color: Style.textMuted
                  font.pixelSize: 10
                  elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                // Color Swatches
                Row {
                  spacing: 4
                  Layout.topMargin: 2
                  Rectangle { width: 10; height: 10; radius: 5; color: thmBg; border.color: "#ffffff"; border.width: 0.6 }
                  Rectangle { width: 10; height: 10; radius: 5; color: thmSurface }
                  Rectangle { width: 10; height: 10; radius: 5; color: thmAccent }
                  Rectangle { width: 10; height: 10; radius: 5; color: thmCyan }
                }
              }
            }

            MouseArea {
              id: cardMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (ipc) {
                  ipc.setActiveTheme(themeItem.id)
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 4. TAB 1 CONTENT: Active Theme Wallpaper Gallery
    // =========================================================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.activeTab === 1
      radius: 10
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Sub-Header: Action Bar (Next Wallpaper button & Counter)
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: root.activeWallpapersList.length + " Duvar Kağıdı Bulundu"
            color: Style.textMuted
            font.pixelSize: 10
            Layout.fillWidth: true
          }

          // Next Wallpaper Quick Button
          Rectangle {
            height: 24
            radius: 6
            color: nextHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant
            border.color: nextHover.containsMouse ? Style.accentCyan : Style.border
            border.width: 1
            implicitWidth: nextBtnRow.implicitWidth + 14

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
              id: nextBtnRow
              anchors.centerIn: parent
              spacing: 5

              Text {
                text: "🎲"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: "Sıradaki Görsel"
                color: Style.textPrimary
                font.pixelSize: 10
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              id: nextHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (ipc) {
                  ipc.nextWallpaper(root.currentActiveThemeId)
                }
              }
            }
          }
        }

        // Empty State Handler
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: root.activeWallpapersList.length === 0

          Column {
            anchors.centerIn: parent
            spacing: 6
            width: Math.min(260, parent.width - 20)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "🖼️"
              font.pixelSize: 32
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Bu tema için görsel bulunamadı"
              color: Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.Bold
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "~/Pictures/Wallpapers/" + root.currentActiveThemeName.split(" ")[0] + "/ klasörüne resim ekleyebilirsiniz."
              color: Style.textMuted
              font.pixelSize: 10
              wrapMode: Text.Wrap
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }
          }
        }

        // 2-Column Responsive Wallpaper Preview Grid
        GridView {
          id: wallpapersGrid
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: root.activeWallpapersList.length > 0
          cellWidth: Math.floor(wallpapersGrid.width / 2)
          cellHeight: Math.floor(wallpapersGrid.cellWidth * 0.62)
          boundsBehavior: Flickable.StopAtBounds
          clip: true

          model: root.activeWallpapersList

          delegate: Item {
            width: wallpapersGrid.cellWidth
            height: wallpapersGrid.cellHeight

            readonly property string wallpaperPath: modelData
            readonly property bool isCurrentActive: root.activeWallpaperPath === wallpaperPath
            readonly property string fileName: root.getBaseFileName(wallpaperPath)

            Rectangle {
              id: wpCardRect
              anchors.fill: parent
              anchors.margins: 4
              radius: 8
              color: Style.surfaceVariant
              border.color: isCurrentActive ? Style.accentCyan : (wpMouseArea.containsMouse ? Style.borderHover : Style.border)
              border.width: isCurrentActive ? 2 : 1
              clip: true

              scale: wpMouseArea.containsMouse ? 1.02 : 1.0

              Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
              }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              // Asynchronous Image Preview
              Image {
                anchors.fill: parent
                source: "file://" + wallpaperPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 320
                sourceSize.height: 180
                smooth: true
              }

              // Subtle bottom gradient bar with filename
              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 24
                color: "#cc11111b"

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 6
                  anchors.right: parent.right
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  text: fileName
                  color: Style.textPrimary
                  font.pixelSize: 10
                  font.weight: Font.DemiBold
                  elide: Text.ElideMiddle
                }
              }

              // Active Badge
              Rectangle {
                visible: isCurrentActive
                anchors.top: parent.top
                anchors.topMargin: 5
                anchors.right: parent.right
                anchors.rightMargin: 5
                height: 16
                radius: 8
                color: "#e611111b"
                border.color: Style.accentCyan
                border.width: 1
                implicitWidth: activeBadgeRow.implicitWidth + 10

                Row {
                  id: activeBadgeRow
                  anchors.centerIn: parent
                  spacing: 3

                  Rectangle {
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Style.accentCyan
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: "Aktif ✓"
                    color: Style.textPrimary
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }

              // Click Handler
              MouseArea {
                id: wpMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) {
                    ipc.setWallpaper(root.currentActiveThemeId, wallpaperPath)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
