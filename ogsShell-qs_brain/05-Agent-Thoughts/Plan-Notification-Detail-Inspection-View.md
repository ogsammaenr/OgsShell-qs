---
title: "Plan: Right-Click Notification Detail Inspection View"
type: agent-thought
tags:
  - ui/notifications
  - quickshell/qml
  - dynamic-island/control-center
  - interaction/right-click
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Notification-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Right-Click Notification Detail Inspection View

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Bildirim merkezindeki bildirim kartlarına sağ tıklandığında (veya tıklandığında), bildirimin tam başlığını, uzun gövde metnini (scroll edilebilir, seçilebilir ve kopyalanabilir), uygulama kaynağını, zamanını ve aksiyon butonlarını (Kapat, Bildirimi Sil) içeren şık bir detay inceleme penceresi başarıyla entegre edildi.

## 1. Problem ve Kullanıcı İhtiyacı
* Önceden `NotificationsView.qml` içinde bildirimler sadece 38px yüksekliğinde tek satırlık kartlar olarak listeleniyor ve uzun gövde metinleri kesiliyordu.
* Kullanıcı talebi doğrultusunda: Bildirim kartına sağ tıklandığında tüm metnin okunabileceği, uygulama içi detay modalı geliştirildi.

## 2. Uygulanan Mimari Çözüm

### A. Bildirim Kartı Etkileşimi ([NotificationsView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/NotificationsView.qml))
1. Bildirim kartı `MouseArea` nesnesine `acceptedButtons: Qt.LeftButton | Qt.RightButton` eklendi.
2. Tıklama anında `root.openDetail(modelData)` çağrıldı ve okunmamış bildirimler otomatik olarak okundu işaretlendi.
3. Kart alt metninde ve sağ kenarında bağımsız silme ve detay ipuçları sunuldu.

### B. Detay İnceleme Görünümü (`detailModal`)
1. **Header Alanı:**
   - Geri / Kapat butonu (`‹`)
   - Uygulama rozeti (`app_name`, `Style.accentCyan`)
   - Saat / Zaman damgası etiketi
2. **Scrollable İçerik Alanı:**
   - Bildirim Başlığı / Özeti (`summary`, `Font.Bold`, `11px`, `Style.textPrimary`)
   - `Flickable` + `TextEdit` içine yerleştirilmiş tam gövde metni (`body`, `WrapAnywhere`, seçilebilir, kopyalanabilir).
3. **Alt Eylem Çubuğu:**
   - "Kapat" butonu
   - "Bildirimi Sil" butonu (`ipc.deleteNotification(id)`)

## 3. Güncellenen Dosyalar
- [NotificationsView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/views/NotificationsView.qml)
- [Control-Center-Widget.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ogsShell-qs_brain/03-UI-Components/Control-Center-Widget.md)
- [Notification-Service.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ogsShell-qs_brain/02-Services/Notification-Service.md)
