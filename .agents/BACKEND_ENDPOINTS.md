# 🔌 Backend IPC Endpoints & Socket Protocol Reference

Bu doküman, `ogsShell-qs` Go daemon arka plan servisi (`core/`) ile Quickshell QML arayüz katmanı (`shell/`) arasındaki tüm Unix Domain Socket IPC erişim uçlarını, RPC komutlarını (Actions), yayınlanan olayları (Events) ve veri yapılarını (Payload Schemas) eksiksiz olarak tanımlar.

---

## 1. Taşıma Katmanı & Protokol Mimarisi (Transport & Protocol)

* **Soket Yolu:** `$XDG_RUNTIME_DIR/ogs_shell.sock` (Eğer ortam değişkeni tanımsız ise `/tmp/ogs_shell.sock`)
* **Format:** **NDJSON (Newline-Delimited JSON)** — Her JSON mesajı tek bir satırdan oluşur ve `\n` (`0x0A`) karakteri ile sonlandırılır.
* **Mesaj Yönü ve Tipleri:**
  1. **Frontend $\to$ Backend (RPC Action):** `{"name": "<action_name>", "args": { ... }}`
  2. **Backend $\to$ Frontend (Event Broadcast):** `{"type": "<event_type>", "payload": { ... }}`

```text
┌────────────────────────────────────────────────────────┐
│               Go Backend Daemon (core/)                │
│  - ipc.Server (Broadcasts NDJSON to all active clients)│
│  - server.SetActionHandler(func(action Action) error)  │
└───────────────────────────┬────────────────────────────┘
                            │ NDJSON Stream (\n delimited)
                            │ $XDG_RUNTIME_DIR/ogs_shell.sock
┌───────────────────────────▼────────────────────────────┐
│         Quickshell QML Frontend (shell/)               │
│  - DaemonIPC.qml (Quickshell.Io.Socket + SplitParser)  │
│  - sendAction(name, args)                              │
└────────────────────────────────────────────────────────┘
```

---

## 2. Hızlı Erişim Özet Tablosu (Endpoint & Event Cheat Sheet)

### A. İstemci Tarafından Gönderilen Komutlar (RPC Actions)

