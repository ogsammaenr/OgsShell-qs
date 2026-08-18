---
title: "Plan: Focus Mode and Smart Dynamic Island Autohide"
type: agent-thought
tags:
  - ui/focus-mode
  - ui/autohide
  - hyprland/toplevels
  - quickshell/layershell
  - dynamic-island/physics
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Control-Center-Widget]]"
  - "[[Configuration-System-Spec]]"
  - "[[System-Architecture]]"
---

# Plan: Focus Mode and Smart Dynamic Island Autohide

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Dynamic Island için sıfır üst kenar boşluğu (zero exclusive zone) sağlayan, aktif workspacede tiling uygulama varken adayı gizleyen, mouse ekran tepesine yaklaştığında akıcı reveal animasyonu ile açılan ve masaüstü boşken veya sadece floating pencereler varken adayı görünür tutan akıllı Focus Modu başarıyla entegre edildi.

## 1. Problem ve Kullanıcı İhtiyacı
* Kullanıcı tam ekran odaklanmak istediğinde:
  - Ada pencerelerin üzerini kapatmamak için yukarıda saklanmalı.
  - Uygulamalar ekranın en tepesine (`y: 0`) kadar tam ekran büyüyebilmeli (üst rezervasyon alanı kaldırılmalı).
  - Yalnızca fare en tepeye yaklaştırıldığında ada aşağı inmeli.
  - Eğer aktif workspacede floating olmayan (tiling) bir pencere yoksa ada masaüstünde normal şekilde görünmeye devam etmeli.

## 2. Mimari Çözüm ve Tasarım

### A. Yapılandırma ([Config.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/backend/Config.qml))
- `property bool focusMode: false` parametresi.
- `config.json` dosyasından `focus_mode` ayarının okunabilmesi ve `Config.focusMode = !Config.focusMode` ile çalışma anında tetiklenebilmesi.

### B. Üst Rezervasyon Dinamizmi ([shell.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/shell.qml))
- `reservedSpacerWindow.exclusionMode: Config.focusMode ? ExclusionMode.Ignore : ExclusionMode.Auto`
- Focus modu aktifken Hyprland tiling pencereleri ekranın en üstüne kadar genişler (`y: 0`).

### C. Hyprland Tiling Pencere Tespiti
- `import Quickshell.Hyprland` ile aktif workspacedeki pencerelerin `floating` ve `hidden` durumları taranır:
  ```qml
  readonly property bool hasTilingWindows: {
    if (!Hyprland.focusedWorkspace) return false
    let curWsId = Hyprland.focusedWorkspace.id
    let toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : []
    for (let i = 0; i < toplevels.length; i++) {
      let win = toplevels[i]
      if (win.workspace && win.workspace.id === curWsId && !win.floating && !win.hidden) {
        return true
      }
    }
    return false
  }
  ```

### D. Reveal / Autohide Mekanizması
- Ekranın en üstünde `topHotspot` ve `topHotspotMouseArea` tanımlandı.
- Ada, `isRevealed` durumuna göre `y: (Config.isNotch ? 0 : Config.activeGeometry.top_margin)` veya `y: -island.implicitHeight - 30` pozisyonuna Apple HIG `SpringAnimation` (`spring: 28.0`, `damping: 0.78`) ile geçiş yapar.
- Wayland giriş maskesi `mask: Region { item: screenScope.isRevealed ? island : topHotspot }` olarak yapılandırıldı. Ada gizliyken ekranın sadece en üst 6 piksellik hotspot'u aktif kalır; alttaki uygulamaların tıklanması asla engellenmez.
- `EXPANDED` ve `TRANSIENT` durumlarında etkileşim devam ettiği sürece ada açık kalır.

### E. Kontrol Merkezi Butonu ([ControlCenterMain.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/ControlCenterMain.qml))
- 2x2 hızlı eylem ızgarasında **Odak Modu (Focus Mode)** toggle butonu eklendi.

## 3. Güncellenen Dosyalar
- `shell/backend/Config.qml`
- `shell/shell.qml`
- `shell/components/island/DynamicIsland.qml`
- `shell/components/widgets/controlcenter/ControlCenterMain.qml`
