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

  readonly property var clockFonts: [
    "SF Pro Rounded", "SF Pro Display", "Outfit", "Plus Jakarta Sans", "Inter", "Noto Sans Display"
  ]
  readonly property var clockWeights: [
    { "label": "İnce",      "val": "Light" },
    { "label": "Normal",    "val": "Regular" },
    { "label": "Orta",      "val": "Medium" },
    { "label": "Yarı Kalın","val": "SemiBold" },
    { "label": "Kalın",     "val": "Bold" }
  ]

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
    // 1. LIVE MINI LOCKSCREEN PREVIEW + TEST ACTION
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      RowLayout {
        Layout.fillWidth: true

        SettingsSectionHeader {
          titleText: "Canlı Önizleme"
          Layout.fillWidth: true
        }

        SettingsButton {
          text: "Şimdi Test Et (Kilitle)"
          iconText: "󰌾"
          isAccent: true
          onClicked: {
            if (root.ipc) {
              root.ipc.sendAction("open_app", { "app": "lock" })
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 176
        radius: 14
        color: "#0e1015"
        border.color: Style.appBorder
        border.width: 1
        clip: true

        // Simulated blurred backdrop with live dim opacity
        Rectangle {
          anchors.fill: parent
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Style.accent, 0.20) }
            GradientStop { position: 0.6; color: "#1d2028" }
            GradientStop { position: 1.0; color: "#0b0d12" }
          }
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, Math.max(0.15, Math.min(0.85, Config.lockscreenDimOpacity)))
        }

        // Mini Top Lock Notch / Island
        Rectangle {
          anchors.top: parent.top
          anchors.topMargin: Config.isNotch ? 0 : 8
          anchors.horizontalCenter: parent.horizontalCenter
          width: 48
          height: 16
          radius: Config.isNotch ? 8 : 8
          color: "#000000"

          Rectangle {
            visible: Config.isNotch
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 8
            color: "#000000"
          }

          Text {
            anchors.centerIn: parent
            text: "󰌾"
            font.pixelSize: 9
            color: Style.textPrimary
          }
        }

        // Center Hero Clock + Small Date
        Column {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: 4
          spacing: 4

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "21:24"
            font.family: Config.lockscreenClockFont
            font.weight: Config.lockscreenClockWeightInt
            font.pixelSize: Math.round(Math.max(36, Math.min(68, Config.lockscreenClockSize * 0.28)))
            font.letterSpacing: -1.5
            color: "#f4f5f8"
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "27 KASIM CUMA · 2026"
            font.family: Config.lockscreenDateFont
            font.pixelSize: Math.round(Math.max(8, Math.min(13, Config.lockscreenDateSize * 0.56)))
            font.weight: Font.Medium
            font.letterSpacing: 1.6
            color: Qt.rgba(244 / 255, 245 / 255, 248 / 255, 0.68)
          }
        }

        // Mini Bottom-Left Media Pill
        Rectangle {
          visible: Config.lockscreenShowMedia
          anchors.left: parent.left
          anchors.bottom: parent.bottom
          anchors.leftMargin: 14
          anchors.bottomMargin: 12
          width: 78
          height: 18
          radius: 9
          color: Qt.rgba(0, 0, 0, 0.78)
          border.color: Qt.rgba(1, 1, 1, 0.12)
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰎆  M83"
            font.family: Style.fontText
            font.pixelSize: 8
            color: Style.textSecondary
          }
        }

        // Mini Bottom-Right Power Dots
        Row {
          visible: Config.lockscreenShowPower
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: 14
          anchors.bottomMargin: 12
          spacing: 5

          Rectangle { width: 16; height: 16; radius: 8; color: Qt.rgba(0, 0, 0, 0.72); border.color: Qt.rgba(1, 1, 1, 0.14); border.width: 1 }
          Rectangle { width: 16; height: 16; radius: 8; color: Qt.rgba(0, 0, 0, 0.72); border.color: Qt.rgba(1, 1, 1, 0.14); border.width: 1 }
          Rectangle { width: 16; height: 16; radius: 8; color: Qt.rgba(0, 0, 0, 0.72); border.color: Qt.alpha(Style.accentRed, 0.45); border.width: 1 }
        }
      }
    }

    // =========================================================================
    // 2. CLOCK TYPOGRAPHY
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Saat Tipografisi"
      }

      SettingsCard {
        innerPadding: 14
        spacing: 12

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Saat Fontu"
            font.family: Style.fontText
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Style.textSecondary
          }

          Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
              model: root.clockFonts

              delegate: Rectangle {
                required property string modelData
                readonly property bool isSelected: Config.lockscreenClockFont === modelData
                height: 30
                implicitWidth: cfTxt.implicitWidth + 20
                radius: 7
                color: isSelected ? Qt.alpha(Style.accent, 0.14) : (cfMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSelected ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: cfTxt
                  anchors.centerIn: parent
                  text: modelData
                  font.family: modelData
                  font.pixelSize: 12
                  font.weight: isSelected ? Font.DemiBold : Font.Normal
                  color: isSelected ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: cfMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Config.saveConfig({ "lockscreen": { "clock_font": modelData } })
                    root.notifyToast("Saat fontu " + modelData + " yapıldı.", false)
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
            text: "Saat Kalınlığı"
            font.family: Style.fontText
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Style.textSecondary
          }

          Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
              model: root.clockWeights

              delegate: Rectangle {
                required property var modelData
                readonly property bool isSelected: (Config.lockscreenClockWeight || "").toLowerCase() === modelData.val.toLowerCase()
                height: 28
                implicitWidth: cwTxt.implicitWidth + 18
                radius: 7
                color: isSelected ? Qt.alpha(Style.accent, 0.14) : (cwMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSelected ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: cwTxt
                  anchors.centerIn: parent
                  text: modelData.label
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: isSelected ? Font.DemiBold : Font.Medium
                  color: isSelected ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: cwMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Config.saveConfig({ "lockscreen": { "clock_weight": modelData.val } })
                    root.notifyToast("Saat kalınlığı güncellendi.", false)
                  }
                }
              }
            }
          }
        }
      }

      SettingsCard {
        SettingsSliderRow {
          iconText: "󰥔"
          title: "Saat Boyutu"
          subtitle: "Merkezdeki büyük saatin yazı boyutu."
          value: Config.lockscreenClockSize
          minValue: 120; maxValue: 260; step: 4; unit: "px"
          showDivider: true
          onValueModified: val => Config.saveConfig({ "lockscreen": { "clock_size": Math.round(val) } })
        }

        SettingsSliderRow {
          iconText: "󰃭"
          title: "Tarih Boyutu"
          subtitle: "Saatin altındaki küçük tarih göstergesi."
          value: Config.lockscreenDateSize
          minValue: 12; maxValue: 28; step: 1; unit: "px"
          showDivider: false
          onValueModified: val => Config.saveConfig({ "lockscreen": { "date_size": Math.round(val) } })
        }
      }
    }

    // =========================================================================
    // 3. BACKDROP BLUR & DIMMING
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Arka Plan Efekti"
      }

      SettingsCard {
        SettingsSliderRow {
          iconText: "󰂵"
          title: "Bulanıklık Şiddeti (Blur)"
          subtitle: "Kilit öncesi yakalanan masaüstü görüntüsünün bulanıklık yarıçapı."
          value: Config.lockscreenBlurRadius
          minValue: 0; maxValue: 128; step: 4; unit: "px"
          showDivider: true
          onValueModified: val => Config.saveConfig({ "lockscreen": { "blur_radius": Math.round(val) } })
        }

        SettingsSliderRow {
          iconText: "󰃠"
          title: "Karartma Yoğunluğu"
          subtitle: "Saat ve çentiğin okunabilirliği için koyu katman opaklığı."
          value: Math.round(Config.lockscreenDimOpacity * 100)
          minValue: 15; maxValue: 85; step: 5; prefix: "%"
          showDivider: false
          onValueModified: val => Config.saveConfig({ "lockscreen": { "dim_opacity": Math.round(val) / 100.0 } })
        }
      }
    }

    // =========================================================================
    // 4. BOTTOM ELEMENTS
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Görünür Bileşenler"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰎆"
          title: "Medya Oynatıcı Kapsülü"
          subtitle: "Müzik veya video çalarken sol altta mini kontrol kapsülü gösterir."
          showDivider: true

          SettingsToggle {
            checked: Config.lockscreenShowMedia
            onToggled: isChecked => {
              Config.saveConfig({ "lockscreen": { "show_media": isChecked } })
              root.notifyToast("Medya kapsülü ayarı kaydedildi.", false)
            }
          }
        }

        SettingsRow {
          iconText: "󰐥"
          title: "Oturum ve Güç Butonları"
          subtitle: "Sağ altta Uyku, Yeniden Başlat ve Kapat butonlarını gösterir."
          showDivider: false

          SettingsToggle {
            checked: Config.lockscreenShowPower
            onToggled: isChecked => {
              Config.saveConfig({ "lockscreen": { "show_power": isChecked } })
              root.notifyToast("Güç butonları ayarı kaydedildi.", false)
            }
          }
        }
      }
    }
  }
}