| Servis / Modül | Action İsmi | Parametreler (`args`) | Tetiklenen / Yanıt Event | Açıklama |
| :--- | :--- | :--- | :--- | :--- |
| **Wi-Fi** | `scan_wifi` | `{}` | `wifi_scan_results` | Çevredeki Wi-Fi ağlarını tarar |
| **Wi-Fi** | `get_saved_wifi_profiles` | `{}` | `saved_wifi_profiles` | Kayıtlı bağlantı profillerini listeler |
| **Wi-Fi** | `get_wifi_secrets` | `{"ssid_or_uuid": "..."}` | `wifi_secrets` | Kayıtlı ağın şifre ve güvenlik detayını döner |
| **Wi-Fi** | `connect_wifi` | `{"ssid": "...", "password": "...", "hidden": false}` | `wifi_update` | Belirtilen Wi-Fi ağına bağlanır |
| **Wi-Fi** | `disconnect_wifi` | `{}` | `wifi_update` | Aktif Wi-Fi bağlantısını keser |
| **Wi-Fi** | `update_wifi_secrets` | `{"ssid_or_uuid": "...", "password": "..."}` | `wifi_update` | Profil parolasını günceller |
| **Wi-Fi** | `delete_wifi_profile` / `forget_wifi` | `{"ssid_or_uuid": "..."}` | `saved_wifi_profiles` | Kayıtlı Wi-Fi profilini siler / unutur |
| **Wi-Fi** | `set_wifi_enabled` | `{"enabled": true/false}` | `wifi_update` | Wi-Fi donanımını açar / kapatır |
| **Wi-Fi** | `get_active_wifi` | `{}` | `active_wifi_info` | Aktif bağlantının detaylı telemetrisini döner |
| **Bluetooth** | `toggle_bluetooth` | `{"enabled": true/false}` *(opsiyonel)* | `bluetooth_update` | Bluetooth gücünü açar, kapatır veya tersine çevirir |
| **Bluetooth** | `connect_bluetooth` | `{"mac": "XX:XX:XX:XX:XX:XX"}` | `bluetooth_update` | MAC adresi verilen cihaza bağlanır |
| **Bluetooth** | `disconnect_bluetooth` | `{"mac": "XX:XX:XX:XX:XX:XX"}` | `bluetooth_update` | Cihaz bağlantısını sonlandırır |
| **Bluetooth** | `start_bluetooth_scan` | `{}` | `bluetooth_update` | 15 saniyelik cihaz keşif taraması başlatır |
| **Bluetooth** | `stop_bluetooth_scan` | `{}` | `bluetooth_update` | Aktif taramayı durdurur |
| **Bluetooth** | `get_bluetooth_state` | `{}` | `bluetooth_update` | Mevcut adaptör ve cihaz listesini sorgular |
| **Alarm** | `add_alarm` | `{"time": "HH:MM", "days": [...], "label": "..."}` | `alarms_update` | Yeni alarm kaydeder ve zamanlayıcı kurar |
| **Alarm** | `delete_alarm` | `{"id": "alarm_..."}` | `alarms_update` | Alarmı siler ve çalıyorsa susturur |
| **Alarm** | `toggle_alarm` | `{"id": "alarm_...", "enabled": true/false}` | `alarms_update` | Alarmın aktiflik durumunu değiştirir |
| **Alarm** | `snooze_alarm` | `{"id": "alarm_...", "minutes": 5}` | `alarms_update` | Çalan alarmı X dakika erteler (varsayılan: 5) |
| **Alarm** | `dismiss_alarm` | `{"id": "alarm_..."}` | `alarms_update` | Çalan alarmı kapatır, ertelemeyi sıfırlar |
| **Alarm** | `get_alarms` | `{}` | `alarms_update` | Tüm kayıtlı alarmları listeler |
| **Takvim** | `get_calendar_month` | `{"year": 2026, "month": 8}` | `calendar_month_data` | Ay matrisini, tatilleri ve etkinlikleri getirir |
| **Takvim** | `add_calendar_event` | `{"title": "...", "date": "YYYY-MM-DD", ...}` | `calendar_events_update` | Yeni etkinlik ekler ve hatırlatıcı kurar |
| **Takvim** | `update_calendar_event` | `{"id": "evt_...", "title": "...", ...}` | `calendar_events_update` | Mevcut etkinliği günceller |
| **Takvim** | `delete_calendar_event` | `{"id": "evt_..."}` | `calendar_events_update` | Etkinliği siler |
| **Takvim** | `toggle_calendar_event` | `{"id": "evt_...", "completed": true/false}` | `calendar_events_update` | Etkinliğin tamamlanma durumunu değiştirir |
| **Takvim** | `get_holidays` | `{"year": 2026}` | `holidays_data` | Yıla ait milli ve dini tatilleri döner |
| **Takvim** | `sync_holidays` | `{"year": 2026}` | `holidays_data` + `calendar_month_data` | Tatilleri asenkron olarak dış kaynaktan eşitler |
| **Bildirim** | `add_notification` | `{"app_name": "...", "summary": "...", "body": "...", "urgency": "normal"}` | `notification_received` + `notifications_update` | Bildirimi işler, kural/DND kontrolü yapar ve kaydeder |
| **Bildirim** | `get_notifications` | `{}` | `notifications_update` | Tüm bildirim geçmişini listeler |
| **Bildirim** | `delete_notification` | `{"id": "notif_..."}` | `notifications_update` | Tek bir bildirimi geçmişten siler |
| **Bildirim** | `clear_notifications` | `{}` | `notifications_update` | Tüm bildirim geçmişini temizler |
| **Bildirim** | `mark_notification_read` | `{"id": "notif_..."}` veya `{"all": true}` | `notifications_update` | Bildirimi veya tümünü okundu işaretler |
| **Bildirim** | `toggle_dnd` | `{"enabled": true/false}` *(opsiyonel)* | `dnd_update` | Rahatsız Etme Modunu açar, kapatır veya değiştirir |
| **Bildirim** | `get_dnd_state` | `{}` | `dnd_update` | DND durumunu sorgular |
| **Bildirim** | `set_notification_rule` | `{"app_name": "...", "mode": "mute/block/priority/normal"}` | `notification_rules_update` | Uygulamaya özel sessize alma / filtreleme kuralı ekler |
| **Bildirim** | `delete_notification_rule` | `{"app_name": "..."}` | `notification_rules_update` | Uygulama kuralını kaldırır |
| **Bildirim** | `get_notification_rules` | `{}` | `notification_rules_update` | Tüm uygulama kurallarını listeler |
| **Pano** | `get_clipboard_history` | `{"limit": 50, "query": "..."}` | `clipboard_update` | Pano geçmişini listeler ve filtreler |
| **Pano** | `copy_clipboard_item` | `{"id": "..."}` veya `{"text": "..."}` | `clipboard_update` | Seçilen veya verilen metni aktif panoya kopyalar (`wl-copy`) |
| **Pano** | `get_clipboard_content` | `{"id": "..."}` | `clipboard_content_data` | Belirli bir öğenin tam içeriğini döner |
| **Pano** | `delete_clipboard_item` | `{"id": "..."}` | `clipboard_update` | Öğeyi geçmişten siler (`cliphist delete`) |
| **Pano** | `clear_clipboard_history` | `{}` | `clipboard_update` | Geçmişi temizler (`cliphist wipe`, sabitlenenler korunur) |
| **Pano** | `pin_clipboard_item` | `{"id": "...", "label": "..."}` | `pinned_clipboard_update` | Öğeyi favorilere sabitler |
| **Pano** | `unpin_clipboard_item` | `{"id": "..."}` | `pinned_clipboard_update` | Öğeyi favorilerden kaldırır |
| **Pano** | `get_pinned_clipboard_items`| `{}` | `pinned_clipboard_update` | Tüm sabitlenmiş favori metinleri listeler |
| **Klavye** | `get_keyboard_layout` | `{}` | `keyboard_layout_update` | Aktif klavye durumu, düzeni ve kısa kodunu döner |
| **Klavye** | `switch_keyboard_layout` | `{"target": "next/0/1"}` | `keyboard_layout_update` | Klavye düzenini bir sonrakine veya indekse geçirir |
| **Klavye** | `set_configured_layouts` | `{"layouts": ["tr", "us"]}` | `keyboard_layout_update` | Aktif layout listesini ayarlar ve kaydeder |
| **Klavye** | `get_available_system_layouts` | `{}` | `available_layouts_data` | XKB sistemindeki tüm dillerin listesini döner |
| **Tema** | `get_theme_state` | `{}` | `theme_update` | Aktif tema, mevcut temalar ve adaptör durumlarını döner |
| **Tema** | `get_available_themes` | `{}` | `available_themes_data` | Sistemdeki tüm tema paletlerini listeler |
| **Tema** | `set_active_theme` | `{"theme_id": "tokyo-night"}` | `theme_update` | Temayı tüm aktif uygulamalara paralel uygular |
| **Tema** | `save_custom_theme` | `{"theme": {...}}` | `theme_update` | Yeni özel tema JSON paleti kaydeder |
| **Tema** | `delete_custom_theme` | `{"theme_id": "..."}` | `theme_update` | Özel tema JSON dosyasını siler |
| **Tema** | `toggle_theme_adapter` | `{"adapter_id": "kitty", "enabled": bool}` | `theme_update` | Uygulama bazlı tema senkronizasyonunu açar/kapatır |
| **Duvar Kağıdı** | `get_theme_wallpapers` | `{"theme_id": "everforest"}` *(opsiyonel)* | `theme_wallpapers_data` | Temaya ait havuzdaki tüm görselleri ve aktif olanı döner |
| **Duvar Kağıdı** | `set_wallpaper` | `{"theme_id": "...", "wallpaper_path": "..."}` | `theme_wallpapers_data` | Belirli bir duvar kağıdını `awww` ile anında uygular ve kaydeder |
| **Duvar Kağıdı** | `next_wallpaper` | `{"theme_id": "everforest"}` *(opsiyonel)* | `theme_wallpapers_data` | Aktif temanın havuzundaki sıradaki duvar kağıdına geçer |
| **Launcher** | `search_apps` | `{"query": "gimp", "limit": 15}` | `app_search_results` | Akıllı fuzzy/akronym arama yapar ve ilk X sonucu döner |
| **Launcher** | `list_apps` | `{"limit": 50}` | `app_list_data` | İndekslenen uygulamaları popülerliğe göre listeler |
| **Launcher** | `launch_app` | `{"id": "...", "exec": "..."}` | `app_launched` | Uygulamayı bağımsız/izole süreç (`systemd-run`) olarak başlatır |
| **Launcher** | `reindex_apps` | `{}` | `app_list_data` | Masaüstü uygulama indeksini yeniden tarar |
| **Launcher** | `toggle_launcher` | `{}` | `toggle_launcher` | Dynamic Island üzerinde App Launcher görünümünü açar/kapatır |
| **Launcher** | `open_launcher` | `{}` | `open_launcher` | Dynamic Island üzerinde App Launcher görünümünü açar |
| **Launcher** | `close_launcher` | `{}` | `close_launcher` | Açık olan App Launcher görünümünü kapatır |
| **App Routing** | `open_app` | `{"app": "themes", "subview": "..."}` | `open_app` | Belirtilen uygulamayı Dynamic Island üzerinde odaklar ve açar |
| **App Routing** | `toggle_app` | `{"app": "...", "subview": "..."}` | `toggle_app` | Belirtilen uygulamayı Dynamic Island üzerinde açar veya kapatır |
| **Kısayollar** | `toggle_control_center` / `open_control_center` | `{}` | `toggle_control_center` | Kontrol Merkezi görünümünü açar/kapatır |
| **Kısayollar** | `toggle_themes` / `open_themes` | `{}` | `toggle_themes` | Tema galerisi ve ayarları görünümünü açar/kapatır |
| **Kısayollar** | `toggle_notifications` / `open_notifications` | `{}` | `toggle_notifications` | Bildirim merkezi görünümünü açar/kapatır |
| **Kısayollar** | `toggle_power_menu` / `open_power_menu` | `{}` | `toggle_power_menu` | Dairesel güç ve oturum menüsünü açar/kapatır |
| **Kısayollar** | `toggle_media_player` / `open_media_player` | `{}` | `toggle_media_player` | Medya oynatıcısı görünümünü açar/kapatır |
| **Kısayollar** | `toggle_calendar` / `open_calendar` | `{}` | `toggle_calendar` | Takvim ve etkinlikler görünümünü açar/kapatır |
| **Kısayollar** | `toggle_clipboard` / `open_clipboard` | `{}` | `toggle_clipboard` | Pano geçmişi yöneticisini açar/kapatır |
| **Kısayollar** | `toggle_clock` / `open_clock` | `{}` | `toggle_clock` | Saat, Pomodoro ve Alarm uygulamasını açar/kapatır |
| **Kısayollar** | `toggle_wifi_view` / `open_wifi` | `{}` | `toggle_wifi_view` | Wi-Fi ayarları panelini açar/kapatır |
| **Kısayollar** | `toggle_bluetooth_view` / `open_bluetooth` | `{}` | `toggle_bluetooth_view` | Bluetooth ayarları panelini açar/kapatır |

