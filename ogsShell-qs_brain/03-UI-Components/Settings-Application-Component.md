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
updated: 2026-11-19
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
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
> `[[Apple-HIG-Minimal-Design-System]]` kuralları ve `[[Style-Design-Tokens]]` rehberliğindeki **Sistem Ayarları (Settings App)** penceresi: monokrom Nerd Font glifleri, 1px hairline kenarlıklar, `Style.fontText` / `Style.fontDisplay` tipografi hiyerarşisi ve tekil `Style.accent` vurgulama dili ile **Ağ & Güvenli DNS**, **Ada & Çentik**, **Hyprland** ve **Ses** yapılandırma merkezi.

---

## 1. Mimari Yapı ve Tasarım Felsefesi

1. **Bağımsız Masaüstü Penceresi (`settings_app/shell.qml`):**
   - Quickshell `FloatingWindow` (Wayland XDG Toplevel) mimarisiyle çalışan bağımsız bir masaüstü uygulamasıdır (`app-id: ogs-settings`).
   - `settings_app/assets -> ../shell/assets` sembolik bağı üzerinden `FontLoader` (`Inter.ttf`, `NotoSansDisplay.ttf`) dosyalarını Quickshell QRC kökü içinde hatasız yükler; `Style.fontText` ve `Style.fontDisplay` token'larını besler.
   - `Alt+Tab` ile pencereler arasında geçilebilir, başlıktan tutularak taşınabilir ve kenarlarından yeniden boyutlandırılabilir.
   - Sol üstte minimal pencere kapatma butonu barındırır.
2. **Tekil Odaklama Koruması (`~/.config/ogsShell/ogsshell.sh open_settings`):**
   - Uygulama zaten açıksa `hyprctl dispatch focuswindow class:^ogs-settings$` komutuyla mevcut pencereye odaklanır, klon pencere açmaz.
3. **Masaüstü Entegrasyonu (`ogs-settings.desktop`):**
   - `~/.local/share/applications/ogs-settings.desktop` aracılığıyla sistem uygulama menüsünde (Spotlight, Rofi vb.) "Ayarlar" olarak listelenir.
4. **Sol Kenar Çubuğu (Sidebar - 224px):**
   - Emoji içermez; tüm kategoriler monokrom Nerd Font glifleri ve aktif sekmede `Style.accent` tonlaması ile sunulur:
   - `󰖩` **Ağ ve Wi-Fi** (`network`) — *Aktif*
   - `󰂯` **Bluetooth** (`bluetooth`)
   - `󰏘` **Görünüm ve Tema** (`appearance`)
   - `󱂬` **Ada ve Çentik** (`island`) — *Aktif*
   - `󰖲` **Hyprland ve Efektler** (`hyprland`) — *Aktif*
   - `󰕾` **Ses ve Donanım** (`sound`) — *Aktif*
   - `󰂚` **Bildirimler** (`notifications`)
   - `󰌌` **Klavye ve Giriş** (`keyboard`)
   - `󰋼` **Sistem Hakkında** (`about`)
5. **Yeniden Kullanılabilir UI Bileşenleri (`components/`):**
   - `SettingsCard.qml`: `radius: 10`, `Style.appCard` dolgusu ve `1px` `Style.appBorder` hairline kenarlıklı inset grouped kart kutusu.
   - `SettingsRow.qml`: Sabit `18px` genişliğinde monokrom (`Style.textSecondary`) ikon slotu, `Style.fontText` tipografi, hairline ayırıcı ve sağ kontrol slotundan oluşan standart satır.
   - `SettingsChoiceCard.qml`: Seçili durumda `Style.accent` hairline kenarlık ve `Qt.alpha(Style.accent, 0.10)` dolgu kullanan mod seçim kartı.
   - `SettingsNumberRow.qml`: Sayısal değerleri `1px` `Style.appBorder` kapsülü içinde bütünleşik `26px` `-` / `+` segmentli stepper ve sakin `Style.textPrimary` okuma alanı ile ayarlayan satır.
   - `SettingsToggle.qml`: Kompakt `38×22` boyutlu, `Style.accent` / `Style.bgPrimary` token'larını kullanan yay animasyonlu Switch.
   - `SettingsButton.qml`: Birincil (`Style.accent` / `Style.bgPrimary`) ve tehlike (`Qt.alpha(Style.accentRed, 0.16)`) varyantlarını destekleyen `Style.fontText` aksiyon butonu.
   - `SettingsDnsCard.qml`: DNS sağlayıcıları için `1px` `Style.accent` seçili durumlu ve `Style.fontText` tipografili kart.
   - `SettingsSectionHeader.qml`: `Style.fontText`, `11px`, `letterSpacing: 0.7` sessiz ve zarif kategori üst başlığı.
   - `CubicBezierEditor.qml`: Monokrom Nerd Font ikonları, iç içe çerçevesiz $P_1$ / $P_2$ kontrol parametreleri ve `SettingsButton` aksiyonlarına sahip Bézier eğri editörü.

