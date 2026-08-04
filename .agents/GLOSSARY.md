# OgsShell-qs Dosya ve Bileşen Sözlüğü (GLOSSARY.md)

Bu dosya, projedeki tüm dosyaları, bileşenleri, servisleri, C daemon'larını ve Python Qt Ayarlar Uygulamasını dizinleyerek her birinin amacını, barındırdığı özellikleri ve birbirleriyle olan ilişkilerini açıklar.

---

## 1. Dizin ve Proje Yapısı

| Dizin / Dosya | Türü | Açıklama / Görevi |
| :--- | :--- | :--- |
| [bin/](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/) | Dizin | Tüm derlenmiş C binary dosyaları (`monitor`, `workspaces`, `app_launcher_helper`, `wallpaper_helper`, `theme_sync_helper`) ve çalıştırılabilir yardımcı betikler (`audio_mixer_helper.py`, `bluetooth_helper.sh`). |
| [shared/](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shared/) | Dizin | Shell ve Ayarlar Uygulaması tarafından ortak kullanılan tema şablonları (`app_configs/`), renk tanımları (`themes/themes.json`) ve IPC protokol spesifikasyonları (`ipc/protocol.json`). |
| [shell/](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/) | Dizin | Quickshell Layer Shell masaüstü barı ve overlay pencerelerinin bulunduğu dizin (`shell.qml`, `components/`, `windows/`, `services/`, `ipc.sh`, `reload.sh`). |
| [settings_app/](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/settings_app/) | Dizin | Kontrol merkezinden bağımsız, **Qt for Python (PySide6)** ile geliştirilmiş masaüstü tercihleri GUI uygulaması. |
| [Makefile](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/Makefile) | Makefile | Kök dizin derleme betiği. `make run-shell` ve `make run-settings` komutlarını barındırır. |

---

## 2. Merkezi Binary ve Betikler (`bin/`)

- **[monitor](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/monitor):** CPU, RAM, GPU, Ağ hızları, ses, parlaklık ve Bluetooth/Medya verilerini JSON olarak yayınlayan C daemon'ı.
- **[workspaces](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/workspaces):** Hyprland çalışma alanı değişikliklerini ve D-Bus bildirimlerini anlık yayınlayan C daemon'ı.
- **[app_launcher_helper](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/app_launcher_helper):** Sistemdeki `.desktop` uygulamalarını tarayan ve ikonlarını çözen C binary'si.
- **[wallpaper_helper](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/wallpaper_helper):** Duvar kağıdı dizinini tarayan ve temaya göre duvar kağıdını senkronize değiştiren C binary'si.
- **[theme_sync_helper](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/theme_sync_helper):** GTK3/4, Qt/Dolphin, Kitty, Zed, IntelliJ, Neovim, Tmux ve Vesktop uygulamalarına anlık tema senkronize eden C binary'si.
- **[audio_mixer_helper.py](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/audio_mixer_helper.py):** WirePlumber / PulseAudio akışlarını ve uygulama seslerini kontrol eden Python betiği.
- **[bluetooth_helper.sh](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/bin/bluetooth_helper.sh):** `bluetoothctl` tarama ve eşleştirme komutlarını yürüten bash betiği.

---

## 3. Quickshell Servisleri (`shell/services/`)

- **[ShellConfigService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/services/ShellConfigService.qml):** `~/.config/ogsshell/config.json` dosyasındaki bar yüksekliği (`barHeight`), ada genişlik ölçeği (`islandWidthScale`) ve modül aktiflik durumlarını dinamik yükleyerek shell bileşenlerine sunan servis.
- **[ShellIpcService.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/services/ShellIpcService.qml):** `$XDG_RUNTIME_DIR/ogsshell-ipc` named pipe üzerinden gelen canlı kontrol paneli, tema ve konfigürasyon yenileme (`config_reload`) komutlarını dinleyen ve sinyal yayan servis.