---

### B. Backend Tarafından Yayınlanan Olaylar (Broadcast Events)

| Olay Tipi (`type`) | Tetiklenme Kaynağı / Sıklık | Payload Veri Tipi | Açıklama |
| :--- | :--- | :--- | :--- |
| `sys_metrics` | 1 saniyede bir periyodik | `SystemMetricsPayload` | CPU, RAM, GPU ve Ağ kullanım/sıcaklık telemetrisi |
| `wifi_update` | D-Bus sinyal odaklı (500ms debounce) | `[]AccessPoint` | Çevredeki Wi-Fi ağlarının güncel listesi |
| `wifi_scan_results` | `scan_wifi` RPC komutuna yanıt | `[]AccessPoint` | Manuel tarama sonucu bulunan erişim noktaları |
| `saved_wifi_profiles` | `get_saved_wifi_profiles` / silme işlemi | `[]WifiProfile` | NetworkManager kayıtlı Wi-Fi bağlantı profilleri |
| `wifi_secrets` | `get_wifi_secrets` RPC komutuna yanıt | `WifiSecrets` | Wi-Fi profiline ait WPA parolası ve anahtar yönetimi |
| `active_wifi_info` | `get_active_wifi` RPC komutuna yanıt | `ActiveWifiInfo` | Aktif bağlı ağın IP, Gateway, DNS, Sinyal, Hız detayları |
| `bluetooth_update` | D-Bus sinyal odaklı (500ms debounce) | `BluetoothState` | Adaptör durumu, tarama durumu ve cihaz listesi |
| `alarms_update` | Alarm CRUD veya durum değişimlerinde | `[]Alarm` | Kayıtlı tüm alarmların güncel listesi |
| `alarm_triggered` | Alarm çalma vakti geldiğinde | `AlarmTriggeredPayload` | Çalan alarmın ID, etiket ve saat bilgisi |
| `calendar_month_data` | `get_calendar_month` / `sync_holidays` | `MonthData` | Ayın günleri, tatilleri ve etkinlikleri |
| `calendar_events_update` | Etkinlik CRUD işlemlerinde | `[]CalendarEvent` | Kayıtlı takvim etkinlikleri listesi |
| `calendar_reminder_triggered` | Etkinlik hatırlatma vakti geldiğinde | `CalendarReminderTriggeredPayload` | Hatırlatma başlığı, tarihi, saati ve kalan dakika |
| `holidays_data` | `get_holidays` / `sync_holidays` | `[]Holiday` | Resmi ve dini tatil listesi |
| `notifications_update` | Bildirim CRUD veya okundu işlemlerinde | `[]Notification` | Kayıtlı bildirim geçmişi listesi (en yeni en başta) |
| `notification_received` | Yeni bildirim geldiğinde | `NotificationReceivedPayload` | Bildirim nesnesi, `should_popup` ve `reason` kararı |
| `dnd_update` | DND modu değiştiğinde | `{"dnd_enabled": bool}` | Rahatsız Etme Modu aktiflik durumu |
| `notification_rules_update` | Kural eklendiğinde / silindiğinde | `[]NotificationRule` | Uygulama bazlı kurallar listesi |
| `clipboard_update` | Pano değiştiğinde veya işlem yapıldığında | `[]ClipboardItem` | Son kopyalanan pano geçmişi listesi |
| `clipboard_item_copied` | Yeni bir metin/öğe kopyalandığında | `ClipboardItemCopiedPayload` | Yeni kopyalanan öğenin ID, önizleme ve tipi |
| `pinned_clipboard_update` | Favori eklendiğinde / çıkarıldığında | `[]PinnedItem` | Sabitlenmiş/favori metin parçacıkları listesi |
| `clipboard_content_data` | `get_clipboard_content` RPC yanıtı | `ItemContentResponse` | Çözülen tam ham pano içeriği |
| `keyboard_layout_update` | Klavye düzeni değiştiğinde (fiziksel kısayol veya UI) | `KeyboardState` | Aktif düzen, kısa kod ve yapılandırılmış düzenler |
| `available_layouts_data` | `get_available_system_layouts` yanıtı | `[]AvailableLayout` | Sistemde tanımlı tüm XKB klavye dilleri |
| `theme_update` | Tema değiştiğinde veya adaptör güncellendiğinde | `ThemeState` | Aktif tema, renk haritası, tüm temalar ve adaptörler |
| `available_themes_data` | `get_available_themes` yanıtı | `[]ThemePalette` | Diskten taranan tüm tema paletleri |
| `theme_wallpapers_data` | Duvar kağıdı sorgulandığında / değiştiğinde | `ThemeWallpapersResponse` | Temanın havuzundaki görseller ve aktif duvar kağıdı yolu |
| `app_search_results` | `search_apps` RPC komutuna yanıt | `AppSearchResultPayload` | Arama sorgusuna göre puanlanmış ve sıralanmış uygulama listesi |
| `app_list_data` | `list_apps` / `reindex_apps` / dosya değişikliği | `[]AppEntry` | Sistemdeki tüm indekslenmiş masaüstü uygulamaları |
| `app_launched` | `launch_app` RPC komutu yürütüldüğünde | `AppLaunchedPayload` | Uygulama başlatma durumu ve hata mesajı |
| `toggle_launcher` | `toggle_launcher` RPC komutuna yanıt | `{}` | Dynamic Island'ın launcher modunu açıp/kapatması için sinyal |
| `open_launcher` | `open_launcher` RPC komutuna yanıt | `{}` | Dynamic Island'ın launcher modunu açması için sinyal |
| `close_launcher` | `close_launcher` RPC komutuna yanıt | `{}` | Dynamic Island'ın launcher modunu kapatması için sinyal |

