---
title: "Plan: Dynamic Island & Control Center Audio Mixer Sub-App and Trigger Script"
type: agent-thought
tags:
  - ui/audio-mixer
  - control-center/views
  - dynamic-island/expanded
  - pulseaudio/pipewire
  - pactl/streams
created: 2026-08-19
updated: 2026-08-19
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Audio-Mixer-View]]"
  - "[[Style-Design-Tokens]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[System-Architecture]]"
---

# Plan: Dynamic Island & Control Center Audio Mixer Sub-App and Trigger Script

> [!IDEA]
> Control Center ana ekranındaki ses kapsülüne (Volume Slider) sağ tıklandığında veya harici kısayol scripti (`scripts/toggle_audio_mixer.sh`) çalıştırıldığında açılan; PipeWire / PulseAudio tabanlı aktif uygulama ses akışlarını (sink-inputs) ve çıkış aygıtlarını (sinks) listeleyen, her birine özel ses seviyesi ve sessize alma kontrolleri sunan zarif bir `AudioMixerView` bileşeni geliştirmek.

## User Requirements & Feature Specification

1. **Ses Barına Sağ Tık Etkileşimi:**
   - `ControlCenterMain.qml` içerisindeki `soundCapsule` ses çubuğuna **sağ tıklandığında** (`acceptedButtons: Qt.LeftButton | Qt.RightButton`) doğrudan `AudioMixerView` alt görünümü açılır (`root.openView("AUDIO_MIXER")`).
2. **Harici Çalıştırma Scripti:**
   - `scripts/toggle_audio_mixer.sh` oluşturuldu ve Unix socket üzerinden `toggle_audio_mixer` (veya `toggle_app` ile `app: "audio_mixer"`) aksiyonu gönderilerek Dynamic Island içerisinde Ses Karıştırıcısı açılıp kapatılabilir.
3. **İki Sekmeli (Tabs) Karıştırıcı Arayüzü:**
   - **Uygulamalar (Applications):** Sistemde anlık ses çalan tüm uygulamalar (Firefox, Spotify, Discord, Oyunlar vb.) listelenir. Her uygulamanın simgesi/ismi, bireysel sessize alma (Mute) butonu ve bağımsız ses düzeyi kapsül kaydırıcısı bulunur.
   - **Çıkış Cihazları (Output Devices):** Sistemdeki ses çıkış aygıtları (Kulaklık, Dahili Hoparlör, HDMI, USB DAC vb.) listelenir. Varsayılan çıkış seçimi, aygıt bazlı ses ve sessize alma yönetimi sunulur.
4. **Tasarım Dili (Apple HIG + Material You):**
   - Saf siyah / koyu cam zemin (`Style.surface`), şık yuvarlatılmış köşeler (`radius: 12`), tema renkleriyle aydınlanan interaktif kaydırıcılar (`Style.accent`), ve pürüzsüz mikro animasyonlar.

## Technical Design & Architecture

```mermaid
graph TD
    User[Kullanıcı] -->|Sağ Tık: Volume Slider| CCMain[ControlCenterMain.qml]
    Script[scripts/toggle_audio_mixer.sh] -->|IPC: toggle_audio_mixer| Daemon[Go Backend / DaemonIPC]
    Daemon --> Island[DynamicIsland.qml]
    CCMain -->|openView('AUDIO_MIXER')| CCView[ControlCenterView.qml]
    Island -->|expandedActiveTab = 'CONTROL_CENTER'| CCView

    CCView --> Mixer[AudioMixerView.qml]
    Mixer -->|Process: pactl -f json list sink-inputs| Streams[Uygulama Ses Akışları]
    Mixer -->|Process: pactl -f json list sinks| Sinks[Çıkış Aygıtları]
    Mixer -->|pactl set-sink-input-volume / mute| AudioEngine[PipeWire / PulseAudio Engine]
```

## Verification & Test Results

- `AudioMixerView.qml` oluşturuldu ve `ControlCenterView.qml` içine entegre edildi.
- `ControlCenterMain.qml` ses kapsülü `Qt.RightButton` ile `AudioMixerView` görünümünü açacak şekilde güncellendi.
- `scripts/toggle_audio_mixer.sh` oluşturuldu ve terminalden çalıştırılarak canlı olarak doğrulandı.
- Tüm `pactl` stream ve sink komutları test edilerek optimize edildi.
