import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../backend"
import "../components"

Flickable {
  id: root

  property var ipc: null
  signal notifyToast(string msg, bool isErr)

  readonly property var themeCards: [
    { "id": "monochrome",  "name": "Monochrome",  "bg": "#141416", "accent": "#e0e0e0", "sec": "#888888" },
    { "id": "everforest",  "name": "Everforest",  "bg": "#1e2326", "accent": "#a7c080", "sec": "#dbbc7f" },
    { "id": "catppuccin",  "name": "Catppuccin",  "bg": "#24273a", "accent": "#c6a0f6", "sec": "#8aadf4" },
    { "id": "tokyonight",  "name": "Tokyo Night", "bg": "#1a1b26", "accent": "#7aa2f7", "sec": "#bb9af7" },
    { "id": "nord",        "name": "Nord",        "bg": "#2e3440", "accent": "#88c0d0", "sec": "#a3be8c" },
    { "id": "gruvbox",     "name": "Gruvbox",     "bg": "#282828", "accent": "#d65d0e", "sec": "#fabd2f" },
    { "id": "rosepine",    "name": "Rosé Pine",   "bg": "#191724", "accent": "#ebbcba", "sec": "#c4a7e7" }
  ]

  readonly property var fontChoices: [
    "Noto Sans Display", "SF Pro Display", "SF Pro Rounded", "Outfit", "Plus Jakarta Sans", "Inter"
  ]
  readonly property var weightChoices: [
    { "label": "Normal",   "val": "Normal" },
    { "label": "Orta",     "val": "Medium" },
    { "label": "Yarı Kalın","val": "SemiBold" },
    { "label": "Kalın",    "val": "Bold" }
  ]

  readonly property string activeWallName: {
    let p = (ipc && ipc.activeWallpaper) ? ipc.activeWallpaper : ""
    if (!p) return "Aktif tema duvar kağıdı"
    let idx = p.lastIndexOf("/")
    return idx !== -1 ? p.substring(idx + 1) : p
  }

  contentWidth: width
  contentHeight: mainCol.implicitHeight + 48
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  ColumnLayout {
    id: mainCol
    width: parent.width - 48
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 22
    spacing: 20

    // =========================================================================
    // 1. COLOR THEME GALLERY
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Renk Teması"
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
          model: root.themeCards

          delegate: Rectangle {
            required property var modelData
            readonly property bool isSelected: (Style.activeThemeId || "").toLowerCase() === modelData.id

            Layout.fillWidth: true
            implicitHeight: 68
            radius: 10
            color: isSelected ? Qt.alpha(Style.accent, 0.12) : (tMouse.containsMouse ? Style.surfaceHover : Style.appCard)
            border.color: isSelected ? Style.accent : (tMouse.containsMouse ? Style.borderHover : Style.appBorder)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle { width: 14; height: 14; radius: 7; color: modelData.bg; border.color: Style.appBorder; border.width: 1 }
                Rectangle { width: 14; height: 14; radius: 7; color: modelData.accent }
                Rectangle { width: 14; height: 14; radius: 7; color: modelData.sec }

                Item { Layout.fillWidth: true }

                Text {
                  visible: isSelected
                  text: "󰄬"
                  font.pixelSize: 13
                  color: Style.accent
                }
              }

              Text {
                text: modelData.name
                font.family: Style.fontText
                font.pixelSize: 12
                font.weight: isSelected ? Font.DemiBold : Font.Medium
                color: isSelected ? Style.accent : Style.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            MouseArea {
              id: tMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Config.updateTheme(modelData.id)
                if (root.ipc) root.ipc.setActiveTheme(modelData.id)
                root.notifyToast(modelData.name + " teması uygulandı.", false)
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 2. WALLPAPER QUICK CONTROL
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Duvar Kağıdı"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰸉"
          title: "Tema Duvar Kağıdı Havuzu"
          subtitle: root.activeWallName
          showDivider: false

          SettingsButton {
            text: "Sonrakine Geç"
            iconText: "󰒭"
            isAccent: true
            onClicked: {
              if (root.ipc) {
                root.ipc.nextWallpaper()
                root.notifyToast("Sıradaki duvar kağıdı uygulanıyor...", false)
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. SHELL TYPOGRAPHY
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Kabuk Yazı Tipi"
      }

      SettingsCard {
        innerPadding: 14
        spacing: 12

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Başlık ve Saat Fontu"
            font.family: Style.fontText
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Style.textSecondary
          }

          Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
              model: root.fontChoices

              delegate: Rectangle {
                required property string modelData
                readonly property bool isSelected: Config.fontDisplay === modelData
                height: 30
                implicitWidth: fTxt.implicitWidth + 20
                radius: 7
                color: isSelected ? Qt.alpha(Style.accent, 0.14) : (fMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSelected ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: fTxt
                  anchors.centerIn: parent
                  text: modelData
                  font.family: modelData
                  font.pixelSize: 12
                  font.weight: isSelected ? Font.DemiBold : Font.Normal
                  color: isSelected ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: fMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Config.saveConfig({ "typography": { "font_display": modelData } })
                    root.notifyToast("Yazı tipi " + modelData + " olarak güncellendi.", false)
                  }
                }
              }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Yazı Kalınlığı"
            font.family: Style.fontText
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Style.textSecondary
          }

          Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
              model: root.weightChoices

              delegate: Rectangle {
                required property var modelData
                readonly property bool isSelected: (Config.fontWeightDisplay || "").toLowerCase() === modelData.val.toLowerCase()
                height: 28
                implicitWidth: wTxt.implicitWidth + 18
                radius: 7
                color: isSelected ? Qt.alpha(Style.accent, 0.14) : (wMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSelected ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: wTxt
                  anchors.centerIn: parent
                  text: modelData.label
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: isSelected ? Font.DemiBold : Font.Medium
                  color: isSelected ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: wMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Config.saveConfig({ "typography": { "font_weight_display": modelData.val } })
                    root.notifyToast("Yazı kalınlığı güncellendi.", false)
                  }
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 4. SCREEN CORNERS & SHADOWS
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Ekran Köşeleri ve Gölgeler"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰘖"
          title: "Yuvarlatılmış Ekran Köşeleri"
          subtitle: "Monitörün 4 köşesine donanım benzeri siyah kavis ekler."
          showDivider: true

          SettingsToggle {
            checked: Config.screenCornersEnabled
            onToggled: isChecked => {
              Config.saveConfig({ "screen_corners": { "enabled": isChecked } })
              root.notifyToast(isChecked ? "Ekran köşeleri açıldı." : "Ekran köşeleri kapatıldı.", false)
            }
          }
        }

        SettingsSliderRow {
          visible: Config.screenCornersEnabled
          iconText: "󰩭"
          title: "Köşe Kavis Yarıçapı"
          subtitle: "Ekran köşelerinin yuvarlaklık derecesi."
          value: Config.screenCornersRadius
          minValue: 4
          maxValue: 28
          step: 2
          unit: "px"
          showDivider: true
          onValueModified: val => {
            Config.saveConfig({ "screen_corners": { "radius": Math.round(val) } })
          }
        }

        SettingsRow {
          iconText: "󰆦"
          title: "Kabuk Gölge Efektleri"
          subtitle: "Ada, çentik ve HUD panellerine yumuşak derinlik gölgesi uygular."
          showDivider: false

          SettingsToggle {
            checked: Config.shadowsEnabled
            onToggled: isChecked => {
              Config.saveConfig({ "shadows": { "enabled": isChecked } })
              root.notifyToast(isChecked ? "Gölgeler etkinleştirildi." : "Gölgeler kapatıldı.", false)
            }
          }
        }
      }
    }
  }
}
