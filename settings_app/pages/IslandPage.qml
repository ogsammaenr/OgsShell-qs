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

  readonly property bool isNotchMode: Config.formFactor === "notch"

  function resetDefaults() {
    Config.saveConfig({
      "form_factor": "notch",
      "focus_mode": false,
      "show_pinned_system_metrics": true,
      "island": {
        "top_margin": 3,
        "idle_width": 180,
        "idle_height": 36,
        "hover_width": 480,
        "hover_height": 58,
        "transient_width": 340,
        "transient_height": 56,
        "expanded_width": 490,
        "expanded_height": 315,
        "radius_full": 18,
        "radius_expanded": 24
      },
      "notch": {
        "top_margin": 0,
        "idle_width": 190,
        "idle_height": 28,
        "hover_width": 500,
        "hover_height": 74,
        "transient_width": 350,
        "transient_height": 58,
        "expanded_width": 500,
        "expanded_height": 315,
        "bottom_radius": 20,
        "bottom_radius_expanded": 26
      },
      "animation": {
        "duration_compact": 250,
        "duration_transient": 280,
        "duration_expanded": 320,
        "overshoot_factor": 1.12
      }
    })
    root.notifyToast("Ada ve çentik ayarları varsayılana sıfırlandı.", false)
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
    // 1. LIVE VISUAL PREVIEW + FORM FACTOR CHOICE
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      RowLayout {
        Layout.fillWidth: true

        SettingsSectionHeader {
          titleText: "Sunum Şekli"
          Layout.fillWidth: true
        }

        SettingsButton {
          text: "Varsayılana Sıfırla"
          iconText: "󰑐"
          onClicked: root.resetDefaults()
        }
      }

      // Live Mini Desktop Bezel Preview
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 92
        radius: 12
        color: Style.appCard
        border.color: Style.appBorder
        border.width: 1
        clip: true

        // Subtle wallpaper gradient inside preview
        Rectangle {
          anchors.fill: parent
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Style.accent, 0.10) }
            GradientStop { position: 1.0; color: Qt.alpha("#000000", 0.35) }
          }
        }

        // Active Notch / Island Silhouette
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: root.isNotchMode ? 0 : Math.max(8, Config.islandTopMargin + 6)
          width: root.isNotchMode ? Math.min(260, Config.notchIdleWidth) : Math.min(260, Config.islandIdleWidth)
          height: root.isNotchMode ? Math.max(26, Config.notchIdleHeight) : Math.max(28, Config.islandIdleHeight)
          radius: root.isNotchMode ? Math.min(14, Config.notchBottomRadius) : Math.min(height / 2, Config.islandRadiusFull)
          color: "#000000"

          // Square off top edge visually in Notch mode
          Rectangle {
            visible: root.isNotchMode
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: "#000000"
          }

          Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutQuart } }
          Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutQuart } }
          Behavior on anchors.topMargin { NumberAnimation { duration: 240; easing.type: Easing.OutQuart } }

          Text {
            anchors.centerIn: parent
            text: "21:24"
            font.family: Style.fontDisplay
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 10
          text: root.isNotchMode
            ? ("Aktif Mod: Dynamic Notch  •  " + Config.notchIdleWidth + "×" + Config.notchIdleHeight + " px")
            : ("Aktif Mod: Dynamic Island  •  " + Config.islandIdleWidth + "×" + Config.islandIdleHeight + " px")
          font.family: Style.fontText
          font.pixelSize: 11
          color: Style.textMuted
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        SettingsChoiceCard {
          title: "Dynamic Notch"
          subtitle: "Üst kenara yapışık organik kavisli çentik."
          iconText: "󰞷"
          badgeText: "Çentik"
          isSelected: root.isNotchMode
          onClicked: {
            Config.saveConfig({ "form_factor": "notch" })
            root.notifyToast("Dynamic Notch moduna geçildi.", false)
          }
        }

        SettingsChoiceCard {
          title: "Dynamic Island"
          subtitle: "Ekran üstünde süzülen kapsül görünümü."
          iconText: "󰘔"
          badgeText: "Ada"
          isSelected: !root.isNotchMode
          onClicked: {
            Config.saveConfig({ "form_factor": "island" })
            root.notifyToast("Dynamic Island moduna geçildi.", false)
          }
        }
      }
    }

    // =========================================================================
    // 2. CORE BEHAVIORS (Clear, Everyday Controls)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Temel Davranışlar"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰓾"
          title: "Akıllı Odak Modu (Focus Mode)"
          subtitle: "Pencere açıkken üst barı gizler; fare üst kenara gelince gösterir."
          showDivider: true

          SettingsToggle {
            checked: Config.focusMode
            onToggled: isChecked => {
              Config.saveConfig({ "focus_mode": isChecked })
              root.notifyToast(isChecked ? "Odak modu açıldı." : "Odak modu kapatıldı.", false)
            }
          }
        }

        SettingsRow {
          iconText: "󰄨"
          title: "Sabit Sistem Metrikleri"
          subtitle: "Çentik yanında canlı CPU, RAM ve GPU göstergelerini tutar."
          showDivider: true

          SettingsToggle {
            checked: Config.showPinnedSystemMetrics
            onToggled: isChecked => {
              Config.saveConfig({ "show_pinned_system_metrics": isChecked })
              root.notifyToast(isChecked ? "Sistem metrikleri gösteriliyor." : "Sistem metrikleri gizlendi.", false)
            }
          }
        }

        SettingsRow {
          iconText: "󰍹"
          title: "Sol-Üst Köşe HUD Göstergesi"
          subtitle: "Ses, çalışma alanı, Caps Lock ve pano değişimlerini sol köşede gösterir."
          showDivider: true

          SettingsToggle {
            checked: Config.cornerHudEnabled
            onToggled: isChecked => {
              Config.saveConfig({ "corner_hud": { "enabled": isChecked } })
              root.notifyToast("Köşe HUD ayarı güncellendi.", false)
            }
          }
        }

        SettingsRow {
          iconText: "󰀻"
          title: "Sağ-Üst Sistem Tepsisi (Tray)"
          subtitle: "Arka planda çalışan uygulamaların tepsi simgelerini sağ köşede toplar."
          showDivider: false

          SettingsToggle {
            checked: Config.cornerTrayEnabled
            onToggled: isChecked => {
              Config.saveConfig({ "corner_tray": { "enabled": isChecked } })
              root.notifyToast("Sistem tepsisi ayarı güncellendi.", false)
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. PROGRESSIVE DISCLOSURE: ACTIVE MODE DIMENSIONS ONLY
    // =========================================================================
    SettingsCollapsibleSection {
      title: root.isNotchMode ? "İnce Boyut Ayarları (Notch)" : "İnce Boyut Ayarları (Island)"
      subtitle: "Boşta, hover ve genişletilmiş piksel boyutları ile köşe kavisleri"
      iconText: "󰙖"
      expanded: false

      SettingsSliderRow {
        visible: !root.isNotchMode
        title: "Üst Kenar Boşluğu"
        value: Config.islandTopMargin
        minValue: 0; maxValue: 32; step: 1; unit: "px"
        onValueModified: val => Config.saveConfig({ "island": { "top_margin": Math.round(val) } })
      }

      SettingsSliderRow {
        title: "Boşta Genişlik (Idle)"
        value: root.isNotchMode ? Config.notchIdleWidth : Config.islandIdleWidth
        minValue: 120; maxValue: 340; step: 5; unit: "px"
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "idle_width": Math.round(val) } })
          else Config.saveConfig({ "island": { "idle_width": Math.round(val) } })
        }
      }

      SettingsSliderRow {
        title: "Boşta Yükseklik (Idle)"
        value: root.isNotchMode ? Config.notchIdleHeight : Config.islandIdleHeight
        minValue: 22; maxValue: 52; step: 2; unit: "px"
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "idle_height": Math.round(val) } })
          else Config.saveConfig({ "island": { "idle_height": Math.round(val) } })
        }
      }

      SettingsSliderRow {
        title: "Hover Genişlik"
        value: root.isNotchMode ? Config.notchHoverWidth : Config.islandHoverWidth
        minValue: 320; maxValue: 700; step: 10; unit: "px"
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "hover_width": Math.round(val) } })
          else Config.saveConfig({ "island": { "hover_width": Math.round(val) } })
        }
      }

      SettingsSliderRow {
        title: "Hover Yükseklik"
        value: root.isNotchMode ? Config.notchHoverHeight : Config.islandHoverHeight
        minValue: 40; maxValue: 96; step: 2; unit: "px"
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "hover_height": Math.round(val) } })
          else Config.saveConfig({ "island": { "hover_height": Math.round(val) } })
        }
      }

      SettingsSliderRow {
        title: "Genişletilmiş Panel Genişliği"
        value: root.isNotchMode ? Config.notchExpandedWidth : Config.islandExpandedWidth
        minValue: 360; maxValue: 720; step: 10; unit: "px"
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "expanded_width": Math.round(val) } })
          else Config.saveConfig({ "island": { "expanded_width": Math.round(val) } })
        }
      }

      SettingsSliderRow {
        title: "Genişletilmiş Panel Yüksekliği"
        value: root.isNotchMode ? Config.notchExpandedHeight : Config.islandExpandedHeight
        minValue: 220; maxValue: 480; step: 5; unit: "px"
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "expanded_height": Math.round(val) } })
          else Config.saveConfig({ "island": { "expanded_height": Math.round(val) } })
        }
      }

      SettingsSliderRow {
        title: root.isNotchMode ? "Alt Kavis Yarıçapı" : "Köşe Yarıçapı"
        value: root.isNotchMode ? Config.notchBottomRadius : Config.islandRadiusFull
        minValue: 8; maxValue: 34; step: 1; unit: "px"
        showDivider: false
        onValueModified: val => {
          if (root.isNotchMode) Config.saveConfig({ "notch": { "bottom_radius": Math.round(val) } })
          else Config.saveConfig({ "island": { "radius_full": Math.round(val) } })
        }
      }
    }

    // =========================================================================
    // 4. PROGRESSIVE DISCLOSURE: ANIMATION SPEED
    // =========================================================================
    SettingsCollapsibleSection {
      title: "Animasyon Süreleri ve Fizik"
      subtitle: "Açılış/kapanış hızları ve yay esneme katsayısı"
      iconText: "󰚗"
      expanded: false

      SettingsSliderRow {
        title: "Kompakt Geçiş Süresi"
        value: (Config.animation && Config.animation.duration_compact) ? Config.animation.duration_compact : 250
        minValue: 100; maxValue: 600; step: 25; unit: "ms"
        onValueModified: val => Config.saveConfig({ "animation": { "duration_compact": Math.round(val) } })
      }

      SettingsSliderRow {
        title: "Genişletilmiş Panel Süresi"
        value: (Config.animation && Config.animation.duration_expanded) ? Config.animation.duration_expanded : 320
        minValue: 120; maxValue: 700; step: 25; unit: "ms"
        onValueModified: val => Config.saveConfig({ "animation": { "duration_expanded": Math.round(val) } })
      }

      SettingsSliderRow {
        title: "Yay Esneme Çarpanı"
        value: (Config.animation && Config.animation.overshoot_factor) ? Config.animation.overshoot_factor : 1.12
        minValue: 1.0; maxValue: 1.6; step: 0.02; decimals: 2; unit: "x"
        showDivider: false
        onValueModified: val => Config.saveConfig({ "animation": { "overshoot_factor": val } })
      }
    }
  }
}
