---
title: "Shell Config Service"
type: service
tags:
  - config
  - quickshell/qml
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Settings-App-UI]]"
  - "[[ShellIPC-Service]]"
  - "[[Shell-Bar-Components]]"
  - "[[Architecture-Overview]]"
---

# Shell Config Service (`ShellConfigService.qml`)

> [!NOTE]
> `ShellConfigService.qml`, `~/.config/ogsshell/config.json` yapılandırma dosyasını okuyarak shell barının dinamik yüksekliği, adaların genişlik ölçeği ve modül aktiflik/pasiflik durumlarını yöneten merkezi QML servisidir.

## Özellikler ve Parametreler

| Özellik (Property) | Tür | Varsayılan | Açıklama |
| :--- | :--- | :--- | :--- |
| `barHeight` | `int` | `34` | Shell barının ve adaların piksel yüksekliği (24px - 56px). |
| `islandWidthScale` | `real` | `1.0` | Adaların yatay genişlik ölçeği (%70 - %150). |
| `showWorkspaces` | `bool` | `true` | Sol Hyprland çalışma alanı adasının görünürlüğü. |
| `showSysStats` | `bool` | `true` | Sistem istatistikleri (CPU, RAM, GPU) adasının görünürlüğü. |
| `showCenterHud` | `bool` | `true` | Orta saat ve dinamik HUD adasının görünürlüğü. |
| `showMedia` | `bool` | `true` | Sağ medya oynatıcı ve bildirim adasının görünürlüğü. |
| `showPomodoro` | `bool` | `true` | Pomodoro ve kronometre zamanlayıcı servisinin aktifliği. |
| `compactMode` | `bool` | `false` | Sıkışık bar modunun aktifliği. |
| `cornerRadius` | `int` | `12` | Kart ve ada köşe yarıçapı. |

## IPC Entegrasyonu
Ayarlar uygulamasından bir ayar değiştirildiğinde `ShellIpcService.qml` üzerinden `config_reload` sinyali tetiklenir ve `ShellConfigService.reloadConfig()` fonksiyonu çağrılarak shell görsel olarak anında güncellenir.
