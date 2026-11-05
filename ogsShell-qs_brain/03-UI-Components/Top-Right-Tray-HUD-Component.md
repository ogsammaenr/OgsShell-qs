---
title: "Top-Right Screen Corner System Tray HUD Component"
type: ui-component
tags:
  - ui/system-tray
  - ui/screen-corners
  - quickshell/qml
  - wayland/layershell
status: active
---

# Top-Right Screen Corner System Tray HUD Component (`shell/components/corners/TopRightTrayHUD.qml`)

> [!NOTE]
> `TopRightTrayHUD.qml`, sağ-üst ekran köşesinde konumlanan, `CornerIslandHUD.qml` (sol-üst mini bildirim HUD'ı) bileşeniyle tam simetrik (1:1 mirrored) Bézier kavis ve OLED Siyah kapsül geometrisine sahip, arka planda çalışan sistem tepsisi (System Tray / StatusNotifierItem) uygulamalarını gösteren ve yöneten interaktif arayüz bileşenidir.

---

## 1. Mimari ve Bileşen Mimarisi

* **Wayland Layer & Surface:** `topRightTrayWindow` (`PanelWindow`) üzerinde barındırılır. Wayland buffer yeniden tahsisi ve pencere boyutu değiştirme gecikmelerini (surface resizing jitter/lag) engellemek için **sabit 420x130px yüzey alanı** kullanılır.
* **Hassas Wayland Giriş Maskesi (Zero-Click Blocking):** `mask: Region { item: activeTrayInputEnvelope }` yapısı sayesinde:
  - **IDLE Modunda:** Yalnızca sağ-üst köşedeki 28x28px tetikleyici alan tıklanabilir; kalan tüm alanlar altındaki Hyprland pencerelerine %100 geçirgendir.
  - **EXPANDED Modunda:** Açılan OLED kapsülünün sınırları tıklamaları yakalar; arka plandaki `backdropWindow` ise kapsül dışına tıklamalarda adayı zarifçe kapatır.
  - **CONTEXT MENU (Kapat Menüsü Açıkken):** Menü açıkken giriş maskesi dikeyde `topRightTrayHud.height + 72px` derinliğe ve yatayda `155px` genişliğe dinamik olarak genişletilerek Kapat butonu ve kart üzerindeki fare etkileşimlerinin pencereler tarafından engellenmesi önlenir.
* **1:1 Simetrik Vektör Geometrisi (`expandedShape`):**
  - Sol-üst köşedeki `CornerIslandHUD.qml` ile tam ayna simetriği oluşturur.
  - **Üst-Sol Kulak (Top-Left Ear):** Üst ekran çerçevesinden (`y=0`) sol dikey duvara pürüzsüz dışbükey Bézier geçişi (`PathCubic`, `earW: 16, earH: 16`).
  - **Sol Dikey Duvar:** Dikey eksende `earH` noktasından `animHeight - br` noktasına düz hat.
  - **Sol-Alt Yuvarlatılmış Köşe:** `br: 14` yarıçaplı saat yönünün tersine (`PathArc.Counterclockwise`) pürüzsüz çember kavisi.
  - **Alt Yatay Duvar:** Kapsül alt taban çizgisi.
  - **Sağ-Alt Kulak (Bottom-Right Ear):** Alt tabandan sağ ekran çerçevesine bağlanan dışbükey Bézier kulak (`PathCubic`, `rightEarW: 12, rightEarH: 12`).
  - **Sağ Dikey Duvar:** Sağ ekran çerçevesi boyunca `(width, 0)` başlangıç noktasına dönüş.
* **Native D-Bus Entegrasyonu:** `Quickshell.Services.SystemTray` singleton'ı (`SystemTray.items`) üzerinden `StatusNotifierItem` listesi reaktif olarak takip edilir (`values.length` ve `Repeater.count`).
* **Akıllı İkon Çözümleme:** `Quickshell.iconPath()` ve `image://qspixmap/` destekli reaktif görselleyici; ikon bulunamadığında uygulama baş harfini taşıyan monogram badge yedeği.
* **Zarif Kapatma Popover Menüsü (`closeMenuCard`):** Sağ tıklanan uygulama ikonunun tam altında beliren, uygulamanın başlığını/ikonunu ve kırmızı vurgulu `[ 󰅖 Kapat ]` aksiyon butonunu içeren OLED Siyah `#0a0b10` mini popover.
* **Çok Aşamalı Güvenli Süreç Sonlandırıcı (`close_tray_app.sh`):**
  1. `org.kde.StatusNotifierWatcher` kayıtları taranarak ilgili D-Bus servisi tespit edilir.
  2. `com.canonical.dbusmenu` üzerinden "Quit" / "Exit" / "Kapat" eylemi aranıp zarifçe tetiklenir.
  3. `org.freedesktop.DBus.GetConnectionUnixProcessID` ile bağlantının tam PID'si bulunarak `SIGTERM` (ve gerekiyorsa `SIGKILL`) sinyali gönderilir.
  4. Sınır durumlar için proses adına göre `pkill` yedeği devreye girer.

---

## 2. Etkileşim ve Davranış Modeli

* **Köşe Tıklaması:** Sağ-üst köşeye tıklandığında kapsül 360ms `Easing.OutCubic` animasyonuyla genişler; içerikler `scale: 0.92 -> 1.0` ve opaklık geçişiyle belirir.
* **Sol Tık (İkon):** `trayItem.activate()` çağrılarak uygulamanın penceresi öne getirilir (eğer kapatma menüsü açıksa önce menü kapatılır).
* **Sağ Tık (İkon):** Uygulama ikonunun etrafında kırmızı seçim çerçevesi belirir ve ikonun hemen altında **Kapat Butonu Popover'ı** açılır. Aynı ikona tekrar sağ tıklanırsa menü kapanır.
* **Kapat Butonuna Tıklama:** Uygulamanın D-Bus / proses sonlandırma süreci başlatılır (`closeApp()`), popover gizlenir ve uygulama kapandığında tepsi listesinden otomatik düşer.
* **Orta Tık (İkon):** `trayItem.secondaryActivate()` tetiklenir.
* **Dışarı Tıklama (Backdrop):** Menü açıksa önce menü pürüzsüzce kapatılır; menü kapalıysa kapsül köşe kavis boyutuna (`14px`) geri kapanır.

---

## 3. Konfigürasyon Parametreleri (`config.json`)

```json
"corner_tray": {
  "enabled": true,
  "height": 34,
  "trigger_mode": "click",
  "timeout_ms": 0
}
```

---

## 4. İlgili Yaşayan Dokümanlar

* Ekran Köşeleri: `[[Screen-Corners-Component]]`
* Sol-Üst Bildirim ve OSD HUD: `[[Corner-Island-HUD-Component]]`
* Ana Kabuk Katmanı: `[[Shell-Root-PanelWindow]]`
* Konfigürasyon Sistemi: `[[Configuration-System-Spec]]`
* Sistem Mimarisi: `[[System-Architecture]]`
