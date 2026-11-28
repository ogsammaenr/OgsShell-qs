---
title: "Settings Application & Unified Configuration Hub (Quickshell QML)"
type: ui-component
tags:
  - ui/settings
  - quickshell/qml
  - apple/hig
  - config/sync
  - network/dns
  - ui/lockscreen
status: active
---

# Settings Application & Unified Configuration Hub (`settings_app/`)

> [!NOTE]
> `[[Apple-HIG-Minimal-Design-System]]` ve `[[Style-Design-Tokens]]` rehberliğinde tamamen yenilenen bağımsız **Sistem Ayarları** uygulaması (`980×680`, `app-id: ogs-settings`): gruplu sol menü, anlık Türkçe arama, kaymayan yüzer toast bildirimleri, `Loader` tabanlı hızlı sayfa geçişleri ve **boş yer tutucu içermeyen 9 eksiksiz ayar sayfası**.

---

## 1. Pencere Mimarisi & Gezinme (`settings_app/shell.qml`)

* **Gruplu Sol Kenar Çubuğu (`244px`):**
  * Üstte anlık anahtar kelime araması (`"Ayar ara..."` — başlık, alt başlık ve Türkçe etiketlerde canlı filtreleme).
  * Alt kısımda aktif tema rengi ve sunum formatı (`Dynamic Notch` / `Dynamic Island`) özet kartı.
  * **3 Net Kategori Grubu (9 Tam Çalışan Sayfa):**
    * **Kabuk ve Görünüm:** `Görünüm ve Tema` (`AppearancePage`), `Ada ve Çentik` (`IslandPage`), `Kilit Ekranı` (`LockScreenPage`), `Hyprland` (`HyprlandPage`)
    * **Bağlantı ve Donanım:** `Ağ ve DNS` (`NetworkPage`), `Bluetooth` (`BluetoothPage`), `Ses` (`SoundPage`)
    * **Sistem:** `Bildirimler` (`NotificationsPage`), `Klavye ve Sistem` (`SystemPage`)
* **Sağ İçerik Alanı:** Sayfa ikonu, başlık ve 1 satırlık sade Türkçe açıklama başlığı + `Loader.setSource(url, { "ipc": ipcService })` ile `Component.onCompleted` öncesinde IPC bağlantısının sağlanması (sayfa geçişlerinde ayarların varsayılana dönmesini engeller; `HyprlandPage` ayrıca kapanışta bekleyen debounce kayıtlarını anında diske yazar) + sağ altta düzeni bozmayan yüzer geri bildirim kapsülü (`showToast`).

---

## 2. Paylaşılan UI Bileşenleri (`settings_app/components/`)

* `SettingsSegmentedTabs.qml`: `Easing.OutQuart` (`260ms`) animasyonlu 2–4 sekmeli kayan kapsül sekme kontrolü.
* `SettingsSliderRow.qml`: Etkileşimli sürükle/tıkla destekli kaydırıcı satırı + canlı değer rozeti (sayfa kaydırma kazalarını önlemek için scroll tekerleği kapalıdır; sürükleme sırasında geçici `_dragValue` kullanarak dış QML binding'lerini asla bozmaz).
* `SettingsCollapsibleSection.qml`: Gelişmiş ayarları tek tıkla açıp kapatan daraltılabilir kart (progressive disclosure).
* `SettingsCard.qml`, `SettingsRow.qml`, `SettingsChoiceCard.qml`, `SettingsDnsCard.qml`, `SettingsNumberRow.qml`, `SettingsToggle.qml`, `SettingsButton.qml`, `SettingsSectionHeader.qml`, `CubicBezierEditor.qml`.

---

## 3. Sayfa Sorumlulukları (`settings_app/pages/`)

1. **`AppearancePage.qml`:** 7 sistem teması için renk örnekli galeri (`DaemonIPC.setActiveTheme` + `Config.updateTheme`), duvar kağıdı hızlı geçişi, kabuk yazı tipi/kalınlığı, ekran köşe yuvarlatma ve gölge ayarları.
2. **`IslandPage.qml`:** Canlı üst çentik/ada önizlemesi, `Dynamic Notch` / `Dynamic Island` seçimi, temel davranışlar (`focus_mode`, sabit metrikler, Köşe HUD, Sistem Tepsisi) ve yalnızca **aktif moda ait** açılır-kapanır ince boyut/animasyon kaydırıcıları.
3. **`LockScreenPage.qml`:** `[[Lock-Screen-Component]]` için canlı mini kilit ekranı önizlemesi, **"Şimdi Test Et (Kilitle)"** butonu, saat fontu (`SF Pro Rounded`, `SF Pro Display`, `Outfit`, `Inter`...), kalınlık, saat/tarih boyutu, bulanıklık (`blur_radius`), karartma (`dim_opacity`) ve alt medya/güç bileşeni anahtarları.
4. **`HyprlandPage.qml`:** Oyun/Performans Modu, Monitör Profili seçici, Pencere Görünümü preset kartları + kapalı kenarlık/boşluk/gölge ince ayar çekmecesi, **Hyprland 0.57.2 Blur Stüdyosu** (11 varyant + seçili varyanta özel dinamik kontroller), **7'li Modüler Animasyon** presetleri + kapalı tekil animasyon özelleştirme çekmecesi ve kapalı `CubicBezierEditor` çekmecesi (`[[Hyprland-Profile-Service]]`).
5. **`NetworkPage.qml`:** `Wi-Fi` / `Ethernet` sekmeli geçiş, kompakt **2×3 Güvenli DNS ızgarası** (Cloudflare, Quad9, AdGuard, Google, Otomatik DHCP, Özel DNS), IPv6 koruması, çevredeki Wi-Fi ağları ve kopya profil temizleme.
6. **`BluetoothPage.qml`:** `[[Bluetooth-Service]]` adaptör gücü, tarama başlat/durdur ve tek tıkla cihaz bağlan/kes yönetimi.
7. **`SoundPage.qml`:** Canlı PipeWire çıkış kaydırıcısı + hızlı seviye presetleri (`%25–%150`), `%150` ses yükseltme (`auto-clamp`), akustik geri bildirim ve köşe OSD ayarları.
8. **`NotificationsPage.qml`:** `[[Notification-Service]]` DND modu, kart görünürlüğü/süresi, geçmiş temizleme ve uygulama filtre kuralları.
9. **`SystemPage.qml`:** `[[Keyboard-Service]]` klavye dili değiştirici, `[[Currency-Service]]` döviz çevirici ayarları ve `ogsShell` yeniden yükleme / kilitleme hızlı işlemleri.

---

## 4. İlgili Bağlantılar

* Sistem Mimarisi: `[[System-Architecture]]`
* Konfigürasyon Şeması: `[[Configuration-System-Spec]]`
* Kilit Ekranı: `[[Lock-Screen-Component]]`
* Dinamik Ada: `[[Dynamic-Island-Component]]`
* Hyprland Profil Servisi: `[[Hyprland-Profile-Service]]`
* Tasarım Token'ları: `[[Style-Design-Tokens]]`
* IPC İstemcisi: `[[Daemon-IPC-Client]]`
