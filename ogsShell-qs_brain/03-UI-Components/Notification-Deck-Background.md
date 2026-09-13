---
title: "Notification Deck Background QML Component"
type: ui-component
tags:
  - ui/dynamic-island
  - quickshell/qml
  - notifications
  - animations
  - deck
status: active
---

# Notification Deck Background QML Component

> [!NOTE]
> `shell/components/island/NotificationDeckBackground.qml`, Dynamic Island ve Dynamic Notch bildirim katmanında bekleyen bildirimler olduğunda arkada 3D derinlik hissi veren katmanlı kart silüetlerini çizen görsel bileşendir.

---

## 1. Mimari ve Görevler

* **Katmanlı Kart Deste Efekti:** Deste seviyesine (`tierLevel: 2` veya `tierLevel: 3`) göre genişlik ölçekleme (`widthRatio`), dikey kaydırma (`islandYOffset` / `notchExtraHeight`) ve opaklık (`targetOpacity`) hesaplar.
* **Notch ve Island Uyumluluğu:** `Config.isNotch` moduna bağlı olarak ya `Shape` ve Bézier eğrileri ile üst panele yapışık notch şeklinde ya da süzülen kapsül `Rectangle` şeklinde çizilir.
* **Dinamik Geçiş İnterpolasyonu:** Ön kart kapatıldığında veya değiştiğinde `shiftProgress` (0.0 -> 1.0) parametresiyle kademeli olarak bir üst katmana doğru genişler ve yükselir.
* **Aciliyet Vurgusu:** Kartın aciliyet seviyesi (`urgency === "critical"`) olduğunda kenar çizgi rengi (`strokeColor`) uyarı tonlarına bürünür.

---

## 2. Özellikler ve Arayüz (Properties)

| Özellik Adı | Tip | Varsayılan | Açıklama |
| :--- | :--- | :--- | :--- |
| `tierLevel` | `int` | `2` | Deste seviyesi (2: hemen arkadaki kart, 3: en alttaki kart) |
| `isNotch` | `bool` | `Config.isNotch` | Çentik modunda olup olmadığı |
| `baseWidth` | `real` | `360` | Temel ada genişliği |
| `baseHeight` | `real` | `56` | Temel ada yüksekliği |
| `activeRadius` | `real` | `28` | Temel köşe yarıçapı |
| `surfaceColor` | `color` | `Style.bgSecondary` | Yüzey dolgu rengi |
| `visibleTier` | `bool` | `false` | Katmanın görünür olup olmadığı |
| `urgency` | `string` | `"normal"` | Bildirimin aciliyet düzeyi |
| `shiftProgress` | `real` | `0.0` | Deste geçiş animasyon ilerlemesi (0.0 - 1.0) |
| `hasCardBehind` | `bool` | `false` | Arkada daha fazla kart olup olmadığı |

---

## 3. İlgili Bağlantılar

* Dynamic Island Bileşeni: `[[Dynamic-Island-Component]]`
* Bildirim Kartı Görünümü: `[[Notification-Card-View]]`
* Stil ve Tasarım Token'ları: `[[Style-Design-Tokens]]`
* Root Pencere Katmanı: `[[Shell-Root-PanelWindow]]`
