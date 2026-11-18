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
    root.statusFeedbackMessage = feedbackMsg || "Ses ayarları kaydedildi."
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
    width: parent.width - 40
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 20
    spacing: 18

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: "Çıkış Düzeyi ve Yükseltme"
          font.family: Style.fontText
          font.pixelSize: 14
          font.weight: Font.DemiBold
          color: Style.textPrimary
        }

        Text {
          text: "%150 ses sınırı, geri bildirim ve köşe OSD tercihleri."
          font.family: Style.fontText
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

    // 1. Live Output Device & Volume Preview
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
            width: 34
            height: 34
            radius: 8
            color: root.liveMuted
              ? Qt.alpha(Style.accentRed, 0.14)
              : (root.liveVolumePct > 100 ? Qt.alpha(Style.accentOrange, 0.14) : Style.surfaceVariant)

            Text {
              anchors.centerIn: parent
              text: root.liveMuted ? "󰖁" : (root.liveVolumePct > 50 ? "󰕾" : (root.liveVolumePct > 0 ? "󰖀" : "󰕿"))
              font.pixelSize: 15
              color: root.liveMuted ? Style.accentRed : (root.liveVolumePct > 100 ? Style.accentOrange : Style.textPrimary)
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: root.sinkDisplayName
              font.family: Style.fontText
              font.pixelSize: 13
              font.weight: Font.Medium
              color: Style.textPrimary
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              text: root.liveMuted
                ? "Sessize alındı"
                : ("Düzey: %" + root.liveVolumePct + "  •  Sınır: %" + root.activeMaxVolume)
              font.family: Style.fontText
              font.pixelSize: 11
              color: root.liveVolumePct > 100 ? Style.accentOrange : Style.textMuted
              Layout.fillWidth: true
              elide: Text.ElideRight
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

        // Interactive Volume Capsule Slider
        Rectangle {
          id: previewSlider
          Layout.fillWidth: true
          implicitHeight: 32
          radius: 8
          color: Style.appBackground
          border.color: Style.appBorder
          border.width: 1
          clip: true

          Rectangle {
            height: parent.height
            width: root.liveMuted ? 0 : Math.max(0, Math.min(parent.width, parent.width * (root.liveVolumePct / root.activeMaxVolume)))
            radius: 8
            color: (!root.liveMuted && root.liveVolumePct >= 135)
              ? Qt.alpha(Style.accentRed, 0.34)
              : ((!root.liveMuted && root.liveVolumePct > 100)
                ? Qt.alpha(Style.accentOrange, 0.32)
                : Qt.alpha(Style.accent, 0.24))

            Behavior on width {
              enabled: !previewSliderMouse.pressed
              NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
            }
          }

          Rectangle {
            visible: root.overAmplification
            x: Math.round(parent.width * (100.0 / root.activeMaxVolume))
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            width: 1.5
            radius: 1
            color: Style.textMuted
            opacity: 0.55
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
              text: root.liveMuted ? "Sessiz" : (root.liveVolumePct > 100 ? "Yükseltilmiş" : "Ses Düzeyi")
              font.family: Style.fontText
              font.pixelSize: 12
              font.weight: Font.Medium
              color: root.liveMuted ? Style.accentRed : (root.liveVolumePct > 100 ? Style.accentOrange : Style.textSecondary)
              Layout.fillWidth: true
            }

            Text {
              text: root.liveMuted ? "0%" : ("%" + root.liveVolumePct)
              font.family: Style.fontDisplay
              font.pixelSize: 12
              font.weight: Font.DemiBold
              color: root.liveMuted ? Style.accentRed : (root.liveVolumePct >= 135 ? Style.accentRed : (root.liveVolumePct > 100 ? Style.accentOrange : Style.textPrimary))
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

    // 2. Over-Amplification (%150 Boost)
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Ses Yükseltme (Over-Amplification)"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰕾"
          iconColor: root.overAmplification ? Style.accentOrange : Style.textSecondary
          title: "Maksimum Sesi %150'ye Çıkar"
          subtitle: "Tüm kaydırıcılarda ve kısayollarda üst sınırı %150 yapar."
          showDivider: root.overAmplification

          SettingsToggle {
            checked: root.overAmplification
            onToggled: isChecked => {
              root.overAmplification = isChecked
              if (!isChecked) {
                root.clampAllVolumesTo100()
                root.saveSoundSettings("%150 yükseltme kapatıldı ve yüksek sesler %100'e çekildi.")
              } else {
                root.saveSoundSettings("%150 ses yükseltme etkinleştirildi.")
              }
            }
          }
        }

        Rectangle {
          visible: root.overAmplification
          Layout.fillWidth: true
          implicitHeight: warnRow.implicitHeight + 18
          color: Qt.alpha(Style.accentOrange, 0.08)

          RowLayout {
            id: warnRow
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 9
            anchors.bottomMargin: 9
            spacing: 10

            Text {
              text: "󰀪"
              font.pixelSize: 14
              color: Style.accentOrange
              Layout.alignment: Qt.AlignTop
            }

            Text {
              text: "%100 üzeri yükseltme yüksek donanım kazancında seste bozulmaya yol açabilir. Kapatıldığında %100 üzerindeki sesler otomatik olarak %100'e çekilir."
              font.family: Style.fontText
              font.pixelSize: 11
              color: Style.textSecondary
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }
          }
        }
      }
    }

    // 3. Audio Feedback & Corner HUD OSD
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Geri Bildirim & Ekran Göstergesi"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰎆"
          title: "Ses Geri Bildirim Efektleri"
          subtitle: "Sistem ses olaylarında akustik efekt çalınmasını etkinleştirir."
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
          iconText: "󰂚"
          title: "Ses Değişimi Pop Sesi"
          subtitle: "Ses düzeyi değiştirildiğinde kısa geri bildirim sesi çalar."
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
          iconText: "󰔛"
          title: "Geri Bildirim Gecikmesi"
          subtitle: "Kaydırıcı veya tuş basılı tutulduğunda çalma sıklığı."
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
          iconText: "󰍹"
          title: "Köşe Ses Göstergesi (Corner HUD)"
          subtitle: "Ses değiştiğinde sol-üst köşede kompakt bildirim gösterir."
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