---

## 2. Ada ve Çentik Yapılandırma Merkezi (`IslandPage.qml`)

* **Tutarlı Sayfa Düzeni:** Tüm sayfalarla uyumlu `width: parent.width - 40`, `topMargin: 20` ve `spacing: 18` yerleşim ritmini takip eder; geometri ve fizik stepper satırları tekrarlanan ikon kalabalığından arındırılmıştır.
* **Sunum Formatı (Form Factor):** `island` (Süzülen Ada) vs `notch` (Üst Çentik) görsel kart seçimi.
* **Genel Davranış & Modlar:**
  - `focus_mode`: Akıllı gizleme / odak modu toggle'ı.
  - `show_pinned_system_metrics`: Canlı CPU/RAM/GPU telemetrisi sabitleme toggle'ı.
  - `notifications.enabled` & `notifications.default_timeout_ms`: Bildirim pop-up'ları ve zaman aşımı.
* **Ada Geometrisi (Floating Island):** Üst boşluk, Boşta (Idle), Hover, Geçici (Transient), Genişletilmiş (Expanded) boyutlar ve köşe yarıçapları.
* **Çentik Geometrisi (Dynamic Notch):** Üst boşluk, Boşta, Hover, Geçici, Genişletilmiş boyutlar ve alt kavis yarıçapları.
* **Fizik, Animasyon ve Sıfırlama:** Kompakt, Geçici, Genişletilmiş süreleri, yay çarpanı (`overshoot_factor`) ve `Config.resetDefaults()` ile güvenli varsayılanlara dönüş.
* **Canlı Çift Yönlü Eşitleme:** Yapılan değişiklikler `Config.saveConfig()` ile anında `$XDG_CONFIG_HOME/ogsShell/config.json`, `shell/config.json` ve `shared/app_configs/shell/config.json` dosyalarına atomik yazılır; çalışan Quickshell masaüstü kabuğu anında canlı olarak güncellenir.

---

## 3. Ağ ve Güvenli DNS Yönetimi (`NetworkPage.qml`)

