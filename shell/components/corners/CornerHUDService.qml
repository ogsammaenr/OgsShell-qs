import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "../.."
import "../../theme"

Item {
  id: root

  property var ipc: null
  property var activeEvent: null
  property bool isVisible: activeEvent !== null

  // Cooldown timer to prevent initial boot/sync spam
  property bool isInitialized: false

  // PipeWire Sink (Speaker/Volume) & Source (Microphone) Tracking
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  // Startup Cooldown
  Timer {
    id: startupCooldownTimer
    interval: 1200
    repeat: false
    running: true
    onTriggered: {
      root.isInitialized = true
      console.log("[CornerHUDService] Initialized corner HUD service listeners.")
    }
  }

  // Dismiss Timer
  Timer {
    id: dismissTimer
    interval: (Config.cornerHudTimeoutMs !== undefined && Config.cornerHudTimeoutMs > 0) ? Config.cornerHudTimeoutMs : 1800
    repeat: false
    onTriggered: {
      root.dismiss()
    }
  }

  // Public API to trigger an event HUD
  function triggerEvent(type, payload, customTimeoutMs) {
    if (!Config.cornerHudEnabled) return

    let eventData = {
      "type": type || "GENERIC",
      "icon": payload.icon || "󰋼",
      "title": payload.title || "",
      "subtitle": payload.subtitle || "",
      "progress": (payload.progress !== undefined) ? payload.progress : -1,
      "badgeColor": payload.badgeColor || Style.accent,
      "isMuted": !!payload.isMuted,
      "isCaps": !!payload.isCaps
    }

    root.activeEvent = eventData

    let defaultTimeout = (Config.cornerHudTimeoutMs > 0) ? Config.cornerHudTimeoutMs : 1200
    let timeout = (customTimeoutMs && customTimeoutMs > 0) ? customTimeoutMs : defaultTimeout
    dismissTimer.interval = timeout
    dismissTimer.restart()
  }

  function dismiss() {
    dismissTimer.stop()
    root.activeEvent = null
  }

  // =========================================================================
  // 1. PipeWire Volume & Mute Listener
  // =========================================================================
  property double lastVolume: -1.0
  property bool lastSinkMuted: false

  Connections {
    target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    function onVolumeChanged() {
      if (!root.isInitialized) return
      if (!Config.cornerHudEnabled || !Config.cornerHudVolume) return

      let sink = Pipewire.defaultAudioSink
      if (!sink || !sink.audio) return

      let currentVol = sink.audio.volume
      let isMuted = sink.audio.muted

      if (Math.abs(currentVol - root.lastVolume) >= 0.005 || isMuted !== root.lastSinkMuted) {
        root.lastVolume = currentVol
        root.lastSinkMuted = isMuted

        let volPercent = Math.round(currentVol * 100)
        let icon = "󰕾"
        let badgeColor = Style.accent

        if (isMuted || volPercent === 0) {
          icon = "󰝟"
          badgeColor = Style.accentRed
        } else if (volPercent < 30) {
          icon = "󰕿"
        } else if (volPercent < 70) {
          icon = "󰖀"
        }

        root.triggerEvent("VOLUME", {
          "icon": icon,
          "title": "Ses",
          "subtitle": isMuted ? "Sessiz" : (volPercent + "%"),
          "progress": isMuted ? 0 : Math.min(1.0, currentVol),
          "badgeColor": badgeColor,
          "isMuted": isMuted
        })
      }
    }

    function onMutedChanged() {
      if (!root.isInitialized) return
      if (!Config.cornerHudEnabled || !Config.cornerHudVolume) return

      let sink = Pipewire.defaultAudioSink
      if (!sink || !sink.audio) return

      let isMuted = sink.audio.muted
      root.lastSinkMuted = isMuted

      let currentVol = sink.audio.volume
      let volPercent = Math.round(currentVol * 100)

      root.triggerEvent("VOLUME", {
        "icon": isMuted ? "󰝟" : (volPercent >= 70 ? "󰕾" : (volPercent >= 30 ? "󰖀" : "󰕿")),
        "title": "Ses",
        "subtitle": isMuted ? "Sessize Alındı" : (volPercent + "%"),
        "progress": isMuted ? 0 : Math.min(1.0, currentVol),
        "badgeColor": isMuted ? Style.accentRed : Style.accent,
        "isMuted": isMuted
      })
    }
  }

  // =========================================================================
  // 2. PipeWire Microphone Mute Listener
  // =========================================================================
  property bool lastSourceMuted: false

  Connections {
    target: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null

    function onMutedChanged() {
      if (!root.isInitialized) return
      if (!Config.cornerHudEnabled || !Config.cornerHudMic) return

      let source = Pipewire.defaultAudioSource
      if (!source || !source.audio) return

      let isMuted = source.audio.muted
      root.lastSourceMuted = isMuted

      root.triggerEvent("MIC", {
        "icon": isMuted ? "󰍭" : "󰍬",
        "title": "Mikrofon",
        "subtitle": isMuted ? "Sessize Alındı" : "Mikrofon Açık",
        "badgeColor": isMuted ? Style.accentOrange : Style.accentGreen,
        "isMuted": isMuted
      })
    }
  }

  // =========================================================================
  // 3. DaemonIPC Signals (Caps Lock & Clipboard Item Copied)
  // =========================================================================
  Connections {
    target: root.ipc

    function onClipboardItemCopied(payload) {
      if (!root.isInitialized) return
      if (!Config.cornerHudEnabled || !Config.cornerHudClipboard) return
      if (!payload) return

      let preview = payload.preview || ""
      preview = preview.replace(/[\r\n\t]+/g, " ").trim()
      if (preview.length > 28) {
        preview = preview.substring(0, 28) + "..."
      }
      if (preview.length === 0) {
        preview = "Metin panoya alındı"
      }

      let clipTimeout = Math.round(((Config.cornerHudTimeoutMs > 0) ? Config.cornerHudTimeoutMs : 1200) * 1.25)
      root.triggerEvent("CLIPBOARD", {
        "icon": "󰅍",
        "title": "Kopyalandı",
        "subtitle": preview,
        "badgeColor": Style.accentMagenta
      }, clipTimeout)
    }

    function onCapsLockChanged(payload) {
      if (!root.isInitialized) return
      if (!Config.cornerHudEnabled || !Config.cornerHudCapslock) return
      if (!payload) return

      let isCaps = !!payload.caps_lock

      root.triggerEvent("CAPSLOCK", {
        "icon": "󰪛",
        "title": "Caps Lock",
        "subtitle": isCaps ? "AÇIK" : "KAPALI",
        "badgeColor": isCaps ? Style.accentGreen : Style.textMuted,
        "isCaps": isCaps
      })
    }
  }
}
