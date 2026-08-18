---
title: "Plan: Per-Monitor Focus Mode and Independent Autohide"
type: agent-thought
tags:
  - ui/focus-mode
  - ui/multi-monitor
  - hyprland/workspaces
  - quickshell/variants
  - dynamic-island/autohide
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Plan-Focus-Mode-And-Smart-Autohide]]"
  - "[[Plan-Multi-Monitor-Dynamic-Island]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Per-Monitor Focus Mode and Independent Autohide

> [!IDEA]
> Focus Mode (Odak Modu) açıkken adanın gizlenme/görünme durumunu global `Hyprland.focusedWorkspace` yerine her monitörün kendi aktif çalışma alanına (`hyprMonitor.activeWorkspace`) bağlayarak çoklu monitörlerde bağımsız ve monitöre özel akıllı gizleme sağlamak.

## 1. Problem Tanımı ve Kullanıcı Talebi
* Çoklu monitör kurulumlarında Odak Modu (Focus Mode) aktifken:
  * Fare uygulama açık olan bir ekrandan (örn. Monitör A) uygulama olmayan boş bir ekrana (Monitör B) kaydırıldığında, ada her iki monitörde de görünür hale gelmektedir.
  * Fare uygulama açık olan ekrana (Monitör A) geri kaydırıldığında ise ada her iki monitörde de birden kaybolmaktadır.
* **İstenen Davranış:** Bu özelliğin her monitöre özel olması:
  * Uygulama açık olan monitörde ada gizli kalmalı (autohide).
  * Uygulama olmayan (boş masaüstü) monitörde ada görünür kalmalı.

## 2. Kök Neden Analizi (Root Cause)
* `shell/shell.qml` içerisindeki `Variants { model: Quickshell.screens }` döngüsünde `screenScope.hasTilingWindows` özelliği şu şekilde yazılmıştı:
  ```qml
  if (!Hyprland.focusedWorkspace) return false
  let curWsId = Hyprland.focusedWorkspace.id
  ```
* `Hyprland.focusedWorkspace` tüm sistem genelinde o an klavye/fare odağına sahip olan tek bir çalışma alanını (workspace) temsil eder.
* Dolayısıyla fare hangi ekrana geçerse, o ekranın çalışma alanı global olarak odaklanmakta ve tüm ekranlardaki ada örnekleri aynı global çalışma alanının pencere durumuna göre eşzamanlı olarak açılıp kapanmaktaydı.

## 3. Mimari Çözüm ve Uygulama Adımları

1. **Monitör Eşleştirmesi:**
   * `Hyprland.monitorFor(screenScope.modelData)` veya `screenScope.modelData.name` ile `Hyprland.monitors.values` taranarak ilgili ekrana ait `HyprlandMonitor` nesnesi elde edilir.
2. **Monitöre Özel Aktif Çalışma Alanı:**
   * İlgili monitörün kendi aktif çalışma alanı `hyprMonitor.activeWorkspace` olarak okunur.
3. **Monitöre Özel Tiling Pencere Denetimi (`hasTilingWindows`):**
   * Yalnızca bu monitörün `activeWorkspace.id` değerine sahip olan pencereler incelenir.
   * `floating: false` ve `hidden: false` olan tiling pencereler varsa ilgili ekran için `hasTilingWindows = true`, yoksa `false` olur.
4. **Bağımsız Autohide / Reveal Döngüsü:**
   * Her ekran kendi `hasTilingWindows` ve `shouldAutoHide` değerine göre bağımsız olarak adasını saklar veya gösterir.

## 4. Etkilenen Dosyalar
* `shell/shell.qml`
* `ogsShell-qs_brain/03-UI-Components/Shell-Root-PanelWindow.md`
* `ogsShell-qs_brain/03-UI-Components/Dynamic-Island-Component.md`
* `.agents/ARCHITECTURE.md`
