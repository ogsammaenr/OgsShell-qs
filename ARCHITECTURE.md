# OgsShell-qs Mimari Dokümantasyonu (ARCHITECTURE.md)

Bu doküman, OgsShell-qs ekosisteminin çoklu-uygulama mimarisini, dizin organizasyonunu, veri akış kurallarını, binary yönetimini ve gelecekte sisteme yeni özellikler eklenirken uyulması gereken mimari standartları tanımlar.

---

## 1. Ekosistem Mimarisi

OgsShell-qs, modülerlik ve yüksek performans sağlamak amacıyla 4 temel katmandan oluşur:

```
+-------------------------------------------------------------------------------+
|                             OgsShell-qs Ekosistemi                            |
+------------------------------------+------------------------------------------+
|  Quickshell Desktop Shell (QML/C)  |   Python Qt Settings Application (GUI)  |
|  - TopBar, Dynamic Islands         |   - Appearance & Live Theme Switcher     |
|  - Overlays (Control Center, etc.) |   - Module Toggles & Performance Modes   |
+------------------------------------+------------------------------------------+
|                     Ortak İletişim & Konfigürasyon Katmanı                     |
|  - IPC Named Pipe ($XDG_RUNTIME_DIR/ogsshell-ipc)                             |
|  - Shared App Config Templates (shared/app_configs/)                          |
|  - Shared Themes Registry (shared/themes/themes.json)                         |
+-------------------------------------------------------------------------------+
|                            Merkezi Binary Katmanı                             |
|  - bin/monitor, bin/workspaces, bin/theme_sync_helper, etc.                  |
+-------------------------------------------------------------------------------+
```

1. **Merkezi Çalıştırıcı Dizin (`bin/`):** Tüm derlenmiş C daemon'ları (`monitor`, `workspaces`, `app_launcher_helper`, `wallpaper_helper`, `theme_sync_helper`) ve çalıştırılabilir betikler (`audio_mixer_helper.py`, `bluetooth_helper.sh`).
2. **Ortak Kaynaklar (`shared/`):** Uygulama tema şablonları (`app_configs/`), tema JSON tanımları (`themes/`) ve IPC haberleşme protokol standartları (`ipc/`).
3. **Quickshell Desktop Shell (`shell/`):** Quickshell Layer Shell tabanlı masaüstü barı ve overlay pencereleri. **Servis-Pencere-Bileşen (Service-Window-Component)** deseniyle modülerleştirilmiştir.
   - **Servisler (`shell/services/`):** Görsel olmayan, arka plan işlemleri, C daemon süreç yönetimi ve global durum (state) yönetimi.
   - **Pencereler (`shell/windows/`):** Ekran katmanı ayarlarını (`PanelWindow`, `exclusiveZone`) yöneten pencereler.
   - **Bileşenler (`shell/components/`):** Sadece çizim, animasyon ve etkileşimleri yöneten tekrar kullanılabilir UI parçaları.
4. **Ayarlar Uygulaması (`settings_app/`):** Kontrol merkezinden bağımsız, **Qt for Python (PySide6 / PyQt)** ile yazılmış masaüstü tercihleri GUI uygulaması.

---

## 2. Detaylı Dizin Yapısı ve Dosya Sorumlulukları

```
OgsShell-qs/
├── Makefile                       # Kök Makefile (Shell C daemons derler & uygulamaları çalıştırır)
├── ARCHITECTURE.md                # Mimari dokümantasyonu
├── bin/                           # Merkezi ikili dosyalar ve çalıştırılabilir betikler
│   ├── monitor                    # CPU, RAM, GPU, Ağ hızları, Ses, Medya takip daemon'ı (C)
│   ├── workspaces                 # Hyprland çalışma alanı ve D-Bus bildirim takip daemon'ı (C)
│   ├── app_launcher_helper        # Uygulama tarama ve simge çözümleyici binary (C)
│   ├── wallpaper_helper           # Duvar kağıdı tarama ve dinamik değiştirme binary (C)
│   ├── theme_sync_helper          # GTK, Qt, Kitty, Zed, IntelliJ, Neovim vb. tema senkronize binary (C)
│   ├── audio_mixer_helper.py      # WirePlumber/PulseAudio ses karıştırıcı betiği (Python)
│   └── bluetooth_helper.sh        # Bluetoothctl tarama ve eşleştirme betiği (Bash)
├── shared/                        # Ortak kaynaklar ve yapılandırmalar
│   ├── app_configs/               # GTK, Qt, Kitty, Zed, IntelliJ, Vesktop, Tmux tema şablonları
│   ├── themes/                    # Ortak renk teması JSON tanımları (themes.json)
│   └── ipc/                       # Ortak IPC komut spesifikasyonu (protocol.json)
├── shell/                         # Quickshell Bar ve Overlay Panelleri
│   ├── shell.qml                  # Shell giriş noktası (Global servisleri ve MonitorGroup'u başlatır)
│   ├── reload.sh                  # Shell ortam değişkenli yeniden başlatma scripti
│   ├── ipc.sh                     # Kısayollar ve dış komutlar için IPC tetikleyici script
│   ├── Makefile                   # C daemon derleme betiği (Çıktıları ../bin/ içine üretir)
│   ├── services/                  # Görsel olmayan mantıksal servisler (WorkspaceService, SystemStatsService vb.)
│   ├── windows/                   # Üst düzey PanelWindow katmanları (MonitorGroup, TopBarWindow, ControlCenterWindow vb.)
│   └── components/                # UI widget bileşenleri (LeftWorkspaceBar, CenterHudIsland, RightMediaNotifIsland vb.)
└── settings_app/                  # Bağımsız Python Qt Ayarlar Uygulaması
    ├── main.py                    # Python uygulama giriş noktası
    ├── config.py                  # ~/.config/ogsshell/config.json yapılandırma yöneticisi
    ├── requirements.txt           # Python bağımlılıkları (PySide6)
    ├── ui/                        # PySide6 arayüz bileşenleri
    │   ├── qt_compat.py           # PySide6 / PyQt6 / PyQt5 otomatik uyumluluk katmanı
    │   ├── main_window.py         # Sol gezinti menüsü ve sayfa yığını (QStackedWidget)
    │   ├── pages/                 # Tercih sayfaları (AppearancePage, ModulesPage, SystemPage, GeneralPage, AboutPage)
    │   └── widgets/               # Kartlar, şalterler (ToggleSwitch) ve slider'lar
    └── utils/                     # Yardımcı fonksiyonlar
        └── ipc_client.py          # Shell named pipe'ına (`ogsshell-ipc`) canlı komut gönderen istemci
```