---

## 3. Detaylı Servis Şemaları ve Payload Tipleri

### 3.1. Sistem Metrikleri (`sys_metrics`)

* **Yayın Sıklığı:** 1 saniyede bir (`monitors.Manager`)
* **Örnek JSON:**

```json
{
  "type": "sys_metrics",
  "payload": {
    "cpu": {
      "cpu_percent": 14.82,
      "cpu_temp": 48.5
    },
    "ram": {
      "ram_used_mb": 4210,
      "ram_total_mb": 16032,
      "ram_percent": 26.25
    },
    "gpu": {
      "gpu_temp": 51.0,
      "gpu_percent": 8.0
    },
    "net": {
      "rx_bytes_sec": 128450.5,
      "tx_bytes_sec": 34200.0,
      "interface": "wlan0",
      "is_connected": true
    }
  }
}
```

* **Alan Tanımları:**
  * `cpu.cpu_percent` (`float64`): Genel işlemci yükü (0.0 - 100.0).
  * `cpu.cpu_temp` (`float64`): `/sys/class/thermal` üzerinden okunan CPU sıcaklığı (°C). Desteklenmiyorsa `-1.0`.
  * `ram.ram_used_mb` (`uint64`): Kullanılan RAM (MB).
  * `ram.ram_total_mb` (`uint64`): Toplam fiziksel RAM (MB).
  * `ram.ram_percent` (`float64`): RAM kullanım yüzdesi.
  * `gpu.gpu_percent` (`float64`): GPU kullanım oranı (NVML veya sysfs üzerinden). Desteklenmiyorsa `-1.0`.
  * `gpu.gpu_temp` (`float64`): GPU sıcaklığı (°C). Desteklenmiyorsa `-1.0`.
  * `net.rx_bytes_sec` (`float64`): Anlık indirme hızı (Byte/sn).
  * `net.tx_bytes_sec` (`float64`): Anlık yükleme hızı (Byte/sn).
  * `net.interface` (`string`): Varsayılan route'a sahip aktif ağ arayüzü (`wlan0`, `eth0` vb.).
  * `net.is_connected` (`bool`): Varsayılan internet gateway bağlantı durumu.

