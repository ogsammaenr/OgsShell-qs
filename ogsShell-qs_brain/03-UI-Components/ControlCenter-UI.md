---
title: "Control Center Overlay UI"
type: ui-component
tags:
  - ui/controlcenter
  - ui/overlay
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[AudioMixer-Service]]"
  - "[[Bluetooth-Service]]"
  - "[[ThemeSync-Service]]"
  - "[[Shell-Bar-Components]]"
---

# Control Center Overlay UI

> [!NOTE]
> The Control Center is an overlay panel rendered inside `ControlCenterWindow.qml` (`PanelWindow`). It provides quick system controls for Wi-Fi, Bluetooth, Audio Streams, Themes, and Clipboard history.

## Sub-Components

- **Action Buttons (`ActionButtons.qml`):** Quick toggles for Wi-Fi, Bluetooth, Game Mode, and Night Light.
- **Audio Mixer (`ControlCenterAudioMixer.qml`):** Per-app audio sliders and output device selector interfaced with `[[AudioMixer-Service]]`.
- **Bluetooth Manager (`ControlCenterBluetooth.qml`):** Device discovery list interfaced with `[[Bluetooth-Service]]`.
- **Wi-Fi Manager (`ControlCenterWifiList.qml`):** APN scanner and password prompt (`ControlCenterWifiPassword.qml`).
- **Theme Selector (`ControlCenterThemeList.qml`):** Live theme grid interfaced with `[[ThemeSync-Service]]`.
- **Clipboard History (`ControlCenterClipboard.qml`):** Recent clipboard history manager.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Audio Mixer Service: `[[AudioMixer-Service]]`
- Bluetooth Service: `[[Bluetooth-Service]]`
- Theme Sync Service: `[[ThemeSync-Service]]`
