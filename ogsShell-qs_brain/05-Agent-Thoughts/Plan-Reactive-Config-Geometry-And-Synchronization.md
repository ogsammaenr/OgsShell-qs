---
title: "Plan: Reactive Config Geometry and Synchronization"
type: agent-thought
tags:
  - architecture/config
  - config/json
  - quickshell/qml
  - dynamic-notch
  - dynamic-island
created: 2026-08-23
updated: 2026-08-23
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Reactive Config Geometry and Synchronization

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> `shell/backend/Config.qml` mimarisi hem `shell/config.json` hem de `~/.config/ogsShell/config.json` dosyalarını bağımsız olarak canlı dinleyecek ve otomatik olarak eşitleyecek şekilde yenilendi. Çentik/ada yüksekliği veya herhangi bir parametre değiştirildiğinde tüm pencere, spacer ve vektör şekiller anında yeniden hesaplanmaktadır.

## 1. Problem Tespiti (Root Cause Analysis)
1. **Dosya Öncelik ve Gözlemci Körlüğü:** `shell/backend/Config.qml` içinde `configFile` (`~/.config/ogsShell/config.json`) ve `workspaceConfigFile` (`shell/config.json`) olmak üzere iki `FileView` tanımlıdır. Ancak `workspaceConfigFile.onTextChanged` altında `if (!configFile.path || configFile.text().length === 0)` şartı bulunduğu için, sistemde `~/.config/ogsShell/config.json` mevcut olduğunda `shell/config.json` üzerinde yapılan hiçbir değişiklik okunmamakta ve uygulanmamaktadır.
2. **Kullanıcı/Geliştirici Düzenlemeleri:** Kullanıcı `shell/config.json` dosyasını düzenlediğinde, kabuk yeniden başlatılsa dahi `~/.config/ogsShell/config.json` eski değerleri barındırdığı için çentik yüksekliği (`idle_height`) değişmemektedir.
3. **QML Nesne Referansı Reaktivitesi:** `property var notch` ve `property var island` gibi genel JavaScript nesnelerinin iç alanları (`notch.idle_height`) QML motorunda derinlemesine izlenmeyebilmektedir.

## 2. Çözüm Stratejisi
1. **Reaktif Çoklu Dosya İzleme ve Eşitleme (Multi-File Reactive Sync):**
   - Hem `$XDG_CONFIG_HOME/ogsShell/config.json` hem de `shell/config.json` bağımsız olarak canlı izlenir.
   - Her iki dosyadan birinde değişiklik olduğunda `loadConfigString` anında tetiklenir.
   - Başlangıçta (`Component.onCompleted`) çalışma dizinindeki `shell/config.json` veya kullanıcı konfigürasyonu okunur; değişiklikler `$XDG_CONFIG_HOME/ogsShell/config.json` ile senkronize edilir.
2. **Birinci Sınıf Tip Güvenli Reaktif QML Özellikleri (First-Class Reactive Properties):**
   - `Config.qml` içerisine `notchIdleHeight`, `notchHoverHeight`, `islandIdleHeight` vb. açık QML özellikleri eklenir ve bileşik geometriler güncellendiğinde binding sinyalleri tetiklenir.
3. **Pencere ve Geometri Katmanları:**
   - `shell.qml` ve `DynamicIsland.qml` içindeki tüm spacer, input envelope ve vector shape elemanlarının `Config.activeGeometry` ile tam reaktif çalışması garanti altına alınır.

## 3. Etkilenen Dosyalar
- `shell/backend/Config.qml`
- `shell/config.json`
- `scripts/run_frontend.sh`
- `scripts/run_shell.sh`