---

### 3.2. Wi-Fi Servisi (`core/services/wifi/`)

#### A. Veri Modelleri

1. **`AccessPoint`** (Taranan Wi-Fi Ağı):
```json
{
  "ssid": "MyHomeNetwork",
  "bssid": "00:11:22:33:44:55",
  "signal": 85,
  "frequency": 5180,
  "band": "5GHz",
  "security": "WPA2-PSK",
  "is_saved": true,
  "is_active": true,
  "channel": 36
}
```
* `security` Değerleri: `"OPEN"`, `"WPA-PSK"`, `"WPA2-PSK"`, `"WPA3-SAE"`, `"WPA-EAP"`, `"WEP"`, `"UNKNOWN"`
* `band` Değerleri: `"2.4GHz"`, `"5GHz"`, `"6GHz"`

2. **`WifiProfile`** (Kayıtlı Profil):
```json
{
  "uuid": "7c152a55-8c3b-48bb-a877-f279b90c1020",
  "name": "MyHomeNetwork",
  "ssid": "MyHomeNetwork",
  "security_type": "WPA2-PSK",
  "auto_connect": true,
  "last_used": 1723380000,
  "has_password": true
}
```

3. **`ActiveWifiInfo`** (Aktif Bağlantı Bilgisi):
```json
{
  "ssid": "MyHomeNetwork",
  "bssid": "00:11:22:33:44:55",
  "device": "wlan0",
  "ip_address": "192.168.1.105",
  "gateway": "192.168.1.1",
  "dns": ["1.1.1.1", "8.8.8.8"],
  "signal": 88,
  "frequency": 5180,
  "bitrate_kbps": 866000,
  "security": "WPA2-PSK"
}
```

4. **`WifiSecrets`** (Kayıtlı Parola):
```json
{
  "ssid": "MyHomeNetwork",
  "uuid": "7c152a55-8c3b-48bb-a877-f279b90c1020",
  "password": "secretpassword123",
  "key_mgmt": "wpa-psk"
}
```

#### B. RPC Komut Örnekleri

* **Ağa Bağlanma:**
```json
{
  "name": "connect_wifi",
  "args": {
    "ssid": "Office_Guest",
    "password": "guestpassword",
    "hidden": false
  }
}
```

* **Şifre Güncelleme:**
```json
{
  "name": "update_wifi_secrets",
  "args": {
    "ssid_or_uuid": "Office_Guest",
    "password": "newpassword2026"
  }
}
```

* **Wi-Fi Donanımını Kapatma:**
```json
{
  "name": "set_wifi_enabled",
  "args": {
    "enabled": false
  }
}
```

---

### 3.3. Bluetooth Servisi (`core/services/bluetooth/`)

#### A. Veri Modelleri

1. **`BluetoothState`**:
```json
{
  "type": "bluetooth_update",
  "payload": {
    "adapter_powered": true,
    "discovering": false,
    "devices": [
      {
        "mac": "38:18:4C:BE:11:92",
        "name": "Sony WH-1000XM4",
        "icon": "audio-headset",
        "connected": true,
        "paired": true,
        "rssi": -58
      },
      {
        "mac": "F4:4E:FC:AA:BB:CC",
        "name": "Keychron K2",
        "icon": "input-keyboard",
        "connected": false,
        "paired": true,
        "rssi": -72
      }
    ]
  }
}
```
* `icon` Değerleri: `"audio-headset"`, `"audio-card"`, `"input-keyboard"`, `"input-mouse"`, `"input-gaming"`, `"phone"`, `"computer"`, `"bluetooth"`

#### B. RPC Komut Örnekleri

* **Cihaza Bağlan:**
```json
{
  "name": "connect_bluetooth",
  "args": { "mac": "38:18:4C:BE:11:92" }
}
```

* **Taramayı Başlat:**
```json
{
  "name": "start_bluetooth_scan",
  "args": {}
}
```

---

### 3.4. Alarm Servisi (`core/services/alarm/`)

* **Kayıt Dosyası:** `$XDG_CONFIG_HOME/ogsShell/alarms.json`
* **Ses Çalma Motoru:** PipeWire `pw-play` / PulseAudio `paplay` (İptal ve ertelemede anında sonlandırılır).

#### A. Veri Modelleri

1. **`Alarm`**:
```json
{
  "id": "alarm_1786392495182",
  "time": "07:30",
  "days": [1, 2, 3, 4, 5],
  "label": "Hafta İçi Uyanma",
  "enabled": true,
  "sound_path": "",
  "snooze_count": 0
}
```
* `days`: Haftanın günleri listesi (`1` = Pazartesi, `7` = Pazar). Liste boş ise tek seferlik (one-shot) alarmdır.

2. **`AlarmTriggeredPayload`** (`alarm_triggered` Event):
```json
{
  "type": "alarm_triggered",
  "payload": {
    "id": "alarm_1786392495182",
    "label": "Hafta İçi Uyanma",
    "time": "07:30"
  }
}
```

#### B. RPC Komut Örnekleri

* **Yeni Alarm Ekle:**
```json
{
  "name": "add_alarm",
  "args": {
    "time": "08:15",
    "days": [1, 2, 3, 4, 5],
    "label": "Standup Toplantısı",
    "enabled": true
  }
}
```

* **Alarmı Ertele (Snooze):**
```json
{
  "name": "snooze_alarm",
  "args": {
    "id": "alarm_1786392495182",
    "minutes": 10
  }
}
```

* **Alarmı Kapat / Sustur (Dismiss):**
```json
{
  "name": "dismiss_alarm",
  "args": {
    "id": "alarm_1786392495182"
  }
}
```

