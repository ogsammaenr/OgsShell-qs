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
> `shell/components/widgets/controlcenter/views/AudioMixerView.qml` (paired with `shell/components/widgets/controlcenter/views/VolumeCapsuleSlider.qml`) provides a PipeWire / PulseAudio powered volume mixer inside Control Center and Dynamic Island, displaying per-application audio streams (`sink-inputs`) and audio output devices (`sinks`) with independent volume sliders and mute toggles.

---

## 1. Tetikleme Yöntemleri (Trigger Methods)

1. **Ses Barına Sağ Tık:** `ControlCenterMain.qml` ana görünümündeki `soundCapsule` ses kaydırıcısına sağ tıklandığında (`mouse.button === Qt.RightButton`) doğrudan `AudioMixerView` alt görünümü açılır.
2. **Kısayol Scripti:** `~/.config/ogsShell/ogsshell.sh toggle_audio_mixer` (veya `ogsshell.sh mixer`) çalıştırıldığında (veya Hyprland kısayoluna bağlandığında) Dynamic Island açılarak Ses Karıştırıcısına odaklanır.

---

## 2. Arayüz ve Özellikler

* **Başlık Çubuğu:** Geri dön butonu (`󰁍`), "Ses Karıştırıcısı" rozeti ve anlık yenileme butonu (`󰑐`).
* **Sekmeler (Pill Tabs):**
  - **Uygulamalar (Applications):** Sistemde anlık ses çalan tüm aktif uygulamalar (Firefox, Spotify, Discord, Oyunlar vb.) rozet sayısı ile listelenir.
  - **Çıkış Cihazları (Output Devices):** Sistemdeki tüm ses çıkış donanımları (Kulaklık, Dahili Hoparlör, HDMI vb.) listelenir.
* **Uygulama Akış Kartları (Tek Kart Gruplaması):**
  - Aynı uygulamanın birden fazla PipeWire/PulseAudio `sink-input` akışı (ör. tarayıcı sekmeleri veya `corked` askıdaki akışlar) `application.name` / ikili adı bazında tek bir kart altında birleştirilir; alt akış sayısı 1'den büyükse alt başlıkta (`<N> akış • ...`) gösterilir.
  - Uygulama simgesi ve başlığı (örn. *Firefox* / *Zen* / *Vesktop*).
  - Bireysel sessize alma (Mute) butonu (`󰕾` / `󰖁`, uygulamanın tüm alt akışlarına `pactl set-sink-input-mute <id> 1|0` uygular).
  - Paylaşımlı `VolumeCapsuleSlider.qml` ses kapsülü kaydırıcısı (uygulamanın tüm alt akışlarına `pactl set-sink-input-volume <id> <vol>%` uygular).
* **Çıkış Aygıtı Kartları:**
  - Aygıt türü ikonu (Kulaklık, Hoparlör, HDMI).
  - "Varsayılan" butonu (`pactl get-default-sink` üzerinden aktif varsayılan vurgusu ve `pactl set-default-sink <name>`).
  - Master çıkış ses seviyesi ve sessize alma yönetimi (`pactl set-sink-volume` / `set-sink-mute <id> 1|0`).
* **Durum Koruma, Kaydırma Kararlılığı ve Sıralı Komut Kuyruğu:**
  - **Yerinde `ListModel` Uzlaştırması (`reconcileModel`):** `streamsModel` ve `sinksModel` periyodik taramalarda (`pollTimer`, 1800ms) sıfırdan dizi atamak yerine satırları `itemKey` (`app:<ad>` / `sink:<id>`) bazında yerinde günceller (`insert`, `remove`, `move`, `setProperty`). Böylece alt akışlar açılıp kapansa bile uzun listelerde kaydırma konumu (`ListView.contentY`) asla başa ışınlanmaz ve aktif sürükleme kesilmez.
  - **Kesintisiz Sıralı Komut Kuyruğu (`cmdQueue`):** `controlCmdProc` çalışan bir `pactl` işlemini `SIGTERM` ile öldürmez; aynı hedefe gelen hızlı güncellemeleri (`stream_vol:<id>`, `sink_vol:<id>`, `default_sink`) kuyrukta birleştirip `onExited` üzerinden sırayla yürütür.
  - **Eski Tarama Koruması:** Sürükleme (`isDragging`), mutasyon jenerasyon sayaçları (`streamMutationGen`/`sinkMutationGen`) ve öğe bazlı düzenleme kilidi (`recentEdits`, 850ms) sayesinde arka plandaki eski `pactl` çıktıları kullanıcının yeni ayarladığı ses veya sessiz durumunu geri döndürebilecek şekilde ezmez. `VolumeCapsuleSlider`, tek tık/sürükleme (`onPressed`/`onPositionChanged`/`onReleased`) ve tekerlek (`onWheel`) akışını çift tetikleme (`onClicked` tekrarı) olmadan yönetir.
* **Canlı Senkronizasyon & %150 Over-Amplification:** `Config.audioOverAmplification` (`[[Configuration-System-Spec]]`) aktif olduğunda hem **Uygulamalar (`sink-inputs`)** hem **Çıkış Aygıtları (`sinks`)** kaydırıcıları `%100` eşik işaretçisi ve boost renk vurgusuyla `%150`'ye kadar ayarlanabilir (`[[Settings-Application-Component]]`, `[[QML-Best-Practices]]`).

---

## 3. İlgili Bağlantılar

* Kontrol Merkezi: `[[Control-Center-Widget]]`
* Dinamik Ada: `[[Dynamic-Island-Component]]`
* Tasarım Tokenleri: `[[Style-Design-Tokens]]`
* Plan Notu: `[[Plan-Audio-Mixer-View-And-Trigger-Script]]`
