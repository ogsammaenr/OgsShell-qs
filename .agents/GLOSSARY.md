# OgsShell-qs Dosya ve Bileşen Sözlüğü (GLOSSARY.md)

Bu dosya, projedeki tüm dosyaları, bileşenleri, servisleri ve C daemon'larını dizinleyerek her birinin amacını, barındırdığı özellikleri, dışa aktardığı arayüzleri (properties, signals, functions) ve birbirleriyle olan ilişkilerini açıklar.

Yapay zeka (AI) geliştiricileri, bu sözlüğü kullanarak hangi dosyada ne olduğunu hızlıca görebilir ve yeni özellik eklerken hangi bileşeni/servisi kullanacaklarını tespit edebilirler.

---

## 1. Kök Dizin Dosyaları

| Dosya Adı | Türü | Açıklama / Görevi |
| :--- | :--- | :--- |
| [shell.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell.qml) | QML (Giriş) | Uygulamanın giriş noktası (`ShellRoot`). Tüm global servisleri (`WorkspaceService`, `SystemStatsService` vb.) tekil (singleton) olarak tanımlar, resmi tatil verilerini API'den çeker ve `MonitorGroup` ile `PowerMenuWindow` nesnelerini başlatır. |
| [Makefile](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/Makefile) | Makefile | C daemon'larını (`monitor` ve `workspaces`) derlemek için kullanılan derleme betiğidir. |
| [reload.sh](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/reload.sh) | Shell Betiği | Çalışan Quickshell oturumunu sonlandırıp yeni kodlar ile arka planda (detached) yeniden başlatan geliştirici aracıdır. |
| [ARCHITECTURE.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ARCHITECTURE.md) | Markdown | Projenin genel mimarisi, veri akış şeması ve kodlama kurallarını içeren teknik kılavuz. |
| [AGENTS.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/AGENTS.md) | Markdown | Yapay zeka ve insan geliştiriciler için uyması zorunlu mimari standartları ve shadowing önlemlerini içeren kurallar belgesi. |

---

## 2. Servisler (`services/`)

