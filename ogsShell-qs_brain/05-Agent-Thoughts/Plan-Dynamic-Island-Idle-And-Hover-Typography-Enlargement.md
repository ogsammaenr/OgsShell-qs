---
title: "Plan: Dynamic Island Idle and Hover Typography Enlargement"
type: agent-thought
tags:
  - ui/typography
  - ui/clock
  - ui/hover
  - quickshell/qml
  - dynamic-island
created: 2026-08-23
updated: 2026-08-23
status: implemented
related_notes:
  - "[[Clock-Widget]]"
  - "[[Media-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Dynamic Island Idle and Hover Typography Enlargement

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Dynamic Island ve Notch arayüzünde IDLE durumundaki saat metni font boyutu `13px`'ten `16px`'e çıkarıldı; HOVER durumunda ise saat `20px Bold`, tarih `13px Medium`, medya başlığı `12px DemiBold`, sanatçı `11px`, Wi-Fi/BT ikonları `14px` ve SSID `11px DemiBold` olarak dengeli ve okunaklı bir şekilde büyütüldü.

## 1. Problem ve Kullanıcı Talebi
* Kullanıcı talebi: IDLE modunda adanın merkezinde duran saat yazısının (`timeText`) font boyutunun büyütülmesi ve HOVER durumuna geçildiğinde görünen metinlerin (saat, tarih, medya başlığı/sanatçısı, Wi-Fi SSID ve ikonlar) buna bağlı olarak daha okunaklı ve orantılı hale getirilmesi.

## 2. Tipografi Ölçeklendirme Matrisi (Typography Scale Matrix)

| Bileşen / Metin | Mevcut Boyut | Yeni Hedef Boyut | Ağırlık / Stil |
| :--- | :--- | :--- | :--- |
| **ClockWidget (IDLE Saat)** | `13px` | **`16px`** | `Font.Bold` (0.3 Letter Spacing) |
| **ClockWidget (HOVER Saat)** | `17px` | **`20px`** | `Font.Bold` (0.5 Letter Spacing) |
| **ClockWidget (HOVER Tarih)** | `11px` | **`13px`** | `Font.Medium` (0.3 Letter Spacing) |
| **MediaWidget (Şarkı Başlığı)** | `10px` | **`12px`** | `Font.DemiBold` |
| **MediaWidget (Sanatçı / Durum)** | `9px` | **`11px`** | `Font.Normal` |
| **MediaWidget (Medya İkonu)** | `9px / 12px` | **`11px / 14px`** | İkon rozeti `26x26` |
| **ConnectivityWidget (SSID)** | `9px` | **`11px`** | `Font.DemiBold` (Genişlik sınırı 42px -> 54px) |
| **ConnectivityWidget (İkonlar)** | `12px` | **`14px`** | Wi-Fi ve Bluetooth glifleri |

## 3. Düzen ve Geometri Ayarlamaları
1. **ClockWidget:**
   - HOVER dikey kaydırma ofseti (`anchors.verticalCenterOffset`): `-8px` $\to$ `-10px` (20px saat + 13px tarih için ideal dikey denge).
   - Tarih üst boşluğu (`anchors.topMargin`): `2px` $\to$ `3px`.
   - Canlı aktivite durum noktası (`dotContainer`): `6px` $\to$ `7px`.
2. **MediaWidget & ConnectivityStatusWidget:**
   - Yükseklik: `28px` $\to$ `30px`.
   - MediaWidget maksimum genişliği: `130px` $\to$ `150px`.
   - ConnectivityStatusWidget genişliği: `90px` $\to$ `104px`.

## 4. Etkilenen Dosyalar
- `shell/components/widgets/ClockWidget.qml`
- `shell/components/widgets/MediaWidget.qml`
- `shell/components/widgets/ConnectivityStatusWidget.qml`
- `shell/components/island/DynamicIsland.qml`
