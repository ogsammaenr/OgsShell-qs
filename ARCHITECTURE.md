# OgsShell-qs Mimari Dokümantasyonu (ARCHITECTURE.md)

Bu dosya, projenin modüler QML mimarisini, dosya yapısını, veri akış kurallarını ve gelecekte yeni özellikler eklenirken uyulması gereken standartları açıklamaktadır. Gelecekte projede çalışacak yapay zeka (AI) geliştiricileri ve insanlar bu yapıya sadık kalmalıdır.

---

## 1. Mimari Genel Bakış
OgsShell-qs, Quickshell Layer Shell tabanlı bir masaüstü bar/shell uygulamasıdır. Kod tabanı **Servis-Pencere-Bileşen (Service-Window-Component)** deseniyle modülerleştirilmiştir.

* **Servisler (`services/`):** Görsel olmayan, arka plan işlemleri (C daemon'ları), soket dinleme, veri ayrıştırma (JSON parser) ve global durum (state) yönetiminden sorumludur.
* **Pencereler (`windows/`):** Ekran katmanı ayarlarını (`PanelWindow`, `exclusiveZone`, `Region` maskeleri) yöneten ve ilgili monitöre göre konumlanan çerçevelerdir.
* **Bileşenler (`components/`):** Sadece çizim, animasyon ve kullanıcı tıklama/üzerine gelme (interaction) olaylarını yöneten tekrar kullanılabilir UI parçalarıdır.

---

## 2. Dizin Yapısı ve Dosya Sorumlulukları

```
OgsShell-qs/
├── shell.qml                  # Uygulama giriş noktası (Sadece servisleri ve pencere gruplarını bağlar)
├── ipc.sh                     # Hyprland kısayolları için dış IPC tetikleyici script
├── services/                  # Görsel olmayan mantıksal servisler
│   ├── WorkspaceService.qml   # Hyprland workspaces takibi ve bildirim yığını (stack) yönetimi
│   ├── ShellIpcService.qml    # Named pipe (IPC) üzerinden gelen dış pencere/sayfa eylemlerini dinler
│   ├── SystemStatsService.qml # CPU, RAM, GPU, Ağ hızları, ses, parlaklık ve Bluetooth/Medya verileri
│   ├── TimeService.qml        # Kronometre ve Pomodoro sayaçları/durumları
│   ├── AppLauncherService.qml # Sistemdeki uygulamaları ve ikonlarını yükleyen arayıcı servis
│   ├── app_launcher_helper.c  # Hızlı arama için stat/mtime önbellekli C yardımcı kaynak kodu
│   └── app_launcher_helper    # Derlenmiş yerel uygulama arama ve simge çözümleyici binary dosya
├── windows/                   # Üst düzey PanelWindow katmanları
│   ├── MonitorGroup.qml       # Her ekran için pencereleri ve yerel durumları yöneten grup yöneticisi
│   ├── TopBarWindow.qml       # Ana üst panel barı
│   ├── ControlCenterWindow.qml# Hızlı ayarları barındıran kontrol merkezi overlay'i
│   ├── TimeManagerWindow.qml  # Pomodoro/Kronometre yönetim overlay'i
│   ├── CalendarWindow.qml     # Takvim ve resmi tatiller overlay'i
│   ├── AppLauncherWindow.qml  # Uygulama arayıcı overlay'i (saat adasının altında açılır)
│   ├── AppDashboardWindow.qml # Uygulama kütüphanesi overlay'i (ekranı kaplayan dikey sekme paneli)
│   └── PowerMenuWindow.qml    # Sistem kapatma/uyku/çıkış overlay'i (Global tekil)
└── components/                # Arayüz bileşenleri (UI Widgets)
    ├── LeftWorkspaceBar.qml   # Çalışma alanları görsel gösterge barı
    ├── CenterHudIsland.qml    # Ortadaki dinamik saat, hud slider'ı ve zamanlayıcı adası
    ├── RightMediaNotifIsland.qml # Sağdaki medya/bildirim adası
    ├── AppLauncher.qml        # Arama girdisi ve sonuçları gösteren uygulama arayıcı bileşeni
    ├── AppDashboard.qml       # Kategorize dikey tab bar ve ızgara tabanlı uygulama kütüphanesi
    └── ...                    # Diğer alt bileşenler (Theme.qml, PowerButton.qml, vb.)
```

---

## 3. Veri Akışı ve Durum Yönetimi Kuralları

### A. Global Servislere Erişim
Global servisler, `shell.qml` içinde tanımlanmış olan `ShellRoot` (`id: root`) altındaki ID'leri aracılığıyla tüm alt QML nesneleri tarafından doğrudan okunabilir.
* **Çalışma Alanları & Bildirimler:** `workspaceService.workspaceState` ve `workspaceService.activeNotifications`
* **İstatistikler & Medya:** `systemStatsService.cpuUsage`, `systemStatsService.volume`, `systemStatsService.mediaTitle` vb.
* **Zamanlayıcılar:** `timeService.stopwatchTime`, `timeService.pomodoroTime` vb.

### B. Monitörler Arası Bağımsızlık ve `MonitorGroup`
Her ekran için bağımsız olan açılıp kapanma durumları, yerel temalar ve HUD özellikleri `windows/MonitorGroup.qml` üzerinde tanımlanır.
* `MonitorGroup`, `Quickshell.screens` modeliyle dinamik olarak çoğaltılır.
* İçindeki pencerelere (`TopBarWindow`, `ControlCenterWindow` vb.) kendi referansını `monitorGroup` veya `group` parametresiyle aktarır.
* **Kural:** Herhangi bir pencere, kendi monitörüne ait açık/kapalı durumunu veya yerel temasını okumak için bu parametreyi (örneğin `monitorGroup.isControlCenterOpen`) kullanmalıdır.

### C. Shadowing (Ekran Tanımlama) Önlemi
`PanelWindow` bileşeninin yerleşik `screen` özelliğiyle çakışma yaşanmaması için, alt pencerelere ekran referansı aktarılırken `targetScreen` ismi kullanılmalı ve pencerenin yerleşik özelliğine bağlanmalıdır:
```qml
PanelWindow {
  id: win
  required property var targetScreen
  screen: targetScreen
  ...
}
```

### D. Dış Kısayollar ve IPC (ogsshell-ipc)
Hyprland veya diğer pencere yöneticilerinde klavye kısayolları ile bar üzerindeki panelleri doğrudan açabilmek/kapatabilmek için bir IPC (Inter-Process Communication) yapısı mevcuttur:
* **Mekanizma:** Arka planda `ShellIpcService.qml` servisi, `$XDG_RUNTIME_DIR/ogsshell-ipc` konumunda bir Named Pipe (FIFO) oluşturur ve `tail -f` aracılığıyla dinler.
* **Tetikleme:** Kullanıcı veya sistem, `./ipc.sh <komut>` scripti aracılığıyla boruya (pipe) veri gönderdiğinde, bu komut anında yakalanır.
* **Aktif Ekran Tespiti:** Gelen komutlar, `workspaceService` üzerinden o an aktif/odaklanmış olan monitör (focused: true) tespit edilerek sadece o ekranın `MonitorGroup` örneği üzerinde yürütülür.
* **Desteklenen Komutlar:**
  * `control_center` - Kontrol merkezini açar/kapatır.
  * `control_center:wifi` - Kontrol merkezini Wi-Fi sayfasıyla açar.
  * `control_center:bluetooth` - Kontrol merkezini Bluetooth sayfasıyla açar.
  * `control_center:theme` - Kontrol merkezini Tema seçici sayfasıyla açar.
  * `control_center:clipboard` - Kontrol merkezini Pano geçmişi sayfasıyla açar.
  * `time_manager` - Pomodoro/Kronometre panelini açar/kapatır.
  * `calendar` - Takvim panelini açar/kapatır.

---

## 4. Yeni Bir Özellik Eklerken İzlenecek Adımlar (AI/İnsan Rehberi)

Eğer sisteme yeni bir özellik (örneğin; hava durumu göstergesi, yeni bir HUD modu vb.) eklemek istiyorsanız şu adımları izleyin:

1. **Adım 1 (Veri/İş Mantığı):** Veriyi çekecek ve işleyecek mantığı `services/` altında yeni bir servis dosyası oluşturarak (örneğin `WeatherService.qml`) ya da mevcut `SystemStatsService.qml` içine ekleyerek tanımlayın.
2. **Adım 2 (Global Kayıt):** Bu servisi `shell.qml` içindeki `ShellRoot` seviyesinde bir kez başlatın ve ona bir ID (örn: `weatherService`) verin.
3. **Adım 3 (Görsel Tasarım):** Görsel kartı veya adayı `components/` altında bağımsız bir QML dosyası olarak tasarlayın (örn: `components/WeatherWidget.qml`). Veri okuma işlemlerini doğrudan `weatherService` üzerinden yapın.
4. **Adım 4 (Pencere Entegrasyonu):** Tasarladığınız widget'ı ya `TopBarWindow.qml` içindeki uygun bir adaya ekleyin, ya da yeni bir overlay pencereye ihtiyaç duyuyorsa `windows/` altında yeni bir `WeatherWindow.qml` (PanelWindow) oluşturup bunu `MonitorGroup.qml` içine dahil edin.
5. **Adım 5 (Yerel Durumlar):** Eğer özellik her monitörde bağımsız açılıp kapanacak bir yapıdaysa, durum değişkenini (örn: `property bool isWeatherOpen`) `MonitorGroup.qml` içine ekleyin.
