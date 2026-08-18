---
title: "Plan: Typography Scale and Readability Optimization"
type: agent-thought
tags:
  - ui/typography
  - ui/readability
  - quickshell/qml
  - dynamic-island/styling
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Style-Design-Tokens]]"
  - "[[Control-Center-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[System-Architecture]]"
---

# Plan: Typography Scale and Readability Optimization

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Pano geçmişi (ClipboardView), Bildirim Merkezi (NotificationsView), Kontrol Merkezi (ControlCenter) ve ada içi tüm alt uygulamalarda fazla küçük olan (8px-9px) mikroskobik yazı tipi boyutları modern Apple HIG tipografi standartlarına uygun ölçeğe (10.5px - 16px) yükseltilerek okunabilirlik ve erişilebilirlik maksimize edildi.

## 1. Problem ve Kullanıcı İhtiyacı
* Kullanıcı geri bildirimi doğrultusunda: Yazı tiplerinin mikroskobik boyutları nedeniyle okunması zor olan tüm arayüzlerde kapsamlı bir tipografi ölçek revizyonu yapıldı.

## 2. Uygulanan Mimari Çözüm ve Yeni Tipografi Standartları

### A. Tipografi Hiyerarşisi (Type Scale Matrix)
* **Metadata & Alt İpuçları (Captions / Status):** `8px-9px` $\to$ `10px - 11px` (Font.Medium / Bold)
* **Liste Öğeleri & Gövde Metinleri (Body Text):** `9px-11px` $\to$ `12px - 13px` (Font.Medium / DemiBold)
* **Modül Başlıkları & Kart Başlıkları (Card Titles):** `11px-12px` $\to$ `13px - 14px` (Font.Bold)
* **Modal & Overlay Başlıkları:** `12px-15px` $\to$ `15px - 16px` (Font.Bold)
* **İkon Glifleri (Nerd Fonts):** `12px-15px` $\to$ `14px - 19px`

### B. Yenilenen Bileşenler
1. **[ClipboardView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/ClipboardView.qml):** Kart yüksekliği `52px`'e çıkarıldı, önizleme metinleri `12.5px`, alt metadata `10.5px`, detay modalı `12.5px` seçilebilir metin boyutuna yükseltildi.
2. **[NotificationsView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/NotificationsView.qml):** Kart yüksekliği `48px`, başlık `12px`, alt önizleme `10px`, detay modalı gövde metni `11.5px` yapıldı.
3. **[ControlCenterMain.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/ControlCenterMain.qml):** Wi-Fi & Bluetooth başlıkları `12.5px`, alt durum metinleri `10.5px`, 2x2 aksiyon etiketleri `10.5px`, slider yüzdeleri `11.5px`, telemetri metinleri `10.5px` olarak ferahlatıldı.
4. **[WifiView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/WifiView.qml) & [BluetoothView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/BluetoothView.qml):** Liste kartları `42px - 44px`, ağ/aygıt isimleri `12px - 12.5px` yapıldı.
5. **[KeyboardLayoutView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/KeyboardLayoutView.qml) & [ThemesView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/ThemesView.qml):** Tüm başlık, sekme ve kart metinleri okunaklı ölçeğe taşındı.
6. **[PowerOverlay.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/PowerOverlay.qml):** Aksiyon buton başlıkları `13px`, açıklamalar `10.5px`, başlık `16px` olarak ölçeklendi.
7. **[MonthGridView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/calendar/MonthGridView.qml) & [ClockSuiteView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/clock/ClockSuiteView.qml):** Gün sayıları `12px`, takvim başlığı `14px`, saat sekmeleri `12px` yapıldı.
8. **[PinnedMetricsWidget.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/PinnedMetricsWidget.qml):** Telemetri metinleri `11px` (Font.Bold) ve ikonlar `13px` yapıldı.

## 3. Güncellenen Dosyalar
- `shell/components/widgets/controlcenter/views/ClipboardView.qml`
- `shell/components/widgets/controlcenter/views/NotificationsView.qml`
- `shell/components/widgets/controlcenter/ControlCenterMain.qml`
- `shell/components/widgets/controlcenter/views/WifiView.qml`
- `shell/components/widgets/controlcenter/views/BluetoothView.qml`
- `shell/components/widgets/controlcenter/views/KeyboardLayoutView.qml`
- `shell/components/widgets/controlcenter/views/ThemesView.qml`
- `shell/components/widgets/controlcenter/PowerOverlay.qml`
- `shell/components/widgets/calendar/MonthGridView.qml`
- `shell/components/widgets/clock/ClockSuiteView.qml`
- `shell/components/widgets/PinnedMetricsWidget.qml`
