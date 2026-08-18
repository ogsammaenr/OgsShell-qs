---
title: "Audio Mixer View Component Specification"
type: ui-component
tags:
  - ui/audio-mixer
  - control-center/views
  - dynamic-island/expanded
  - pulseaudio/pipewire
  - pactl/streams
created: 2026-08-19
updated: 2026-08-19
status: active
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[Plan-Audio-Mixer-View-And-Trigger-Script]]"
---

# Audio Mixer View Component Specification

> [!NOTE]
> `shell/components/widgets/controlcenter/views/AudioMixerView.qml` provides a PipeWire / PulseAudio powered volume mixer inside Control Center and Dynamic Island, displaying per-application audio streams (sink-inputs) and audio output devices (sinks) with independent volume sliders and mute toggles.

---

## 1. Tetikleme Yöntemleri (Trigger Methods)

1. **Ses Barına Sağ Tık:** `ControlCenterMain.qml` ana görünümündeki `soundCapsule` ses kaydırıcısına sağ tıklandığında (`mouse.button === Qt.RightButton`) doğrudan `AudioMixerView` alt görünümü açılır.
2. **Kısayol Scripti:** `scripts/toggle_audio_mixer.sh` çalıştırıldığında (veya Hyprland kısayoluna bağlandığında) Dynamic Island açılarak Ses Karıştırıcısına odaklanır.

---

## 2. Arayüz ve Özellikler

* **Başlık Çubuğu:** Geri dön butonu (`󰁍`), "Ses Karıştırıcısı" rozeti ve anlık yenileme butonu (`󰑐`).
* **Sekmeler (Pill Tabs):**
  - **Uygulamalar (Applications):** Sistemde anlık ses çalan tüm aktif uygulamalar (Firefox, Spotify, Discord, Oyunlar vb.) rozet sayısı ile listelenir.
  - **Çıkış Cihazları (Output Devices):** Sistemdeki tüm ses çıkış donanımları (Kulaklık, Dahili Hoparlör, HDMI vb.) listelenir.
* **Uygulama Akış Kartları:**
  - Uygulama simgesi ve başlığı (örn. *Firefox* / *YouTube*).
  - Bireysel sessize alma (Mute) butonu (`󰕾` / `󰖁`).
  - Akıcı ses kapsülü kaydırıcısı (`pactl set-sink-input-volume <id> <vol>%`).
* **Çıkış Aygıtı Kartları:**
  - Aygıt türü ikonu (Kulaklık, Hoparlör, HDMI).
  - "Varsayılan Yap" butonu (`pactl set-default-sink <id>`).
  - Master çıkış ses seviyesi ve sessize alma yönetimi.
* **Canlı Senkronizasyon:** Periyodik arka plan taraması ve kullanıcı kaydırma hareketinde anlık optimistik arayüz tepkisi.

---

## 3. İlgili Bağlantılar

* Kontrol Merkezi: `[[Control-Center-Widget]]`
* Dinamik Ada: `[[Dynamic-Island-Component]]`
* Tasarım Tokenleri: `[[Style-Design-Tokens]]`
* Plan Notu: `[[Plan-Audio-Mixer-View-And-Trigger-Script]]`
