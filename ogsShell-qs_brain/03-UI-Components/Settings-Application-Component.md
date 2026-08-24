---
title: "Settings Application & Network Management Component (Quickshell QML)"
type: ui-component
tags:
  - ui/settings
  - network/dns
  - quickshell/layershell
  - apple/hig
  - components/cards
created: 2026-08-23
updated: 2026-08-23
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Wifi-Client-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Plan-System-Settings-App-And-Network-Architecture]]"
---

# Settings Application & Network Management Component (`shell/components/settings/`)

> [!NOTE]
> Apple Human Interface Guidelines (HIG) ve macOS Sequoia tasarım dilinden ilham alan, 'AI slop' karmaşasından uzak, modüler, hafif ve tam reaktif bir **Sistem Ayarları (Settings App)** penceresi ve **Ağ & Güvenli DNS** yönetim merkezi.

---

## 1. Mimari Yapı ve Tasarım Felsefesi

1. **Bağımsız Masaüstü Penceresi (`settings_app/shell.qml`):**
   - Quickshell `FloatingWindow` (Wayland XDG Toplevel) mimarisiyle `880px × 580px` boyutunda çalışan bağımsız bir masaüstü uygulamasıdır (`app-id: ogs-settings`).
   - `Alt+Tab` ile pencereler arasında geçilebilir, başlıktan tutularak taşınabilir ve kenarlarından yeniden boyutlandırılabilir.
   - Sol üstte Apple macOS tarzı pencere kontrol butonları (🔴 Kapat, 🟡 Simge Durumu, 🟢 Büyüt) barındırır.
2. **Tekil Odaklama Koruması (`scripts/open_settings_app.sh`):**
   - Uygulama zaten açıksa `hyprctl dispatch focuswindow class:^ogs-settings$` komutuyla mevcut pencereye odaklanır, klon pencere açmaz.
3. **Masaüstü Entegrasyonu (`ogs-settings.desktop`):**
   - `~/.local/share/applications/ogs-settings.desktop` aracılığıyla sistem uygulama menüsünde (Spotlight, Rofi vb.) "Ayarlar" olarak listelenir.
4. **Sol Kenar Çubuğu (Sidebar - 230px):**
   - 🌐 **Ağ ve Wi-Fi** (`network`)
   - 󰂯 **Bluetooth** (`bluetooth`)
   - 🎨 **Görünüm ve Tema** (`appearance`)
   - 🏝️ **Ada ve Çentik** (`island`)
   - 🔊 **Ses ve Donanım** (`sound`)
   - 🔔 **Bildirimler** (`notifications`)
   - ⌨️ **Klavye ve Giriş** (`keyboard`)
   - ℹ️ **Sistem Hakkında** (`about`)
3. **Yeniden Kullanılabilir UI Bileşenleri (`components/`):**
   - `SettingsCard.qml`: `Style.surface` ve 1px `Style.border` ile sınırlandırılmış ferah inset grouped kart kutusu.
   - `SettingsRow.qml`: İkon, başlık, açıklama ve sağ kontrol slotundan oluşan standart satır.
   - `SettingsToggle.qml`: iOS/macOS stili pürüzsüz yay animasyonlu Switch.
   - `SettingsButton.qml`: Minimalist aksiyon butonu.
   - `SettingsDnsCard.qml`: DNS sağlayıcıları için radyo seçimli interaktif kart.
   - `SettingsSectionHeader.qml`: Sessiz ve zarif kategori üst başlığı.

---

## 2. Ağ ve Güvenli DNS Yönetimi (`NetworkPage.qml`)

* **Aktif Bağlantı Telemetrisi:** Wi-Fi güç switch'i, bağlı SSID, yeşil durum rozeti, IP Adresi, Ağ Geçidi ve Sinyal gücü (`%`).
* **Güvenli DNS ve DPI Bypass (Zapret) Seçici:**
  * ⚡ **Cloudflare DNS** (`1.1.1.1, 1.0.0.1`) — *Hızlı & DPI Atlatma*
  * 🛡️ **Quad9 DNS** (`9.9.9.9, 149.112.112.112`) — *Zararlı Yazılım ve Tehdit Engelleme*
  * 🛑 **AdGuard DNS** (`94.140.14.14, 94.140.15.15`) — *Reklam ve İzleyici Filtresi*
  * 🔍 **Google DNS** (`8.8.8.8, 8.8.4.4`) — *Standart Genel DNS*
  * 🔄 **Otomatik (Modem/DHCP)** — *Servis Sağlayıcı Varsayılanı*
  * ⚙️ **Özel DNS** — *Manuel Birincil ve İkincil DNS IP Girişi*
* **IPv6 Sızıntı Koruması:** Zapret'in tüm paketleri eksiksiz yakalaması için tek dokunuşla `ipv6.method: disabled` yapabilme.
* **Kullanılabilir Ağlar Listesi:** Çevredeki Wi-Fi ağlarının canlı sinyal ve güvenlik durumuyla listelenmesi.
* **Ağ Bakımı & Kopya Temizleyici:** Diskte birikmiş aynı adlı `.nmconnection` dosyalarını tek tıkla silen temizlik butonu.

---

## 3. İlgili Bağlantılar

* Tasarım Token'ları: `[[Style-Design-Tokens]]`
* IPC Protokolü: `[[Daemon-IPC-Client]]`
* Wi-Fi Backend Servisi: `[[Wifi-Client-Service]]`
* Düşünce Günlüğü: `[[Plan-System-Settings-App-And-Network-Architecture]]`
