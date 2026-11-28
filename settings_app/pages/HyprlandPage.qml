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

  contentWidth: width
  contentHeight: mainCol.implicitHeight + 52
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  // =========================================================================
  // Reactive Backend State Bindings
  // =========================================================================
  readonly property var hyprData: (ipc && ipc.hyprState) ? ipc.hyprState : null
  readonly property var activeProfiles: (hyprData && hyprData.active) ? hyprData.active : ({})
  readonly property var availableProfiles: (hyprData && hyprData.available) ? hyprData.available : ({})
  readonly property var monitorList: (availableProfiles && availableProfiles.monitors) ? availableProfiles.monitors : []
  readonly property var appearancePresets: (hyprData && hyprData.appearance_presets) ? hyprData.appearance_presets : []
  readonly property var animationPresets: (hyprData && hyprData.animation_presets) ? hyprData.animation_presets : []
  readonly property var availableCurves: (hyprData && hyprData.available_curves && hyprData.available_curves.length > 0)
    ? hyprData.available_curves
    : ["easeOutQuint", "easeOutExpo", "easeInOutCubic", "quick", "snappyQuick", "overshoot", "easeOutBack", "gentle", "smoothSlide", "linear", "springSoft", "springBouncy", "springGentle"]

  property bool gameMode: false
  property string activeAppearancePreset: "minimal"
  property string activeAnimationPreset: "macos"
  property string expandedAnimKey: "windows_in"
  property string newAppearancePresetName: ""
  property string newAnimationPresetName: ""
  property bool _syncingFromBackend: false

  // Local working clone of Appearance & Blur
  property var appCfg: ({
    "border_size": 1,
    "border_color_mode": "theme",
    "active_border_color": "89b4faff",
    "active_border_color_2": "cba6f7ff",
    "border_gradient_angle": 45,
    "inactive_border_color": "313244cc",
    "gaps_in": 4, "gaps_out": 1,
    "rounding": 10, "rounding_power": 4.0,
    "active_opacity": 1.0, "inactive_opacity": 0.96,
    "shadow_enabled": true, "shadow_range": 15, "shadow_render_power": 2,
    "dim_inactive": false, "dim_strength": 0.08,
    "blur": {
      "enabled": true, "variant": "kawase", "size": 6, "passes": 3,
      "ignore_opacity": true, "new_optimizations": true, "xray": false,
      "proportional": false, "noise": 0.012, "contrast": 0.90, "brightness": 1.0,
      "vibrancy": 0.17, "vibrancy_darkness": 0.0, "special": false, "popups": true,
      "glass": { "refraction": 8, "size": 48, "roughness": 0.45 },
      "acrylic": { "refraction": 20, "bulb": 48, "clarity": 0.82, "aberration": 0.025, "tint": "14eef5ff" },
      "drops": { "speed": 2.0 },
      "heat_shimmer": { "speed": 1.0 },
      "aurora": { "speed": 1.0, "intensity": 0.35, "color1": "29f0a0ff", "color2": "7a4dffff" },
      "haze": { "intensity": 0.35, "iridescence": 0.70 },
      "ripple": { "strength": 24, "radius": 400, "width": 32, "duration": 0.45 },
      "water": { "strength": 24, "radius": 20, "speed": 0.76, "damping": 0.95, "duration": 10.0 },
      "fluid_jar": { "speed": 3.0, "fill_amount": 0.50, "mass": 1.4, "precision": 2.0, "turbulence": 1.2, "distortion": 6.0, "color": "cc3399ff" }
    }
  })

  // Curated Border Color Swatches (RRGGBB)
  readonly property var activeBorderSwatches: [
    "#ffffff", "#ebbcba", "#c4a7e7", "#7aa2f7", "#88c0d0",
    "#a7c080", "#f6c177", "#e69875", "#eb6f92", "#9ccfd8"
  ]
  readonly property var inactiveBorderSwatches: [
    "#1f1d2ecc", "#2a2838cc", "#313244cc", "#3b4252cc",
    "#444444aa", "#55555588", "#00000000"
  ]

  function cleanHexInput(raw) {
    let s = (raw || "").trim().replace(/^#/, "").replace(/^0x/i, "").toLowerCase()
    if (/^[0-9a-f]{6}$/.test(s)) return s + "ff"
    if (/^[0-9a-f]{8}$/.test(s)) return s
    return ""
  }

  function formatHexDisplay(raw, fallback) {
    let s = (raw || fallback || "89b4faff").trim().replace(/^#/, "").replace(/^0x/i, "").toLowerCase()
    if (s.length === 8 && s.endsWith("ff")) return "#" + s.substring(0, 6)
    return "#" + s
  }

  function hex8ToQColor(raw, fallback) {
    let s = (raw || "").trim().replace(/^#/, "").replace(/^0x/i, "").toLowerCase()
    if (/^[0-9a-f]{6}$/.test(s)) return "#" + s
    if (/^[0-9a-f]{8}$/.test(s)) {
      // Hyprland uses RRGGBBAA; Qt QML color uses #AARRGGBB
      return "#" + s.substring(6, 8) + s.substring(0, 6)
    }
    return fallback
  }

  readonly property bool isCustomBorderColor: (root.appCfg.border_color_mode || "theme") === "custom"
  readonly property bool hasBorderGradient: isCustomBorderColor && (root.appCfg.active_border_color_2 || "").trim().length > 0
  readonly property color previewActiveBorderColor: isCustomBorderColor
    ? hex8ToQColor(root.appCfg.active_border_color, Style.accent)
    : Style.accent

  // Local working clone of 7-Leaf Animations
  property var animCfg: ({
    "enabled": true,
    "windows_in":   { "enabled": true, "speed": 4.2, "bezier": "easeOutQuint", "style": "popin 88%" },
    "windows_out":  { "enabled": true, "speed": 3.5, "bezier": "easeInOutCubic", "style": "popin 88%" },
    "windows_move": { "enabled": true, "speed": 4.5, "bezier": "easeOutQuint", "style": "" },
    "workspaces":   { "enabled": true, "speed": 4.8, "bezier": "easeOutQuint", "style": "slidefade 18%" },
    "layers":       { "enabled": true, "speed": 3.6, "bezier": "easeOutQuint", "style": "popin 85%" },
    "fade":         { "enabled": true, "speed": 3.2, "bezier": "almostLinear", "style": "" },
    "border":       { "enabled": true, "speed": 5.0, "bezier": "easeOutQuint", "style": "" }
  })

  // Hyprland 0.57.2 Blur Variant Metadata
  readonly property var blurVariants: [
    { "id": "kawase",       "label": "Kawase",       "desc": "Klasik yüksek performanslı yumuşak bulanıklık (GPU dostu)." },
    { "id": "acrylic",      "label": "Acrylic",      "desc": "Liquid Glass / akrilik lens kırılması, kromatik sapma ve parlaklık." },
    { "id": "frost",        "label": "Frost",        "desc": "Buzlu cam dokusu, yüzey pürüzlülüğü ve ışık kırılması." },
    { "id": "prism",        "label": "Prism",        "desc": "Prizmatik cam kırılması ve dokulu ışık dağılımı." },
    { "id": "haze",         "label": "Haze",         "desc": "İnci parıltılı ve renk geçişli (iridescence) sis efekti." },
    { "id": "aurora",       "label": "Aurora",       "desc": "Hareketli kuzey ışıkları renk perdesi (animasyonlu GPU efekti)." },
    { "id": "water",        "label": "Water",        "desc": "İmleç hareketine tepki veren canlı su yüzeyi dalgalanması." },
    { "id": "ripple",       "label": "Ripple",       "desc": "Tıklama noktalarından yayılan cam kırılma dalgaları." },
    { "id": "drops",        "label": "Drops",        "desc": "Pencere arkasında akan yağmur damlaları kırılma efekti." },
    { "id": "heat_shimmer", "label": "Heat Shimmer", "desc": "Sıcak hava dalgası gibi titreşen arka plan kırılması." },
    { "id": "fluid_jar",    "label": "Fluid Jar",    "desc": "Türbülanslı ve kütleli sıvı simülasyonu efekti." }
  ]

  readonly property string activeBlurVariantDesc: {
    let v = (appCfg && appCfg.blur && appCfg.blur.variant) ? appCfg.blur.variant : "kawase"
    for (let i = 0; i < blurVariants.length; i++) {
      if (blurVariants[i].id === v) return blurVariants[i].desc
    }
    return ""
  }

  // 7-Leaf Animation Metadata
  readonly property var animLeavesMeta: [
    { "key": "windows_in",   "title": "Pencere Açılış",      "icon": "󰖲", "styles": ["popin 88%", "popin 80%", "popin 60%", "slide", "gnomed"] },
    { "key": "windows_out",  "title": "Pencere Kapanış",     "icon": "󰅙", "styles": ["popin 88%", "popin 80%", "popin 60%", "slide", "gnomed"] },
    { "key": "windows_move", "title": "Pencere Taşıma",      "icon": "󰆾", "styles": [] },
    { "key": "workspaces",   "title": "Çalışma Alanı",       "icon": "󰍹", "styles": ["slide", "slidevert", "fade", "slidefade 18%", "slidefadevert 20%"] },
    { "key": "layers",       "title": "Katmanlar & Menüler", "icon": "󰌨", "styles": ["popin 85%", "fade", "slide"] },
    { "key": "fade",         "title": "Solma (Fade)",        "icon": "󰂵", "styles": [] },
    { "key": "border",       "title": "Aktif Kenarlık",      "icon": "󰆞", "styles": [] }
  ]

  function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj))
  }

  function syncFromState(payload) {
    if (!payload || !payload.config) return
    _syncingFromBackend = true
    let c = payload.config
    root.gameMode = !!c.game_mode
    root.activeAppearancePreset = c.active_appearance_preset || ""
    root.activeAnimationPreset = c.active_animation_preset || ""
    if (c.appearance) root.appCfg = deepClone(c.appearance)
    if (c.animations) root.animCfg = deepClone(c.animations)
    _syncingFromBackend = false
  }

  // Debounced Auto-Save + 0ms Live Apply Timers
  Timer {
    id: appearanceCommitTimer
    interval: 90
    repeat: false
    onTriggered: {
      if (root.ipc) root.ipc.applyHyprAppearance(root.appCfg, root.activeAppearancePreset)
    }
  }

  Timer {
    id: animationCommitTimer
    interval: 90
    repeat: false
    onTriggered: {
      if (root.ipc) root.ipc.applyHyprAnimations(root.animCfg, root.activeAnimationPreset)
    }
  }

  function updateAppField(key, val) {
    if (_syncingFromBackend) return
    let next = deepClone(root.appCfg)
    next[key] = val
    root.appCfg = next
    root.activeAppearancePreset = ""
    appearanceCommitTimer.restart()
  }

  function updateBlurField(key, val) {
    if (_syncingFromBackend) return
    let next = deepClone(root.appCfg)
    if (!next.blur) next.blur = {}
    next.blur[key] = val
    root.appCfg = next
    root.activeAppearancePreset = ""
    appearanceCommitTimer.restart()
  }

  function updateBlurSubField(group, key, val) {
    if (_syncingFromBackend) return
    let next = deepClone(root.appCfg)
    if (!next.blur) next.blur = {}
    if (!next.blur[group]) next.blur[group] = {}
    next.blur[group][key] = val
    root.appCfg = next
    root.activeAppearancePreset = ""
    appearanceCommitTimer.restart()
  }

  function updateAnimGlobal(enabled) {
    if (_syncingFromBackend) return
    let next = deepClone(root.animCfg)
    next.enabled = enabled
    root.animCfg = next
    root.activeAnimationPreset = ""
    animationCommitTimer.restart()
  }

  function updateAnimLeaf(leafKey, field, val) {
    if (_syncingFromBackend) return
    let next = deepClone(root.animCfg)
    if (!next[leafKey]) next[leafKey] = { "enabled": true, "speed": 4.0, "bezier": "easeOutQuint", "style": "" }
    next[leafKey][field] = val
    root.animCfg = next
    root.activeAnimationPreset = ""
    animationCommitTimer.restart()
  }

  function hydrateFromIpc() {
    if (!ipc) return
    if (ipc.hyprState) syncFromState(ipc.hyprState)
    ipc.getHyprState()
  }

  onIpcChanged: hydrateFromIpc()

  Component.onCompleted: hydrateFromIpc()

  Component.onDestruction: {
    // Flush any pending debounced appearance/animation changes before page unloads
    if (appearanceCommitTimer.running) {
      appearanceCommitTimer.stop()
      if (root.ipc) root.ipc.applyHyprAppearance(root.appCfg, root.activeAppearancePreset)
    }
    if (animationCommitTimer.running) {
      animationCommitTimer.stop()
      if (root.ipc) root.ipc.applyHyprAnimations(root.animCfg, root.activeAnimationPreset)
    }
  }

  Connections {
    target: root.ipc
    function onHyprStateReceived(payload) {
      if (!appearanceCommitTimer.running && !animationCommitTimer.running) {
        root.syncFromState(payload)
      }
    }
  }

  // =========================================================================
  // MAIN SCROLLABLE PAGE CONTENT (Option A: Clean Presets + Collapsible Drawers)
  // =========================================================================
  ColumnLayout {
    id: mainCol
    width: parent.width - 48
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 22
    spacing: 22

    // =======================================================================
    // 1. QUICK CONTROLS: GAME MODE & MONITOR PROFILES
    // =======================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Hızlı Kontroller"
      }

      SettingsCard {
        SettingsRow {
          iconText: root.gameMode ? "󰊗" : "󰮂"
          iconColor: root.gameMode ? Style.accentOrange : Style.textSecondary
          title: "Oyun ve Performans Modu (Game Mode)"
          subtitle: root.gameMode
            ? "Aktif — animasyon, blur, gölge ve boşluklar geçici kapatıldı."
            : "Tek tıkla tüm efektleri geçici kapatır; çıkınca ayarlarınız aynen geri döner."
          showDivider: root.monitorList.length > 0

          SettingsToggle {
            checked: root.gameMode
            onToggled: isChecked => {
              root.gameMode = isChecked
              if (root.ipc) root.ipc.setHyprGameMode(isChecked)
              root.notifyToast(isChecked ? "Oyun Modu etkinleştirildi." : "Oyun Modu kapatıldı, ayarlar geri yüklendi.", false)
            }
          }
        }

        SettingsRow {
          visible: root.monitorList.length > 0
          iconText: "󰍹"
          title: "Monitör Profili"
          subtitle: "Aktif düzen: " + (root.activeProfiles.monitor_profile || "-")
          showDivider: false

          RowLayout {
            spacing: 6

            Repeater {
              model: root.monitorList

              delegate: Rectangle {
                required property string modelData
                readonly property bool isSel: root.activeProfiles.monitor_profile === modelData
                height: 26
                implicitWidth: monTxt.implicitWidth + 16
                radius: 6
                color: isSel ? Qt.alpha(Style.accent, 0.16) : (monMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSel ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: monTxt
                  anchors.centerIn: parent
                  text: modelData.replace(/_/g, " ")
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: isSel ? Font.DemiBold : Font.Medium
                  color: isSel ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: monMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root.ipc && !isSel) {
                      root.ipc.setHyprProfile("monitor", modelData)
                      root.notifyToast("Monitör profili: " + modelData, false)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // =======================================================================
    // 2. WINDOW APPEARANCE PRESETS + COLLAPSIBLE FINE-TUNE DRAWER
    // =======================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Pencere Görünümü"
      }

      // Preset Cards Grid
      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
          model: root.appearancePresets

          delegate: Rectangle {
            required property var modelData
            readonly property bool isSel: root.activeAppearancePreset === modelData.id
            Layout.fillWidth: true
            implicitHeight: 74
            radius: 10
            color: isSel ? Qt.alpha(Style.accent, 0.12) : (apMouse.containsMouse ? Style.surfaceHover : Style.appCard)
            border.color: isSel ? Style.accent : (apMouse.containsMouse ? Style.borderHover : Style.appBorder)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 4

              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                  text: modelData.name
                  font.family: Style.fontText
                  font.pixelSize: 13
                  font.weight: isSel ? Font.DemiBold : Font.Medium
                  color: isSel ? Style.accent : Style.textPrimary
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  visible: isSel && modelData.builtin
                  text: "󰄬"
                  font.pixelSize: 13
                  color: Style.accent
                }

                // Delete icon for user custom presets
                Text {
                  visible: !modelData.builtin
                  text: "󰅖"
                  font.pixelSize: 12
                  color: delApMouse.containsMouse ? Style.accentRed : Style.textMuted

                  MouseArea {
                    id: delApMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                      mouse.accepted = true
                      if (root.ipc) {
                        root.ipc.deleteHyprPreset("appearance", modelData.id)
                        root.notifyToast(modelData.name + " silindi.", false)
                      }
                    }
                  }
                }
              }

              Text {
                text: modelData.description || ""
                font.family: Style.fontText
                font.pixelSize: 10
                color: Style.textMuted
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            MouseArea {
              id: apMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              z: -1
              onClicked: {
                if (root.ipc) {
                  root.ipc.applyHyprPreset("appearance", modelData.id)
                  root.notifyToast("Görünüm preseti: " + modelData.name, false)
                }
              }
            }
          }
        }
      }

      // Collapsible Appearance Fine-Tuning Drawer
      SettingsCollapsibleSection {
        title: "Kenarlık, Boşluk, Gölge ve Opaklık"
        subtitle: "Değişiklikler 0ms canlı uygulanır ve otomatik kaydedilir"
        iconText: "󰆞"
        expanded: false

        // Live Window Preview
        Item {
          Layout.fillWidth: true
          implicitHeight: 112

          Rectangle {
            anchors.fill: parent
            anchors.margins: 14
            radius: 10
            color: Style.appBackground
            border.color: Style.appBorder
            border.width: 1

            Rectangle {
              anchors.centerIn: parent
              width: 210
              height: 62
              radius: root.appCfg.rounding || 0
              color: Style.appCard
              opacity: root.appCfg.active_opacity || 1.0
              border.color: root.previewActiveBorderColor
              border.width: root.appCfg.border_size || 0

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Kenarlık " + (root.appCfg.border_size || 0) + "px • Köşe " + (root.appCfg.rounding || 0) + "px"
                  font.family: Style.fontText; font.pixelSize: 11; font.weight: Font.Medium; color: Style.textPrimary
                }
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Boşluk " + (root.appCfg.gaps_in || 0) + "/" + (root.appCfg.gaps_out || 0) + "px • Opaklık %" + Math.round((root.appCfg.active_opacity || 1) * 100)
                  font.family: Style.fontText; font.pixelSize: 10; color: Style.textMuted
                }
              }
            }
          }
        }

        SettingsSliderRow {
          title: "Kenarlık Kalınlığı"
          value: root.appCfg.border_size || 0
          minValue: 0; maxValue: 8; step: 1; unit: "px"
          onValueModified: v => root.updateAppField("border_size", Math.round(v))
        }

        // Border Color Mode (Theme-synced vs Custom Color / Gradient)
        SettingsRow {
          iconText: "󰏘"
          iconColor: root.previewActiveBorderColor
          title: "Kenarlık Rengi"
          subtitle: root.isCustomBorderColor
            ? (root.hasBorderGradient ? "Özel çift renkli gradyan kenarlık" : "Özel tek renk kenarlık")
            : "Aktif sistem temasıyla otomatik senkronize"
          showDivider: true

          RowLayout {
            spacing: 6

            Repeater {
              model: [
                { "id": "theme",  "label": "Temaya Uyumlu" },
                { "id": "custom", "label": "Özel Renk" }
              ]

              delegate: Rectangle {
                required property var modelData
                readonly property bool isSel: (root.appCfg.border_color_mode || "theme") === modelData.id
                height: 26
                implicitWidth: bmTxt.implicitWidth + 16
                radius: 6
                color: isSel ? Qt.alpha(Style.accent, 0.16) : (bmMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSel ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: bmTxt
                  anchors.centerIn: parent
                  text: modelData.label
                  font.family: Style.fontText; font.pixelSize: 11
                  font.weight: isSel ? Font.DemiBold : Font.Medium
                  color: isSel ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: bmMouse
                  anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.updateAppField("border_color_mode", modelData.id)
                    root.notifyToast(modelData.id === "theme" ? "Kenarlık rengi temaya bağlandı." : "Özel kenarlık rengi etkinleştirildi.", false)
                  }
                }
              }
            }
          }
        }

        // Custom Border Color Picker Panel (Progressive Disclosure when Custom selected)
        ColumnLayout {
          visible: root.isCustomBorderColor
          Layout.fillWidth: true
          spacing: 0

          // Active Primary Color
          ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14; Layout.rightMargin: 14
            Layout.topMargin: 10; Layout.bottomMargin: 10
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: "Aktif Kenarlık Rengi"
                font.family: Style.fontText; font.pixelSize: 12; font.weight: Font.Medium
                color: Style.textPrimary
                Layout.fillWidth: true
              }

              Rectangle {
                width: 18; height: 18; radius: 5
                color: root.hex8ToQColor(root.appCfg.active_border_color, Style.accent)
                border.color: Style.appBorder; border.width: 1
              }

              Rectangle {
                width: 96; height: 26; radius: 6
                color: Style.appBackground
                border.color: actColIn.activeFocus ? Style.accent : Style.appBorder
                border.width: 1

                TextInput {
                  id: actColIn
                  anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                  verticalAlignment: TextInput.AlignVCenter
                  color: Style.textPrimary; font.family: "Monospace"; font.pixelSize: 11
                  selectByMouse: true
                  text: root.formatHexDisplay(root.appCfg.active_border_color, "89b4faff")
                  onEditingFinished: {
                    let cleaned = root.cleanHexInput(text)
                    if (cleaned !== "") root.updateAppField("active_border_color", cleaned)
                    else text = root.formatHexDisplay(root.appCfg.active_border_color, "89b4faff")
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              spacing: 7

              Repeater {
                model: root.activeBorderSwatches
                delegate: Rectangle {
                  required property string modelData
                  readonly property string normVal: root.cleanHexInput(modelData)
                  readonly property bool isCur: root.cleanHexInput(root.appCfg.active_border_color) === normVal
                  width: 24; height: 24; radius: 12
                  color: modelData
                  border.color: isCur ? "#ffffff" : Qt.rgba(1, 1, 1, 0.22)
                  border.width: isCur ? 2 : 1
                  scale: sw1Mouse.containsMouse ? 1.12 : 1.0
                  Behavior on scale { NumberAnimation { duration: 100 } }

                  MouseArea {
                    id: sw1Mouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.updateAppField("active_border_color", normVal)
                  }
                }
              }
            }
          }

          Rectangle { Layout.fillWidth: true; Layout.leftMargin: 14; Layout.rightMargin: 14; height: 1; color: Style.appBorder; opacity: 0.6 }

          // Gradient Toggle & 2nd Color
          SettingsRow {
            title: "İkinci Renk (Gradyan Geçiş)"
            subtitle: "Aktif pencere kenarlığında iki renk arasında akıcı geçiş oluşturur."
            showDivider: false

            SettingsToggle {
              checked: root.hasBorderGradient
              onToggled: isOn => {
                root.updateAppField("active_border_color_2", isOn ? "cba6f7ff" : "")
              }
            }
          }

          ColumnLayout {
            visible: root.hasBorderGradient
            Layout.fillWidth: true
            Layout.leftMargin: 14; Layout.rightMargin: 14
            Layout.bottomMargin: 8
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: "İkinci Gradyan Rengi"
                font.family: Style.fontText; font.pixelSize: 12; font.weight: Font.Medium
                color: Style.textSecondary
                Layout.fillWidth: true
              }

              Rectangle {
                width: 18; height: 18; radius: 5
                color: root.hex8ToQColor(root.appCfg.active_border_color_2, Style.accentSecondary)
                border.color: Style.appBorder; border.width: 1
              }

              Rectangle {
                width: 96; height: 26; radius: 6
                color: Style.appBackground
                border.color: actCol2In.activeFocus ? Style.accent : Style.appBorder
                border.width: 1

                TextInput {
                  id: actCol2In
                  anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                  verticalAlignment: TextInput.AlignVCenter
                  color: Style.textPrimary; font.family: "Monospace"; font.pixelSize: 11
                  selectByMouse: true
                  text: root.formatHexDisplay(root.appCfg.active_border_color_2, "cba6f7ff")
                  onEditingFinished: {
                    let cleaned = root.cleanHexInput(text)
                    if (cleaned !== "") root.updateAppField("active_border_color_2", cleaned)
                    else text = root.formatHexDisplay(root.appCfg.active_border_color_2, "cba6f7ff")
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              spacing: 7

              Repeater {
                model: root.activeBorderSwatches
                delegate: Rectangle {
                  required property string modelData
                  readonly property string normVal: root.cleanHexInput(modelData)
                  readonly property bool isCur: root.cleanHexInput(root.appCfg.active_border_color_2) === normVal
                  width: 24; height: 24; radius: 12
                  color: modelData
                  border.color: isCur ? "#ffffff" : Qt.rgba(1, 1, 1, 0.22)
                  border.width: isCur ? 2 : 1
                  scale: sw2Mouse.containsMouse ? 1.12 : 1.0
                  Behavior on scale { NumberAnimation { duration: 100 } }

                  MouseArea {
                    id: sw2Mouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.updateAppField("active_border_color_2", normVal)
                  }
                }
              }
            }
          }

          SettingsSliderRow {
            visible: root.hasBorderGradient
            title: "Gradyan Açısı"
            value: root.appCfg.border_gradient_angle !== undefined ? root.appCfg.border_gradient_angle : 45
            minValue: 0; maxValue: 360; step: 15; unit: "°"
            showDivider: false
            onValueModified: v => root.updateAppField("border_gradient_angle", Math.round(v))
          }

          Rectangle { Layout.fillWidth: true; Layout.leftMargin: 14; Layout.rightMargin: 14; height: 1; color: Style.appBorder; opacity: 0.6 }

          // Inactive Border Color
          ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14; Layout.rightMargin: 14
            Layout.topMargin: 10; Layout.bottomMargin: 10
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: "Pasif Kenarlık Rengi"
                font.family: Style.fontText; font.pixelSize: 12; font.weight: Font.Medium
                color: Style.textPrimary
                Layout.fillWidth: true
              }

              Rectangle {
                width: 18; height: 18; radius: 5
                color: root.hex8ToQColor(root.appCfg.inactive_border_color, "#313244")
                border.color: Style.appBorder; border.width: 1
              }

              Rectangle {
                width: 96; height: 26; radius: 6
                color: Style.appBackground
                border.color: inactColIn.activeFocus ? Style.accent : Style.appBorder
                border.width: 1

                TextInput {
                  id: inactColIn
                  anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                  verticalAlignment: TextInput.AlignVCenter
                  color: Style.textPrimary; font.family: "Monospace"; font.pixelSize: 11
                  selectByMouse: true
                  text: root.formatHexDisplay(root.appCfg.inactive_border_color, "313244cc")
                  onEditingFinished: {
                    let cleaned = root.cleanHexInput(text)
                    if (cleaned !== "") root.updateAppField("inactive_border_color", cleaned)
                    else text = root.formatHexDisplay(root.appCfg.inactive_border_color, "313244cc")
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              spacing: 7

              Repeater {
                model: root.inactiveBorderSwatches
                delegate: Rectangle {
                  required property string modelData
                  readonly property string normVal: root.cleanHexInput(modelData)
                  readonly property bool isCur: root.cleanHexInput(root.appCfg.inactive_border_color) === normVal
                  width: 24; height: 24; radius: 12
                  color: root.hex8ToQColor(modelData, "#313244")
                  border.color: isCur ? Style.accent : Qt.rgba(1, 1, 1, 0.25)
                  border.width: isCur ? 2 : 1
                  scale: sw3Mouse.containsMouse ? 1.12 : 1.0
                  Behavior on scale { NumberAnimation { duration: 100 } }

                  Text {
                    visible: modelData === "#00000000"
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.pixelSize: 10
                    color: Style.textMuted
                  }

                  MouseArea {
                    id: sw3Mouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.updateAppField("inactive_border_color", normVal)
                  }
                }
              }
            }
          }

          Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder; opacity: 0.7 }
        }
        SettingsSliderRow {
          title: "Köşe Yuvarlama (Rounding)"
          value: root.appCfg.rounding || 0
          minValue: 0; maxValue: 28; step: 1; unit: "px"
          onValueModified: v => root.updateAppField("rounding", Math.round(v))
        }
        SettingsSliderRow {
          title: "Squircle Eğrilik (Rounding Power)"
          subtitle: "2.0 Dairesel • 4.0 iOS Squircle • 10.0 Keskin"
          value: root.appCfg.rounding_power || 4.0
          minValue: 2.0; maxValue: 10.0; step: 0.5; decimals: 1; unit: "x"
          onValueModified: v => root.updateAppField("rounding_power", v)
        }
        SettingsSliderRow {
          title: "Pencereler Arası Boşluk (Gaps In)"
          value: root.appCfg.gaps_in || 0
          minValue: 0; maxValue: 30; step: 1; unit: "px"
          onValueModified: v => root.updateAppField("gaps_in", Math.round(v))
        }
        SettingsSliderRow {
          title: "Ekran Kenarı Boşluğu (Gaps Out)"
          value: root.appCfg.gaps_out || 0
          minValue: 0; maxValue: 40; step: 1; unit: "px"
          onValueModified: v => root.updateAppField("gaps_out", Math.round(v))
        }
        SettingsRow {
          title: "Pencere Gölgesi"
          showDivider: true
          SettingsToggle {
            checked: !!root.appCfg.shadow_enabled
            onToggled: v => root.updateAppField("shadow_enabled", v)
          }
        }
        SettingsSliderRow {
          visible: !!root.appCfg.shadow_enabled
          title: "Gölge Yayılımı"
          value: root.appCfg.shadow_range || 15
          minValue: 4; maxValue: 60; step: 2; unit: "px"
          onValueModified: v => root.updateAppField("shadow_range", Math.round(v))
        }
        SettingsSliderRow {
          title: "Aktif Pencere Opaklığı"
          value: Math.round((root.appCfg.active_opacity || 1.0) * 100)
          minValue: 50; maxValue: 100; step: 2; prefix: "%"
          onValueModified: v => root.updateAppField("active_opacity", v / 100.0)
        }
        SettingsSliderRow {
          title: "Pasif Pencere Opaklığı"
          value: Math.round((root.appCfg.inactive_opacity || 0.95) * 100)
          minValue: 50; maxValue: 100; step: 2; prefix: "%"
          showDivider: true
          onValueModified: v => root.updateAppField("inactive_opacity", v / 100.0)
        }
        SettingsRow {
          title: "Pasif Pencereyi Karart (Dim Inactive)"
          subtitle: "Kenarlıksız kullanımda odak dışı pencereleri hafifçe karartarak aktif pencereyi öne çıkarır."
          showDivider: true
          SettingsToggle {
            checked: !!root.appCfg.dim_inactive
            onToggled: v => root.updateAppField("dim_inactive", v)
          }
        }
        SettingsSliderRow {
          visible: !!root.appCfg.dim_inactive
          title: "Karartma Şiddeti"
          value: Math.round((root.appCfg.dim_strength || 0.08) * 100)
          minValue: 2; maxValue: 40; step: 2; prefix: "%"
          showDivider: true
          onValueModified: v => root.updateAppField("dim_strength", v / 100.0)
        }

        // Save Current Appearance as Preset
        Item {
          Layout.fillWidth: true
          implicitHeight: 54

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 8

            Rectangle {
              Layout.fillWidth: true
              height: 32; radius: 7
              color: Style.appBackground
              border.color: appSaveIn.activeFocus ? Style.accent : Style.appBorder
              border.width: 1

              TextInput {
                id: appSaveIn
                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Style.textPrimary; font.family: Style.fontText; font.pixelSize: 12
                text: root.newAppearancePresetName
                onTextChanged: root.newAppearancePresetName = text
                Text {
                  anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                  text: "Mevcut görünümü yeni preset olarak adlandır..."
                  color: Style.textMuted; font.family: Style.fontText; font.pixelSize: 11
                  visible: appSaveIn.text.length === 0
                }
              }
            }

            SettingsButton {
              text: "Preset Kaydet"
              iconText: "󰆓"
              isAccent: true
              onClicked: {
                let nm = root.newAppearancePresetName.trim()
                if (nm === "") { root.notifyToast("Önce bir preset adı girin.", true); return }
                if (root.ipc) {
                  root.ipc.saveHyprPreset("appearance", nm, "Kenarlık " + root.appCfg.border_size + "px • " + (root.appCfg.blur ? root.appCfg.blur.variant : "kawase"))
                  root.newAppearancePresetName = ""
                  root.notifyToast("'" + nm + "' görünüm preseti kaydedildi.", false)
                }
              }
            }
          }
        }
      }
    }

    // =======================================================================
    // 3. HYPRLAND 0.57.2 BLUR STUDIO (11 Native Variants + Dynamic Controls)
    // =======================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Hyprland 0.57 Blur Stüdyosu"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰂵"
          iconColor: (root.appCfg.blur && root.appCfg.blur.enabled) ? Style.accent : Style.textMuted
          title: "Pencere Arka Plan Bulanıklığı (Blur)"
          subtitle: (root.appCfg.blur && root.appCfg.blur.enabled)
            ? root.activeBlurVariantDesc
            : "Blur shader devre dışı."
          showDivider: !!(root.appCfg.blur && root.appCfg.blur.enabled)

          SettingsToggle {
            checked: !!(root.appCfg.blur && root.appCfg.blur.enabled)
            onToggled: v => root.updateBlurField("enabled", v)
          }
        }

        // 11 Variant Selector Chips
        ColumnLayout {
          visible: !!(root.appCfg.blur && root.appCfg.blur.enabled)
          Layout.fillWidth: true
          Layout.margins: 14
          spacing: 10

          Text {
            text: "Blur Varyantı (Shader Efekti)"
            font.family: Style.fontText; font.pixelSize: 12; font.weight: Font.Medium; color: Style.textSecondary
          }

          Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
              model: root.blurVariants

              delegate: Rectangle {
                required property var modelData
                readonly property bool isSel: (root.appCfg.blur && root.appCfg.blur.variant === modelData.id)
                height: 28
                implicitWidth: bvTxt.implicitWidth + 18
                radius: 7
                color: isSel ? Qt.alpha(Style.accent, 0.16) : (bvMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSel ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  id: bvTxt
                  anchors.centerIn: parent
                  text: modelData.label
                  font.family: Style.fontText; font.pixelSize: 11
                  font.weight: isSel ? Font.DemiBold : Font.Medium
                  color: isSel ? Style.accent : Style.textPrimary
                }

                MouseArea {
                  id: bvMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.updateBlurField("variant", modelData.id)
                    root.notifyToast("Blur varyantı: " + modelData.label, false)
                  }
                }
              }
            }
          }
        }

        // Dynamic Variant-Specific Controls (Only active variant's knobs!)
        ColumnLayout {
          readonly property string v: (root.appCfg.blur && root.appCfg.blur.variant) ? root.appCfg.blur.variant : "kawase"
          visible: !!(root.appCfg.blur && root.appCfg.blur.enabled && v !== "kawase")
          Layout.fillWidth: true
          spacing: 0

          Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

          // GLASS (frost / prism / drops)
          SettingsSliderRow {
            visible: parent.v === "frost" || parent.v === "prism" || parent.v === "drops"
            title: "Cam Kırılması (Glass Refraction)"
            value: (root.appCfg.blur && root.appCfg.blur.glass) ? root.appCfg.blur.glass.refraction : 8
            minValue: 0; maxValue: 20; step: 1; unit: "px"
            onValueModified: val => root.updateBlurSubField("glass", "refraction", Math.round(val))
          }
          SettingsSliderRow {
            visible: parent.v === "frost" || parent.v === "prism"
            title: "Cam Desen Boyutu (Glass Size)"
            value: (root.appCfg.blur && root.appCfg.blur.glass) ? root.appCfg.blur.glass.size : 48
            minValue: 4; maxValue: 256; step: 4; unit: "px"
            onValueModified: val => root.updateBlurSubField("glass", "size", Math.round(val))
          }
          SettingsSliderRow {
            visible: parent.v === "frost" || parent.v === "prism" || parent.v === "drops"
            title: "Yüzey Pürüzlülüğü (Roughness)"
            value: (root.appCfg.blur && root.appCfg.blur.glass) ? root.appCfg.blur.glass.roughness : 0.45
            minValue: 0.0; maxValue: 1.0; step: 0.05; decimals: 2
            showDivider: parent.v === "drops"
            onValueModified: val => root.updateBlurSubField("glass", "roughness", val)
          }

          // ACRYLIC
          SettingsSliderRow {
            visible: parent.v === "acrylic"
            title: "Akrilik Lens Kırılması (Refraction)"
            value: (root.appCfg.blur && root.appCfg.blur.acrylic) ? root.appCfg.blur.acrylic.refraction : 20
            minValue: 0; maxValue: 48; step: 2; unit: "px"
            onValueModified: val => root.updateBlurSubField("acrylic", "refraction", Math.round(val))
          }
          SettingsSliderRow {
            visible: parent.v === "acrylic"
            title: "Kenar Kavis Genişliği (Bulb)"
            value: (root.appCfg.blur && root.appCfg.blur.acrylic) ? root.appCfg.blur.acrylic.bulb : 48
            minValue: 4; maxValue: 200; step: 4; unit: "px"
            onValueModified: val => root.updateBlurSubField("acrylic", "bulb", Math.round(val))
          }
          SettingsSliderRow {
            visible: parent.v === "acrylic"
            title: "Cam Berraklığı (Clarity)"
            value: (root.appCfg.blur && root.appCfg.blur.acrylic) ? root.appCfg.blur.acrylic.clarity : 0.82
            minValue: 0.0; maxValue: 1.0; step: 0.02; decimals: 2
            onValueModified: val => root.updateBlurSubField("acrylic", "clarity", val)
          }
          SettingsSliderRow {
            visible: parent.v === "acrylic"
            title: "Kromatik Sapma (Aberration)"
            value: (root.appCfg.blur && root.appCfg.blur.acrylic) ? root.appCfg.blur.acrylic.aberration : 0.025
            minValue: 0.0; maxValue: 0.25; step: 0.005; decimals: 3
            showDivider: false
            onValueModified: val => root.updateBlurSubField("acrylic", "aberration", val)
          }

          // DROPS
          SettingsSliderRow {
            visible: parent.v === "drops"
            title: "Yağmur Damlası Hızı (0 = Sabit)"
            value: (root.appCfg.blur && root.appCfg.blur.drops) ? root.appCfg.blur.drops.speed : 2.0
            minValue: 0.0; maxValue: 10.0; step: 0.5; decimals: 1
            showDivider: false
            onValueModified: val => root.updateBlurSubField("drops", "speed", val)
          }

          // HEAT SHIMMER
          SettingsSliderRow {
            visible: parent.v === "heat_shimmer"
            title: "Isı Titremesi Hızı (0 = Sabit)"
            value: (root.appCfg.blur && root.appCfg.blur.heat_shimmer) ? root.appCfg.blur.heat_shimmer.speed : 1.0
            minValue: 0.0; maxValue: 10.0; step: 0.5; decimals: 1
            showDivider: false
            onValueModified: val => root.updateBlurSubField("heat_shimmer", "speed", val)
          }

          // AURORA
          SettingsSliderRow {
            visible: parent.v === "aurora"
            title: "Aurora Hızı (0 = Dondur)"
            value: (root.appCfg.blur && root.appCfg.blur.aurora) ? root.appCfg.blur.aurora.speed : 1.0
            minValue: 0.0; maxValue: 10.0; step: 0.5; decimals: 1
            onValueModified: val => root.updateBlurSubField("aurora", "speed", val)
          }
          SettingsSliderRow {
            visible: parent.v === "aurora"
            title: "Aurora Renk Yoğunluğu"
            value: (root.appCfg.blur && root.appCfg.blur.aurora) ? root.appCfg.blur.aurora.intensity : 0.35
            minValue: 0.0; maxValue: 1.0; step: 0.05; decimals: 2
            showDivider: false
            onValueModified: val => root.updateBlurSubField("aurora", "intensity", val)
          }

          // HAZE
          SettingsSliderRow {
            visible: parent.v === "haze"
            title: "İnci Parıltısı Yoğunluğu (Intensity)"
            value: (root.appCfg.blur && root.appCfg.blur.haze) ? root.appCfg.blur.haze.intensity : 0.35
            minValue: 0.0; maxValue: 1.0; step: 0.05; decimals: 2
            onValueModified: val => root.updateBlurSubField("haze", "intensity", val)
          }
          SettingsSliderRow {
            visible: parent.v === "haze"
            title: "Renk Geçişi (Iridescence)"
            value: (root.appCfg.blur && root.appCfg.blur.haze) ? root.appCfg.blur.haze.iridescence : 0.70
            minValue: 0.0; maxValue: 1.0; step: 0.05; decimals: 2
            showDivider: false
            onValueModified: val => root.updateBlurSubField("haze", "iridescence", val)
          }

          // RIPPLE
          SettingsSliderRow {
            visible: parent.v === "ripple"
            title: "Tıklama Dalgası Gücü"
            value: (root.appCfg.blur && root.appCfg.blur.ripple) ? root.appCfg.blur.ripple.strength : 24
            minValue: 0; maxValue: 32; step: 1; unit: "px"
            onValueModified: val => root.updateBlurSubField("ripple", "strength", val)
          }
          SettingsSliderRow {
            visible: parent.v === "ripple"
            title: "Dalga Yarıçapı"
            value: (root.appCfg.blur && root.appCfg.blur.ripple) ? root.appCfg.blur.ripple.radius : 400
            minValue: 50; maxValue: 1000; step: 25; unit: "px"
            onValueModified: val => root.updateBlurSubField("ripple", "radius", Math.round(val))
          }
          SettingsSliderRow {
            visible: parent.v === "ripple"
            title: "Dalga Süresi"
            value: (root.appCfg.blur && root.appCfg.blur.ripple) ? root.appCfg.blur.ripple.duration : 0.45
            minValue: 0.1; maxValue: 3.0; step: 0.05; decimals: 2; unit: "sn"
            showDivider: false
            onValueModified: val => root.updateBlurSubField("ripple", "duration", val)
          }

          // WATER
          SettingsSliderRow {
            visible: parent.v === "water"
            title: "Su Kırılma Gücü"
            value: (root.appCfg.blur && root.appCfg.blur.water) ? root.appCfg.blur.water.strength : 24
            minValue: 0; maxValue: 32; step: 1; unit: "px"
            onValueModified: val => root.updateBlurSubField("water", "strength", val)
          }
          SettingsSliderRow {
            visible: parent.v === "water"
            title: "Su Yayılma Hızı"
            value: (root.appCfg.blur && root.appCfg.blur.water) ? root.appCfg.blur.water.speed : 0.76
            minValue: 0.0; maxValue: 5.0; step: 0.1; decimals: 2
            onValueModified: val => root.updateBlurSubField("water", "speed", val)
          }
          SettingsSliderRow {
            visible: parent.v === "water"
            title: "Sönümleme (Damping)"
            value: (root.appCfg.blur && root.appCfg.blur.water) ? root.appCfg.blur.water.damping : 0.95
            minValue: 0.50; maxValue: 0.99; step: 0.01; decimals: 2
            showDivider: false
            onValueModified: val => root.updateBlurSubField("water", "damping", val)
          }

          // FLUID JAR
          SettingsSliderRow {
            visible: parent.v === "fluid_jar"
            title: "Sıvı Hızı"
            value: (root.appCfg.blur && root.appCfg.blur.fluid_jar) ? root.appCfg.blur.fluid_jar.speed : 3.0
            minValue: 0.0; maxValue: 10.0; step: 0.5; decimals: 1
            onValueModified: val => root.updateBlurSubField("fluid_jar", "speed", val)
          }
          SettingsSliderRow {
            visible: parent.v === "fluid_jar"
            title: "Doluluk Oranı (Fill Amount)"
            value: (root.appCfg.blur && root.appCfg.blur.fluid_jar) ? root.appCfg.blur.fluid_jar.fill_amount : 0.50
            minValue: 0.0; maxValue: 1.0; step: 0.05; decimals: 2
            onValueModified: val => root.updateBlurSubField("fluid_jar", "fill_amount", val)
          }
          SettingsSliderRow {
            visible: parent.v === "fluid_jar"
            title: "Türbülans"
            value: (root.appCfg.blur && root.appCfg.blur.fluid_jar) ? root.appCfg.blur.fluid_jar.turbulence : 1.2
            minValue: 0.0; maxValue: 5.0; step: 0.2; decimals: 1
            onValueModified: val => root.updateBlurSubField("fluid_jar", "turbulence", val)
          }
          SettingsSliderRow {
            visible: parent.v === "fluid_jar"
            title: "Kırılma Bozulması (Distortion)"
            value: (root.appCfg.blur && root.appCfg.blur.fluid_jar) ? root.appCfg.blur.fluid_jar.distortion : 6.0
            minValue: 0.0; maxValue: 10.0; step: 0.5; decimals: 1
            showDivider: false
            onValueModified: val => root.updateBlurSubField("fluid_jar", "distortion", val)
          }
        }
      }

      // Collapsible Core Blur Parameters Drawer
      SettingsCollapsibleSection {
        visible: !!(root.appCfg.blur && root.appCfg.blur.enabled)
        title: "Temel Blur Parametreleri (Boyut, Geçiş, Canlılık, Xray)"
        subtitle: "Tüm blur varyantları için ortak mesafe, parlaklık ve performans ayarları"
        iconText: "󰒓"
        expanded: false

        SettingsSliderRow {
          title: "Blur Boyutu (Size)"
          value: (root.appCfg.blur && root.appCfg.blur.size !== undefined) ? root.appCfg.blur.size : 6
          minValue: 0; maxValue: 32; step: 1; unit: "px"
          onValueModified: v => root.updateBlurField("size", Math.round(v))
        }
        SettingsSliderRow {
          title: "Geçiş Sayısı (Passes)"
          subtitle: "Yüksek geçiş daha pürüzsüz blur verir (önerilen: 2–4)."
          value: (root.appCfg.blur && root.appCfg.blur.passes !== undefined) ? root.appCfg.blur.passes : 3
          minValue: 1; maxValue: 8; step: 1
          onValueModified: v => root.updateBlurField("passes", Math.round(v))
        }
        SettingsSliderRow {
          title: "Renk Canlılığı (Vibrancy)"
          value: (root.appCfg.blur && root.appCfg.blur.vibrancy !== undefined) ? root.appCfg.blur.vibrancy : 0.17
          minValue: 0.0; maxValue: 1.0; step: 0.05; decimals: 2
          onValueModified: v => root.updateBlurField("vibrancy", v)
        }
        SettingsSliderRow {
          title: "Kontrast"
          value: (root.appCfg.blur && root.appCfg.blur.contrast !== undefined) ? root.appCfg.blur.contrast : 0.90
          minValue: 0.2; maxValue: 2.0; step: 0.05; decimals: 2
          onValueModified: v => root.updateBlurField("contrast", v)
        }
        SettingsSliderRow {
          title: "Parlaklık (Brightness)"
          value: (root.appCfg.blur && root.appCfg.blur.brightness !== undefined) ? root.appCfg.blur.brightness : 1.0
          minValue: 0.2; maxValue: 2.0; step: 0.05; decimals: 2
          onValueModified: v => root.updateBlurField("brightness", v)
        }
        SettingsSliderRow {
          title: "Kumlanma (Noise)"
          value: (root.appCfg.blur && root.appCfg.blur.noise !== undefined) ? root.appCfg.blur.noise : 0.012
          minValue: 0.0; maxValue: 0.25; step: 0.005; decimals: 3
          onValueModified: v => root.updateBlurField("noise", v)
        }
        SettingsRow {
          title: "X-Ray Modu (Duvar Kağıdını Örnekle)"
          subtitle: "Yüzen pencereler arkadaki pencereler yerine duvar kağıdını bulanıklaştırır."
          showDivider: true
          SettingsToggle {
            checked: !!(root.appCfg.blur && root.appCfg.blur.xray)
            onToggled: v => root.updateBlurField("xray", v)
          }
        }
        SettingsRow {
          title: "Açılır Menülerde Blur (Popups)"
          subtitle: "Sağ tık menüleri ve açılır pencerelerde blur uygular."
          showDivider: false
          SettingsToggle {
            checked: !!(root.appCfg.blur && root.appCfg.blur.popups)
            onToggled: v => root.updateBlurField("popups", v)
          }
        }
      }
    }

    // =======================================================================
    // 4. 7-LEAF MODULAR ANIMATION PRESETS + PER-ANIMATION CUSTOMIZER DRAWER
    // =======================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Animasyon Hissiyatı"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰚗"
          iconColor: root.animCfg.enabled ? Style.accent : Style.textMuted
          title: "Hyprland Animasyonları"
          subtitle: root.animCfg.enabled ? "Aktif — 7 animasyon kanalı bağımsız yönetiliyor." : "Tüm animasyonlar devre dışı."
          showDivider: false

          SettingsToggle {
            checked: !!root.animCfg.enabled
            onToggled: v => {
              root.updateAnimGlobal(v)
              root.notifyToast(v ? "Animasyonlar açıldı." : "Animasyonlar kapatıldı.", false)
            }
          }
        }
      }

      // Animation Preset Cards Grid
      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
          model: root.animationPresets

          delegate: Rectangle {
            required property var modelData
            readonly property bool isSel: root.activeAnimationPreset === modelData.id
            Layout.fillWidth: true
            implicitHeight: 74
            radius: 10
            color: isSel ? Qt.alpha(Style.accent, 0.12) : (anMouse.containsMouse ? Style.surfaceHover : Style.appCard)
            border.color: isSel ? Style.accent : (anMouse.containsMouse ? Style.borderHover : Style.appBorder)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 4

              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                  text: modelData.name
                  font.family: Style.fontText; font.pixelSize: 13
                  font.weight: isSel ? Font.DemiBold : Font.Medium
                  color: isSel ? Style.accent : Style.textPrimary
                  elide: Text.ElideRight; Layout.fillWidth: true
                }

                Text {
                  visible: isSel && modelData.builtin
                  text: "󰄬"
                  font.pixelSize: 13
                  color: Style.accent
                }

                Text {
                  visible: !modelData.builtin
                  text: "󰅖"
                  font.pixelSize: 12
                  color: delAnMouse.containsMouse ? Style.accentRed : Style.textMuted

                  MouseArea {
                    id: delAnMouse
                    anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                      mouse.accepted = true
                      if (root.ipc) {
                        root.ipc.deleteHyprPreset("animation", modelData.id)
                        root.notifyToast(modelData.name + " silindi.", false)
                      }
                    }
                  }
                }
              }

              Text {
                text: modelData.description || ""
                font.family: Style.fontText; font.pixelSize: 10; color: Style.textMuted
                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            MouseArea {
              id: anMouse
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1
              onClicked: {
                if (root.ipc) {
                  root.ipc.applyHyprPreset("animation", modelData.id)
                  root.notifyToast("Animasyon preseti: " + modelData.name, false)
                }
              }
            }
          }
        }
      }

      // Collapsible 7-Leaf Individual Animation Customizer Drawer
      SettingsCollapsibleSection {
        title: "7 Animasyonu Ayrı Ayrı Özelleştir"
        subtitle: "Her animasyon için hız, eğri ve stil ayarı (anında canlı uygulanır)"
        iconText: "󰙖"
        expanded: false

        Repeater {
          model: root.animLeavesMeta

          delegate: ColumnLayout {
            id: leafDelegate
            required property var modelData
            required property int index
            readonly property string leafKey: modelData.key
            readonly property var leafObj: (root.animCfg && root.animCfg[leafKey])
              ? root.animCfg[leafKey]
              : ({ "enabled": true, "speed": 4.0, "bezier": "easeOutQuint", "style": "" })
            readonly property bool isOpen: root.expandedAnimKey === leafKey

            Layout.fillWidth: true
            spacing: 0

            // Summary Row (Click to Expand Leaf Controls)
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 52
              color: rowHov.containsMouse ? Style.surfaceHover : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 14
                spacing: 12

                Text {
                  text: modelData.icon
                  font.pixelSize: 15
                  color: leafObj.enabled ? Style.accent : Style.textMuted
                  Layout.preferredWidth: 18
                  horizontalAlignment: Text.AlignHCenter
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    text: modelData.title
                    font.family: Style.fontText; font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textPrimary
                  }

                  Text {
                    text: leafObj.enabled
                      ? ("Hız " + Number(leafObj.speed || 4).toFixed(1) + "  •  " + (leafObj.bezier || "easeOutQuint") + (leafObj.style ? ("  •  " + leafObj.style) : ""))
                      : "Kapalı"
                    font.family: Style.fontText; font.pixelSize: 11; color: Style.textMuted
                    elide: Text.ElideRight; Layout.fillWidth: true
                  }
                }

                SettingsToggle {
                  checked: !!leafObj.enabled
                  onToggled: v => root.updateAnimLeaf(modelData.key, "enabled", v)
                }

                Text {
                  text: "󰅀"
                  font.pixelSize: 15
                  color: Style.textMuted
                  rotation: isOpen ? 180 : 0
                  Behavior on rotation { NumberAnimation { duration: 160 } }
                }
              }

              MouseArea {
                id: rowHov
                anchors.fill: parent
                anchors.rightMargin: 56
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expandedAnimKey = isOpen ? "" : modelData.key
              }
            }

            // Expanded Leaf Controls (Speed Slider + Curve Chips + Style Chips)
            Rectangle {
              visible: isOpen
              Layout.fillWidth: true
              implicitHeight: leafDetailCol.implicitHeight + 20
              color: Qt.alpha(Style.appBackground, 0.55)

              ColumnLayout {
                id: leafDetailCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                SettingsSliderRow {
                  title: "Hız (Küçük = Daha Hızlı)"
                  value: leafObj.speed || 4.0
                  minValue: 0.5; maxValue: 10.0; step: 0.2; decimals: 1
                  showDivider: false
                  onValueModified: v => root.updateAnimLeaf(modelData.key, "speed", v)
                }

                // Curve Selector
                ColumnLayout {
                  Layout.fillWidth: true
                  Layout.leftMargin: 14; Layout.rightMargin: 14
                  spacing: 6

                  Text {
                    text: "Eğri (Easing / Spring / Özel Bézier)"
                    font.family: Style.fontText; font.pixelSize: 11; font.weight: Font.Medium; color: Style.textSecondary
                  }

                  Flow {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                      model: root.availableCurves

                      delegate: Rectangle {
                        required property string modelData
                        readonly property bool isCur: (leafObj.bezier || "") === modelData
                        height: 24
                        implicitWidth: cvTxt.implicitWidth + 14
                        radius: 6
                        color: isCur ? Qt.alpha(Style.accent, 0.16) : (cvMouse.containsMouse ? Style.surfaceHover : Style.appCard)
                        border.color: isCur ? Style.accent : Style.appBorder
                        border.width: 1

                        Text {
                          id: cvTxt
                          anchors.centerIn: parent
                          text: modelData
                          font.family: Style.fontText; font.pixelSize: 10
                          font.weight: isCur ? Font.DemiBold : Font.Normal
                          color: isCur ? Style.accent : Style.textPrimary
                        }

                        MouseArea {
                          id: cvMouse
                          anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                          onClicked: root.updateAnimLeaf(leafDelegate.leafKey, "bezier", modelData)
                        }
                      }
                    }
                  }
                }

                // Style Selector (Only for leaves supporting Hyprland styles)
                ColumnLayout {
                  visible: modelData.styles && modelData.styles.length > 0
                  Layout.fillWidth: true
                  Layout.leftMargin: 14; Layout.rightMargin: 14
                  spacing: 6

                  Text {
                    text: "Geçiş Stili"
                    font.family: Style.fontText; font.pixelSize: 11; font.weight: Font.Medium; color: Style.textSecondary
                  }

                  Flow {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                      model: modelData.styles || []

                      delegate: Rectangle {
                        required property string modelData
                        readonly property bool isSt: (leafObj.style || "") === modelData
                        height: 24
                        implicitWidth: stTxt.implicitWidth + 14
                        radius: 6
                        color: isSt ? Qt.alpha(Style.accent, 0.16) : (stMouse.containsMouse ? Style.surfaceHover : Style.appCard)
                        border.color: isSt ? Style.accent : Style.appBorder
                        border.width: 1

                        Text {
                          id: stTxt
                          anchors.centerIn: parent
                          text: modelData
                          font.family: Style.fontText; font.pixelSize: 10
                          font.weight: isSt ? Font.DemiBold : Font.Normal
                          color: isSt ? Style.accent : Style.textPrimary
                        }

                        MouseArea {
                          id: stMouse
                          anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                          onClicked: root.updateAnimLeaf(leafDelegate.leafKey, "style", modelData)
                        }
                      }
                    }
                  }
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: Style.appBorder
              opacity: 0.7
            }
          }
        }

        // Save Current 7-Leaf Config as Animation Preset
        Item {
          Layout.fillWidth: true
          implicitHeight: 54

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 8

            Rectangle {
              Layout.fillWidth: true
              height: 32; radius: 7
              color: Style.appBackground
              border.color: animSaveIn.activeFocus ? Style.accent : Style.appBorder
              border.width: 1

              TextInput {
                id: animSaveIn
                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Style.textPrimary; font.family: Style.fontText; font.pixelSize: 12
                text: root.newAnimationPresetName
                onTextChanged: root.newAnimationPresetName = text
                Text {
                  anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                  text: "Mevcut 7'li animasyonu yeni preset olarak adlandır..."
                  color: Style.textMuted; font.family: Style.fontText; font.pixelSize: 11
                  visible: animSaveIn.text.length === 0
                }
              }
            }

            SettingsButton {
              text: "Preset Kaydet"
              iconText: "󰆓"
              isAccent: true
              onClicked: {
                let nm = root.newAnimationPresetName.trim()
                if (nm === "") { root.notifyToast("Önce bir preset adı girin.", true); return }
                if (root.ipc) {
                  root.ipc.saveHyprPreset("animation", nm, "Özel 7'li animasyon kombinasyonu")
                  root.newAnimationPresetName = ""
                  root.notifyToast("'" + nm + "' animasyon preseti kaydedildi.", false)
                }
              }
            }
          }
        }
      }

      // Collapsible Custom Bézier Curve Creator Drawer
      SettingsCollapsibleSection {
        title: "Özel Bézier Eğrisi Oluştur"
        subtitle: "Kaydedilen eğriler otomatik olarak yukarıdaki 7 animasyon listesine eklenir"
        iconText: "󰘖"
        expanded: false

        Item {
          Layout.fillWidth: true
          implicitHeight: bezierEd.implicitHeight + 16

          CubicBezierEditor {
            id: bezierEd
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            ipc: root.ipc
          }
        }
      }
    }
  }
}
