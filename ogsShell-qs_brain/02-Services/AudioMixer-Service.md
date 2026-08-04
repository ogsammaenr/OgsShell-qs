---
title: "Audio Mixer Service"
type: service
tags:
  - service/audio
  - python/pulseaudio
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[ControlCenter-UI]]"
---

# Audio Mixer Service

> [!NOTE]
> `AudioMixerService.qml` manages PipeWire / WirePlumber / PulseAudio streams and volume controls by interfacing with `bin/audio_mixer_helper.py`.

## Script Interface (`bin/audio_mixer_helper.py`)

- **Commands:**
  - `--json`: Dumps sinks (output devices) and sink inputs (application audio streams).
  - `--set-default <sink_name>`: Switches active audio output device.
  - `--set-media-vol <pct>`: Sets active media player volume.
  - `--set-media-mute`: Toggles mute state.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Control Center UI: `[[ControlCenter-UI]]`
