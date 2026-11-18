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
    width: 6
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
  property string currentShadowColor: "rgba(00000088)"
  property string customBorderName: "custom_profil"

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

  // Shared chip group component for uniform profile selection
  component ProfileChipGroup: ColumnLayout {
    id: chipGroup
    property string label: ""
    property string activeValue: ""
    property var modelDataList: []
    property bool compact: false
    signal selected(string value)

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
      Layout.fillWidth: true

      Text {
        text: chipGroup.label
        font.family: Style.fontText
        font.pixelSize: chipGroup.compact ? 12 : 13
        font.weight: Font.Medium
        color: Style.textPrimary
        Layout.fillWidth: true
      }

      Text {
        text: chipGroup.activeValue
        font.family: Style.fontText
        font.pixelSize: 11
        color: Style.accent
      }
    }

    Flow {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: chipGroup.modelDataList

        delegate: Rectangle {
          required property string modelData
          readonly property bool isSelected: chipGroup.activeValue === modelData
          height: chipGroup.compact ? 25 : 28
          implicitWidth: chipTxt.implicitWidth + (chipGroup.compact ? 14 : 18)
          radius: 7
          color: isSelected ? Qt.alpha(Style.accent, 0.14) : (chipMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
          border.color: isSelected ? Style.accent : (chipMouse.containsMouse ? Style.borderHover : Style.appBorder)
          border.width: 1

          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on border.color { ColorAnimation { duration: 120 } }

          Text {
            id: chipTxt
            anchors.centerIn: parent
            text: modelData
            font.family: Style.fontText
            font.pixelSize: chipGroup.compact ? 10 : 11
            font.weight: isSelected ? Font.DemiBold : Font.Medium
            color: isSelected ? Style.accent : Style.textPrimary
          }

          MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chipGroup.selected(modelData)
          }
        }
      }
    }
  }

  ColumnLayout {
    id: contentColumn
    width: parent.width - 40
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 20
    spacing: 18

    // =========================================================================
    // 1. QUICK PROFILE PRESETS
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Hızlı Profiller"
      }

      SettingsCard {
        innerPadding: 14
        spacing: 12

        ProfileChipGroup {
          label: "Kenarlık ve Dekorasyon"
          activeValue: root.activeState.border_profile || "minimal"
          modelDataList: root.availableProfiles.borders || ["minimal", "rounded", "sharp", "thick", "borderless", "glow"]
          onSelected: val => {
            if (root.ipc) root.ipc.setHyprProfile("border", val);
            root.applyPresetDefaults(val);
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

        ProfileChipGroup {
          label: "Ana Animasyon"
          activeValue: root.activeState.animation_profile || "bouncy"
          modelDataList: root.availableProfiles.animations || ["smooth", "snappy", "bouncy", "gentle", "macos", "cyberpunk", "minimalist", "cinematic", "disabled"]
          onSelected: val => {
            if (root.ipc) root.ipc.setHyprProfile("animation", val);
          }
        }
      }
    }

    // =========================================================================
    // 2. BORDER & DECORATION STUDIO
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Kenarlık ve Geometri"
      }

      SettingsCard {
        innerPadding: 14
        spacing: 12

        // Live Window Silhouette Preview
        Rectangle {
          Layout.fillWidth: true
          height: 128
          radius: 8
          color: Style.appBackground
          border.color: Style.appBorder
          border.width: 1
          clip: true

          Rectangle {
            id: mockWindow
            anchors.centerIn: parent
            width: 210
            height: 84
            radius: root.currentRounding
            color: Style.appCard
            opacity: root.currentActiveOpacity
            border.color: Style.accent
            border.width: root.currentBorderSize

            Behavior on radius { NumberAnimation { duration: 120 } }
            Behavior on border.width { NumberAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 120 } }

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
              anchors.centerIn: parent
              spacing: 2

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Kenarlık: " + root.currentBorderSize + "px  •  Yarıçap: " + root.currentRounding + "px"
                font.family: Style.fontText
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Style.textPrimary
              }

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Gaps: " + root.currentGapsIn + "/" + root.currentGapsOut + "px  •  Opaklık: " + Math.round(root.currentActiveOpacity * 100) + "%"
                font.family: Style.fontText
                font.pixelSize: 10
                color: Style.textMuted
              }
            }
          }
        }

        SettingsNumberRow {
          title: "Kenarlık Kalınlığı"
          value: root.currentBorderSize
          minValue: 0
          maxValue: 8
          step: 1
          unit: "px"
          onValueModified: val => { root.currentBorderSize = val; root.triggerLivePreview(); }
        }

        SettingsNumberRow {
          title: "Köşe Yuvarlama (Rounding)"
          value: root.currentRounding
          minValue: 0
          maxValue: 30
          step: 1
          unit: "px"
          onValueModified: val => { root.currentRounding = val; root.triggerLivePreview(); }
        }

        SettingsNumberRow {
          title: "Squircle Eğrilik Katsayısı"
          subtitle: "2.0 Dairesel • 4.0 iOS Squircle • 10.0 Kare"
          value: root.currentRoundingPower
          minValue: 2.0
          maxValue: 10.0
          step: 0.5
          unit: "x"
          onValueModified: val => { root.currentRoundingPower = val; root.triggerLivePreview(); }
        }

        SettingsNumberRow {
          title: "İç Boşluk (Gaps In)"
          value: root.currentGapsIn
          minValue: 0
          maxValue: 30
          step: 1
          unit: "px"
          onValueModified: val => { root.currentGapsIn = val; root.triggerLivePreview(); }
        }

        SettingsNumberRow {
          title: "Dış Boşluk (Gaps Out)"
          value: root.currentGapsOut
          minValue: 0
          maxValue: 40
          step: 1
          unit: "px"
          onValueModified: val => { root.currentGapsOut = val; root.triggerLivePreview(); }
        }

        SettingsRow {
          title: "Pencere Gölgesi (Drop Shadow)"

          SettingsToggle {
            checked: root.currentShadowEnabled
            onToggled: isChecked => { root.currentShadowEnabled = isChecked; root.triggerLivePreview(); }
          }
        }

        SettingsNumberRow {
          visible: root.currentShadowEnabled
          title: "Gölge Yayılımı (Shadow Range)"
          value: root.currentShadowRange
          minValue: 5
          maxValue: 60
          step: 5
          unit: "px"
          onValueModified: val => { root.currentShadowRange = val; root.triggerLivePreview(); }
        }

        SettingsNumberRow {
          title: "Aktif Pencere Opaklığı"
          value: root.currentActiveOpacity
          minValue: 0.50
          maxValue: 1.00
          step: 0.02
          unit: ""
          onValueModified: val => { root.currentActiveOpacity = val; root.triggerLivePreview(); }
        }

        SettingsNumberRow {
          title: "Pasif Pencere Opaklığı"
          value: root.currentInactiveOpacity
          minValue: 0.50
          maxValue: 1.00
          step: 0.02
          unit: ""
          showDivider: false
          onValueModified: val => { root.currentInactiveOpacity = val; root.triggerLivePreview(); }
        }

        // Save Custom Border Profile Row
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: Style.appBackground
            border.color: borderNameInput.activeFocus ? Style.accent : Style.appBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 6

              Text {
                text: "󰓹"
                font.pixelSize: 12
                color: Style.textMuted
              }

              TextInput {
                id: borderNameInput
                Layout.fillWidth: true
                text: root.customBorderName
                font.family: Style.fontText
                font.pixelSize: 12
                color: Style.textPrimary
                clip: true
                selectByMouse: true
                onTextChanged: root.customBorderName = text
              }
            }
          }

          SettingsButton {
            text: borderFeedbackTimer.running ? "Kaydedildi" : "Profili Kaydet"
            iconText: borderFeedbackTimer.running ? "󰄬" : "󰆓"
            isAccent: true
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

          Timer { id: borderFeedbackTimer; interval: 2200 }
        }
      }
    }

    // =========================================================================
    // 3. MODULAR ANIMATION OVERRIDES
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Animasyon Geçişleri"
      }

      SettingsCard {
        innerPadding: 14
        spacing: 12

        ProfileChipGroup {
          label: "Pencere Açılış & Kapanış"
          compact: true
          activeValue: root.activeState.window_animation || "popin_smooth"
          modelDataList: root.availableProfiles.windows || ["popin_smooth", "popin_bouncy", "slide_in", "snappy_pop", "pure_fade", "elastic_rebound", "gentle_float", "zoom_focus"]
          onSelected: val => { if (root.ipc) root.ipc.setHyprProfile("window", val); }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

        ProfileChipGroup {
          label: "Çalışma Alanı Değişimi"
          compact: true
          activeValue: root.activeState.workspace_animation || "slide_horizontal"
          modelDataList: root.availableProfiles.workspaces || ["slide_horizontal", "slidefade_horizontal", "slide_vertical", "slidefade_vertical", "fade", "bouncy_slide", "snappy_slide", "cinematic_swipe"]
          onSelected: val => { if (root.ipc) root.ipc.setHyprProfile("workspace", val); }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Style.appBorder }

        ProfileChipGroup {
          label: "Katmanlar & Menüler (Layers)"
          compact: true
          activeValue: root.activeState.layer_animation || "popin_layers"
          modelDataList: root.availableProfiles.layers || ["popin_layers", "slide_layers", "fade_layers", "bouncy_layers"]
          onSelected: val => { if (root.ipc) root.ipc.setHyprProfile("layer", val); }
        }
      }
    }

    // =========================================================================
    // 4. CUBIC BÉZIER EDITOR
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Özel Bézier Eğrisi"
      }

      CubicBezierEditor {
        ipc: root.ipc
      }
    }
  }
}
