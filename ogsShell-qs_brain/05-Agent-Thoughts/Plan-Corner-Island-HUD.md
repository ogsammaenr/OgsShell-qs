---
title: "Plan: Dynamic Corner Island HUD (Sol-Üst Köşe Yuvarlama HUD)"
type: agent-thought
tags:
  - plan/corner-hud
  - quickshell/qml
  - screen-corners
  - hyprland/workspaces
  - pipewire/audio
  - clipboard
  - config/schema
created: 2026-09-06
updated: 2026-09-06
status: implemented
related_notes:
  - "[[Screen-Corners-Component]]"
  - "[[Corner-Island-HUD-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Configuration-System-Spec]]"
  - "[[Audio-Feedback-Service]]"
  - "[[Clipboard-Service]]"
  - "[[Keyboard-Service]]"
  - "[[Dynamic-Island-Component]]"
  - "[[System-Architecture]]"
---

# Plan: Dynamic Corner Island HUD (Sol-Üst Köşe Yuvarlama HUD)

> [!IDEA]
> Ekranın sol-üst köşesindeki statik içbükey (concave) yuvarlamayı; ses değişimi, workspace geçişi, caps lock, mikrofon mute ve pano kopyalama gibi anlık sistem olaylarında Apple Dynamic Island fiziğiyle (`SpringAnimation`) dışa doğru genişleyen modüler bir OLED Siyah HUD kapsülüne dönüştürmek.

---

## 1. Problem ve Tasarım Vizyonu

Mevcut durumda ekranın 4 köşesinde `14px` yarıçapında statik siyah kavisler ([`ScreenCorners.qml`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/corners/ScreenCorners.qml)) yer almaktadır. 

Kullanıcı etkileşimlerinde (ses açma/kısma, masaüstü değiştirme, kopyalama, caps lock açma/kapama):
- Merkezi Dynamic Island'ı OSD bildirimleriyle meşgul etmek yerine, ekranın sol-üst köşesindeki kavis organik olarak açılarak kompakt ve estetik bir durum kapsülü oluşturur.
- Olay tamamlandıktan 1.5 - 2 saniye sonra kapsül pürüzsüzce tekrar sol-üst köşedeki `14px`'lik statik kavis formuna geri çekilir.

---

## 2. Desteklenen Olaylar (Triggers)

1. **Ses Seviyesi Değişimi (`VOLUME`):**
   - Kaynak: `Pipewire.defaultAudioSink.audio.volume` ve `muted`.
   - Görünüm: `󰕾` / `󰖀` / `󰕿` / `󰝟` ikonu, ince dinamik ilerleme çubuğu (progress bar), yüzde metni (`%75`).
2. **Workspace Değişimi (`WORKSPACE`):**
   - Kaynak: Per-screen `hyprMonitor.activeWorkspace.id` (Monitörler arası odak/fare geçişleri izole edilmiştir).
   - Görünüm: `󱂬` ikonu, `WS <ID>` metni ve o monitöre özel çalışma alanı noktaları (`Repeater`). Aktif masaüstü noktası `16px` hap formunda parlar, diğerleri soluklaşır. Noktalar arası `SpringAnimation` ile akıcı kayma hissi sağlanır.
3. **Caps Lock Durumu (`CAPSLOCK`):**
   - Kaynak: Sysfs LED watcher (`/sys/class/leds/*capslock*/brightness`) veya Hyprland keyboard state.
   - Görünüm: `󰪛` ikonu, `CAPS LOCK AÇIK` (Yeşil/Vurgulu) / `KAPALI` rozeti.
4. **Mikrofon Mute (`MIC`):**
   - Kaynak: `Pipewire.defaultAudioSource.audio.muted`.
   - Görünüm: `󰍬` (Açık) / `󰍭` (Sessiz - Kırmızı/Turuncu rozet).
5. **Pano Kopyalama (`CLIPBOARD`):**
   - Kaynak: `DaemonIPC.clipboardItemCopied` (Go backend `clipboard_item_copied`).
   - Görünüm: `󰅍` ikonu, `Kopyalandı` başlığı ve kırpılmış metin önizlemesi (`"export const foo = ..."`).

---

## 3. Uygulanan Mimari Bileşenler

* **`shell/components/corners/CornerIslandHUD.qml`:**
  - Morphing vektör yolu (`QtQuick.Shapes`) ve dinamik genişlik/yükseklik (`SpringAnimation: spring: 28.0, damping: 0.78`).
  - Çoklu durum slotları: `VolumeSlot`, `WorkspaceSlot`, `CapsSlot`, `MicSlot`, `ClipboardSlot`.
* **`shell/components/corners/CornerHUDService.qml`:**
  - Singleton / Event Dispatcher: Olayları dinler, önceliklendirir ve `triggerEvent(type, data)` API'si ile `CornerIslandHUD`'ı tetikler.
* **`shell/backend/Config.qml` & `shell/config.json`:**
  - `"corner_hud"` şema bloğu (açma/kapama, süre, tetikleyici bazlı filtreler).

---

## 4. İlgili Bağlantılar

* Köşe Bileşeni: `[[Screen-Corners-Component]]`
* Corner HUD Bileşeni: `[[Corner-Island-HUD-Component]]`
* Konfigürasyon Şeması: `[[Configuration-System-Spec]]`
* PipeWire Ses: `[[Audio-Feedback-Service]]`
* Pano Servisi: `[[Clipboard-Service]]`
* Klavye Servisi: `[[Keyboard-Service]]`
