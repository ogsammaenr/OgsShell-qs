import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../backend"
import "../components"

Flickable {
  id: root

  property var ipc: null

  // Local working state synchronized with Config singleton
  property bool overAmplification: Config.audioOverAmplification
  property bool feedbackEnabled: Config.audioFeedbackEnabled
  property bool volumeChangeSound: Config.audioFeedbackVolumeChangeSound
  property int feedbackThrottleMs: Config.audioFeedbackThrottleMs
  property bool cornerHudVolumeEnabled: Config.cornerHudVolume

  // Live PipeWire default output sink telemetry
  property int liveVolumePct: 50
  property bool liveMuted: false
  property string sinkDisplayName: "Varsayılan Çıkış Aygıtı"

  property string statusFeedbackMessage: ""
  readonly property int activeMaxVolume: overAmplification ? 150 : 100

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  function syncLiveSink() {
    let sink = Pipewire.defaultAudioSink
    if (sink) {
      root.sinkDisplayName = sink.description || sink.nickname || sink.name || "Varsayılan Çıkış Aygıtı"
      if (sink.audio) {
        root.liveVolumePct = Math.max(0, Math.round(sink.audio.volume * 100))
        root.liveMuted = !!sink.audio.muted
        return
      }
    }
    wpctlGetProc.running = true
  }

  Connections {
    target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    function onVolumeChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.liveVolumePct = Math.max(0, Math.round(Pipewire.defaultAudioSink.audio.volume * 100))
      }
    }
    function onMutedChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.liveMuted = !!Pipewire.defaultAudioSink.audio.muted
      }
    }
  }

  Connections {
    target: Pipewire
    function onDefaultAudioSinkChanged() {
      root.syncLiveSink()
    }
  }

  Process {
    id: wpctlGetProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    stdout: SplitParser {
      onRead: data => {
        let m = data.match(/Volume:\s*([0-9.]+)/)
        if (m && m[1]) {
          let v = Math.round(parseFloat(m[1]) * 100)
          if (!isNaN(v)) root.liveVolumePct = Math.max(0, v)
        }
        root.liveMuted = data.indexOf("[MUTED]") !== -1
      }
    }
  }

  Process { id: setVolProc }
  Process { id: clampProc }

  function setSinkVolume(pct) {
    let target = Math.max(0, Math.min(root.activeMaxVolume, Math.round(pct)))
    root.liveVolumePct = target
    root.liveMuted = false
    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      Pipewire.defaultAudioSink.audio.volume = target / 100.0
      Pipewire.defaultAudioSink.audio.muted = false
    }
    let maxRatio = (root.activeMaxVolume / 100.0).toFixed(1)
    setVolProc.running = false
    setVolProc.command = ["wpctl", "set-volume", "-l", maxRatio, "@DEFAULT_AUDIO_SINK@", target + "%"]
    setVolProc.running = true
  }

  function toggleMute() {
    root.liveMuted = !root.liveMuted
    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
      Pipewire.defaultAudioSink.audio.muted = root.liveMuted
    } else {
      setVolProc.running = false
      setVolProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
      setVolProc.running = true
    }
  }

  function clampAllVolumesTo100() {
    if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.volume > 1.0) {
      Pipewire.defaultAudioSink.audio.volume = 1.0
    }
    let pyScript = "import subprocess, json\n" +
      "def clamp_kind(list_cmd, set_cmd):\n" +
      "    try:\n" +
      "        res = subprocess.run(['pactl', '--format=json', 'list', list_cmd], capture_output=True, text=True)\n" +
      "        txt = res.stdout.strip()\n" +
      "        idx = txt.find('[')\n" +
      "        if idx == -1: return\n" +
      "        for item in json.loads(txt[idx:]):\n" +
      "            vdict = item.get('volume', {})\n" +
      "            over = False\n" +
      "            for ch in vdict.values():\n" +
      "                if isinstance(ch, dict) and 'value_percent' in ch:\n" +
      "                    try:\n" +
      "                        if int(ch['value_percent'].replace('%', '').strip()) > 100:\n" +
      "                            over = True\n" +
      "                            break\n" +
      "                    except Exception: pass\n" +
      "            if over and item.get('index') is not None:\n" +
      "                subprocess.run(['pactl', set_cmd, str(item['index']), '100%'], capture_output=True)\n" +
      "    except Exception: pass\n" +
      "clamp_kind('sinks', 'set-sink-volume')\n" +
      "clamp_kind('sink-inputs', 'set-sink-input-volume')\n" +
      "subprocess.run(['wpctl', 'set-volume', '-l', '1.0', '@DEFAULT_AUDIO_SINK@', '0%+'], capture_output=True)\n"

    clampProc.running = false
    clampProc.command = ["python3", "-c", pyScript]
    clampProc.running = true
    root.syncLiveSink()
  }

  function pullValuesFromConfig() {
    root.overAmplification = Config.audioOverAmplification
    root.feedbackEnabled = Config.audioFeedbackEnabled
    root.volumeChangeSound = Config.audioFeedbackVolumeChangeSound
    root.feedbackThrottleMs = Config.audioFeedbackThrottleMs
    root.cornerHudVolumeEnabled = Config.cornerHudVolume
  }

  function saveSoundSettings(feedbackMsg) {
    Config.saveConfig({
      "audio": {
        "over_amplification": root.overAmplification,
        "max_volume": 150
      },
      "audio_feedback": {
        "enabled": root.feedbackEnabled,
        "volume_change_sound": root.volumeChangeSound,
        "throttle_ms": root.feedbackThrottleMs
      },
      "corner_hud": {
        "volume_enabled": root.cornerHudVolumeEnabled
      }
    })
    root.statusFeedbackMessage = feedbackMsg || "✓ Ses ayarları kaydedildi ve anında uygulandı."
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
    root.syncLiveSink()
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
    width: parent.width - 24
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 16
    spacing: 20

    // =========================================================================
    // HEADER
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: "Ses ve Donanım"
          font.pixelSize: 15
          font.weight: Font.Bold
          color: Style.textPrimary
        }

        Text {
          text: "Ses yükseltme sınırı (%150 Over-Amplification), ses geri bildirimi ve köşe göstergesi ayarları."
          font.pixelSize: 11
          color: Style.textMuted
        }
      }

      SettingsButton {
        text: "Karıştırıcıyı Aç"
        iconText: "󰓃"
        visible: !!root.ipc
        onClicked: {
          if (root.ipc) {
            root.ipc.sendAction("toggle_audio_mixer", {})
          }
        }
      }
    }

    // Status Banner
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
    // 1. LIVE OUTPUT DEVICE & VOLUME PREVIEW
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Aktif Ses Çıkışı"
      }

      SettingsCard {
        innerPadding: 14
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Rectangle {
            width: 36
            height: 36
            radius: 10
            color: root.liveMuted
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.16)
              : (root.liveVolumePct > 100
                ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.18)
                : Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.16))

            Text {
              anchors.centerIn: parent
              text: root.liveMuted ? "󰖁" : (root.liveVolumePct > 50 ? "󰕾" : (root.liveVolumePct > 0 ? "󰖀" : "󰕿"))
              font.pixelSize: 16
              color: root.liveMuted ? Style.accentRed : (root.liveVolumePct > 100 ? Style.accentOrange : Style.accentCyan)
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              text: root.sinkDisplayName
              font.pixelSize: 13
              font.weight: Font.DemiBold
              color: Style.textPrimary
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              text: root.liveMuted
                ? "Çıkış şu anda sessize alınmış durumda"
                : ("Mevcut düzey: %" + root.liveVolumePct + " • İzin verilen üst sınır: %" + root.activeMaxVolume)
              font.pixelSize: 11
              color: root.liveVolumePct > 100 ? Style.accentOrange : Style.textMuted
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }

          // Active Max Limit Pill
          Rectangle {
            implicitWidth: limitBadgeText.implicitWidth + 14
            implicitHeight: 24
            radius: 12
            color: root.overAmplification
              ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.18)
              : Style.surfaceVariant
            border.color: root.overAmplification ? Style.accentOrange : Style.border
            border.width: 1

            Text {
              id: limitBadgeText
              anchors.centerIn: parent
              text: root.overAmplification ? "Maks. %150" : "Maks. %100"
              font.pixelSize: 11
              font.weight: Font.Bold
              color: root.overAmplification ? Style.accentOrange : Style.textSecondary
            }
          }

          SettingsButton {
            visible: !root.liveMuted && root.liveVolumePct > 100
            text: "%100'e İndir"
            onClicked: root.setSinkVolume(100)
          }

          SettingsButton {
            text: root.liveMuted ? "Sesi Aç" : "Sustur"
            isDanger: root.liveMuted
            onClicked: root.toggleMute()
          }
        }

        // Interactive Volume Capsule Preview Slider
        Rectangle {
          id: previewSlider
          Layout.fillWidth: true
          implicitHeight: 34
          radius: 10
          color: Style.appBackground
          border.color: Style.border
          border.width: 1
          clip: true

          // Filled Level
          Rectangle {
            height: parent.height
            width: root.liveMuted ? 0 : Math.max(0, Math.min(parent.width, parent.width * (root.liveVolumePct / root.activeMaxVolume)))
            radius: 10
            color: (!root.liveMuted && root.liveVolumePct >= 135)
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.38)
              : ((!root.liveMuted && root.liveVolumePct > 100)
                ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.36)
                : Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.28))

            Behavior on width {
              enabled: !previewSliderMouse.pressed
              NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
            }
          }

          // 100% Threshold Marker when Over-Amplification is ON
          Rectangle {
            visible: root.overAmplification
            x: Math.round(parent.width * (100.0 / root.activeMaxVolume))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            width: 2
            radius: 1
            color: Style.textMuted
            opacity: 0.65
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
              text: root.liveMuted ? "Sessiz" : (root.liveVolumePct > 100 ? "Yükseltilmiş Ses (Boost)" : "Ses Seviyesi")
              font.pixelSize: 12
              font.weight: Font.Medium
              color: root.liveMuted ? Style.accentRed : (root.liveVolumePct > 100 ? Style.accentOrange : Style.textSecondary)
              Layout.fillWidth: true
            }

            Text {
              text: root.liveMuted ? "0%" : ("%" + root.liveVolumePct)
              font.pixelSize: 12
              font.weight: Font.Bold
              color: root.liveMuted ? Style.accentRed : (root.liveVolumePct >= 135 ? Style.accentRed : (root.liveVolumePct > 100 ? Style.accentOrange : Style.accentCyan))
            }
          }

          MouseArea {
            id: previewSliderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function updateVol(mouse) {
              let pct = (mouse.x / width) * root.activeMaxVolume
              root.setSinkVolume(pct)
            }

            onPressed: mouse => updateVol(mouse)
            onPositionChanged: mouse => { if (pressed) updateVol(mouse) }
            onClicked: mouse => updateVol(mouse)
            onWheel: wheel => {
              let delta = wheel.angleDelta.y > 0 ? 5 : -5
              root.setSinkVolume(root.liveVolumePct + delta)
            }
          }
        }
      }
    }

    // =========================================================================
    // 2. OVER-AMPLIFICATION (%150 BOOST)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Ses Yükseltme (Over-Amplification)"
      }

      SettingsCard {
        SettingsRow {
          iconText: "🔊"
          iconColor: root.overAmplification ? Style.accentOrange : Style.accentCyan
          title: "Maksimum Sesi %150'ye Çıkar"
          subtitle: "Kontrol Merkezi, Ses Karıştırıcısı, Köşe HUD, Alt Çentik ve Hyprland kısayollarında ses sınırını %150 yapar."
          showDivider: root.overAmplification

          SettingsToggle {
            checked: root.overAmplification
            onToggled: isChecked => {
              root.overAmplification = isChecked
              if (!isChecked) {
                root.clampAllVolumesTo100()
                root.saveSoundSettings("✓ %150 ses yükseltme kapatıldı. %100 üzerindeki sesler güvenli seviyeye indirildi.")
              } else {
                root.saveSoundSettings("✓ %150 ses yükseltme etkinleştirildi.")
              }
            }
          }
        }

        // Boost Warning Callout Row (shown when enabled)
        Rectangle {
          visible: root.overAmplification
          Layout.fillWidth: true
          implicitHeight: warnRow.implicitHeight + 20
          color: Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.08)

          RowLayout {
            id: warnRow
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
              text: "⚠️"
              font.pixelSize: 14
              Layout.alignment: Qt.AlignTop
            }

            Text {
              text: "%100 üzerindeki dijital yükseltme, düşük sesli medya dosyalarında yararlıdır; ancak yüksek donanım sesinde seste bozulmaya (clipping) neden olabilir. Kapatıldığında %100 üzerindeki tüm çıkışlar ve uygulama akışları otomatik olarak %100'e indirilir."
              font.pixelSize: 11
              color: Style.textSecondary
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. AUDIO FEEDBACK & CORNER HUD OSD
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Geri Bildirim & Ekran Göstergesi"
      }

      SettingsCard {
        SettingsRow {
          iconText: "🎵"
          iconColor: Style.accentCyan
          title: "Ses Geri Bildirim Efektleri"
          subtitle: "Sistem ses olaylarında akustik bildirim seslerinin çalınmasını etkinleştirir."
          showDivider: true

          SettingsToggle {
            checked: root.feedbackEnabled
            onToggled: isChecked => {
              root.feedbackEnabled = isChecked
              root.saveSoundSettings()
            }
          }
        }

        SettingsRow {
          iconText: "🔔"
          iconColor: Style.accentGreen
          title: "Ses Değişimi Pop Sesi"
          subtitle: "Ses seviyesi değiştirildiğinde kısa bir PipeWire/Canberra geri bildirim sesi çalar."
          showDivider: true

          SettingsToggle {
            checked: root.volumeChangeSound
            onToggled: isChecked => {
              root.volumeChangeSound = isChecked
              root.saveSoundSettings()
            }
          }
        }

        SettingsNumberRow {
          iconText: "⏱️"
          iconColor: Style.accentMagenta
          title: "Ses Geri Bildirim Gecikmesi (Throttle)"
          subtitle: "Kaydırıcı veya tuş basılı tutulduğunda pop sesi çalma sıklığı."
          value: root.feedbackThrottleMs
          minValue: 50
          maxValue: 500
          step: 25
          unit: "ms"
          showDivider: true
          onValueModified: val => {
            root.feedbackThrottleMs = val
            root.saveSoundSettings()
          }
        }

        SettingsRow {
          iconText: "📐"
          iconColor: Style.accentBlue
          title: "Köşe Ses Göstergesi (Corner HUD OSD)"
          subtitle: "Ses veya sessiz durumu değiştiğinde ekranın sol-üst köşesinde bilgi kapsülü gösterir."
          showDivider: false

          SettingsToggle {
            checked: root.cornerHudVolumeEnabled
            onToggled: isChecked => {
              root.cornerHudVolumeEnabled = isChecked
              root.saveSoundSettings()
            }
          }
        }
      }
    }
  }
}
