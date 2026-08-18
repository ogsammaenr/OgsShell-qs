---
title: "Plan: Dock Smart Autohide and Bottom-Edge Overlay Reveal"
type: agent-thought
tags:
  - ui/dock
  - quickshell/panelwindow
  - hyprland/toplevels
  - overlay/exclusion-mode
  - autohide/hotspot
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Dock-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Dock Smart Autohide and Bottom-Edge Overlay Reveal

> [!IDEA]
> Çalışma alanında aktif bir pencere varken alt Dock'un küçülüp ekranın altına doğru kaybolması, fare ekranın en altına (1-2px) çarptığında pencereleri yukarı ötelemeden (`ExclusionMode.Ignore`) uygulamanın üzerine binerek açılması ve fare çekildiğinde 350ms gecikmeyle pürüzsüzce yeniden gizlenmesi mimarisi.

## 1. Problem ve Kullanıcı İhtiyacı
* Kullanıcı açık bir uygulama varken Dock'un ekranı kaplamamasını ve otomatik olarak gizlenmesini talep etmektedir.
* Fare ekranın en altına (1px) çarptığında Dock derhal açılmalı, ancak açık uygulamayı yukarı kaydırmamalı, uygulamanın üzerine binmelidir (`overlay`).
* Masaüstünde hiç pencere yokken Dock açık kalmalı; pencere açıldığında gizlenmelidir.

## 2. Mimari Çözüm
1. **Pencere Algılama (`dockShouldAutoHide`):** `screenScope.hasTilingWindows` sorgusu ile ilgili monitörün aktif çalışma alanındaki pencereler taranır. Pencere varsa `dockShouldAutoHide = true`, yoksa `false`.
2. **Alt 3px Hotspot Tetikleyici:** Ekranın alt sınırında 3px yüksekliğinde `bottomHotspotMouseArea` konumlandırılır. Fare alta değdiği an `dockIsRevealed = true` yapılır.
3. **Pencereyi Kaydırmayan Overlay (`ExclusionMode.Ignore`):** `dockWindow` `exclusionMode: ExclusionMode.Ignore` olarak ayarlanır. Bu sayede pencereler ekranın tamamını kullanır, Dock açıldığında hiçbir pencere hareket etmez.
4. **Dinamik Girdi Maskesi (Zero Click-Blocking):** Dock gizliyken maske sadece 3px alt hotspot'u kapsar (arkadaki uygulama %100 tıklanabilir). Dock açıkken maske yukarı genişleyerek Dock ve önizleme kartını kapsar.
5. **Debounce Dismiss (350ms):** Fare Dock üzerinden ayrıldığında 350ms gecikme ile pürüzsüz küçülme ve kaybolma animasyonu devreye girer.

## 3. Uygulama Adımları
1. `shell/components/dock/Dock.qml` & `DockItem.qml` içerisine `isRevealed` ve `isDockHovered` durumlarının eklenmesi.
2. `shell/shell.qml` içerisindeki `screenScope` ve `dockWindow` yapısının autohide, hotspot ve dinamik maske ile güncellenmesi.
3. Canlı doğrulama ve Obsidian dokümantasyon senkronizasyonu.
