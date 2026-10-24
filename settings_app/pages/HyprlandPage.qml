import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../backend"
import "../components"

Flickable {
  id: root

  property var ipc: null

  contentWidth: width
  contentHeight: contentColumn.implicitHeight + 40
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
  }

  // Active state and profile choices from Go backend IPC
  readonly property var activeState: (ipc && ipc.hyprState && ipc.hyprState.active) ? ipc.hyprState.active : ({})
  readonly property var availableProfiles: (ipc && ipc.hyprState && ipc.hyprState.available) ? ipc.hyprState.available : ({})

  // Working properties for live editing & custom border synthesis
  property int currentBorderSize: 1
  property int currentRounding: 10
  property real currentRoundingPower: 4.0
  property int currentGapsIn: 4
  property int currentGapsOut: 1
  property real currentActiveOpacity: 1.00
  property real currentInactiveOpacity: 0.95
  property bool currentShadowEnabled: true
  property int currentShadowRange: 20
  property int currentShadowPower: 2
  property string customBorderName: "custom_profil"

  // Sync working properties from active profile presets
  function applyPresetDefaults(profileName) {
    if (profileName === "minimal") {
      currentBorderSize = 1; currentRounding = 10; currentRoundingPower = 10.0;
      currentGapsIn = 4; currentGapsOut = 1; currentActiveOpacity = 1.0;
      currentInactiveOpacity = 0.96; currentShadowEnabled = true; currentShadowRange = 15;
    } else if (profileName === "rounded") {
      currentBorderSize = 2; currentRounding = 14; currentRoundingPower = 4.0;
      currentGapsIn = 5; currentGapsOut = 10; currentActiveOpacity = 1.0;
      currentInactiveOpacity = 0.94; currentShadowEnabled = true; currentShadowRange = 35;
    } else if (profileName === "sharp") {
      currentBorderSize = 2; currentRounding = 0; currentRoundingPower = 2.0;
      currentGapsIn = 2; currentGapsOut = 4; currentActiveOpacity = 1.0;
      currentInactiveOpacity = 0.95; currentShadowEnabled = false; currentShadowRange = 0;
    } else if (profileName === "thick") {
      currentBorderSize = 3; currentRounding = 10; currentRoundingPower = 2.0;
      currentGapsIn = 6; currentGapsOut = 12; currentActiveOpacity = 1.0;
      currentInactiveOpacity = 0.92; currentShadowEnabled = true; currentShadowRange = 25;
    } else if (profileName === "borderless") {
      currentBorderSize = 0; currentRounding = 12; currentRoundingPower = 3.0;
      currentGapsIn = 7; currentGapsOut = 14; currentActiveOpacity = 1.0;
      currentInactiveOpacity = 0.95; currentShadowEnabled = true; currentShadowRange = 40;
    } else if (profileName === "glow") {
      currentBorderSize = 2; currentRounding = 12; currentRoundingPower = 3.0;
      currentGapsIn = 5; currentGapsOut = 10; currentActiveOpacity = 1.0;
      currentInactiveOpacity = 0.92; currentShadowEnabled = true; currentShadowRange = 35;
    }
  }

  // 0ms Live Desktop Preview via Go Backend IPC (hyprctl eval)
  Timer {
    id: previewDebounceTimer
    interval: 50
    repeat: false
    onTriggered: {
      if (root.ipc) {
        let lua = "hl.config({ general = { border_size = " + currentBorderSize
          + ", gaps_in = " + currentGapsIn
          + ", gaps_out = " + currentGapsOut
          + " }, decoration = { rounding = " + currentRounding
          + ", rounding_power = " + currentRoundingPower.toFixed(1)
          + ", active_opacity = " + currentActiveOpacity.toFixed(2)
          + ", inactive_opacity = " + currentInactiveOpacity.toFixed(2)
          + ", shadow = { enabled = " + currentShadowEnabled
          + ", range = " + currentShadowRange + " } } })";
        root.ipc.previewHyprEval(lua);
      }
    }
  }

  function triggerLivePreview() {
    previewDebounceTimer.restart();
  }

  Component.onCompleted: {
    if (root.ipc) {
      root.ipc.getHyprState();
    }
    if (activeState.border_profile) {
      applyPresetDefaults(activeState.border_profile);
    }
  }

  Connections {
    target: root.ipc
    function onHyprStateReceived(payload) {
      if (payload && payload.active && payload.active.border_profile) {
        root.applyPresetDefaults(payload.active.border_profile);
      }
    }
  }

  ColumnLayout {
    id: contentColumn
    width: parent.width - 40
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 18

    // Top Spacer
    Item { height: 6 }

    // =========================================================================
    // 1. HERO CARD: HIZLI PROFİL SEÇİCİ (KENARLIK & ANİMASYON)
    // =========================================================================
    SettingsSectionHeader {
      titleText: "Hızlı Profil Seçimi"
    }

    SettingsCard {
      innerPadding: 14
      spacing: 12

      // Border Profiles Row
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
          spacing: 6
          Text { text: "🪟"; font.pixelSize: 13 }
          Text {
            text: "Kenarlık ve Dekorasyon Profili"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
          Item { Layout.fillWidth: true }
          Text {
            text: "Aktif: " + (root.activeState.border_profile || "minimal")
            font.pixelSize: 11
            color: Style.accentCyan
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: root.availableProfiles.borders || ["minimal", "rounded", "sharp", "thick", "borderless", "glow"]

            delegate: Rectangle {
              height: 28
              implicitWidth: bdrText.implicitWidth + 16
              radius: 14
              readonly property bool isSelected: (root.activeState.border_profile || "minimal") === modelData
              color: isSelected ? Style.surfaceActive : (bdrMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
              border.color: isSelected ? Style.accent : Style.borderSubtle
              border.width: 1

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on border.color { ColorAnimation { duration: 120 } }

              Text {
                id: bdrText
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 11
                font.weight: isSelected ? Font.Bold : Font.Medium
                color: isSelected ? Style.accentCyan : Style.textPrimary
              }

              MouseArea {
                id: bdrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) {
                    root.ipc.setHyprProfile("border", modelData);
                  }
                  root.applyPresetDefaults(modelData);
                }
              }
            }
          }
        }
      }

      // Separator
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Style.appBorder
      }

      // Animation Preset Row
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
          spacing: 6
          Text { text: "🎬"; font.pixelSize: 13 }
          Text {
            text: "Ana Animasyon Preseti"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
          Item { Layout.fillWidth: true }
          Text {
            text: "Aktif: " + (root.activeState.animation_profile || "bouncy")
            font.pixelSize: 11
            color: Style.accent
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: root.availableProfiles.animations || ["smooth", "snappy", "bouncy", "gentle", "macos", "cyberpunk", "minimalist", "cinematic", "disabled"]

            delegate: Rectangle {
              height: 28
              implicitWidth: animText.implicitWidth + 16
              radius: 14
              readonly property bool isSelected: (root.activeState.animation_profile || "bouncy") === modelData
              color: isSelected ? Style.surfaceActive : (animMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
              border.color: isSelected ? Style.accent : Style.borderSubtle
              border.width: 1

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on border.color { ColorAnimation { duration: 120 } }

              Text {
                id: animText
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 11
                font.weight: isSelected ? Font.Bold : Font.Medium
                color: isSelected ? Style.accent : Style.textPrimary
              }

              MouseArea {
                id: animMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) {
                    root.ipc.setHyprProfile("animation", modelData);
                  }
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 2. KENARLIK VE DEKORASYON STÜDYOSU (CANLI MOCK PENCERE + STEPPER'LAR)
    // =========================================================================
    SettingsSectionHeader {
      titleText: "Kenarlık ve Geometri Stüdyosu"
    }

    SettingsCard {
      innerPadding: 14
      spacing: 14

      // Mock Desktop Preview Box
      Rectangle {
        Layout.fillWidth: true
        height: 140
        radius: 10
        color: Style.appBackground
        border.color: Style.appBorder
        border.width: 1
        clip: true

        // Mock Desktop Background Grid / Gradient
        Rectangle {
          anchors.fill: parent
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.08) }
            GradientStop { position: 1.0; color: "transparent" }
          }
        }

        // Live Simulated Window
        Rectangle {
          id: mockWindow
          anchors.centerIn: parent
          width: 220
          height: 96
          radius: root.currentRounding
          color: Style.appCard
          opacity: root.currentActiveOpacity
          border.color: Style.accent
          border.width: root.currentBorderSize

          Behavior on radius { NumberAnimation { duration: 120 } }
          Behavior on border.width { NumberAnimation { duration: 120 } }
          Behavior on opacity { NumberAnimation { duration: 120 } }

          // Drop shadow simulation
          Rectangle {
            anchors.fill: parent
            anchors.margins: -root.currentShadowRange / 3
            radius: mockWindow.radius + 2
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, root.currentShadowEnabled ? 0.35 : 0)
            border.width: root.currentShadowEnabled ? Math.max(1, root.currentShadowRange / 4) : 0
            z: -1
            visible: root.currentShadowEnabled
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            // Window Header with Dots
            RowLayout {
              spacing: 5
              Rectangle { width: 8; height: 8; radius: 4; color: Style.accentRed }
              Rectangle { width: 8; height: 8; radius: 4; color: Style.accentOrange }
              Rectangle { width: 8; height: 8; radius: 4; color: Style.accentGreen }
              Item { Layout.fillWidth: true }
              Text {
                text: "Canlı Önizleme"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Style.textMuted
              }
            }

            Item { Layout.fillHeight: true }

            Text {
              text: "Sınır: " + root.currentBorderSize + "px | Köşe: " + root.currentRounding + "px"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: Style.textPrimary
              Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true }
          }
        }
      }

      // Steppers for Border Geometries
      SettingsNumberRow {
        title: "Kenarlık Kalınlığı"
        subtitle: "Pencerelerin dış çerçeve genişliği"
        value: root.currentBorderSize
        minValue: 0
        maxValue: 8
        step: 1
        unit: "px"
        onValueModified: val => {
          root.currentBorderSize = val;
          root.triggerLivePreview();
        }
      }

      SettingsNumberRow {
        title: "Köşe Yuvarlama Yarıçapı (Rounding)"
        subtitle: "Pencere köşelerinin kavisi"
        value: root.currentRounding
        minValue: 0
        maxValue: 30
        step: 1
        unit: "px"
        onValueModified: val => {
          root.currentRounding = val;
          root.triggerLivePreview();
        }
      }

      SettingsNumberRow {
        title: "Squircle Eğrilik Katsayısı"
        subtitle: "2.0: Dairesel | 4.0: Modern iOS Squircle | 10.0: Kareye Yakın"
        value: root.currentRoundingPower
        minValue: 2.0
        maxValue: 10.0
        step: 0.5
        unit: "x"
        onValueModified: val => {
          root.currentRoundingPower = val;
          root.triggerLivePreview();
        }
      }

      SettingsNumberRow {
        title: "Pencereler Arası İç Boşluk (Gaps In)"
        subtitle: "Yan yana duran pencerelerin birbirine mesafesi"
        value: root.currentGapsIn
        minValue: 0
        maxValue: 30
        step: 1
        unit: "px"
        onValueModified: val => {
          root.currentGapsIn = val;
          root.triggerLivePreview();
        }
      }

      SettingsNumberRow {
        title: "Ekran Dış Boşluğu (Gaps Out)"
        subtitle: "Pencerelerin ekran kenarlarına olan boşluğu"
        value: root.currentGapsOut
        minValue: 0
        maxValue: 40
        step: 1
        unit: "px"
        onValueModified: val => {
          root.currentGapsOut = val;
          root.triggerLivePreview();
        }
      }

      SettingsRow {
        title: "Pencere Gölgesi (Drop Shadow)"
        subtitle: "Pencerelerin arkasındaki yumuşak derinlik gölgesi"

        SettingsToggle {
          checked: root.currentShadowEnabled
          onToggled: isChecked => {
            root.currentShadowEnabled = isChecked;
            root.triggerLivePreview();
          }
        }
      }

      SettingsNumberRow {
        visible: root.currentShadowEnabled
        title: "Gölge Yayılma Alanı (Shadow Range)"
        subtitle: "Gölgenin pencerelerden dışarıya doğru dağılma mesafesi"
        value: root.currentShadowRange
        minValue: 5
        maxValue: 60
        step: 5
        unit: "px"
        onValueModified: val => {
          root.currentShadowRange = val;
          root.triggerLivePreview();
        }
      }

      SettingsNumberRow {
        title: "Aktif Pencere Opaklığı"
        subtitle: "Odakta bulunan pencerenin saydamlık derecesi"
        value: root.currentActiveOpacity
        minValue: 0.50
        maxValue: 1.00
        step: 0.02
        unit: ""
        onValueModified: val => {
          root.currentActiveOpacity = val;
          root.triggerLivePreview();
        }
      }

      SettingsNumberRow {
        title: "Pasif Pencere Opaklığı"
        subtitle: "Arka plandaki pencerelerin saydamlık derecesi"
        value: root.currentInactiveOpacity
        minValue: 0.50
        maxValue: 1.00
        step: 0.02
        unit: ""
        onValueModified: val => {
          root.currentInactiveOpacity = val;
          root.triggerLivePreview();
        }
      }

      // Custom Profile Creation Action Row
      Rectangle {
        Layout.fillWidth: true
        height: 48
        radius: 8
        color: Style.surface
        border.color: Style.borderSubtle
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 8
          spacing: 10

          Text { text: "💾"; font.pixelSize: 13 }

          TextInput {
            id: customBorderInput
            Layout.fillWidth: true
            text: root.customBorderName
            font.pixelSize: 12
            color: Style.textPrimary
            clip: true
            selectByMouse: true
            onTextChanged: root.customBorderName = text
          }

          Rectangle {
            width: 140
            height: 32
            radius: 6
            color: saveBorderMouse.containsMouse ? Style.accentCyan : Style.surfaceActive
            border.color: Style.accentCyan
            border.width: 1

            RowLayout {
              anchors.centerIn: parent
              spacing: 6
              Text {
                text: borderFeedbackTimer.running ? "✓" : "➕"
                font.pixelSize: 11
              }
              Text {
                text: borderFeedbackTimer.running ? "Kaydedildi" : "Profili Kaydet"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: saveBorderMouse.containsMouse ? Style.bgPrimary : Style.accentCyan
              }
            }

            Timer { id: borderFeedbackTimer; interval: 2200 }

            MouseArea {
              id: saveBorderMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                let name = root.customBorderName.trim() || "custom_profil";
                if (root.ipc) {
                  root.ipc.saveCustomBorder({
                    "name": name,
                    "border_size": root.currentBorderSize,
                    "gaps_in": root.currentGapsIn,
                    "gaps_out": root.currentGapsOut,
                    "rounding": root.currentRounding,
                    "rounding_power": root.currentRoundingPower,
                    "active_opacity": root.currentActiveOpacity,
                    "inactive_opacity": root.currentInactiveOpacity,
                    "shadow_enabled": root.currentShadowEnabled,
                    "shadow_range": root.currentShadowRange,
                    "shadow_render_power": root.currentShadowPower,
                    "shadow_offset": [0, 6],
                    "shadow_color": root.currentShadowColor,
                    "dim_inactive": false,
                    "dim_strength": 0.08
                  });
                }
                borderFeedbackTimer.restart();
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. MODÜLER ANİMASYON GEÇİŞLERİ (OVERRIDES)
    // =========================================================================
    SettingsSectionHeader {
      titleText: "Modüler Animasyon Geçişleri (Overrides)"
    }

    SettingsCard {
      innerPadding: 14
      spacing: 12

      // Windows Animation Override
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
          spacing: 6
          Text { text: "🪟"; font.pixelSize: 12 }
          Text {
            text: "Pencere Açılış & Kapanış (Windows)"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.activeState.window_animation || "popin_smooth"
            font.pixelSize: 11
            color: Style.accentCyan
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: 5

          Repeater {
            model: root.availableProfiles.windows || ["popin_smooth", "popin_bouncy", "slide_in", "snappy_pop", "pure_fade", "elastic_rebound", "gentle_float", "zoom_focus"]

            delegate: Rectangle {
              height: 24
              implicitWidth: winText.implicitWidth + 12
              radius: 12
              readonly property bool isSelected: (root.activeState.window_animation || "popin_smooth") === modelData
              color: isSelected ? Style.surfaceActive : (winMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
              border.color: isSelected ? Style.accent : Style.borderSubtle
              border.width: 1

              Text {
                id: winText
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 10
                font.weight: isSelected ? Font.Bold : Font.Medium
                color: isSelected ? Style.accentCyan : Style.textPrimary
              }

              MouseArea {
                id: winMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) root.ipc.setHyprProfile("window", modelData);
                }
              }
            }
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

      // Workspace Animation Override
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
          spacing: 6
          Text { text: "📑"; font.pixelSize: 12 }
          Text {
            text: "Çalışma Alanı Değişimi (Workspaces)"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.activeState.workspace_animation || "slide_horizontal"
            font.pixelSize: 11
            color: Style.accentOrange
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: 5

          Repeater {
            model: root.availableProfiles.workspaces || ["slide_horizontal", "slidefade_horizontal", "slide_vertical", "slidefade_vertical", "fade", "bouncy_slide", "snappy_slide", "cinematic_swipe"]

            delegate: Rectangle {
              height: 24
              implicitWidth: wsText.implicitWidth + 12
              radius: 12
              readonly property bool isSelected: (root.activeState.workspace_animation || "slide_horizontal") === modelData
              color: isSelected ? Style.surfaceActive : (wsMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
              border.color: isSelected ? Style.accentOrange : Style.borderSubtle
              border.width: 1

              Text {
                id: wsText
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 10
                font.weight: isSelected ? Font.Bold : Font.Medium
                color: isSelected ? Style.accentOrange : Style.textPrimary
              }

              MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) root.ipc.setHyprProfile("workspace", modelData);
                }
              }
            }
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

      // Layers Animation Override
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
          spacing: 6
          Text { text: "🥞"; font.pixelSize: 12 }
          Text {
            text: "Katmanlar & Menüler (Layers / HUD)"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.activeState.layer_animation || "popin_layers"
            font.pixelSize: 11
            color: Style.accentGreen
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: 5

          Repeater {
            model: root.availableProfiles.layers || ["popin_layers", "slide_layers", "fade_layers", "bouncy_layers"]

            delegate: Rectangle {
              height: 24
              implicitWidth: lyrText.implicitWidth + 12
              radius: 12
              readonly property bool isSelected: (root.activeState.layer_animation || "popin_layers") === modelData
              color: isSelected ? Style.surfaceActive : (lyrMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant)
              border.color: isSelected ? Style.accentGreen : Style.borderSubtle
              border.width: 1

              Text {
                id: lyrText
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 10
                font.weight: isSelected ? Font.Bold : Font.Medium
                color: isSelected ? Style.accentGreen : Style.textPrimary
              }

              MouseArea {
                id: lyrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc) root.ipc.setHyprProfile("layer", modelData);
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 4. CUBIC BÉZIER FİZİK & EĞRİ EDİTÖRÜ (CSSPORTAL CLONE)
    // =========================================================================
    SettingsSectionHeader {
      titleText: "Cubic Bézier Fizik & Özel Eğri Stüdyosu"
    }

    CubicBezierEditor {
      ipc: root.ipc
    }

    // Bottom Spacer
    Item { height: 16 }
  }
}
