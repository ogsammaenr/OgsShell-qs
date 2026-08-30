---
title: "Settings Application & Dynamic Island / Notch Management (Quickshell QML)"
type: ui-component
tags:
  - ui/settings
  - network/dns
  - quickshell/layershell
  - apple/hig
  - components/cards
  - config/sync
created: 2026-08-23
updated: 2026-08-29
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Configuration-System-Spec]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Wifi-Client-Service]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Control-Center-Widget]]"
  - "[[Plan-Settings-App-Island-And-Notch-Tab]]"
  - "[[Plan-Fix-Settings-App-Launcher-From-Control-Center]]"
  - "[[Plan-Standalone-Qt-Settings-Application-Architecture]]"
---

# Settings Application & Dynamic Island / Notch Management (`settings_app/`)

> [!NOTE]
> Apple Human Interface Guidelines (HIG) ve macOS Sequoia tasarım dilinden ilham alan, modüler, hafif ve tam reaktif bir **Sistem Ayarları (Settings App)** penceresi, **Ağ & Güvenli DNS** yönetim merkezi ve **Ada & Çentik Geometri Yapılandırıcısı**.

---

## 1. Mimari Yapı ve Tasarım Felsefesi

1. **Bağımsız Masaüstü Penceresi (`settings_app/shell.qml`):**
   - Quickshell `FloatingWindow` (Wayland XDG Toplevel) mimarisiyle `880px × 580px` boyutunda çalışan bağımsız bir masaüstü uygulamasıdır (`app-id: ogs-settings`).
   - `Alt+Tab` ile pencereler arasında geçilebilir, başlıktan tutularak taşınabilir ve kenarlarından yeniden boyutlandırılabilir.
   - Sol üstte minimal pencere kapatma butonu barındırır.
2. **Tekil Odaklama Koruması (`scripts/open_settings_app.sh`):**
   - Uygulama zaten açıksa `hyprctl dispatch focuswindow class:^ogs-settings$` komutuyla mevcut pencereye odaklanır, klon pencere açmaz.
3. **Masaüstü Entegrasyonu (`ogs-settings.desktop`):**
   - `~/.local/share/applications/ogs-settings.desktop` aracılığıyla sistem uygulama menüsünde (Spotlight, Rofi vb.) "Ayarlar" olarak listelenir.
4. **Sol Kenar Çubuğu (Sidebar - 230px):**
   - 🌐 **Ağ ve Wi-Fi** (`network`)
   - 󰂯 **Bluetooth** (`bluetooth`)
   - 🎨 **Görünüm ve Tema** (`appearance`)
   - 🏝️ **Ada ve Çentik** (`island`) — *Aktif*
   - 🔊 **Ses ve Donanım** (`sound`)
   - 🔔 **Bildirimler** (`notifications`)
   - ⌨️ **Klavye ve Giriş** (`keyboard`)
   - ℹ️ **Sistem Hakkında** (`about`)
5. **Yeniden Kullanılabilir UI Bileşenleri (`components/`):**
   - `SettingsCard.qml`: `Style.surface` ve 1px `Style.border` ile sınırlandırılmış ferah inset grouped kart kutusu.
   - `SettingsRow.qml`: İkon, başlık, açıklama ve sağ kontrol slotundan oluşan standart satır.
   - `SettingsChoiceCard.qml`: İki veya daha fazla mod arasında görsel radyo seçimi yapmayı sağlayan kart.
   - `SettingsNumberRow.qml`: Sayısal değerleri (px, ms, x) hassas - / + butonları ile ayarlayan stepper satırı.
   - `SettingsToggle.qml`: iOS/macOS stili pürüzsüz yay animasyonlu Switch.
   - `SettingsButton.qml`: Minimalist aksiyon butonu.
   - `SettingsDnsCard.qml`: DNS sağlayıcıları için radyo seçimli interaktif kart.
   - `SettingsSectionHeader.qml`: Sessiz ve zarif kategori üst başlığı.

---

## 2. Ada ve Çentik Yapılandırma Merkezi (`IslandPage.qml`)

* **Sunum Formatı (Form Factor):** `island` (Süzülen Ada) vs `notch` (Üst Çentik) görsel kart seçimi.
* **Genel Davranış & Modlar:**
  - `focus_mode`: Akıllı gizleme / odak modu toggle'ı.
  - `show_pinned_system_metrics`: Canlı CPU/RAM/GPU telemetrisi sabitleme toggle'ı.
  - `notifications.enabled` & `notifications.default_timeout_ms`: Bildirim pop-up'ları ve zaman aşımı.
* **Ada Geometrisi (Floating Island):** Üst boşluk, Boşta (Idle), Hover, Geçici (Transient), Genişletilmiş (Expanded) boyutlar ve köşe yarıçapları.
* **Çentik Geometrisi (Dynamic Notch):** Üst boşluk, Boşta, Hover, Geçici, Genişletilmiş boyutlar ve alt kavis yarıçapları.
* **Fizik ve Animasyon Yay Katsayıları:** Kompakt, Geçici, Genişletilmiş süreleri ve yay çarpanı (`overshoot_factor`).
* **Canlı Çift Yönlü Eşitleme:** Yapılan değişiklikler `Config.saveConfig()` ile anında `$XDG_CONFIG_HOME/ogsShell/config.json`, `shell/config.json` ve `shared/app_configs/shell/config.json` dosyalarına atomik yazılır; çalışan Quickshell masaüstü kabuğu anında canlı olarak güncellenir.

---

## 3. Ağ ve Güvenli DNS Yönetimi (`NetworkPage.qml`)

* **Aktif Bağlantı Telemetrisi:** Wi-Fi güç switch'i, bağlı SSID, yeşil durum rozeti, IP Adresi, Ağ Geçidi ve Sinyal gücü (`%`).
* **Güvenli DNS ve DPI Bypass (Zapret) Seçici:** Cloudflare, Quad9, AdGuard, Google DNS, Otomatik DHCP ve Özel DNS desteği.
* **IPv6 Sızıntı Koruması:** `ipv6.method: disabled` tek dokunuşla sansür ve sızıntı önleme.
* **Kullanılabilir Ağlar Listesi:** Çevredeki Wi-Fi ağlarının canlı sinyal ve güvenlik durumuyla taranması.
* **Ağ Bakımı & Kopya Temizleyici:** Diskte birikmiş aynı adlı `.nmconnection` dosyalarını temizleyen araç.

---

## 4. İlgili Bağlantılar

* Konfigürasyon Spesifikasyonu: `[[Configuration-System-Spec]]`
* Tasarım Token'ları: `[[Style-Design-Tokens]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Dynamic Notch: `[[Dynamic-Notch-Design-Specification]]`
* Düşünce Günlüğü: `[[Plan-Settings-App-Island-And-Notch-Tab]]`