---

## 3. Veri Akışı ve Mimari Kurallar

### A. Binary Yollarının Dinamik Çözümlenmesi (`binDir`)
Quickshell QML servislerinde süreç (Process) başlatılırken sabit yollar kullanılmaz. Yol çözünürlüğü `Quickshell.env("ROOT_DIR")` üzerinden dinamik olarak sağlanır:

```qml
readonly property string binDir: (typeof Quickshell !== "undefined" && Quickshell.env("ROOT_DIR"))
                                   ? Quickshell.env("ROOT_DIR") + "/bin"
                                   : "/home/excalibur/WorkSpace/projects/OgsShell-qs/bin"

Process {
    command: [service.binDir + "/monitor"]
    running: true
}
```

### B. Shadowing (Ekran Tanımlama) Önleme Kuralı
`PanelWindow` bileşeninin yerleşik `screen` özelliğiyle çakışma yaşanmaması için, alt pencerelere ekran referansı aktarılırken `targetScreen` ismi kullanılmalı ve pencerenin yerleşik özelliğine bağlanmalıdır:

```qml
PanelWindow {
    id: win
    required property var targetScreen
    screen: targetScreen
}
```

### C. Monitör Bağımsızlığı ve `MonitorGroup`
Her ekran için bağımsız olan açılıp kapanma durumları, yerel temalar ve HUD özellikleri `shell/windows/MonitorGroup.qml` üzerinde tanımlanır.
* `MonitorGroup`, `Quickshell.screens` modeliyle dinamik olarak çoğaltılır.
* İçindeki pencereler (`TopBarWindow`, `ControlCenterWindow` vb.) kendi monitörüne ait durumu `monitorGroup.isControlCenterOpen` üzerinden okur.

### D. İki Yönlü IPC (Inter-Process Communication)
* **Shell Tarafı (`ShellIpcService.qml`):** `$XDG_RUNTIME_DIR/ogsshell-ipc` konumunda bir Named Pipe (FIFO) oluşturur ve `tail -f` ile dinler.
* **Tetikleyiciler (`ipc.sh` & `settings_app/utils/ipc_client.py`):** Dış kısayollardan veya Python Ayarlar Uygulamasından komut gönderildiğinde tema, oyun modu ve overlay paneller anında güncellenir.

---

## 4. Yeni Bir Özellik Eklerken İzlenecek Adımlar (Rehber)

1. **Adım 1 (Veri/Arka Plan):**
   - Sistem verisi çekilecekse C daemon kodunu `shell/services/` altında geliştirin ve `shell/Makefile` ile çıktıyı `../bin/` klasörüne yönlendirin.
   - QML tarafında mantığı yönetmek için `shell/services/` altında yeni bir QML servisi tanımlayın (örn. `WeatherService.qml`).
2. **Adım 2 (Global Kayıt):**
   - Servisi `shell/shell.qml` içindeki `ShellRoot` seviyesinde bir kez başlatın ve ona bir ID verin.
3. **Adım 3 (Görsel Tasarım):**
   - Görsel kartı `shell/components/` altında geliştirin.
4. **Adım 4 (Pencere & Ayarlar Entegrasyonu):**
   - Yeni bir overlay pencereye ihtiyaç varsa `shell/windows/` altına ekleyip `MonitorGroup.qml` içine dahil edin.
   - Ayarlar Uygulamasında açıp kapatma düğmesi eklemek için `settings_app/ui/pages/modules_page.py` dosyasını güncelleyin.
5. **Adım 5 (Dokümantasyon Güncellemesi):**
   - Yeni bileşeni veya servisi [.agents/GLOSSARY.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/GLOSSARY.md) sözlüğüne ekleyin.
   - `brain/` alanındaki Obsidian dokümantasyonunu [.agents/skills/obsidian-glossary/SKILL.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/skills/obsidian-glossary/SKILL.md) kurallarına göre güncelleyin.

---

## 5. Çalıştırma Komutları

* **Shell'i Başlatma / Yeniden Yükleme:**
  ```bash
  make run-shell
  # veya: ./shell/reload.sh
  ```
* **Ayarlar Uygulamasını Başlatma:**
  ```bash
  make run-settings
  # veya: python3 settings_app/main.py
  ```
* **Binary'leri Derleme:**
  ```bash
  make
  # veya: make -C shell
  ```
