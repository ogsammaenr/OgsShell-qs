---
title: "Corner Island HUD Component"
type: ui-component
tags:
  - ui/corner-hud
  - quickshell/qml
  - screen-corners
  - hyprland/workspaces
  - pipewire/audio
  - clipboard
created: 2026-09-06
updated: 2026-09-06
status: active
related_notes:
  - "[[Screen-Corners-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Configuration-System-Spec]]"
  - "[[Audio-Feedback-Service]]"
  - "[[Clipboard-Service]]"
  - "[[Keyboard-Service]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Plan-Corner-Island-HUD]]"
---

# Corner Island HUD Component (`shell/components/corners/CornerIslandHUD.qml`)

> [!NOTE]
> Ekranın sol-üst köşesindeki içbükey (concave) yuvarlamayı; ses değişimi, workspace geçişi, caps lock, mikrofon durumu ve pano kopyalama gibi anlık sistem olaylarında Apple Dynamic Island fizik standartlarında (`SpringAnimation`) genişleterek kompakt bir OLED Siyah HUD kapsülü oluşturan modüler arayüz bileşenidir.

---

## 1. Mimari ve Bileşen Yapısı

Corner Island HUD sistemi üç ana katmandan oluşur:

1. **`CornerHUDService.qml` (Global Olay Yöneticisi & Sinyal Dağıtıcı):**
   - `Pipewire.defaultAudioSink` (Ses seviyesi ve mute) ve `Pipewire.defaultAudioSource` (Mikrofon mute) durumlarını izler.
   - `DaemonIPC` üzerinden `clipboardItemCopied` (Pano kopyalama) ve `capsLockChanged` (Caps Lock) olaylarını dinler.
   - `triggerEvent(type, payload, timeoutMs)` API'si ile dinamik önceliklendirme ve zamanlayıcı yönetimi sağlar.
2. **`CornerIslandHUD.qml` (Morphing Vektör & Kapsül Alanı):**
   - **IDLE Durumu:** `14px` x `14px` içbükey siyah kavis çizer.
   - **EXPANDED Durumu:** Yumuşak ve akıcı genişleme animasyonu (`duration: 360ms`, `Easing.OutCubic`) ile `(0,0)` ekran köşesine oturan, sağ üstünde ve sol altında dışa doğru Bézier kavisli kulaklara (`PathCubic`) ve sağ altında yuvarlatılmış köşeye (`PathArc`) sahip borderless saf OLED Siyah (`#000000`) bir HUD kapsülüne dönüşür. İçerikler (`contentContainer`) kapsül açılırken zarif bir ölçek ve opaklık geçişiyle (`scale: 0.92 -> 1.0`) belirir.
   - Modüler içerik slotları (Volume, Workspace Dots, CapsLock, Mic, Clipboard).
   - `localEvent` desteği ve `showWorkspaceHUD(activeWsId, displayTitle, workspacesList)` fonksiyonu ile monitöre özel bağımsız OSD gösterimi.
3. **`ScreenCorners.qml` (Monitör Bazlı Köşe Katmanı Entegrasyonu):**
   - Her ekranda bağımsız çalışan `ScreenCorners` örneği, bağlı olduğu monitörün `currentWsId` (`hyprMonitor.activeWorkspace.id`) değerini ve o ekrana ait `monitorWorkspaces` listesini hesaplar.
   - **Monitör İzolasyonu & Focus Ayrımı:** Monitörler arası fare/odak geçişlerinde masaüstü ID'si değişmediğinden yanlış bildirimler tamamen engellenir. Sadece aktif olarak masaüstü değiştirilen monitörün sol-üst köşesinde HUD açılır.
   - `mask: Region {}` sayesinde alttaki uygulamalara **%100 tıklama şeffaflığı** sunar.

---

## 2. Desteklenen Olay Slotları (Dynamic Event Slots)

```text
┌────────────────────────────────────────────────────────┐
│  󱂬   [•] [====] [•] [•] [•]                            │
│                                                     ╭──╯
└─────────────────────────────────────────────────────╯
```

| Olay Tipi | İkon | Görsel Öğeler | Davranış & Animasyon |
| :--- | :---: | :--- | :--- |
| `VOLUME` | `󰕾`/`󰖀`/`󰕿`/`󰝟` | Yatay ses çubuğu, yüzde metni | 1500 ms dinamik slider dolumu |
| `WORKSPACE` | `󱂬` | Monitöre özel çalışma alanı noktaları (`Repeater`, metinsiz) | Aktif nokta genişler (`18px`, `accentBlue`), pasif noktalar (`6px`). Noktalar arası `SpringAnimation` ve renk geçişi. |
| `CAPSLOCK` | `󰪛` | Durum rozeti (`AÇIK` - Yeşil / `KAPALI` - Gri) | 1500 ms durum rozeti |
| `MIC` | `󰍬`/`󰍭` | Mikrofon durum rozeti (`Açık` / `Sessiz`) | 1600 ms mute uyarısı |
| `CLIPBOARD` | `󰅍` | "Pano Kopyalandı" başlığı, kırpılmış metin | 2000 ms metin toast bildirimi |

---

## 3. Konfigürasyon Şeması (`config.json`)

```json
"corner_hud": {
  "enabled": true,
  "volume_enabled": true,
  "workspace_enabled": true,
  "capslock_enabled": true,
  "mic_enabled": true,
  "clipboard_enabled": true,
  "timeout_ms": 1800,
  "height": 34
}
```

---

## 4. İlgili Bağlantılar

* Köşe Yuvarlama Bileşeni: `[[Screen-Corners-Component]]`
* Konfigürasyon Sistemi: `[[Configuration-System-Spec]]`
* Ses Geri Bildirim Servisi: `[[Audio-Feedback-Service]]`
* Pano Servisi: `[[Clipboard-Service]]`
* Klavye Servisi: `[[Keyboard-Service]]`
* Ajan Düşünce Notu: `[[Plan-Corner-Island-HUD]]`