---

### 3.5. Takvim ve Tatil Servisi (`core/services/calendar/`)

* **Kayıt Dosyası:** `$XDG_CONFIG_HOME/ogsShell/calendar_events.json`
* **Tatil Motoru:** Türkiye milli bayramları ve hicri takvime göre hesaplanan dini bayramlar (Ramazan, Kurban ve Arefeler).

#### A. Veri Modelleri

1. **`Holiday`**:
```json
{
  "date": "2026-10-29",
  "name": "Cumhuriyet Bayramı",
  "is_half_day": false,
  "type": "national"
}
```

2. **`CalendarEvent`**:
```json
{
  "id": "evt_1786395000",
  "title": "Mimari Tasarım İncelemesi",
  "description": "Dynamic Island animasyon performansı",
  "date": "2026-08-15",
  "time": "14:30",
  "all_day": false,
  "color": "#89b4fa",
  "completed": false,
  "notify_before_minutes": 15,
  "notified": false
}
```

3. **`MonthData`** (`calendar_month_data` Event):
```json
{
  "type": "calendar_month_data",
  "payload": {
    "year": 2026,
    "month": 8,
    "holidays": [
      {
        "date": "2026-08-30",
        "name": "Zafer Bayramı",
        "is_half_day": false,
        "type": "national"
      }
    ],
    "events": [
      {
        "id": "evt_1786395000",
        "title": "Mimari Tasarım İncelemesi",
        "date": "2026-08-15",
        "time": "14:30",
        "completed": false
      }
    ]
  }
}
```

4. **`CalendarReminderTriggeredPayload`** (`calendar_reminder_triggered` Event):
```json
{
  "type": "calendar_reminder_triggered",
  "payload": {
    "id": "evt_1786395000",
    "title": "Mimari Tasarım İncelemesi",
    "date": "2026-08-15",
    "time": "14:30",
    "minutes_until": 15
  }
}
```

#### B. RPC Komut Örnekleri

* **Ay Verisini İste:**
```json
{
  "name": "get_calendar_month",
  "args": {
    "year": 2026,
    "month": 8
  }
}
```

* **Etkinlik Ekle:**
```json
{
  "name": "add_calendar_event",
  "args": {
    "title": "Proje Teslimi",
    "description": "v1.0 sürüm yayını",
    "date": "2026-08-20",
    "time": "18:00",
    "all_day": false,
    "notify_before_minutes": 30
  }
}
```

---

### 3.6. Bildirim, DND ve Uygulama Kuralları Servisi (`core/services/notifications/`)

* **Kayıt Dosyaları:** `$XDG_CONFIG_HOME/ogsShell/notifications.json` ve `notification_rules.json`
* **Otomatik Budama:** Geçmiş en fazla 100 bildirimde tutulur.
* **Kural Modları (`mode`):**
  * `"normal"`: Standart bildirim (ada üzerinde transient pop-up gösterir + geçmişe kaydeder).
  * `"mute"`: Sessiz bildirim (ada üzerinde pop-up açılmaz, sessizce geçmişe kaydeder).
  * `"block"`: Tamamen engellenir (ne açılır ne de geçmişe kaydedilir).
  * `"priority"`: Öncelikli bildirim (DND aktif olsa dahi adada pop-up açar).

#### A. Veri Modelleri

1. **`Notification`**:
```json
{
  "id": "notif_1786395000123_1",
  "app_name": "Discord",
  "summary": "Yeni Mesaj",
  "body": "Toplantı saat 15:00'te başlıyor.",
  "icon": "discord",
  "urgency": "normal",
  "timestamp": 1786395000123,
  "read": false
}
```

2. **`NotificationRule`**:
```json
{
  "app_name": "Spotify",
  "mode": "mute",
  "sound_enabled": false
}
```

3. **`NotificationReceivedPayload`** (`notification_received` Event):
```json
{
  "type": "notification_received",
  "payload": {
    "notification": {
      "id": "notif_1786395000123_1",
      "app_name": "Discord",
      "summary": "Yeni Mesaj",
      "body": "Toplantı saat 15:00'te başlıyor.",
      "urgency": "normal",
      "timestamp": 1786395000123,
      "read": false
    },
    "should_popup": true,
    "reason": "normal"
  }
}
```
* `reason` Değerleri: `"normal"`, `"dnd_suppressed"`, `"app_muted"`, `"priority_override"`, `"critical_override"`

#### B. RPC Komut Örnekleri

* **Bildirim Ekleme:**
```json
{
  "name": "add_notification",
  "args": {
    "app_name": "Firefox",
    "summary": "İndirme Tamamlandı",
    "body": "fedora-workstation.iso indi.",
    "urgency": "normal"
  }
}
```

* **Rahatsız Etme Modunu Aç/Kapat (DND Toggle):**
```json
{
  "name": "toggle_dnd",
  "args": {
    "enabled": true
  }
}
```

