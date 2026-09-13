---
title: "Notification Card View QML Component"
type: ui-component
tags:
  - ui/dynamic-island
  - quickshell/qml
  - notifications
  - animations
  - deck
created: 2026-09-13
updated: 2026-09-13
status: active
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
---

# Notification Card View QML Component

> [!NOTE]
> `shell/components/island/NotificationCardView.qml`, Dynamic Island ve Dynamic Notch bildirim katmanında tek bir bildirimin ikonunu, aciliyet halkasını, başlığını, gövde metnini ve destede bekleyen kalan kart sayısını gösteren modüler görsel bileşendir.

---

## 1. Mimari ve Görevler

* **Modüler Slot:** `DynamicIsland.qml` içerisindeki monolitik kod yapısını sadeleştirerek hem aktif (`currentCardContainer`) hem de geçiş anında gelen (`incomingCardContainer`) kartların aynı bileşeni kullanmasını sağlar.
* **GPU Hızlandırmalı Translate Uyumluluğu:** Kartlar doğrudan `transform: Translate { y: ... }` ile dikey olarak kaydırılır; QML çapa (anchors) sistemi ile çakışmaz.
* **Aciliyet Rozeti:** `urgency === "critical"` olduğunda kırmızı tonlu puls animasyonu (`SequentialAnimation on scale`) ve uyarı bordürü gösterir; normal bildirimlerde tema vurgu rengini (`Style.accent`) kullanır.
* **Deste Rozeti (`+X Deste`):** `remainingStackCount > 0` olduğunda sağ tarafta destede bekleyen kart adedini gösterir. Geçiş sırasında sıradaki kart kendi rozetini önceden doğru sayıyla çizerek animasyon bitiminde ani metin değişimini önler.

---

## 2. Özellikler ve Arayüz (Properties)

| Özellik Adı | Tip | Varsayılan | Açıklama |
| :--- | :--- | :--- | :--- |
| `summary` | `string` | `""` | Bildirim başlığı |
| `body` | `string` | `""` | Bildirim detay metni |
| `appName` | `string` | `"System"` | Gönderen uygulamanın adı |
| `urgency` | `string` | `"normal"` | Aciliyet düzeyi (`low`, `normal`, `critical`) |
| `icon` | `string` | `""` | Uygulama ikon yolu veya adı |
| `remainingStackCount` | `int` | `0` | Destede bekleyen kalan bildirim adedi |
| `isTransitioning` | `bool` | `false` | Kartın kayma animasyonunda olup olmadığı |

---

## 3. İlgili Bağlantılar

* Dynamic Island Bileşeni: `[[Dynamic-Island-Component]]`
* Stil ve Tema Token'ları: `[[Style-Design-Tokens]]`
* IPC İstemcisi: `[[Daemon-IPC-Client]]`
