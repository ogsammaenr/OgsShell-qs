---
title: "Plan: Dock Smart Icon Resolution and Continuous Hover Lock"
type: agent-thought
tags:
  - ui/dock
  - quickshell/icons
  - hyprland/toplevels
  - hover/lock
  - autohide/debounce
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

# Plan: Dock Smart Icon Resolution and Continuous Hover Lock

> [!IDEA]
> Hyprland pencere sınıfları ile masaüstü ikon temaları arasındaki isim uyuşmazlıklarını (örn. `zen` -> `zen-browser`, `jetbrains-idea` -> `intellij-idea-ultimate-edition`) akıllı alias motoruyla çözmek ve fare ekranın en altına çarptıktan sonra Dock üzerinde gezindiği sürece Dock'un ekranda sabit kalmasını (Hover Lock), ancak fare Dock'tan ayrıldığında pürüzsüzce kaybolmasını sağlamak.

## 1. Problem Analizi
1. **İkon İsim Uyuşmazlığı:** Hyprland toplevel sınıfı ile sistem ikon temasındaki isimler farklı olduğunda (`zen` vs `zen-browser`, `jetbrains-idea` vs `intellij-idea-ultimate-edition`, `code` vs `com.visualstudio.code.oss`) `Quickshell.iconPath` boş dönmekte ve ikonlar harf ikonuna düşmektedir.
2. **Hover Kilidi Eksikliği:** Fare alt sınırdaki 3px alandan çıkıp Dock ikonlarına doğru yükseldiğinde, alt tetikleyiciden çıkıldığı ve çocuk bileşenler fare olaylarını tükettiği için ana alan fareyi kaybetmiş sayılmakta ve zamanlayıcı süresi dolunca Dock kullanıcının imleci altındayken kapanmaktadır.

## 2. Mimari Çözüm
1. **`resolveAppIcon` Motoru (`DockItem.qml`):**
   - İkon adı, pencere sınıfı ve uygulama adı taranır.
   - Bilinen alias tablosu (`zen`, `zen-browser`, `jetbrains-idea`, `intellij-idea`, `dev.zed.Zed`, `code`, `code-oss`, `dolphin`, `spotify`, `obsidian`, `vesktop`, `discord`, `telegram`, `steam` vb.) kontrol edilir.
   - Doğrudan `/usr/share/pixmaps/` veya `image://icon/` formatına çevrilir.
2. **Kesintisiz Hover Zarfı (`dockOverallHoverArea` in `shell.qml`):**
   - Ekranın en altından (0px) başlayarak Dock pill ve açılan önizleme kartının en tepesine kadar uzanan şeffaf bir fare kapsama alanı (`acceptedButtons: Qt.NoButton`) oluşturulur.
   - Fare alt sınıra çarptığı an bu alan aktifleşir; fare Dock üzerinde, ikonların arasında veya önizleme kartındayken `dockIsHoveredOverall` sürekli `TRUE` kalır.
   - Fare bu zarftan çıktığı anda 350ms'lik debounce sayacı başlar ve Dock pürüzsüzce kapanır.

## 3. Uygulama Adımları
1. `shell/config.json` güncellemesi.
2. `shell/components/dock/DockItem.qml` ve `DockPreviewCard.qml` içerisine `resolveAppIcon` entegrasyonu.
3. `shell/shell.qml` içerisine kesintisiz `dockOverallHoverArea` zarfı ve reaktif hover kilit mantığının eklenmesi.
4. Test, derleme ve Obsidian dokümantasyonu.
