---
title: "Plan: Standalone XDG Settings Application (settings_app)"
type: agent-thought
tags:
  - frontend/qml
  - settings/app
  - quickshell/floatingwindow
  - xdg/toplevel
  - hyprland/windowrules
created: 2026-08-23
updated: 2026-08-23
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Settings-Application-Component]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Wifi-Client-Service]]"
  - "[[Plan-System-Settings-App-And-Network-Architecture]]"
---

# Plan: Standalone XDG Settings Application (`settings_app/`)

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Ayarlar ekranı Quickshell `FloatingWindow` (XDG Toplevel) mimarisiyle bağımsız bir masaüstü uygulamasına dönüştürüldü. Tekil odaklama koruması (`open_settings_app.sh`), masaüstü kısayolu (`ogs-settings.desktop`) ve macOS pencere kontrolleri eklendi.

## 1. Mimari Dönüşüm
- **Overlay'den XDG Toplevel'a:** `shell.qml` içindeki `PanelWindow` modalı kaldırılacak; yerine bağımsız `settings_app/shell.qml` giriş noktası oluşturulacak.
- **Pencere Başlık Çubuğu:** Apple macOS tarzı pencere kontrolleri (🔴 Kapat, 🟡 Simge Durumu, 🟢 Büyüt/Ekranı Kapla) ve pencere sürükleme alanı eklenecek.
- **Tek Süreç & Odaklama Koruması (`Single Instance`):** `open_settings_app.sh` script'i uygulama zaten açıksa `hyprctl dispatch focuswindow class:^ogs-settings$` ile mevcut pencereye odaklanacak, sıfırdan ikinci pencere açmayacak.
- **Desktop Entry:** `~/.local/share/applications/ogs-settings.desktop` oluşturularak sistem launcher'larına kaydedilecek.

## 2. Modüler Dosya Yapısı
```text
settings_app/
├── shell.qml                     # Standalone FloatingWindow giriş noktası
├── qmldir                        # Modül importları (Style, Config, DaemonIPC)
scripts/
└── open_settings_app.sh          # Bağımsız çalıştırma ve pencereye odaklanma script'i
~/.local/share/applications/
└── ogs-settings.desktop          # Sistem masaüstü uygulama kısayolu
```
