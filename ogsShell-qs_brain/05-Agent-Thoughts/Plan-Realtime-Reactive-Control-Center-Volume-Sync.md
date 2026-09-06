---
title: "Plan: Realtime Reactive Control Center Volume Synchronization"
type: agent-thought
tags:
  - proposal/audio
  - ui/control-center
  - pipewire/quickshell
  - reactive-sync
created: 2026-09-03
updated: 2026-09-03
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Audio-Mixer-View]]"
  - "[[Dynamic-Island-Component]]"
  - "[[QML-Best-Practices]]"
---

# Plan: Realtime Reactive Control Center Volume Synchronization

> [!IDEA]
> Kontrol Merkezi açıkken donanımsal klavye kısayolları, harici uygulamalar veya komut satırı araçları (`pamixer`, `wpctl`, `pactl`) ile ses seviyesi veya sessize alma (mute) durumu değiştirildiğinde, `ControlCenterMain.qml` içerisindeki ses seviyesi kapsülünün anlık (0ms gecikmeli) ve reaktif olarak güncellenmesi sağlanacaktır.

## 1. Problem Tanımı
Mevcut durumda `ControlCenterMain.qml`:
1. Ses seviyesini ve sessiz durumunu sadece bileşen ilk oluşturulduğunda (`Component.onCompleted`) tek seferlik `pamixer --get-volume` ve `pamixer --get-mute` çalıştırarak almaktadır.
2. Kontrol merkezi ekranda açıkken harici bir kaynaktan (örn. klavyedeki ses açma/kapama/kısma tuşları, `wpctl`, `pactl`, `pamixer`, harici mikser veya başka bir uygulama) ses seviyesi değiştirildiğinde veya ses kapatıldığında (mute), arayüzdeki ses kaydırıcısı ve yüzde göstergesi eski değerde donuk kalmaktadır.
3. Kontrol merkezi kapatılıp tekrar açıldığında da bileşen yok edilmediği için `Component.onCompleted` tekrar tetiklenmemekte ve bayat (stale) ses verisi gösterilmeye devam etmektedir.

## 2. Çözüm Yaklaşımı
1. **Quickshell Native PipeWire Servisi:**
   - `Quickshell.Services.Pipewire` modülü import edilir.
   - `PwObjectTracker { objects: [Pipewire.defaultAudioSink] }` ile varsayılan ses çıkış cihazı (`defaultAudioSink`) anlık izlemeye alınır.
   - `Connections` blokları ile `Pipewire.defaultAudioSink.audio.volume` ve `Pipewire.defaultAudioSink.audio.muted` sinyalleri yakalanarak `root.volumeLevel` ve `root.isMuted` değişkenleri gerçek zamanlı (0ms gecikme ile) güncellenir.
2. **Çift Yönlü Etkileşim:**
   - Kullanıcı Kontrol Merkezi kaydırıcısını hareket ettirdiğinde veya sessize alma butonuna tıkladığında doğrudan `Pipewire.defaultAudioSink.audio.volume` ve `muted` değerleri yazılır; PipeWire bulunmadığı durumlarda ise `pamixer` fallback mekanizması devreye girer.
3. **Görünürlük ve Yaşam Döngüsü Senkronizasyonu:**
   - `onVisibleChanged` sinyali eklenerek Kontrol Merkezi her görünür olduğunda parlaklık ve ses telemetrisi yeniden senkronize edilir (`syncTelemetry()`).
4. **Ses Karıştırıcısı (`AudioMixerView.qml`):**
   - Görünüm açıldığında (`onVisibleChanged`) anında ses akışlarının tazelenmesi garanti edilir.

## 3. Etkilenen Dosyalar
- `[[Control-Center-Widget]]` -> `shell/components/widgets/controlcenter/ControlCenterMain.qml`
- `[[Audio-Mixer-View]]` -> `shell/components/widgets/controlcenter/views/AudioMixerView.qml`
- `shell/components/widgets/controlcenter/ControlCenterView.qml`
