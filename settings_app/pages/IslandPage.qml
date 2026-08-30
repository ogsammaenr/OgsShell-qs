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

  function applyAndSave() {
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
    root.statusFeedbackMessage = "✓ Ayarlar başarıyla config.json dosyasına kaydedildi ve anında uygulandı."
    feedbackTimer.restart()
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
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  ColumnLayout {
    id: mainColumn
    width: parent.width - 24
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 16
    spacing: 22

    // =========================================================================
    // HEADER & GLOBAL ACTIONS
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: "Ada ve Çentik Yapılandırması"
          font.pixelSize: 15
          font.weight: Font.Bold
          color: Style.textPrimary
        }

        Text {
          text: "Dynamic Island ve Dynamic Notch sunum modları, geometri boyutları ve yay animasyonları."
          font.pixelSize: 11
          color: Style.textMuted
        }
      }

      SettingsButton {
        text: "Sıfırla"
        iconText: "↺"
        onClicked: {
          Config.resetToDefaults()
          root.pullValuesFromConfig()
          root.statusFeedbackMessage = "✓ Ayarlar varsayılan değerlere sıfırlandı."
          feedbackTimer.restart()
        }
      }

      SettingsButton {
        text: "Değişiklikleri Uygula"
        iconText: "✓"
        isAccent: true
        onClicked: root.applyAndSave()
      }
    }

    // Feedback Toast / Status Banner
    Rectangle {
      visible: root.statusFeedbackMessage !== ""
      Layout.fillWidth: true
      implicitHeight: 34
      radius: 8
      color: Qt.rgba(0.2, 0.8, 0.4, 0.15)
      border.color: Qt.rgba(0.2, 0.8, 0.4, 0.4)
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
          text: root.statusFeedbackMessage
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.accentGreen
          Layout.fillWidth: true
        }
      }
    }

    // =========================================================================
    // 1. FORM FACTOR SELECTION (Dynamic Island vs Dynamic Notch)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Sunum Formatı (Form Factor)"
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        SettingsChoiceCard {
          title: "Dynamic Island (Ada)"
          subtitle: "Ekranın üstünden hafif aşağıda süzülen, OLED siyahı yumuşak köşeli bağımsız kapsül."
          iconText: "🏝️"
          badgeText: "Floating Pill"
          isSelected: root.currentFormFactor === "island"
          onClicked: {
            root.currentFormFactor = "island"
            root.applyAndSave()
          }
        }

        SettingsChoiceCard {
          title: "Dynamic Notch (Çentik)"
          subtitle: "Ekranın üst kenarına tam oturan, organik Bézier kavisli üst panel çentiği."
          iconText: "📱"
          badgeText: "Bezel Notch"
          isSelected: root.currentFormFactor === "notch"
          onClicked: {
            root.currentFormFactor = "notch"
            root.applyAndSave()
          }
        }
      }
    }

    // =========================================================================
    // 2. BEHAVIOR & SYSTEM FLAGS
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Genel Davranış & Modlar"
      }

      SettingsCard {
        SettingsRow {
          iconText: "🎯"
          iconColor: Style.accentCyan
          title: "Akıllı Odak Modu (Focus Mode)"
          subtitle: "İmleç ada/çentik üzerinde değilken ekran alanını maksimuma çıkarmak için arayüzü gizler."
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
          iconText: "📊"
          iconColor: Style.accentGreen
          title: "Sistem Metriklerini Sabitle"
          subtitle: "Boşta durumdayken CPU, RAM ve GPU canlı telemetri kullanım değerlerini gösterir."
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
          iconText: "🔔"
          iconColor: Style.accentYellow
          title: "Bildirim Açılır Pencereleri"
          subtitle: "Gelen bildirimlerin ada üzerinde otomatik olarak geçici pop-up şeklinde açılmasını sağlar."
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
          iconText: "⏱️"
          iconColor: Style.accentMagenta
          title: "Bildirim Kapanma Süresi"
          subtitle: "Geçici bildirim penceresinin ekranda kalma süresi."
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

    // =========================================================================
    // 3. DYNAMIC ISLAND (FLOATING) GEOMETRY
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Dynamic Island (Süzülen Ada) Geometrisi"
      }

      SettingsCard {
        SettingsNumberRow {
          iconText: "📏"
          title: "Üst Kenar Boşluğu (Top Margin)"
          subtitle: "Ekranın üst kenarı ile süzülen ada arasındaki dikey boşluk."
          value: root.islandTopMargin
          minValue: 0
          maxValue: 64
          step: 1
          unit: "px"
          onValueModified: val => { root.islandTopMargin = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📐"
          title: "Boşta (Idle) Genişlik"
          subtitle: "Ada boşta ve küçülmüş durumdaykenki genişlik."
          value: root.islandIdleW
          minValue: 120
          maxValue: 400
          step: 5
          unit: "px"
          onValueModified: val => { root.islandIdleW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📐"
          title: "Boşta (Idle) Yükseklik"
          subtitle: "Ada boşta ve küçülmüş durumdaykenki yükseklik."
          value: root.islandIdleH
          minValue: 24
          maxValue: 64
          step: 2
          unit: "px"
          onValueModified: val => { root.islandIdleH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔍"
          title: "Hover (Üzerine Gelme) Genişlik"
          subtitle: "İmleç adanın üzerine geldiğinde genişleyen boyut."
          value: root.islandHoverW
          minValue: 250
          maxValue: 800
          step: 10
          unit: "px"
          onValueModified: val => { root.islandHoverW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔍"
          title: "Hover (Üzerine Gelme) Yükseklik"
          subtitle: "İmleç adanın üzerine geldiğinde genişleyen yükseklik."
          value: root.islandHoverH
          minValue: 36
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.islandHoverH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "💬"
          title: "Geçici (Transient / Bildirim) Genişlik"
          subtitle: "Yeni bir bildirim geldiğinde adanın aldığı genişlik."
          value: root.islandTransientW
          minValue: 220
          maxValue: 600
          step: 10
          unit: "px"
          onValueModified: val => { root.islandTransientW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "💬"
          title: "Geçici (Transient / Bildirim) Yükseklik"
          subtitle: "Yeni bir bildirim geldiğinde adanın aldığı yükseklik."
          value: root.islandTransientH
          minValue: 36
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.islandTransientH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📱"
          title: "Genişletilmiş (Expanded) Genişlik"
          subtitle: "Tam uygulama panelleri (Launcher, Takvim, Kontrol Merkezi vb.) açıkkenki genişlik."
          value: root.islandExpandedW
          minValue: 320
          maxValue: 900
          step: 10
          unit: "px"
          onValueModified: val => { root.islandExpandedW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📱"
          title: "Genişletilmiş (Expanded) Yükseklik"
          subtitle: "Tam uygulama panelleri açıkkenki yükseklik."
          value: root.islandExpandedH
          minValue: 160
          maxValue: 600
          step: 5
          unit: "px"
          onValueModified: val => { root.islandExpandedH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔘"
          title: "Kompakt Köşe Yuvarlama Yarıçapı"
          subtitle: "Boşta ve hover modunda köşe eğriliği."
          value: root.islandRadiusFull
          minValue: 8
          maxValue: 32
          step: 1
          unit: "px"
          onValueModified: val => { root.islandRadiusFull = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔘"
          title: "Genişletilmiş Köşe Yuvarlama Yarıçapı"
          subtitle: "Genişletilmiş uygulama pencerelerinde köşe eğriliği."
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

    // =========================================================================
    // 4. DYNAMIC NOTCH (BEZEL ATTACHED) GEOMETRY
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Dynamic Notch (Üst Çentik) Geometrisi"
      }

      SettingsCard {
        SettingsNumberRow {
          iconText: "📏"
          title: "Üst Boşluk (Top Margin)"
          subtitle: "Üst panele yapışık çentiğin tepe ofseti (genelde 0px)."
          value: root.notchTopMargin
          minValue: 0
          maxValue: 32
          step: 1
          unit: "px"
          onValueModified: val => { root.notchTopMargin = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📐"
          title: "Boşta (Idle) Genişlik"
          subtitle: "Çentik boşta durumdaykenki genişlik."
          value: root.notchIdleW
          minValue: 120
          maxValue: 400
          step: 5
          unit: "px"
          onValueModified: val => { root.notchIdleW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📐"
          title: "Boşta (Idle) Yükseklik"
          subtitle: "Çentik boşta durumdaykenki yükseklik."
          value: root.notchIdleH
          minValue: 20
          maxValue: 60
          step: 2
          unit: "px"
          onValueModified: val => { root.notchIdleH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔍"
          title: "Hover (Üzerine Gelme) Genişlik"
          subtitle: "İmleç çentiğin üzerine geldiğindeki genişlik."
          value: root.notchHoverW
          minValue: 250
          maxValue: 800
          step: 10
          unit: "px"
          onValueModified: val => { root.notchHoverW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔍"
          title: "Hover (Üzerine Gelme) Yükseklik"
          subtitle: "İmleç çentiğin üzerine geldiğindeki yükseklik."
          value: root.notchHoverH
          minValue: 30
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.notchHoverH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "💬"
          title: "Geçici (Transient / Bildirim) Genişlik"
          subtitle: "Bildirim geldiğinde çentiğin genişliği."
          value: root.notchTransientW
          minValue: 220
          maxValue: 600
          step: 10
          unit: "px"
          onValueModified: val => { root.notchTransientW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "💬"
          title: "Geçici (Transient / Bildirim) Yükseklik"
          subtitle: "Bildirim geldiğinde çentiğin yüksekliği."
          value: root.notchTransientH
          minValue: 30
          maxValue: 90
          step: 2
          unit: "px"
          onValueModified: val => { root.notchTransientH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📱"
          title: "Genişletilmiş (Expanded) Genişlik"
          subtitle: "Tam uygulama panelleri açıkken çentiğin genişliği."
          value: root.notchExpandedW
          minValue: 320
          maxValue: 900
          step: 10
          unit: "px"
          onValueModified: val => { root.notchExpandedW = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "📱"
          title: "Genişletilmiş (Expanded) Yükseklik"
          subtitle: "Tam uygulama panelleri açıkken çentiğin yüksekliği."
          value: root.notchExpandedH
          minValue: 160
          maxValue: 600
          step: 5
          unit: "px"
          onValueModified: val => { root.notchExpandedH = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔘"
          title: "Alt Bézier Kavis Yarıçapı"
          subtitle: "Çentiğin alt köşelerindeki yumuşak organik kavis yarıçapı."
          value: root.notchRadiusBottom
          minValue: 8
          maxValue: 40
          step: 1
          unit: "px"
          onValueModified: val => { root.notchRadiusBottom = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🔘"
          title: "Genişletilmiş Alt Kavis Yarıçapı"
          subtitle: "Genişletilmiş pencerelerde çentiğin alt kavis yarıçapı."
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

    // =========================================================================
    // 5. SPRING PHYSICS & ANIMATION DURATIONS
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Fizik ve Yay Animasyonları"
      }

      SettingsCard {
        SettingsNumberRow {
          iconText: "⚡"
          iconColor: Style.accentYellow
          title: "Kompakt Geçiş Süresi"
          subtitle: "Boşta ve hover arasındaki pürüzsüz yay animasyonu süresi."
          value: root.animCompact
          minValue: 100
          maxValue: 800
          step: 25
          unit: "ms"
          onValueModified: val => { root.animCompact = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "⚡"
          iconColor: Style.accentYellow
          title: "Geçici (Bildirim) Geçiş Süresi"
          subtitle: "Bildirim açılış ve kapanış yay animasyonu süresi."
          value: root.animTransient
          minValue: 100
          maxValue: 800
          step: 25
          unit: "ms"
          onValueModified: val => { root.animTransient = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "⚡"
          iconColor: Style.accentYellow
          title: "Genişletilmiş Panel Süresi"
          subtitle: "Tam boyutlu uygulama panellerinin açılış süresi."
          value: root.animExpanded
          minValue: 100
          maxValue: 1000
          step: 25
          unit: "ms"
          onValueModified: val => { root.animExpanded = val; root.applyAndSave() }
        }

        SettingsNumberRow {
          iconText: "🧲"
          iconColor: Style.accentMagenta
          title: "Yay / Esneme Çarpanı (Overshoot)"
          subtitle: "Animasyonun hedefine ulaşırken yaptığı esneme ve sıçrama katsayısı."
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
