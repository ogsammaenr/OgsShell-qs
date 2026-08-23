---
title: "Plan: Configurable Typography Schema in config.json"
type: agent-thought
tags:
  - architecture/config
  - config/json
  - ui/typography
  - quickshell/qml
  - dynamic-island
  - dynamic-notch
created: 2026-08-23
updated: 2026-08-23
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Clock-Widget]]"
  - "[[Media-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Plan-Reactive-Config-Geometry-And-Synchronization]]"
  - "[[System-Architecture]]"
---

# Plan: Configurable Typography Schema in config.json

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Dynamic Island ve HUD üzerindeki tüm font boyutları `config.json` içerisindeki `"typography"` bloğu ile tam reaktif ve canlı düzenlenebilir hale getirildi. Tüm QML bileşenleri `Config.typography` dinamik binding'lerine bağlandı.

## 1. Problem ve Kullanıcı İhtiyacı
* Kullanıcı talebi: Saat ve hover durumundaki metinlerin yanı sıra tüm tipografi boyutlarının `config.json` dosyası üzerinden ayarlanabilir olması.
* Mevcut durumda font boyutları QML bileşenlerinde sabit (hardcoded) veya varsayılan değerlerde tutulmaktadır.

## 2. Tasarlanan Konfigürasyon Şeması (`config.json`)

```json
{
  "typography": {
    "clock_idle_size": 16,
    "clock_hover_size": 20,
    "date_hover_size": 13,
    "media_title_size": 12,
    "media_artist_size": 11,
    "connectivity_text_size": 11,
    "connectivity_icon_size": 14,
    "notification_title_size": 13,
    "notification_body_size": 11,
    "pinned_metrics_size": 11,
    "pinned_metrics_icon_size": 13
  }
}
```

## 3. Mimari ve Reaktif Entegrasyon
1. **Config.qml:**
   - `property var typography` nesnesi tanımlanacak ve `loadConfigString` içerisinde `cfg.typography` parse edilip `configRevision++` tetiklenecek.
2. **QML Bileşenleri:**
   - `ClockWidget.qml`: `Config.typography.clock_idle_size`, `Config.typography.clock_hover_size`, `Config.typography.date_hover_size`.
   - `MediaWidget.qml`: `Config.typography.media_title_size`, `Config.typography.media_artist_size`.
   - `ConnectivityStatusWidget.qml`: `Config.typography.connectivity_text_size`, `Config.typography.connectivity_icon_size`.
   - `DynamicIsland.qml`: `Config.typography.notification_title_size`, `Config.typography.notification_body_size`.
   - `PinnedMetricsWidget.qml`: `Config.typography.pinned_metrics_size`, `Config.typography.pinned_metrics_icon_size`.

## 4. Etkilenen Dosyalar
- `shell/config.json`
- `shared/app_configs/shell/config.json`
- `shell/backend/Config.qml`
- `shell/components/widgets/ClockWidget.qml`
- `shell/components/widgets/MediaWidget.qml`
- `shell/components/widgets/ConnectivityStatusWidget.qml`
- `shell/components/island/DynamicIsland.qml`
- `shell/components/widgets/PinnedMetricsWidget.qml`
