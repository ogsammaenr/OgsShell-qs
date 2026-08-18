---
title: "Plan: Independent Modern Wayland Dock Component"
type: agent-thought
tags:
  - ui/dock
  - quickshell/panelwindow
  - hyprland/toplevels
  - screencopy/preview
  - apple-hig/dock
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Configuration-System-Spec]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Independent Modern Wayland Dock Component

> [!IDEA]
> Ekranın altında çalışan, Dynamic Island / Notch yapısından tamamen bağımsız, `config.json` üzerinden yönetilen sabitlenmiş uygulama kısayolları (pinned apps) ve açık uygulamaları (running apps) listeleyen, macOS / Apple HIG tarzı hover büyütme ve zengin pencere önizleme kartına (preview popup) sahip modern bir Wayland Dock bileşeni geliştirmek.

## 1. Problem ve Kullanıcı İhtiyacı
* Kullanıcı ekranın en altında konumlanan, tepedeki Dynamic Island'dan bağımsız bir Dock arayüzü talep etmektedir.
* **Gereksinimler:**
  1. Adadan tamamen bağımsız, ekranın altında (`anchors.bottom: true`) çalışan ayrı bir `PanelWindow`.
  2. `config.json` ve `Config.qml` içinde ayrı bir `"dock"` yapılandırma bloğu (boyut, ikon boyutu, kenar boşlukları, sabitlenmiş uygulamalar `pinned_apps`).
  3. Yüksek çözünürlüklü uygulama ikonları (`Quickshell.iconPath`).
  4. Hover durumunda ikonun akıcı büyümesi (hover magnification) ve ikonun üzerinde **Uygulama İsmi** ile birlikte açık pencere önizleme kartının (preview popup) gösterilmesi.
  5. Çalışan uygulamalar için alt kısımda şık durum LED göstergesi.
  6. İkona tıklandığında kapalıysa uygulamayı başlatma, açıksa Hyprland penceresine odaklanma (`focuswindow`).

## 2. Mimari Tasarım
* `shell/components/dock/`:
  - `Dock.qml`: Ana kapsayıcı, koyu cam/OLED arka plan (`Style.surface`, `Style.border`), yuvarlatılmış köşeler (`radius: 20-22`), sabitlenmiş kısayollar ve açık uygulamalar için yatay düzen.
  - `DockItem.qml`: Tekil ikon, hover animasyonu, aktif pencere durumu, Hyprland odaklama / uygulama çalıştırma.
  - `DockPreviewCard.qml`: İkon üzerine gelindiğinde açılan, uygulama adı, pencere başlığı, çalışma alanı rozeti ve `ScreencopyView` önizleme kartı.
* `shell/backend/Config.qml` & `shell/config.json`: Dinamik `dock` konfigürasyonu.
* `shell/shell.qml`: `dockWindow` `PanelWindow` katmanı (`WlrLayershell.layer: WlrLayer.Top`).

## 3. Uygulama Adımları
1. `shell/config.json` ve `shell/backend/Config.qml` güncellemesi.
2. `shell/components/dock/DockPreviewCard.qml` oluşturulması.
3. `shell/components/dock/DockItem.qml` oluşturulması.
4. `shell/components/dock/Dock.qml` oluşturulması.
5. `shell/shell.qml` içerisine `dockWindow` entegrasyonu.
6. Obsidian dokümantasyonu (`ogsShell-qs_brain/03-UI-Components/Dock-Component.md`) ve mimari referansların güncellenmesi.
