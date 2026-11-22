import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property bool showAdapters: false

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

  // Fallback 7 shared preset themes list matching shared/themes/themes.json
  readonly property var fallbackThemes: [
    {
      "id": "nord",
      "name": "Nord",
      "author": "Arctic Ice Studio",
      "colors": { "bg": "#2e3440", "surface": "#3b4252", "card_bg": "#3b4252", "fg": "#eceff4", "accent": "#88c0d0", "border": "#88c0d0", "cyan": "#8fbcbb" }
    },
    {
      "id": "catppuccin",
      "name": "Catppuccin",
      "author": "Catppuccin Org",
      "colors": { "bg": "#24273a", "surface": "#363a4f", "card_bg": "#363a4f", "fg": "#cad3f5", "accent": "#c6a0f6", "border": "#c6a0f6", "cyan": "#8aadf4" }
    },
    {
      "id": "everforest",
      "name": "Everforest",
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
      "name": "Gruvbox",
      "author": "morhetz",
      "colors": { "bg": "#282828", "surface": "#3c3836", "card_bg": "#32302f", "fg": "#ebdbb2", "accent": "#d65d0e", "border": "#d65d0e", "cyan": "#689d6a" }
    },
    {
      "id": "monochrome",
      "name": "Monochrome",
      "author": "ogsShell",
      "colors": { "bg": "#121212", "surface": "#1e1e1e", "card_bg": "#1e1e1e", "fg": "#f0f0f0", "accent": "#e0e0e0", "border": "#e0e0e0", "cyan": "#ffffff" }
    },
    {
      "id": "rosepine",
      "name": "Rosé Pine",
      "author": "mvllow",
      "colors": { "bg": "#191724", "surface": "#1f1d2e", "card_bg": "#1f1d2e", "fg": "#e0def4", "accent": "#ebbcba", "border": "#ebbcba", "cyan": "#9ccfd8" }
    }
  ]

  readonly property var adapterCatalog: [
    { "id": "hyprland", "label": "Hyprland", "icon": "󰖲" },
    { "id": "kitty", "label": "Kitty", "icon": "󰆍" },
    { "id": "zed", "label": "Zed Editor", "icon": "󰨞" },
    { "id": "vesktop", "label": "Vesktop", "icon": "󰙯" },
    { "id": "nvim", "label": "Neovim", "icon": "" },
    { "id": "gtk", "label": "GTK 3/4", "icon": "󰔎" },
    { "id": "qt_dolphin", "label": "Qt / Dolphin", "icon": "󰉋" },
    { "id": "tmux", "label": "Tmux", "icon": "" },
    { "id": "starship", "label": "Starship", "icon": "󱓞" },
    { "id": "btop", "label": "Btop", "icon": "󰄪" },
    { "id": "intellij", "label": "IntelliJ", "icon": "󰬷" },
    { "id": "android_studio", "label": "Android Studio", "icon": "󰀲" }
  ]

  readonly property var activeThemesList: (ipc && ipc.availableThemes && ipc.availableThemes.length > 0) ? ipc.availableThemes : fallbackThemes
  readonly property string currentActiveThemeId: (ipc && ipc.currentTheme && ipc.currentTheme.id) ? ipc.currentTheme.id : (Style.activeThemeId || "everforest")
  readonly property string currentActiveThemeName: (ipc && ipc.currentTheme && ipc.currentTheme.name) ? ipc.currentTheme.name : (Style.activeThemeName || "Everforest Dark")
  readonly property var activeWallpapersList: (ipc && ipc.themeWallpapers) ? ipc.themeWallpapers : []
  readonly property string activeWallpaperPath: (ipc && ipc.activeWallpaper) ? ipc.activeWallpaper : ""
  readonly property var enabledAdaptersMap: (ipc && ipc.enabledThemeAdapters) ? ipc.enabledThemeAdapters : ({})

  readonly property var currentThemeObj: {
    for (let i = 0; i < activeThemesList.length; i++) {
      if (activeThemesList[i].id === currentActiveThemeId) return activeThemesList[i]
    }
    return activeThemesList.length > 0 ? activeThemesList[0] : fallbackThemes[2]
  }

  readonly property var activePaletteColors: {
    let c = (currentThemeObj && currentThemeObj.colors) ? currentThemeObj.colors : ({})
    return {
      "bg": c.bg || Style.appBackground,
      "surface": c.surface || c.card_bg || Style.appCard,
      "fg": c.fg || Style.textPrimary,
      "accent": c.accent || Style.accent,
      "cyan": c.cyan || Style.accentCyan
    }
  }

  function shortThemeName(rawName) {
    if (!rawName) return ""
    if (rawName.indexOf("Catppuccin") !== -1) return "Catppuccin"
    if (rawName.indexOf("Everforest") !== -1) return "Everforest"
    if (rawName.indexOf("Monochrome") !== -1) return "Monochrome"
    if (rawName.indexOf("Gruvbox") !== -1) return "Gruvbox"
    return rawName
  }

  function getBaseFileName(path) {
    if (!path) return ""
    let parts = path.split("/")
    return parts[parts.length - 1]
  }

  function isAdapterEnabled(adapterId) {
    if (!enabledAdaptersMap || enabledAdaptersMap[adapterId] === undefined) return true
    return !!enabledAdaptersMap[adapterId]
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 10

    // =========================================================================
    // 1. Unified Apple HIG Header
    // =========================================================================
    CCViewHeader {
      title: root.showAdapters ? "Uygulama Adaptörleri" : "Görünüm"
      subtitle: root.showAdapters
        ? "Otomatik tema senkronizasyonu"
        : (root.activeWallpapersList.length > 0
            ? (root.currentActiveThemeName + " · " + root.activeWallpapersList.length + " duvar kağıdı")
            : root.currentActiveThemeName)
      onBackRequested: {
        if (root.showAdapters) root.showAdapters = false
        else root.backRequested()
      }

      // Active Theme Compact Palette Capsule
      Rectangle {
        visible: !root.showAdapters
        Layout.preferredHeight: 24
        Layout.preferredWidth: hdrSwatchRow.implicitWidth + 14
        radius: 12
        color: Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Row {
          id: hdrSwatchRow
          anchors.centerIn: parent
          spacing: 4

          Repeater {
            model: [
              root.activePaletteColors.bg,
              root.activePaletteColors.surface,
              root.activePaletteColors.accent,
              root.activePaletteColors.cyan,
              root.activePaletteColors.fg
            ]

            Rectangle {
              width: 7
              height: 7
              radius: 3.5
              color: modelData
              border.color: Qt.rgba(1, 1, 1, 0.18)
              border.width: 0.5
            }
          }
        }
      }

      // Next Wallpaper Quick Shuffle Button
      Rectangle {
        visible: !root.showAdapters && root.activeWallpapersList.length > 0
        Layout.preferredHeight: 26
        Layout.preferredWidth: nextWpRow.implicitWidth + 16
        radius: 13
        color: nextHover.containsMouse ? Style.surfaceHover : Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
          id: nextWpRow
          anchors.centerIn: parent
          spacing: 5

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰒟"
            font.pixelSize: 12
            color: Style.textSecondary
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Sıradaki"
            font.family: Style.fontDisplay
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }

        MouseArea {
          id: nextHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (ipc) ipc.nextWallpaper(root.currentActiveThemeId)
          }
        }
      }

      // Adapters Drawer Toggle Button
      Rectangle {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        radius: 13
        color: root.showAdapters
          ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.22)
          : (adaptBtnHover.containsMouse ? Style.surfaceHover : Style.surface)
        border.color: root.showAdapters
          ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.35)
          : Style.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
          anchors.centerIn: parent
          text: root.showAdapters ? "󰔎" : "󰏖"
          font.pixelSize: 13
          color: root.showAdapters ? Style.accent : Style.textPrimary
        }

        MouseArea {
          id: adaptBtnHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.showAdapters = !root.showAdapters
        }
      }
    }

    // =========================================================================
    // 2. SPLIT STUDIO: Left Theme List + Right 2-Column Vertical Wallpaper Grid
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 10
      visible: !root.showAdapters

      // Left Column: Seamless 7-Theme Selector List
      Rectangle {
        Layout.preferredWidth: 158
        Layout.fillHeight: true
        radius: 14
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
        border.color: Style.borderSubtle
        border.width: 1
        clip: true

        ListView {
          id: themesList
          anchors.fill: parent
          anchors.margins: 5
          spacing: 2
          boundsBehavior: Flickable.StopAtBounds
          model: root.activeThemesList

          delegate: Rectangle {
            width: themesList.width
            height: 36
            radius: 10

            readonly property var themeItem: modelData
            readonly property var themeColors: themeItem.colors || ({})
            readonly property bool isActive: root.currentActiveThemeId === themeItem.id
            readonly property color thmBg: themeColors.bg ? themeColors.bg : "#1e1e2e"
            readonly property color thmAccent: themeColors.accent ? themeColors.accent : "#89b4fa"

            color: isActive
              ? Qt.rgba(thmAccent.r, thmAccent.g, thmAccent.b, 0.16)
              : (themeRowMouse.containsMouse ? Style.surfaceHover : "transparent")

            Behavior on color { ColorAnimation { duration: 140 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 8

              // Dual-Tone Circular Swatch (Outer: Theme BG, Inner: Theme Accent)
              Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: thmBg
                border.color: isActive ? thmAccent : Qt.rgba(1, 1, 1, 0.18)
                border.width: isActive ? 1.5 : 1

                Rectangle {
                  anchors.centerIn: parent
                  width: 8
                  height: 8
                  radius: 4
                  color: thmAccent
                }
              }

              Text {
                Layout.fillWidth: true
                text: root.shortThemeName(themeItem.name || themeItem.id)
                font.family: Style.fontDisplay
                font.pixelSize: 11
                font.weight: isActive ? Font.DemiBold : Font.Medium
                color: isActive ? Style.textPrimary : Style.textSecondary
                elide: Text.ElideRight
              }

              Text {
                visible: isActive
                text: "󰄬"
                font.pixelSize: 12
                color: thmAccent
              }
            }

            MouseArea {
              id: themeRowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (ipc) ipc.setActiveTheme(themeItem.id)
              }
            }
          }
        }
      }

      // Right Column: 2-Column Vertically Scrollable Wallpaper Gallery
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 14
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
        border.color: Style.borderSubtle
        border.width: 1
        clip: true

        // Empty State (Minimal Palette Preview + Folder Hint)
        Column {
          visible: root.activeWallpapersList.length === 0
          anchors.centerIn: parent
          spacing: 8
          width: parent.width - 36

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰸉"
            font.pixelSize: 24
            color: Style.textMuted
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Bu tema için duvar kağıdı yok"
            font.family: Style.fontDisplay
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.textSecondary
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: "~/Pictures/Wallpapers/" + root.shortThemeName(root.currentActiveThemeName) + "/ klasörüne görsel ekleyebilirsiniz."
            font.family: Style.fontText
            font.pixelSize: 10
            color: Style.textMuted
          }
        }

        // 2-Column Responsive Vertical Wallpaper Grid (Native Mouse Wheel Scroll)
        GridView {
          id: wallpapersGrid
          anchors.fill: parent
          anchors.margins: 5
          visible: root.activeWallpapersList.length > 0
          cellWidth: Math.floor(wallpapersGrid.width / 2)
          cellHeight: Math.floor(wallpapersGrid.cellWidth * 0.58)
          cacheBuffer: 120
          boundsBehavior: Flickable.StopAtBounds
          clip: true
          model: root.activeWallpapersList

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 3
            interactive: false
            contentItem: Rectangle {
              implicitWidth: 3
              radius: 2
              color: Style.textMuted
              opacity: 0.45
            }
          }

          delegate: Item {
            width: wallpapersGrid.cellWidth
            height: wallpapersGrid.cellHeight

            readonly property string wpPath: modelData
            readonly property bool isCurrent: root.activeWallpaperPath === wpPath
            readonly property string fileName: root.getBaseFileName(wpPath)

            Rectangle {
              anchors.fill: parent
              anchors.margins: 3
              radius: 10
              color: Style.surfaceVariant
              border.color: isCurrent
                ? Style.accent
                : (wpCardHover.containsMouse ? Qt.rgba(1, 1, 1, 0.30) : Style.borderSubtle)
              border.width: isCurrent ? 1.5 : 1
              clip: true

              scale: wpCardHover.containsMouse ? 1.02 : 1.0
              Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
              Behavior on border.color { ColorAnimation { duration: 140 } }

              Image {
                anchors.fill: parent
                source: "file://" + wpPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: 240
                sourceSize.height: 140
                smooth: true
              }

              // Subtle Hover / Active Filename Scrim
              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 24
                opacity: (wpCardHover.containsMouse || isCurrent) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 130 } }

                gradient: Gradient {
                  GradientStop { position: 0.0; color: "#00000000" }
                  GradientStop { position: 1.0; color: "#cc000000" }
                }

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 7
                  anchors.right: parent.right
                  anchors.rightMargin: 7
                  anchors.bottom: parent.bottom
                  anchors.bottomMargin: 4
                  text: fileName
                  font.family: Style.fontText
                  font.pixelSize: 9
                  font.weight: Font.Medium
                  color: "#ffffff"
                  elide: Text.ElideMiddle
                }
              }

              // Minimal Active Check Badge
              Rectangle {
                visible: isCurrent
                anchors.top: parent.top
                anchors.topMargin: 5
                anchors.right: parent.right
                anchors.rightMargin: 5
                width: 18
                height: 18
                radius: 9
                color: Qt.rgba(0, 0, 0, 0.70)
                border.color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.55)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "󰄬"
                  font.pixelSize: 11
                  color: Style.accent
                }
              }

              MouseArea {
                id: wpCardHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (ipc) ipc.setWallpaper(root.currentActiveThemeId, wpPath)
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. APP ADAPTERS SYNC DRAWER (Go ThemeManager Multi-App Toggles)
    // =========================================================================
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.showAdapters
      radius: 14
      color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.04)
      border.color: Style.borderSubtle
      border.width: 1
      clip: true

      GridView {
        id: adaptersGrid
        anchors.fill: parent
        anchors.margins: 6
        cellWidth: Math.floor(adaptersGrid.width / 2)
        cellHeight: 44
        boundsBehavior: Flickable.StopAtBounds
        model: root.adapterCatalog

        delegate: Item {
          width: adaptersGrid.cellWidth
          height: adaptersGrid.cellHeight

          readonly property bool isOn: root.isAdapterEnabled(modelData.id)

          Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 10
            color: adaptRowHover.containsMouse ? Style.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 140 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 9

              Text {
                text: modelData.icon
                font.pixelSize: 14
                color: isOn ? Style.accent : Style.textMuted
              }

              Text {
                Layout.fillWidth: true
                text: modelData.label
                font.family: Style.fontDisplay
                font.pixelSize: 11
                font.weight: Font.Medium
                color: isOn ? Style.textPrimary : Style.textMuted
                elide: Text.ElideRight
              }

              // Minimal Apple-Style Toggle Switch
              Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 18
                radius: 9
                color: isOn
                  ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.85)
                  : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14)

                Behavior on color { ColorAnimation { duration: 160 } }

                Rectangle {
                  width: 14
                  height: 14
                  radius: 7
                  y: 2
                  x: isOn ? (parent.width - width - 2) : 2
                  color: "#ffffff"

                  Behavior on x {
                    SpringAnimation {
                      spring: 28.0
                      damping: 0.78
                      epsilon: 0.01
                    }
                  }
                }
              }
            }

            MouseArea {
              id: adaptRowHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (ipc) ipc.toggleThemeAdapter(modelData.id, !isOn)
              }
            }
          }
        }
      }
    }
  }
}
