---
title: "Plan: Fullscreen Power and Session Overlay Redesign"
type: agent-thought
tags:
  - ui/power-menu
  - ui/session-overlay
  - quickshell/layershell
  - pure-black/glass
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Power-Overlay-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Fullscreen Power and Session Overlay Redesign

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Dynamic Island içine gömülü sıkışık PowerView listesi tamamen kaldırıldı. Yerine güç butonuna tıklandığında ekranın tamamını kaplayan, hafif karartılmış ve saydam cam zemin üzerinde ortalanmış 4 büyük ve estetik güç kartına (Kapat, Yeniden Başlat, Oturumu Kapat, Uyku Modu) sahip modern `PowerOverlay.qml` bileşeni başarıyla entegre edildi.

## 1. Problem ve Kullanıcı İhtiyacı
* Eski `PowerView.qml` adanın içine gömülü küçük ve sıkışık bir liste şeklinde tasarlanmıştı.
* Kullanıcı talebi doğrultusunda: Güç butonuna basıldığında ekranın üzerine hafif kara saydam blurlu bir katman açılması ve ortasında büyük butonlarla:
  - **Sistemi Kapat (Power Off)** (`systemctl poweroff`)
  - **Yeniden Başlat (Reboot)** (`systemctl reboot`)
  - **Oturumu Kapat (Log Out)** (`hyprctl dispatch exit`)
  - **Uyku Moduna Geç (Suspend)** (`systemctl suspend`)
  eylemlerinin sunulması sağlandı.

## 2. Uygulanan Mimari Çözüm

### A. Yeni Bileşenler ve Singleton
1. **[PowerService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/backend/PowerService.qml):** Menünün açılış ve kapanış durumunu yöneten global reaktif singleton.
2. **[PowerOverlay.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/PowerOverlay.qml):**
   - Karartılmış koyu cam zemin (`Qt.rgba(0, 0, 0, 0.72)`).
   - Ekran ortasında 4 adet büyük squircle aksiyon butonu (Kapat, Yeniden Başlat, Uyku Modu, Oturumu Kapat).
   - Mikro-animasyonlar (`scale: 1.04`, hover glow, yumuşak yay geçişleri).
   - Klavye desteği: `Escape` ile iptal, `P` (Poweroff), `R` (Reboot), `S` (Suspend), `L`/`E` (Logout) kısayolları.
   - Boş alana tıklayınca otomatik kapanma.
3. **[shell.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/shell.qml) Katmanı:**
   - Her ekran için `powerOverlayWindow` `PanelWindow` tanımlandı (`WlrLayershell.layer: WlrLayer.Overlay`, `WlrKeyboardFocus.Exclusive`).

### B. Eski Kodun Temizliği
* `shell/components/widgets/controlcenter/views/PowerView.qml` ve `ControlCenterView.qml` içindeki eski liste loader'ı tamamen kaldırıldı.
* `ControlCenterMain.qml` içindeki güç butonu doğrudan `PowerService.open()` tetikleyecek şekilde bağlandı.

## 3. Güncellenen / Oluşturulan Dosyalar
- [PowerOverlay.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/PowerOverlay.qml)
- [PowerService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/backend/PowerService.qml)
- [ControlCenterMain.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/ControlCenterMain.qml)
- [ControlCenterView.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/ControlCenterView.qml)
- [shell.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/shell.qml)
- [qmldir](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/qmldir)
- [Power-Overlay-Component.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ogsShell-qs_brain/03-UI-Components/Power-Overlay-Component.md)