* **Kayan Kapsüllü Ağ Seçici (Apple HIG Segmented Capsule):** `Wi-Fi` ve `Kablolu Ağ` sekmeleri arasında `SpringAnimation` (`spring: 28.0`, `damping: 0.78`, `epsilon: 0.01`) ile kayan kapsül geçişi; aktif bağlantı tipine göre otomatik sekme seçimi.
* **Ortak Özel DNS Bileşeni (`CustomDnsInputCard`):** Kablolu ve Wi-Fi profilleri için tek paylaşılan bileşen üzerinden manuel DNS girişi (`󰄬` glifi ve `Style` token'ları).
* **Kablolu Ağ & Ethernet Yönetimi:**
  - **Arayüz ve Profil Seçimi:** Birden fazla fiziksel ethernet kartı (`enp6s0`, `enp0s20f0u4` vb.) veya kayıtlı bağlantı profili varsa interaktif mini kart çiplerinden seçim yapabilme.
  - **Canlı Donanım Durumu:** Taşıyıcı sinyali (`carrier` / kablo takılı), bağlantı hızı (`1000 Mbps`), MAC adresi, IP adresi ve Ağ Geçidi göstergesi.
  - **Kablolu Güvenli DNS (DPI Bypass / Zapret):** Cloudflare (`1.1.1.1`), Quad9 (`9.9.9.9`), AdGuard (`94.140.14.14`), Google (`8.8.8.8`), Otomatik DHCP ve Manuel IP girişi; anında `SetConnectionDNS` ile profile yazılıp canlı olarak uygulanır.
  - **Kablolu IPv6 Koruması:** Kablolu hatta sansür ve DNS sızıntılarını önlemek için tek tıkla `ipv6.method: disabled` toggle kontrolü.
* **Wi-Fi & Kablosuz Ağ Yönetimi:**
  - **Aktif Bağlantı Telemetrisi:** Wi-Fi güç switch'i, bağlı SSID, `Style` durum rozeti, IP Adresi, Ağ Geçidi ve Sinyal gücü (`%`).
  - **Güvenli DNS ve DPI Bypass (Zapret) Seçici:** Wi-Fi profili için Cloudflare, Quad9, AdGuard, Google DNS, Otomatik DHCP ve Özel DNS desteği.
  - **IPv6 Sızıntı Koruması:** Wi-Fi için `ipv6.method: disabled` tek dokunuşla sansür ve sızıntı önleme.
  - **Kullanılabilir Ağlar Listesi:** Çevredeki Wi-Fi ağlarının canlı sinyal ve güvenlik durumuyla taranması.
  - **Ağ Bakımı & Kopya Temizleyici:** Diskte birikmiş aynı adlı `.nmconnection` dosyalarını temizleyen araç.

---

## 4. Hyprland ve Efektler Yönetimi (`HyprlandPage.qml`)

* **Ortak Seçim Çip Grubu (`ProfileChipGroup`):** Tekrarlanan çip ve çok renkli karmaşa yerine `ProfileChipGroup` bileşeni ve tekil `Style.accent` vurgusuyla kenarlık (`default`, `borderless`, `cyberpunk`, `nordic`), animasyon (`snappy`, `smooth_float`, `bouncy`, `minimal_fast`), hedef ve eğri profillerini yönetir.
* **Kenarlık ve Geometri Stüdyosu:**
  - Canlı reaktif Hyprland pencere önizlemesi (sahte macOS pencere noktaları olmadan yalın başlık çubuğu, tanımlı `currentShadowColor`, gradyan border, rounding ve drop shadow).
  - Stepper kontrolleri: `border_size` (0-8px), `rounding` (0-28px), `rounding_power` (1.0-4.0 continuous squircle curvature), `gaps_in` (0-30px), `gaps_out` (0-40px), `active_opacity` (0.4-1.0), `inactive_opacity` (0.4-1.0), `drop_shadow` toggle, `shadow_range` (5-60px).
  - Anında sıfır gecikmeli masaüstü canlı önizlemesi (`hyprctl eval` aracılığıyla).
  - `SettingsButton` ile kullanıcı tanımlı özel kenarlık profili kaydetme ve Lua durum dosyasına atomik yazım (`active_state.lua`).
* **Modüler Animasyon Geçişleri (Animation Overrides):**
  - Hedef bazlı eğri ve süre seçimi: `windows`, `windowsIn`, `windowsOut`, `windowsMove`, `workspaces`, `layers`.
  - Hızlı eğri profilleri: `linear`, `snappyEase`, `smoothFloat`, `bouncyPop`, `customCurve`.
* **Gömülü Cubic Bézier Stüdyosu (`CubicBezierEditor.qml`):**
  - CSSPortal tarzı interaktif $P_1$ ve $P_2$ kontrol noktaları.
  - Hyprland yay/sekme fiziği için genişletilmiş $Y$ aralığı: $[-0.5, 1.5]$.
  - Canlı animasyon pisti ve gerçek Hyprland pencereleri üzerinde canlı test butonu.
  - Lua sözdizimine uygun özel eğri kaydetme (`custom_curves.lua`).

---

## 5. Ses ve Donanım Yönetimi (`SoundPage.qml`)

* **Tutarlı Minimal Tasarım:** `width: parent.width - 40`, `topMargin: 20` yerleşimi, monokrom Nerd Font glifleri ve `Style.accent` / `Qt.alpha(Style.accentGreen, 0.12)` / `Style.textSecondary` token'ları ile sadeleştirilmiş arayüz.
* **Aktif Ses Çıkışı Önizlemesi:** `Quickshell.Services.Pipewire` (`PwObjectTracker`) ile varsayılan çıkış cihazının anlık ses yüzdesi (`%0–%150`), aktif sınır rozeti (`Maks. %100` / `Maks. %150`), susturma ve interaktif önizleme kaydırıcısı sunar.
* **%150 Ses Yükseltme (Over-Amplification):**
  - `Config.audioOverAmplification` (`audio.over_amplification`) değerini canlı toggle eder ve `Config.saveConfig()` aracılığıyla tüm kabuk bileşenlerine (`[[Control-Center-Widget]]`, `[[Audio-Mixer-View]]`, `[[Corner-Island-HUD-Component]]`, `[[Bottom-Command-Notch]]`) ile `ogsshell.sh volume` komutuna anında yansıtır.
  - **Güvenli Geri Dönüş (Auto-Clamp):** Özellik kapatıldığında `%100` üzerinde çalışan tüm çıkış aygıtları (`sinks`) ve uygulama akışları (`sink-inputs`) `wpctl` ve `pactl` üzerinden otomatik olarak `%100` seviyesine çekilir.
* **Geri Bildirim ve Köşe OSD Kontrolleri:** `[[Audio-Feedback-Service]]` (`enabled`, `volume_change_sound`, `throttle_ms`) ve `corner_hud.volume_enabled` ayarlarını tek merkezden yönetir.

---

## 6. İlgili Bağlantılar

* Tasarım Sistemi Kuralları: `[[Apple-HIG-Minimal-Design-System]]`
* Hyprland Profil Servisi (Go Daemon): `[[Hyprland-Profile-Service]]`
* Konfigürasyon Spesifikasyonu: `[[Configuration-System-Spec]]`
* Kontrol Merkezi: `[[Control-Center-Widget]]`
* Ses Karıştırıcısı: `[[Audio-Mixer-View]]`
* Köşe HUD OSD: `[[Corner-Island-HUD-Component]]`
* Tasarım Token'ları: `[[Style-Design-Tokens]]`
* Daemon IPC İletişimi: `[[Daemon-IPC-Client]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Dynamic Notch: `[[Dynamic-Notch-Design-Specification]]`
* Düşünce Günlüğü: `[[Plan-Settings-App-Island-And-Notch-Tab]]`
