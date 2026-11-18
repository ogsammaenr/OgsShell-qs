import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../backend"
import "../components"

Flickable {
  id: root

  property var ipc

  // Local working state cloned from Config singleton
  property string currentFormFactor: Config.formFactor
  property bool currentFocusMode: Config.focusMode
  property bool currentShowMetrics: Config.showPinnedSystemMetrics
  property bool currentNotifEnabled: (Config.notifications && Config.notifications.enabled !== undefined) ? Config.notifications.enabled : true
  property int currentNotifTimeout: (Config.notifications && Config.notifications.default_timeout_ms) ? Config.notifications.default_timeout_ms : 3500

  // Island Working Geometries
  property int islandTopMargin: Config.islandTopMargin
  property int islandIdleW: Config.islandIdleWidth
  property int islandIdleH: Config.islandIdleHeight
  property int islandHoverW: Config.islandHoverWidth
  property int islandHoverH: Config.islandHoverHeight
  property int islandTransientW: Config.islandTransientWidth
  property int islandTransientH: Config.islandTransientHeight
  property int islandExpandedW: Config.islandExpandedWidth
  property int islandExpandedH: Config.islandExpandedHeight
  property int islandRadiusFull: Config.islandRadiusFull
  property int islandRadiusExp: Config.islandRadiusExpanded

  // Notch Working Geometries
  property int notchTopMargin: Config.notchTopMargin
  property int notchIdleW: Config.notchIdleWidth
  property int notchIdleH: Config.notchIdleHeight
  property int notchHoverW: Config.notchHoverWidth
  property int notchHoverH: Config.notchHoverHeight
  property int notchTransientW: Config.notchTransientWidth
  property int notchTransientH: Config.notchTransientHeight
  property int notchExpandedW: Config.notchExpandedWidth
  property int notchExpandedH: Config.notchExpandedHeight
  property int notchRadiusBottom: Config.notchBottomRadius
  property int notchRadiusExp: Config.notchBottomRadiusExpanded

  // Animation Working Parameters
  property int animCompact: (Config.animation && Config.animation.duration_compact) ? Config.animation.duration_compact : 250
  property int animTransient: (Config.animation && Config.animation.duration_transient) ? Config.animation.duration_transient : 280
  property int animExpanded: (Config.animation && Config.animation.duration_expanded) ? Config.animation.duration_expanded : 320
  property real animOvershoot: (Config.animation && Config.animation.overshoot_factor) ? Config.animation.overshoot_factor : 1.12

  property string statusFeedbackMessage: ""

  function pullValuesFromConfig() {
    currentFormFactor = Config.formFactor
    currentFocusMode = Config.focusMode
    currentShowMetrics = Config.showPinnedSystemMetrics
    currentNotifEnabled = (Config.notifications && Config.notifications.enabled !== undefined) ? Config.notifications.enabled : true
    currentNotifTimeout = (Config.notifications && Config.notifications.default_timeout_ms) ? Config.notifications.default_timeout_ms : 3500

    islandTopMargin = Config.islandTopMargin
    islandIdleW = Config.islandIdleWidth
    islandIdleH = Config.islandIdleHeight
    islandHoverW = Config.islandHoverWidth
    islandHoverH = Config.islandHoverHeight
    islandTransientW = Config.islandTransientWidth
    islandTransientH = Config.islandTransientHeight
    islandExpandedW = Config.islandExpandedWidth
    islandExpandedH = Config.islandExpandedHeight
    islandRadiusFull = Config.islandRadiusFull
    islandRadiusExp = Config.islandRadiusExpanded

    notchTopMargin = Config.notchTopMargin
    notchIdleW = Config.notchIdleWidth
    notchIdleH = Config.notchIdleHeight
    notchHoverW = Config.notchHoverWidth
    notchHoverH = Config.notchHoverHeight
    notchTransientW = Config.notchTransientWidth
    notchTransientH = Config.notchTransientHeight
    notchExpandedW = Config.notchExpandedWidth
    notchExpandedH = Config.notchExpandedHeight
    notchRadiusBottom = Config.notchBottomRadius
    notchRadiusExp = Config.notchBottomRadiusExpanded

    animCompact = (Config.animation && Config.animation.duration_compact) ? Config.animation.duration_compact : 250
    animTransient = (Config.animation && Config.animation.duration_transient) ? Config.animation.duration_transient : 280
    animExpanded = (Config.animation && Config.animation.duration_expanded) ? Config.animation.duration_expanded : 320
    animOvershoot = (Config.animation && Config.animation.overshoot_factor) ? Config.animation.overshoot_factor : 1.12
  }

  function applyAndSave(customMsg) {
    let payload = {
      "form_factor": root.currentFormFactor,
      "theme": Config.theme,
      "show_pinned_system_metrics": root.currentShowMetrics,
      "focus_mode": root.currentFocusMode,
      "typography": Config.typography,
      "island": {
        "top_margin": root.islandTopMargin,
        "idle_width": root.islandIdleW,
        "idle_height": root.islandIdleH,
        "hover_width": root.islandHoverW,
        "hover_height": root.islandHoverH,
        "transient_width": root.islandTransientW,
        "transient_height": root.islandTransientH,
        "expanded_width": root.islandExpandedW,
        "expanded_height": root.islandExpandedH,
        "radius_full": root.islandRadiusFull,
        "radius_expanded": root.islandRadiusExp
      },
      "notch": {
        "top_margin": root.notchTopMargin,
        "idle_width": root.notchIdleW,
        "idle_height": root.notchIdleH,
        "hover_width": root.notchHoverW,
        "hover_height": root.notchHoverH,
        "transient_width": root.notchTransientW,
        "transient_height": root.notchTransientH,
        "expanded_width": root.notchExpandedW,
        "expanded_height": root.notchExpandedH,
        "bottom_radius": root.notchRadiusBottom,
        "bottom_radius_expanded": root.notchRadiusExp
      },
      "notifications": {
        "enabled": root.currentNotifEnabled,
        "default_timeout_ms": root.currentNotifTimeout
      },
      "animation": {
        "duration_compact": root.animCompact,
        "duration_transient": root.animTransient,
        "duration_expanded": root.animExpanded,
        "overshoot_factor": root.animOvershoot
      }
    }

    Config.saveConfig(payload)
    root.statusFeedbackMessage = customMsg || "Ayarlar kaydedildi ve anında uygulandı."
    feedbackTimer.restart()
  }

  function resetDefaults() {
    root.currentFormFactor = "notch"
    root.currentFocusMode = false
    root.currentShowMetrics = true
    root.currentNotifEnabled = true
    root.currentNotifTimeout = 3500

    root.islandTopMargin = 3
    root.islandIdleW = 180
    root.islandIdleH = 36
    root.islandHoverW = 480
    root.islandHoverH = 58
    root.islandTransientW = 340
    root.islandTransientH = 56
    root.islandExpandedW = 490
    root.islandExpandedH = 315
    root.islandRadiusFull = 18
    root.islandRadiusExp = 24

    root.notchTopMargin = 0
    root.notchIdleW = 190
    root.notchIdleH = 28
    root.notchHoverW = 500
    root.notchHoverH = 74
    root.notchTransientW = 350
    root.notchTransientH = 58
    root.notchExpandedW = 500
    root.notchExpandedH = 315
    root.notchRadiusBottom = 20
    root.notchRadiusExp = 26

    root.animCompact = 250
    root.animTransient = 280
    root.animExpanded = 320
    root.animOvershoot = 1.12

    root.applyAndSave("Varsayılan geometri ve animasyon değerleri geri yüklendi.")
  }

  Connections {
    target: Config
    function onConfigUpdated() {
      root.pullValuesFromConfig()
    }
  }

  Component.onCompleted: {
    root.pullValuesFromConfig()
  }

  Timer {
    id: feedbackTimer
    interval: 3500
    repeat: false
    onTriggered: root.statusFeedbackMessage = ""
  }

  contentWidth: width
  contentHeight: mainColumn.implicitHeight + 40
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  ColumnLayout {
    id: mainColumn
    width: parent.width - 40
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 20
    spacing: 18

    // Header & Global Actions
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: "Ada ve Çentik Yapılandırması"
          font.family: Style.fontText
          font.pixelSize: 14
          font.weight: Font.DemiBold
          color: Style.textPrimary
        }

        Text {
          text: "Sunum formatı, geometri boyutları ve yay animasyonları."
          font.family: Style.fontText
          font.pixelSize: 11
          color: Style.textMuted
        }
      }

      SettingsButton {
        text: "Sıfırla"
        iconText: "󰑐"
        onClicked: root.resetDefaults()
      }

      SettingsButton {
        text: "Uygula"
        iconText: "󰄬"
        isAccent: true
        onClicked: root.applyAndSave()
      }
    }

    // Status Banner
    Rectangle {
      visible: root.statusFeedbackMessage !== ""
      Layout.fillWidth: true
      implicitHeight: 32
      radius: 8
      color: Qt.alpha(Style.accentGreen, 0.12)
      border.color: Qt.alpha(Style.accentGreen, 0.35)
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
          text: "󰄬"
          font.pixelSize: 13
          color: Style.accentGreen
        }

        Text {
          text: root.statusFeedbackMessage
          font.family: Style.fontText
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.accentGreen
          Layout.fillWidth: true
        }
      }
    }

    // 1. Form Factor Selection
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Sunum Formatı"
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        SettingsChoiceCard {
          title: "Dynamic Island"
          subtitle: "Üst kenardan ayrık süzülen kapsül görünümü."
          iconText: "󰘔"
          badgeText: "Floating"
          isSelected: root.currentFormFactor === "island"
          onClicked: {
            root.currentFormFactor = "island"
            root.applyAndSave()
          }
        }

        SettingsChoiceCard {
          title: "Dynamic Notch"
          subtitle: "Ekran üst kenarına bitişik organik çentik."
          iconText: "󰞷"
          badgeText: "Bezel"
          isSelected: root.currentFormFactor === "notch"
          onClicked: {
            root.currentFormFactor = "notch"
            root.applyAndSave()
          }
        }
      }
    }

    // 2. General Behavior
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Genel Davranış"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰓾"
          title: "Akıllı Odak Modu (Focus Mode)"
          subtitle: "İmleç dışarıdayken arayüzü gizleyerek tam ekran alanı sunar."
          showDivider: true

          SettingsToggle {
            checked: root.currentFocusMode
            onToggled: isChecked => {
              root.currentFocusMode = isChecked
              root.applyAndSave()
            }
          }
        }

        SettingsRow {
          iconText: "󰄨"
          title: "Sistem Metriklerini Sabitle"
          subtitle: "Boşta durumdayken canlı CPU, RAM ve GPU değerlerini gösterir."
          showDivider: true

          SettingsToggle {
            checked: root.currentShowMetrics
            onToggled: isChecked => {
              root.currentShowMetrics = isChecked
              root.applyAndSave()
            }
          }
        }

        SettingsRow {
          iconText: "󰂚"
          title: "Bildirim Açılır Pencereleri"
          subtitle: "Gelen bildirimleri geçici kart olarak ada üzerinde gösterir."
          showDivider: true

          SettingsToggle {
            checked: root.currentNotifEnabled
            onToggled: isChecked => {
              root.currentNotifEnabled = isChecked
              root.applyAndSave()
            }
          }
        }

        SettingsNumberRow {
          iconText: "󰔛"
          title: "Bildirim Kapanma Süresi"
          subtitle: "Geçici bildirimin ekranda kalma süresi."
          value: root.currentNotifTimeout
          minValue: 1000
          maxValue: 15000
          step: 500
          unit: "ms"
          showDivider: false
          onValueModified: val => {
            root.currentNotifTimeout = val
            root.applyAndSave()
          }
        }
      }
    }

    // 3. Dynamic Island Geometry
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Dynamic Island Geometrisi"
      }

      SettingsCard {
        SettingsNumberRow {
          title: "Üst Kenar Boşluğu"
          value: root.islandTopMargin
          minValue: 0
          maxValue: 64
          step: 1
          unit: "px"
          onValueModified: val => { root.islandTopMargin = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Boşta (Idle) Genişlik"
          value: root.islandIdleW
          minValue: 120
          maxValue: 400
          step: 5
          unit: "px"
          onValueModified: val => { root.islandIdleW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Boşta (Idle) Yükseklik"
          value: root.islandIdleH
          minValue: 24
          maxValue: 64
          step: 2
          unit: "px"
          onValueModified: val => { root.islandIdleH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Hover Genişlik"
          value: root.islandHoverW
          minValue: 250
          maxValue: 800
          step: 10
          unit: "px"
          onValueModified: val => { root.islandHoverW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Hover Yükseklik"
          value: root.islandHoverH
          minValue: 36
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.islandHoverH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Geçici (Bildirim) Genişlik"
          value: root.islandTransientW
          minValue: 220
          maxValue: 600
          step: 10
          unit: "px"
          onValueModified: val => { root.islandTransientW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Geçici (Bildirim) Yükseklik"
          value: root.islandTransientH
          minValue: 36
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.islandTransientH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş (Expanded) Genişlik"
          value: root.islandExpandedW
          minValue: 320
          maxValue: 900
          step: 10
          unit: "px"
          onValueModified: val => { root.islandExpandedW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş (Expanded) Yükseklik"
          value: root.islandExpandedH
          minValue: 160
          maxValue: 600
          step: 5
          unit: "px"
          onValueModified: val => { root.islandExpandedH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Kompakt Köşe Yarıçapı"
          value: root.islandRadiusFull
          minValue: 8
          maxValue: 32
          step: 1
          unit: "px"
          onValueModified: val => { root.islandRadiusFull = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş Köşe Yarıçapı"
          value: root.islandRadiusExp
          minValue: 10
          maxValue: 40
          step: 1
          unit: "px"
          showDivider: false
          onValueModified: val => { root.islandRadiusExp = val; root.applyAndSave() }
        }
      }
    }

    // 4. Dynamic Notch Geometry
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Dynamic Notch Geometrisi"
      }

      SettingsCard {
        SettingsNumberRow {
          title: "Üst Boşluk"
          value: root.notchTopMargin
          minValue: 0
          maxValue: 32
          step: 1
          unit: "px"
          onValueModified: val => { root.notchTopMargin = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Boşta (Idle) Genişlik"
          value: root.notchIdleW
          minValue: 120
          maxValue: 400
          step: 5
          unit: "px"
          onValueModified: val => { root.notchIdleW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Boşta (Idle) Yükseklik"
          value: root.notchIdleH
          minValue: 20
          maxValue: 60
          step: 2
          unit: "px"
          onValueModified: val => { root.notchIdleH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Hover Genişlik"
          value: root.notchHoverW
          minValue: 250
          maxValue: 800
          step: 10
          unit: "px"
          onValueModified: val => { root.notchHoverW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Hover Yükseklik"
          value: root.notchHoverH
          minValue: 30
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.notchHoverH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Geçici (Bildirim) Genişlik"
          value: root.notchTransientW
          minValue: 220
          maxValue: 600
          step: 10
          unit: "px"
          onValueModified: val => { root.notchTransientW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Geçici (Bildirim) Yükseklik"
          value: root.notchTransientH
          minValue: 30
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.notchTransientH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş (Expanded) Genişlik"
          value: root.notchExpandedW
          minValue: 320
          maxValue: 900
          step: 10
          unit: "px"
          onValueModified: val => { root.notchExpandedW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş (Expanded) Yükseklik"
          value: root.notchExpandedH
          minValue: 160
          maxValue: 600
          step: 5
          unit: "px"
          onValueModified: val => { root.notchExpandedH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Alt Bézier Kavis Yarıçapı"
          value: root.notchRadiusBottom
          minValue: 8
          maxValue: 40
          step: 1
          unit: "px"
          onValueModified: val => { root.notchRadiusBottom = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş Alt Kavis Yarıçapı"
          value: root.notchRadiusExp
          minValue: 12
          maxValue: 50
          step: 1
          unit: "px"
          showDivider: false
          onValueModified: val => { root.notchRadiusExp = val; root.applyAndSave() }
        }
      }
    }

    // 5. Physics & Animations
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Animasyon Süreleri ve Fizik"
      }

      SettingsCard {
        SettingsNumberRow {
          title: "Kompakt Geçiş Süresi"
          value: root.animCompact
          minValue: 100
          maxValue: 800
          step: 25
          unit: "ms"
          onValueModified: val => { root.animCompact = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Geçici (Bildirim) Süresi"
          value: root.animTransient
          minValue: 100
          maxValue: 800
          step: 25
          unit: "ms"
          onValueModified: val => { root.animTransient = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Genişletilmiş Panel Süresi"
          value: root.animExpanded
          minValue: 100
          maxValue: 1000
          step: 25
          unit: "ms"
          onValueModified: val => { root.animExpanded = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          title: "Yay Esneme Çarpanı (Overshoot)"
          value: root.animOvershoot
          minValue: 1.0
          maxValue: 2.0
          step: 0.02
          unit: "x"
          showDivider: false
          onValueModified: val => { root.animOvershoot = val; root.applyAndSave() }
        }
      }
    }
  }
}
