---
title: "Audio Feedback Service (Quickshell)"
type: service
tags:
  - audio/feedback
  - pipewire/quickshell
  - system-sounds
  - quickshell/qml
created: 2026-09-06
updated: 2026-09-06
status: active
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Control-Center-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
  - "[[Plan-Audio-Volume-Feedback-Sound]]"
---

# Audio Feedback Service (`shell/backend/AudioFeedbackService.qml`)

> [!NOTE]
> A shell-wide singleton service that tracks system output volume across all sources (hardware hotkeys, Hyprland binds, CLI tools, and Control Center sliders) and plays a lightweight, non-blocking acoustic feedback sound with anti-spam throttling.

---

## 1. Overview & Architecture

* **Global PipeWire Tracking:** Uses `Quickshell.Services.Pipewire` (`PwObjectTracker`) to listen to `Pipewire.defaultAudioSink.audio.onVolumeChanged` directly from the PipeWire graph.
* **Startup Cooldown (1s):** Suppresses spurious audio clicks during shell initialization and initial daemon handshakes.
* **Mute Suppression:** When the output sink is muted (`isMuted: true`) or volume is zero, feedback playback is bypassed.
* **Throttle Engine (100ms):** Smoothly coalesces rapid slider dragging and held hardware keys to prevent audio popping and process congestion.
* **Multi-Tier Sound Player:**
  1. `canberra-gtk-play -i audio-volume-change -d 'volume-change'` (XDG theme compliant)
  2. `pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga`
  3. `pw-play /usr/share/sounds/ocean/stereo/audio-volume-change.oga`
  4. User-defined `custom_sound_path` in `config.json`.

---

## 2. Configuration Schema (`config.json`)

```json
"audio_feedback": {
  "enabled": true,
  "volume_change_sound": true,
  "throttle_ms": 100,
  "custom_sound_path": ""
}
```

---

## 3. Related Links

* Config Engine Spec: `[[Configuration-System-Spec]]`
* Control Center: `[[Control-Center-Widget]]`
* Proposal Plan: `[[Plan-Audio-Volume-Feedback-Sound]]`