* **Uygulama Kuralı Tanımlama (Örn. Spotify'ı Sessize Al):**
```json
{
  "name": "set_notification_rule",
  "args": {
    "app_name": "Spotify",
    "mode": "mute",
    "sound_enabled": false
  }
}
```

* **Bildirimi Okundu Olarak İşaretle:**
```json
{
  "name": "mark_notification_read",
  "args": {
    "id": "notif_1786395000123_1"
  }
}
```

* **Tüm Geçmişi Temizle:**
```json
{
  "name": "clear_notifications",
  "args": {}
}
```

---

### 3.7. Kopyalama Panosu ve Favori Parçacıklar Servisi (`core/services/clipboard/`)

* **Entegrasyon:** Wayland `cliphist` ve `wl-clipboard` (`wl-copy`, `wl-paste`)
* **Kayıt Dosyası:** Sabitlenmiş/favori parçacıklar için `$XDG_CONFIG_HOME/ogsShell/clipboard_pinned.json`
* **Canlı İzleme:** Arka plan izleyici periyodu ile pano değişikliklerini anında yakalar ve yayınlar.

#### A. Veri Modelleri

1. **`ClipboardItem`**:
```json
{
  "id": "7563",
  "preview": "const token = \"catppuccin-mocha\";",
  "type": "text",
  "is_pinned": false,
  "timestamp": 1786395000123
}
```
* `type` Değerleri: `"text"`, `"image"`

2. **`PinnedItem`**:
```json
{
  "id": "pin_1786395000",
  "content": "git commit -m 'feat: add dynamic island widget'",
  "label": "Git Feat Şablonu",
  "timestamp": 1786395000
}
```

3. **`ClipboardItemCopiedPayload`** (`clipboard_item_copied` Event):
```json
{
  "type": "clipboard_item_copied",
  "payload": {
    "id": "7563",
    "preview": "const token = \"catppuccin-mocha\";",
    "type": "text"
  }
}
```

#### B. RPC Komut Örnekleri

* **Pano Geçmişini Sorgulama:**
```json
{
  "name": "get_clipboard_history",
  "args": {
    "limit": 50,
    "query": "git"
  }
}
```

* **Öğeyi Aktif Panoya Kopyalama:**
```json
{
  "name": "copy_clipboard_item",
  "args": {
    "id": "7563"
  }
}
```

* **Öğeyi Favorilere Sabitleme:**
```json
{
  "name": "pin_clipboard_item",
  "args": {
    "id": "7563",
    "label": "Tema Değişkeni"
  }
}
```

* **Pano Geçmişini Temizleme (Sabitlenenler Korunur):**
```json
{
  "name": "clear_clipboard_history",
  "args": {}
}
```

---

### 3.8. Klavye Düzeni Yöneticisi (`core/services/keyboard/`)

* **Entegrasyon:** Hyprland `.socket2.sock` event listener, `hyprctl devices -j`, `hyprctl switchxkblayout`, `hyprctl keyword input:kb_layout`
* **Kayıt Dosyası:** `$XDG_CONFIG_HOME/ogsShell/keyboard_config.json`
* **XKB Veritabanı:** `/usr/share/X11/xkb/rules/evdev.lst`

#### A. Veri Modelleri

1. **`KeyboardState`** (`keyboard_layout_update` Event):
```json
{
  "type": "keyboard_layout_update",
  "payload": {
    "device_name": "keyd-virtual-keyboard",
    "current_layout_index": 0,
    "current_keymap": "Turkish (Alt-Q)",
    "current_short_code": "TR",
    "current_layout_code": "tr",
    "configured_layouts": ["tr", "us"],
    "configured_variants": ["alt", ""]
  }
}
```

2. **`AvailableLayout`** (`available_layouts_data` Event):
```json
{
  "type": "available_layouts_data",
  "payload": [
    { "code": "tr", "description": "Turkish" },
    { "code": "us", "description": "English (US)" },
    { "code": "de", "description": "German" }
  ]
}
```

#### B. RPC Komut Örnekleri

* **Aktif Klavye Durumunu Sorgulama:**
```json
{
  "name": "get_keyboard_layout",
  "args": {}
}
```

* **Klavye Düzenini Değiştirme (Sonraki Düzen):**
```json
{
  "name": "switch_keyboard_layout",
  "args": {
    "target": "next"
  }
}
```

* **Klavye Düzenlerini Yapılandırma:**
```json
{
  "name": "set_configured_layouts",
  "args": {
    "layouts": ["tr", "us", "de"],
    "variants": ["alt", "", ""]
  }
}
```

* **Sistem XKB Dillerini Sorgulama:**
```json
{
  "name": "get_available_system_layouts",
  "args": {}
}
```

---

### 3.9. Tema Yönetimi ve Çoklu Uygulama Dağıtıcısı (`core/services/theme/`)

* **Uygulama Adaptörleri:** `Hyprland`, `Kitty`, `Zed`, `Vesktop`, `Neovim`, `Dolphin/Qt`
* **Dinamik Tema Dizini:** `$XDG_CONFIG_HOME/ogsShell/themes/`
* **Kullanıcı Konfigürasyonu:** `$XDG_CONFIG_HOME/ogsShell/theme_config.json`

#### A. Veri Modelleri

1. **`ThemePalette`**:
```json
{
  "id": "tokyo-night",
  "name": "Tokyo Night",
  "author": "folke",
  "colors": {
    "bg": "#1a1b26",
    "surface": "#24283b",
    "fg": "#c0caf5",
    "accent": "#7aa2f7",
    "accent_secondary": "#bb9af7",
    "border": "#7aa2f7",
    "red": "#f7768e",
    "green": "#9ece6a",
    "yellow": "#e0af68",
    "blue": "#7aa2f7",
    "magenta": "#bb9af7",
    "cyan": "#7dcfff"
  },
  "app_theme_names": {
    "zed": "Tokyo Night",
    "nvim": "tokyonight",
    "qt_dolphin": "TokyoNight",
    "kitty": "Tokyo Night"
  }
}
```

2. **`ThemeState`** (`theme_update` Event):
```json
{
  "type": "theme_update",
  "payload": {
    "active_theme": { ... },
    "available_themes": [ ... ],
    "enabled_adapters": {
      "hyprland": true,
      "kitty": true,
      "zed": true,
      "vesktop": true,
      "nvim": true,
      "qt_dolphin": true
    }
  }
}
```

#### B. RPC Komut Örnekleri

* **Aktif Temayı Değiştirme (Tüm Uygulamalara Dağıtma):**
```json
{
  "name": "set_active_theme",
  "args": {
    "theme_id": "tokyo-night"
  }
}
```

* **Özel Tema Kaydetme:**
```json
{
  "name": "save_custom_theme",
  "args": {
    "theme": {
      "id": "my-neon",
      "name": "My Neon",
      "colors": {
        "bg": "#0a0a0a",
        "fg": "#ffffff",
        "accent": "#ff007f"
      }
    }
  }
}
```

* **Özel Temayı Silme:**
```json
{
  "name": "delete_custom_theme",
  "args": {
    "theme_id": "my-neon"
  }
}
```

* **Uygulama Adaptörünü Açma / Kapatma:**
```json
{
  "name": "toggle_theme_adapter",
  "args": {
    "adapter_id": "vesktop",
    "enabled": false
  }
}
```

---

### 3.10. Uygulama Arama ve Başlatıcı Servisi (`core/services/launcher/`)

* **Bellek İçi Arama:** <0.5ms gecikme süresi ile 300+ masaüstü uygulamasını RAM üzerinde fuzzy/akronym eşleştirmesi ile filtreler.
* **Frecency ve Kalıcılık:** Uygulama kullanım istatistikleri `$XDG_CONFIG_HOME/ogsShell/launcher_stats.json` dosyasında saklanır.
* **İzole Süreç:** Uygulamalar `systemd-run --user --scope` veya `Setsid` bağımsız process group ile başlatılır.

#### A. Veri Modelleri

1. **`AppEntry`**:
```json
{
  "id": "org.gimp.GIMP.desktop",
  "name": "GNU Image Manipulation Program",
  "generic_name": "Image Editor",
  "exec": "gimp-2.10",
  "exec_binary": "gimp-2.10",
  "icon": "gimp",
  "categories": ["Graphics", "RasterEditor"],
  "keywords": ["photo", "paint", "edit"],
  "acronym": "gimp",
  "launch_count": 5,
  "score": 100,
  "comment": "Create images and edit photographs"
}
```

2. **`AppSearchResultPayload`** (`app_search_results` Event):
```json
{
  "type": "app_search_results",
  "payload": {
    "query": "gimp",
    "results": [
      {
        "id": "org.gimp.GIMP.desktop",
        "name": "GNU Image Manipulation Program",
        "generic_name": "Image Editor",
        "exec": "gimp-2.10",
        "icon": "gimp",
        "launch_count": 5,
        "score": 100
      }
    ],
    "total": 1
  }
}
```

3. **`AppLaunchedPayload`** (`app_launched` Event):
```json
{
  "type": "app_launched",
  "payload": {
    "id": "org.gimp.GIMP.desktop",
    "name": "GNU Image Manipulation Program",
    "success": true
  }
}
```

#### B. RPC Komut Örnekleri

* **Uygulama Arama (Fuzzy/Typo Tolere):**
```json
{
  "name": "search_apps",
  "args": {
    "query": "firfox",
    "limit": 10
  }
}
```

* **Tüm Uygulamaları Listeleme:**
```json
{
  "name": "list_apps",
  "args": {
    "limit": 50
  }
}
```

* **Uygulamayı Başlatma:**
```json
{
  "name": "launch_app",
  "args": {
    "id": "org.gimp.GIMP.desktop"
  }
}
```

* **İndeksi Yeniden Tarama:**
```json
{
  "name": "reindex_apps",
  "args": {}
}
```

---

## 4. Quickshell QML Frontend Entegrasyonu (`DaemonIPC.qml`)

Frontend bileşenleri soket iletişimini `shell/backend/DaemonIPC.qml` singleton'ı üzerinden yönetir.

### Komut Gönderme Kalıbı (Sending Actions)
```qml
// DaemonIPC üzerinden RPC komutu tetikleme
DaemonIPC.sendAction("connect_wifi", {
    "ssid": "HomeWiFi",
    "password": "secretPassword"
});

DaemonIPC.sendAction("add_alarm", {
    "time": "07:30",
    "label": "Sabah Alarmı"
});
```

### Olayları Dinleme ve Reaktif Bağlama (Listening Events)
```qml
// Reaktif veri okuma
Text {
    text: "CPU: " + Math.round(DaemonIPC.cpu.cpu_percent) + "% | Sıcaklık: " + DaemonIPC.cpu.cpu_temp + "°C"
}

// Yüksek öncelikli sinyalleri yakalama
Connections {
    target: DaemonIPC
    function onAlarmTriggered(payload) {
        console.log("Alarm Çalıyor:", payload.label, payload.time);
        // Dynamic Island Transient bildirim tetiklemesi
    }
    function onCalendarReminderTriggered(payload) {
        console.log("Takvim Hatırlatması:", payload.title, "Kalan Süre:", payload.minutes_until);
    }
}
```

---

## 5. Hata Yönetimi, Soket Temizliği ve CLI Testleri

1. **Ölü Soket Kontrolü:** Go daemon açılışta `os.Remove(socketPath)` ile eski soketi temizler (`EADDRINUSE` önlenir).
2. **Kopan İstemciler:** Sokete yazma hatası alındığında ilgili istemci `clients` map'inden thread-safe biçimde çıkarılır.
3. **CLI ile Hızlı Test (socat / netcat):**

```bash
# Soket dinleme ve gelen eventleri izleme:
nc -U "$XDG_RUNTIME_DIR/ogs_shell.sock"

# Sokete RPC Action gönderme:
echo '{"name":"get_alarms","args":{}}' | nc -U "$XDG_RUNTIME_DIR/ogs_shell.sock"
echo '{"name":"toggle_bluetooth","args":{}}' | nc -U "$XDG_RUNTIME_DIR/ogs_shell.sock"
echo '{"name":"get_calendar_month","args":{"year":2026,"month":8}}' | nc -U "$XDG_RUNTIME_DIR/ogs_shell.sock"
```