Sistem durumunu yöneten ve dış veri kaynaklarıyla (C daemon'ları veya CLI araçları) arayüz kuran görsel olmayan QML mantık servisleri.

### 2.1. [WorkspaceService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/WorkspaceService.qml)
- **Görev:** Hyprland masaüstü alanlarını (workspaces), monitör odaklarını ve D-Bus bildirimlerini takip eder.
- **Veri Kaynağı:** Kök dizindeki `workspaces` C daemon'ını bir `Process` olarak çalıştırır ve standart çıktısını (`stdout`) JSON olarak ayrıştırır.
- **Dışa Aktarılan Arayüzler:**
  - `property var workspaceState`: Monitör ve workspace listesini içeren JSON objesi.
  - `property var activeNotifications`: Aktif D-Bus bildirim listesi (Maksimum 4 adet).
  - `property bool isShowingNotification`: Bildirim penceresinin açık olup olmadığını belirtir.
  - `function dismissNotification(index)`: Belirtilen indeksteki bildirimi kapatır.

### 2.2. [SystemStatsService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/SystemStatsService.qml)
- **Görev:** CPU, RAM, GPU, Ağ hızı, Bluetooth, WiFi, ses, parlaklık ve çalmakta olan medya bilgilerini yönetir.
- **Veri Kaynağı:** Kök dizindeki `monitor` C daemon'ını çalıştırır ve JSON çıktısını dinler.
- **Dışa Aktarılan Arayüzler:**
  - `property int cpuUsage`, `property int cpuTemp`, `property int ramUsage`, `property int gpuUsage`, `property int gpuTemp`: Sistem kaynakları yüzdeleri ve sıcaklıkları.
  - `property bool wifiConnected`, `property string wifiSsid`: Kablosuz ağ durumu.
  - `property string bluetoothStatus`: Bluetooth durumu (`off`, `on`, `connected`).
  - `property int brightness`, `property int volume`, `property bool audioMuted`: Ekran parlaklığı ve ses seviyeleri.
  - `property string netSpeed`: Anlık ağ indirme/yükleme hızı stringi (örn. `"1.2 MB/s"`).
  - `property string mediaStatus`, `property string mediaTitle`, `property string mediaArtist`: playerctl aracılığıyla okunan medya durumları.
  - `property bool showCpuUsageOnBar`, `property bool showRamUsageOnBar`, `property bool showGpuUsageOnBar`, `property bool showNetSpeedOnBar`: Bar üzerinde hangi istatistiklerin görünür olacağını belirleyen anahtarlar.
  - `function setBrightness(pct)`: Laptop dahili ekranı (`brightnessctl`) ile harici HDMI/DP monitörlerin (`ddcutil setvcp 10`) parlaklığını senkronize ayarlar. I2C veriyolu kilitlenmesini önlemek için 350ms debouncing ve işlem sonlandırma mekanizmasına sahiptir.

### 2.3. [TimeService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/TimeService.qml)
- **Görev:** Pomodoro ve Kronometre (Stopwatch) sayaçlarının mantığını global olarak yönetir.
- **Dışa Aktarılan Arayüzler:**
  - `property int stopwatchTime`: Milisaniye cinsinden kronometre süresi.
  - `property bool stopwatchRunning`: Kronometrenin çalışıp çalışmadığı.
  - `property int pomodoroTime`: Saniye cinsinden kalan Pomodoro süresi.
  - `property bool pomodoroRunning`: Pomodoro sayacının aktifliği.
  - `property string pomodoroState`: Çalışma veya mola durumu (`"Work"`, `"Break"`).
  - `property int pomodoroWorkDuration`: Ayarlanan çalışma süresi (dakika).
  - `property int pomodoroBreakDuration`: Ayarlanan mola süresi (dakika).

### 2.4. [NetworkManagerService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/NetworkManagerService.qml)
- **Görev:** Sistemdeki ağ kartlarını ve mevcut kablosuz ağları tarar, bağlantı kurma/kesme işlemlerini yönetir.
- **Veri Kaynağı:** Arka planda `nmcli` komutunu kullanarak ağ taraması ve bağlantı işlemlerini yürütür.
- **Dışa Aktarılan Arayüzler:**
  - `property bool wifiConnected`, `property string wifiSsid`: Kablosuz ağ durumu.
  - `property var wifiList`: Çevredeki taranmış kablosuz ağların listesi (SSID, sinyal gücü, güvenlik vb. nesneler).
  - `property var savedConnections`: Sistemde kayıtlı olan bağlantıların adları listesi.
  - `property bool isScanning`, `property bool isConnecting`: İşlem durumu göstergeleri.
  - `function refresh()`: Çevredeki ağları yeniden tarar.
  - `function connectToWifi(ssid, password)`: Belirtilen ağa şifre ile bağlanır.
  - `function disconnectWifi()`: Wi-Fi bağlantısını keser.
  - `function toggleWifi(turnOn)`: Wi-Fi kartını açar/kapatır.

### 2.5. [ClipboardService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/ClipboardService.qml)
- **Görev:** Sistem pano geçmişini (clipboard) yönetir.
- **Veri Kaynağı:** `cliphist` CLI aracını kullanarak pano geçmişini çeker.
- **Dışa Aktarılan Arayüzler:**
  - `property var clipboardItems`: Pano geçmişindeki öğelerin listesi (ID ve metin).
  - `property bool isLoading`: Tarama durumu.
  - `function refresh()`: Pano geçmişini günceller.
  - `function copyItem(id)`: Seçilen öğeyi panoya kopyalar.
  - `function deleteItem(rawLine)`: Seçilen öğeyi pano geçmişinden siler.
  - `function clearHistory()`: Tüm pano geçmişini temizler.

### 2.6. [BluetoothService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/BluetoothService.qml)
- **Görev:** Bluetooth cihazlarını tarar, listeler, eşleştirir (pair), güvenir (trust) ve bağlanma/bağlantı kesme işlemlerini yönetir. Kimlik doğrulamalarını `NoInputNoOutput` arka plan ajanıyla otomatik kabul ederek sorunsuz çalıştırır.
- **Veri Kaynağı:** Arka planda `bluetoothctl` komut setlerini çalıştıran [bluetooth_helper.sh](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/bluetooth_helper.sh) yardımcı betiğini kullanır. Çıktıları gerçek zamanlı (satır satır) parse ederek arayüze anında yansıtır.
- **Dışa Aktarılan Arayüzler:**
  - `property bool isScanning`, `property bool isConnecting`: Tarama ve bağlantı durumu göstergeleri.
  - `property var deviceList`: Çevredeki taranmış bluetooth cihazlarının listesi (MAC adresi, isim, bağlı/eşleşmiş/güvenilen durumları).
  - `property string connectionError`: Bağlantı sırasında oluşan son hata metni.
  - `function refresh()`: Çevredeki bluetooth cihazlarını yeniden tarar.
  - `function togglePower(turnOn)`: Bluetooth kartını açar veya kapatır.
  - `function pairDevice(mac)`: Belirtilen MAC adresli bluetooth cihazını eşleştirir (pair).
  - `function connectDevice(mac)`: Belirtilen MAC adresli bluetooth cihazına bağlanır.
  - `function disconnectDevice(mac)`: Belirtilen MAC adresli bluetooth cihazının bağlantısını keser.
  - `function trustDevice(mac, trust)`: Cihazı güvenilen (trusted) listesine ekler veya çıkarır.
  - `function removeDevice(mac)`: Eşleşmiş bluetooth cihazını sistemden kaldırır (unpair).

### 2.7. [ShellIpcService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/ShellIpcService.qml)
- **Görev:** Harici pencere yöneticisi kısayollarından (örn. Hyprland) veya terminalden gelen ekran/panel tetikleme komutlarını dinler.
- **Veri Kaynağı:** `$XDG_RUNTIME_DIR/ogsshell-ipc` Named Pipe (borusunu) dinleyen bir `Process` (`tail -f`) çalıştırır. Pipe yoksa otomatik oluşturulur.
- **Dışa Aktarılan Arayüzler:**
  - `signal toggleControlCenter(string targetMonitor, string page)`: Belirtilen monitörde kontrol merkezini (opsiyonel sayfa seçimiyle: `wifi`, `bluetooth`, `theme`, `clipboard`) açma/kapatma sinyali.
  - `signal toggleTimeManager(string targetMonitor)`: Belirtilen monitörde Pomodoro/Kronometre panelini açma/kapatma sinyali.
  - `signal toggleCalendar(string targetMonitor)`: Belirtilen monitörde takvim panelini açma/kapatma sinyali.
  - `signal toggleAppLauncher(string targetMonitor)`: Belirtilen monitörde uygulama arayıcısını açma/kapatma sinyali.
  - `signal toggleAppDashboard(string targetMonitor)`: Belirtilen monitörde uygulama kütüphanesi (dashboard) panelini açma/kapatma sinyali.
- **IPC Komutları (`ipc.sh` üzerinden):**
  - `control_center` / `control_center:<page>`: Kontrol merkezini açar, opsiyonel olarak doğrudan belirli bir sayfaya yönlendirir.
  - `time_manager`: Pomodoro/Kronometre panelini açar.
  - `calendar`: Takvim panelini açar.
  - `app_launcher`: Uygulama arayıcısını açar.
  - `app_dashboard`: Uygulama kütüphanesi panelini açar.
  - `gamemode` / `gamemode:on` / `gamemode:off` / `gamemode:toggle`: Oyun modunu açar, kapatır veya durumunu tersine çevirir.

### 2.8. [AppLauncherService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/AppLauncherService.qml) ve [app_launcher_helper.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/app_launcher_helper.c)
- **Görev:** Sistem genelindeki uygulamaları ve bunlara ait simge (ikon) yollarını arka planda tarar ve QML tarafında fuzzy/alt-string/Damerau-Levenshtein tabanlı aramalar için listeler.
- **Veri Kaynağı:** `app_launcher_helper.c` kaynak kodundan derlenen `app_launcher_helper` binary dosyasını çalıştırarak `~/.cache/ogsshell-apps.cache` dosya önbelleği (`# OGSSHELL_CACHE_V2`) üzerinden `mtime` bazlı artımlı güncelleme yapar. `--launch <desktop_path>` argümanıyla çalıştırıldığında o uygulamanın kullanım sayacını (`launch_count`) 1 artırıp çıkar. İkon seçiminde düşük çözünürlüklü pixmap'ler yerine öncelikli olarak vektörel SVG (`.svg`) ve yüksek çözünürlüklü (`512x512`, `256x256`) tema simgelerini otomatik tespit eder.
- **Dışa Aktarılan Arayüzler:**
  - `property var appList`: Taranan uygulamaların `name`, `exec`, `icon`, `desktop_path`, `search_keys`, `description` (GenericName), `category` (Türkçe kategori adı) ve `launch_count` alanlarını içeren JSON dizisi.
  - `property bool isLoading`: Tarama işleminin devam edip etmediği.
  - `function refresh()`: Uygulama listesini günceller.
  - `signal scanFinished()`: Tarama işlemi başarıyla bittiğinde fırlatılan sinyal.
- **`app_launcher_helper.c` Arama Algoritması:** Önce prefix eşleşmesi (skor: 0), sonra substring (skor: 0.5), en son Damerau-Levenshtein fuzzy mesafesi (skor: 1.0 + mesafe) uygulanır. Eşit skorlarda `launch_count`'a göre azalan, en son alfabetik sıralanır. İkon taramasında tema bazlı çözünürlük önceliklendirme algoritması (`try_theme_subdirs`) kullanılır.

### 2.10. [ThemeConfigService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/ThemeConfigService.qml)
- **Görev:** Tema yapılandırmalarını `~/.config/ogsshell/themes/*.json` dizinindeki JSON dosyalarından dinamik olarak yükler ve yönetir. Yeni temaların eklenmesini ve mevcut temaların renk/klasör ayarlarının kolayca konfigüre edilmesini sağlar.
- **Veri Kaynağı:** Arka planda `python3` aracılığıyla `~/.config/ogsshell/themes/*.json` dosyalarını tarar ve dinamik olarak ayrıştırır.
- **Dışa Aktarılan Arayüzler:**
  - `property string activeTheme`: Takip edilen aktif tema ID'si.
  - `property var themeList`: Sistemdeki tüm yüklü temaların yapılandırma nesneleri listesi (`id`, `name`, `folder`, `bg`, `border`, `textPrimary`, `textSecondary`, `accent`, `green`, `red`, `buttonBg`, `workspaces`).
  - `property var activeThemeConfig`: O an aktif olan temanın renk ve klasör konfigürasyon objesi.
  - `property bool isLoading`: Yükleme durumu.
  - `function reloadThemes()`: Dindeki tüm `.json` tema dosyalarını yeniden tarar ve günceller.

### 2.11. [WallpaperService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/WallpaperService.qml) ve [wallpaper_helper.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/wallpaper_helper.c)
- **Görev:** Temaya uygun duvar kağıdı dizinlerini (`~/Pictures/Wallpapers/<ThemeFolder>`, eksik/boş ise `~/Pictures/Wallpapers/default`) C diliyle hızlıca tarar, JSON olarak QML tarafına iletir. Aktif durum dosyaları `~/.config/ogsshell/state/` dizininde saklanır. Tema değiştirildiğinde wallpaper seçme ekranını açmadan o temada son kullanılan (veya varsayılan ilk) duvar kağıdını otomatik uygular.
- **Veri Kaynağı:** `services/wallpaper_helper.c` C kodundan derlenen `wallpaper_helper` binary dosyası. `--scan <folder>`, `--set <theme_id> <path>` ve `--restore <theme_id> [folder]` modları ile çalışır. Aktif duvar kağıdı durumlarını `~/.config/ogsshell/state/wallpaper` ve `~/.config/ogsshell/state/wallpaper_<theme>` dosyalarına kaydeder ve `awww` (`awww img -a --transition-type random`) daemon'ı ile rastgele animasyon geçişleriyle uygular.
- **Dışa Aktarılan Arayüzler:**
  - `property string activeTheme`: Takip edilen aktif tema adı.
  - `property var wallpaperList`: Taranan duvar kağıtlarının nesne listesi (`path`, `filename`, `name`).
  - `property string currentWallpaper`: Aktif seçili duvar kağıdı yolu.
  - `property bool isLoading`: Tarama durumu.
  - `function refresh()`: Dizin duvar kağıdı listesini C binary ile günceller.
  - `function restoreWallpaper()`: Aktif temanın en son kullanılan duvar kağıdını C binary ile otomatik yükler.
  - `function setWallpaper(path)`: Seçilen duvar kağıdını uygular ve konfigürasyona kaydeder.

### 2.12. [ThemeSyncService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/ThemeSyncService.qml) ve [theme_sync_helper.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/theme_sync_helper.c)
- **Görev:** OgsShell-qs üzerinde aktif tema değiştirildiğinde sistemdeki harici uygulamaların (GTK3/GTK4 uygulamaları, Dolphin/Qt, Kitty terminal, Zed Editor, Zen Browser, Neovim, Tmux, btop sistem izleyici, Vesktop Discord istemcisi ve IntelliJ IDEA / JetBrains IDE'leri) temalarını senkronize eder.
- **Veri Kaynağı:** `services/theme_sync_helper.c` kaynak kodundan derlenen `services/theme_sync_helper` yerel C binary dosyası. `app_configs/<app>/<theme_id>` dizinlerindeki resmi ve yüksek kontrastlı renk şablonlarını `~/.config/kdeglobals`, `~/.config/kitty/current-theme.conf`, `~/.config/zed/themes/` & `settings.json`, `~/.zen/<profile>/chrome/userChrome.css`, `~/.config/nvim/colors/` & `lua/plugins/theme.lua`, `~/.tmux/current-theme.conf`, `~/.config/btop/themes/` & `~/.config/btop/btop.conf`, `~/.config/gtk-3.0`/`gtk-4.0`, `~/.config/vesktop/` (`quickCss.css` & `themes/ogsshell.theme.css`) ve `~/.config/JetBrains/*/options/` (`colors.scheme.xml` & `laf.xml`) hedeflerine doğrudan kopyalar ve senkronize eder. Kitty terminallerine canlı `SIGUSR1` sinyali, Neovim soketlerine canlı RPC, btop için canlı konfigürasyon güncellemesi ve KDE/Qt uygulamalarına DBus yenileme sinyali gönderir.
- **Dışa Aktarılan Arayüzler:**
  - `property string activeTheme`: Senkronize edilen aktif tema ID'si.

### 2.13. [GameModeService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/GameModeService.qml)
- **Görev:** Oyun Modu (Game Mode) durumunu yönetir. Aktifleştiğinde Hyprland ayarlarını (blur, animasyonlar, gölgeler, gaps/spacing) kaynak tasarrufu için kapatır, kapatıldığında `hyprctl reload` ile kullanıcının orijinal konfigürasyonunu geri yükler.
- **Veri Kaynağı:** Arka planda `~/.config/ogsshell/state/gamemode` durum dosyasını okur/yazar ve `hyprctl` komutlarını çalıştırır.
- **Dışa Aktarılan Arayüzler:**
  - `property bool isGameModeActive`: Oyun modunun açık/kapalı durumu.
  - `function toggleGameMode()`: Oyun modunu açar veya kapatır.

### 2.14. [AudioMixerService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/AudioMixerService.qml) ve [audio_mixer_helper.py](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/audio_mixer_helper.py)
- **Görev:** Sistemdeki ses çıkış aygıtlarını (sinks) ve çalışan uygulamaların ses yayınlarını (sink-inputs) tarar, her uygulama/aygıt için bağımsız ses ve sessize alma (mute) kontrollerini yürütür. Kullanıcının en son seçtiği varsayılan ses aygıtını `~/.config/ogsshell/state/audio_device` dosyasında saklar ve sistem açılışında otomatik geri yükler.
- **Veri Kaynağı:** `pactl` (PulseAudio / PipeWire) komut setlerini JSON formatında çalıştırır.
- **Dışa Aktarılan Arayüzler:**
  - `property var sinkList`: Sistemdeki ses çıkış aygıtları listesi.
  - `property var appList`: Ses çalan aktif uygulamaların listesi.
  - `property string defaultSink`: Aktif varsayılan ses aygıtının adı.
  - `property bool isLoading`: Tarama/güncelleme işlem durumu.
  - `function refresh()`: Aygıt ve uygulama ses durumlarını günceller.
  - `function setDefaultSink(sinkName)`: Varsayılan ses aygıtını değiştirir, aktif yayınları aktarır ve konfigürasyona kaydeder.
  - `function setSinkVolume(sinkTarget, volPct)`: Belirtilen ses aygıtının ses seviyesini ayarlar.
  - `function setSinkMute(sinkTarget)`: Belirtilen ses aygıtını sessize alır veya açar.
  - `function setAppVolume(appIndex, volPct)`: Belirtilen uygulamanın ses seviyesini ayarlar.
  - `function setAppMute(appIndex)`: Belirtilen uygulamayı sessize alır veya açar.

---

## 3. Pencereler (`windows/`)

Ekran katmanlarını (`exclusiveZone`, `aboveWindows`, `mask` vb.) yöneten, Wayland protokolüyle haberleşen pencereler.

| Dosya Adı | Ekran Katmanı | Açıklama / Görevi |
| :--- | :--- | :--- |
| [MonitorGroup.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/MonitorGroup.qml) | Yok (Grup Nesnesi) | Her monitör için tüm pencerelerin (`TopBarWindow`, `ControlCenterWindow` vb.) birer kopyasını oluşturur. Overlay pencerelerinin açık/kapalı durumlarını (`isControlCenterOpen`, `isTimeManagerOpen`, `isCalendarOpen`, `isAppLauncherOpen`, `isAppDashboardOpen`) ve `activeIslandHud` durumunu yönetir. `openControlCenterPage(page)` fonksiyonu ile doğrudan belirli bir kontrol merkezi sayfası açılabilir; `triggerIslandHud(type)` ile HUD animasyonu tetiklenir. |
| [TopBarWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/TopBarWindow.qml) | `WlrLayer.Top` (28px sabit) | Masaüstünün üstündeki ana panel barıdır. Sol tarafta çalışma alanlarını (`LeftWorkspaceBar`), ortada dinamik adayı (`CenterHudIsland`) ve sağ tarafta medya/bildirim adasını (`RightMediaNotifIsland`) konumlandırır. Input maskesi (`mask`) sayesinde panel dışındaki alanlarda fare tıklamalarının arkadaki pencerelere geçmesini sağlar. |
| [ControlCenterWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/ControlCenterWindow.qml) | `WlrLayer.Overlay` (Float) | Üst barın ortasına veya sağ tarafına hizalanan, içinde hızlı ayarları barındıran kontrol merkezinin (`ControlCenter`) açılır penceresidir. |
| [TimeManagerWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/TimeManagerWindow.qml) | `WlrLayer.Overlay` (Float) | Pomodoro, Kronometre ve takvimi yöneten kontrol penceresinin açılır overlay yapısıdır. |
| [CalendarWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/CalendarWindow.qml) | `WlrLayer.Overlay` (Float) | Takvim ve tatil günlerini gösteren overlay penceresidir. |
| [AppLauncherWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/AppLauncherWindow.qml) | `WlrLayer.Overlay` (Float) | Arama ve uygulama başlatma paneli olan `AppLauncher` bileşenini barındıran, saat adasının altına konumlanan penceredir. |
| [AppDashboardWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/AppDashboardWindow.qml) | `WlrLayer.Overlay` (Float) | Uygulama Kütüphanesi (`AppDashboard`) bileşenini barındıran, tüm ekranı kaplayan overlay penceresidir. |
| [WorkspaceSwitcherWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/WorkspaceSwitcherWindow.qml) | `WlrLayer.Overlay` (Float) | Görsel çalışma alanı geçiş arayüzünü (`WorkspaceSwitcher`) barındıran, ekranın ortasında açılan ve klavye/fare etkileşimini yöneten overlay penceresidir. |
| [PowerMenuWindow.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/windows/PowerMenuWindow.qml) | `WlrLayer.Overlay` (Global) | Tüm sistemi kaplayan karartılmış arka plana sahip, kapatma, yeniden başlatma ve oturumu kapatma butonlarını barındıran global tekil penceredir. |

---

## 4. UI Bileşenleri (`components/`)

Kullanıcı arayüzünü (UI) oluşturan görsel, etkileşimli ve tekrar kullanılabilir widget'lar.

### 4.1. Panel Barı Widget'ları
- **[LeftWorkspaceBar.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/LeftWorkspaceBar.qml):** Hyprland workspace durumlarını görsel noktalar (dots) halinde çizer. Aktif olan workspace uzatılmış bir nokta olarak görünür, içinde pencere olan workspace'ler daha belirgindir. Tıklandığında o workspace'e geçiş yapar.
- **[CenterHudIsland.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/CenterHudIsland.qml):** Barın ortasındaki dinamik adadır. Fare üzerine geldiğinde genişler; normal durumlarda saat/tarih ve varsa aktif sayaçları gösterirken, fare ile üzerine gelindiğinde ses, parlaklık ve minimalist donanım istatistiklerine erişim sunar.
- **[SystemStatsIsland.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/SystemStatsIsland.qml):** Saat adasının soluna sabitlenen dinamik sistem istatistik adasıdır. Temaya uyumlu yarı şeffaf pill kapsül arka planına (`group.theme.bg`), sabitleme vurgusuna (`isPinned` modunda `group.theme.accent` çerçeve) ve her türlü duvar kağıdında okunabilirliği garantileyen yüksek kontrastlı metin dış çizgilerine (`style: Text.Outline`) sahiptir. Fare üzerine geldiğinde (veya sol tıklanıp kilitlendiğinde) akıcı bir şekilde genişleyerek detaylı CPU/GPU sıcaklıklarını, RAM kullanım çubuğunu ve ağ hızını gösterir. Orta tıklama ile göstergeler gizlenebilir.
- **[RightMediaNotifIsland.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/RightMediaNotifIsland.qml):** Barın sağ tarafındaki dinamik menisküs adadır. Üç duruma sahiptir: `idle` (boşta minimalist saat/durum), `notification` (yeni bildirim geldiğinde genişleyen kart) ve `media` (medya çalar hızlı kontrol kartı, albüm kapağı, parça kontrolleri ve çalmakta olan uygulamanın ses seviyesine özel etkileşimli ses ayar barı).

### 4.2. Alt Bileşenler ve Araçlar
- **[Theme.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/Theme.qml):** Renk şemalarını yönetir. `Catppuccin`, `Nord Night`, `Retro Gruvbox` ve `Monochrome` temalarının renk değişkenlerini barındırır. `MonitorGroup` içinde `theme` alias'ı üzerinden erişilir.
- **[ClockDateMinimal.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ClockDateMinimal.qml):** CenterHudIsland içinde kullanılan, fare üzerine gelindiğinde detaylanan minimalist saat ve tarih göstergesidir.
- **[ClockDateWidget.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ClockDateWidget.qml):** Saat ve tarih metinlerini çizen temel bileşendir.
- **[StatusMinimal.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/StatusMinimal.qml):** WiFi ve Bluetooth durum simgelerini çizen minimalist bileşendir.
- **[VolumeBrightnessMinimal.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/VolumeBrightnessMinimal.qml):** Fare tekerleğiyle (scroll) ses ve parlaklık ayarı yapabilmeyi sağlayan minimalist bar göstergesidir.
- **[StatsWidget.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/StatsWidget.qml):** Barın üstüne gelindiğinde görünen minimalist CPU, Sıcaklık ve RAM kullanım satırıdır.
- **[PowerButton.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/PowerButton.qml):** Kapatma menüsünde kullanılan animasyonlu ve ikonlu dairesel butondur.
- **[ActionButtons.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ActionButtons.qml):** Kontrol merkezi veya bar alanında kullanılan bildirim, pano ve güç butonu üçlüsünden oluşan yatay eylem buton satırıdır. `screenContext` property'si üzerinden bildirim sayısını okur.
- **[MediaMinimal.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/MediaMinimal.qml):** Barın içinde hover durumunda genişleyen minimalist medya göstergesidir. Şarkı adı/sanatçı ve oynatma/durdurma durumunu gösterir; tıklandığında `playerctl play-pause` çalıştırır. `isHovered: bool` ve `screenContext` propertyleri gerektirir.

### 4.3. Overlay Panelleri (Açılır Pencerelerin İçerikleri)
- **[AppLauncher.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/AppLauncher.qml):** Uygulama arayıcı (launcher) arayüzüdür. Üst barda arama girdisi (`TextInput`), altında eşleşen sonuçlar `ListView` ile listelenir. Fuzzy arama, hesap makinesi entegrasyonu (`=` öneki) ve `:apps`, `:theme` gibi özel tetikleyicileri destekler. Seçim klavye (`Up`/`Down`/`Enter`) ve fare ile yapılabilir. Açıldığında arama alanı otomatik sıfırlanır ve odaklanır.
  - **Özel Tetikleyiciler:** `:apps` → Uygulama Kütüphanesi'ni açar; `:theme` → Kontrol Merkezi'nin Tema sayfasını açar; `=<ifade>` → Matematik sonucunu listeler ve `Enter` ile `wl-copy`'ye kopyalar.
- **[AppDashboard.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/AppDashboard.qml):** Uygulama Kütüphanesi (Dashboard) 900×650 px kartı. Sol dikey panel kategori sekmeleri (`Tümü`, `Geliştirme`, `İnternet`, `Grafik`, `Multimedya`, `Oyunlar`, `Ofis`, `Sistem`, `Ayarlar`, `Araçlar`, `Diğer`), sağ panel ise arama destekli `GridView` ızgara görünümü barındırır.
  - **Properties:** `isOpen: bool`, `theme: var`; **Signal:** `closeRequested()`.
  - **Klavye:** `Yön tuşları` ile ızgara gezintisi, `Tab`/`Shift+Tab` ile kategori geçişi, `Enter` ile uygulama başlatma, `Escape` ile kapatma.
- **[WorkspaceSwitcher.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/WorkspaceSwitcher.qml):** Görsel çalışma alanı (workspace overview & switcher) 860×510 px ızgara kartıdır. Her bir çalışma alanındaki pencerelerin konum ve boyutlarına (`at`, `size`) göre canlı mini pencereler çizer. Fare ile tıklama, `Super+Tab` / `Tab` / `Yön Tuşları` ile geçiş, `Enter` ile onaylama, `1..9` tuşlarıyla doğrudan erişim ve `Escape` ile kapatma destekler.
- **[ControlCenter.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenter.qml):** Ana kontrol merkezi wrapper arayüzüdür. Üst kısmında dijital saat ve tarih başlığı ile donanım özet barını barındırır. Sayfalar arası geçişleri yönetir ve aşağıdaki alt modülleri çağırır:
  - **[ControlCenterThemeList.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenterThemeList.qml):** Görünüm, aktif tema seçici listesi ve entegre duvar kağıdı (wallpaper) seçme arayüzüdür. Temalar ve Duvar Kağıtları sekmeli modlarını barındırır.
  - **[ControlCenterWifiList.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenterWifiList.qml):** Kablolu ve kablosuz ağ bağlantıları listesidir.
  - **[ControlCenterWifiPassword.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenterWifiPassword.qml):** Wi-Fi şifresi girme arayüzüdür.
  - **[ControlCenterClipboard.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenterClipboard.qml):** Kopyalanan ögelerin pano geçmişi listesidir.
  - **[ControlCenterBluetooth.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenterBluetooth.qml):** Bluetooth cihazları arama ve eşleştirme arayüzüdür.
  - **[ControlCenterAudioMixer.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ControlCenterAudioMixer.qml):** Ses karıştırıcı (Audio Mixer) arayüzüdür; her uygulamanın ve ses çıkış aygıtının ses düzeyini ayrı ayrı ayarlama ve varsayılan ses aygıtları arasında anlık geçiş yapma olanağı sunar.
- **[TimeManager.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/TimeManager.qml):** Dijital saat, kronometre ve Pomodoro yönetim arayüzünü (süre arttırma, durdurma/başlatma, geçme) sekmeli olarak sunar.
- **[CalendarWidget.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/CalendarWidget.qml):** Türkiye resmi tatilleriyle senkronize çalışan, ay geçişleri yapılabilen detaylı görsel takvim kartıdır.
- **[MediaWidget.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/MediaWidget.qml):** Kontrol merkezi veya sağ adada gösterilen albüm kapağı, sanatçı adı, şarkı adı ve oynat/durdur/ileri/geri kontrollerini içeren geniş medya kartıdır.
- **[ExpandedStatsWidget.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/components/ExpandedStatsWidget.qml):** Detaylı CPU, RAM yüzdelerini progress bar'lar ile gösteren ve diğer durumları özetleyen donanım kartıdır.

---

## 5. C Arka Plan Daemon'ları (`services/`)

Sistem kaynaklarını ve Hyprland soketlerini çok iş parçacıklı (multi-threaded) olarak dinleyen C programları. `Makefile` ile derlenirler.

### 5.1. Donanım İzleyici (`services/monitor/`)
Derlenerek kök dizinde `monitor` binary dosyasını oluşturur.
- **[services/monitor/main.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/main.c):** Daemon'ın ana döngüsünü yönetir. Her saniye donanım istatistiklerini sorgular ve stdout'a tek satır JSON olarak yazar.
- **[services/monitor/monitor.h](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/monitor.h):** JSON'a dönüştürülen global `SystemState` struct tanımını barındırır.
- **[services/monitor/sys_info.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/sys_info.c) / [.h](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/sys_info.h):** Linux `/proc/stat`, `/sys/class/thermal` gibi dosyalardan CPU, RAM, GPU sıcaklık/kullanım değerlerini ve ağ hızını okuyan alt fonksiyonları barındırır.
- **[services/monitor/hw_controls.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/hw_controls.c) / [.h](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/hw_controls.h):** WiFi durumunu (`nmcli`), Bluetooth durumunu (`bluetoothctl`), ALSA ses düzeyini (`amixer`) ve klavye düzenini (`hyprctl`) sorgulayan fonksiyonlardır.
- **[services/monitor/media_notif.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/media_notif.c) / [.h](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/monitor/media_notif.h):** `swaync-client` üzerinden bildirim sayısını ve `playerctl` üzerinden müzik çalar verilerini sorgular.

### 5.2. Workspace ve D-Bus Bildirim İzleyici (`services/workspaces/`)
Derlenerek kök dizinde `workspaces` binary dosyasını oluşturur.
- **[services/workspaces/main.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/workspaces/main.c):** Bildirim dinleme iş parçacığını (thread) başlatır ve Hyprland soket dinleme döngüsüne girer.
- **[services/workspaces/hyprland.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/workspaces/hyprland.c) / [.h](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/workspaces/hyprland.h):** Hyprland'in Unix domain soketine (`$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`) bağlanarak workspace değişimlerini, pencere açılıp kapanmalarını canlı dinler ve değişiklik anında `hyprctl` üzerinden monitör ve workspace durumlarını JSON formatında basar.
- **[services/workspaces/notification.c](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/workspaces/notification.c) / [.h](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/services/workspaces/notification.h):** D-Bus bildirimlerini dinlemek amacıyla `dbus-monitor` komutunu arka planda çalıştırır, gelen bildirimlerin uygulama adı, başlık ve gövde kısımlarını parse ederek anında `{"notification": {...}}` JSON satırı olarak stdout'a aktarır.

---

## 6. Harici Komut Kontrolü (IPC Script)

- **[ipc.sh](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ipc.sh):** Hyprland ve sistem genelinden bar panellerini kontrol etmek için oluşturulmuş tetikleyici bash scriptidir. Gönderilen parametreye göre `$XDG_RUNTIME_DIR/ogsshell-ipc` borusuna yazma işlemi gerçekleştirir. Quickshell çalışmıyorsa yazmayı durduracak koruma mekanizmalarına sahiptir.
