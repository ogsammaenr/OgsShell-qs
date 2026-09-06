import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

Item {
  id: root
  visible: false

  property bool isInitialized: false
  property double lastVolume: -1.0
  property bool lastMuted: false

  // Native PipeWire Volume & Mute Tracking (Global Shell-Wide Tracker)
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  // Audio Playback Process
  Process {
    id: playProc
  }

  // Startup Cooldown Timer: Prevents annoying beep on shell boot or initial sink sync
  Timer {
    id: initCooldownTimer
    interval: 1000
    repeat: false
    running: true
    onTriggered: {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.lastVolume = Pipewire.defaultAudioSink.audio.volume
        root.lastMuted = Pipewire.defaultAudioSink.audio.muted
      }
      root.isInitialized = true
      console.log("[AudioFeedbackService] Initialized audio volume feedback listener. Current Volume:", Math.round(root.lastVolume * 100) + "%")
    }
  }

  // Throttle Timer: Coalesces rapid slider dragging or held volume hotkeys into crisp rhythmic feedback
  Timer {
    id: soundThrottleTimer
    interval: (Config.audioFeedbackThrottleMs !== undefined && Config.audioFeedbackThrottleMs > 0) ? Config.audioFeedbackThrottleMs : 100
    repeat: false
    onTriggered: {
      root.playFeedbackSound()
    }
  }

  // Reactive Sink Volume Listener
  Connections {
    target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    function onVolumeChanged() {
      if (!root.isInitialized) return
      if (!Config.audioFeedbackEnabled || !Config.audioFeedbackVolumeChangeSound) return

      let currentVol = (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.volume : -1.0
      let isMuted = (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.muted : false

      // If muted or volume is essentially zero, update baseline silently without sound
      if (isMuted || currentVol <= 0.001) {
        root.lastVolume = currentVol
        return
      }

      // If volume change delta is at least 0.5% (prevents micro-jitter loop)
      if (Math.abs(currentVol - root.lastVolume) >= 0.005) {
        root.lastVolume = currentVol
        if (!soundThrottleTimer.running) {
          soundThrottleTimer.restart()
        }
      }
    }

    function onMutedChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.lastMuted = Pipewire.defaultAudioSink.audio.muted
      }
    }
  }

  // Reactive Sink Switch Listener
  Connections {
    target: Pipewire
    function onDefaultAudioSinkChanged() {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        root.lastVolume = Pipewire.defaultAudioSink.audio.volume
        root.lastMuted = Pipewire.defaultAudioSink.audio.muted
      }
    }
  }

  // Playback execution method
  function playFeedbackSound() {
    let customPath = Config.audioFeedbackCustomSoundPath || ""
    let cmd = []

    if (customPath.length > 0) {
      cmd = ["pw-play", "--latency=20ms", customPath]
    } else {
      let bashScript = "if command -v canberra-gtk-play >/dev/null 2>&1; then " +
        "canberra-gtk-play -i audio-volume-change -d 'volume-change' 2>/dev/null; " +
        "elif [ -f /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga ]; then " +
        "pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga 2>/dev/null; " +
        "elif [ -f /usr/share/sounds/ocean/stereo/audio-volume-change.oga ]; then " +
        "pw-play /usr/share/sounds/ocean/stereo/audio-volume-change.oga 2>/dev/null; " +
        "fi"
      cmd = ["/usr/bin/bash", "-c", bashScript]
    }

    playProc.running = false
    playProc.command = cmd
    playProc.running = true
  }
}
