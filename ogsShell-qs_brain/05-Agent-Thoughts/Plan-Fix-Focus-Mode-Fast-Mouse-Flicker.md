---
title: "Plan: Fix Focus Mode Fast Mouse Flicker and Race Condition"
type: agent-thought
tags:
  - ui/focus-mode
  - bugfix/flicker
  - wayland/input-mask
  - quickshell/qml
  - dynamic-island/physics
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Plan-Fix-Focus-Mode-Hover-Lock]]"
  - "[[Plan-Focus-Mode-And-Smart-Autohide]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Focus Mode Fast Mouse Flicker and Race Condition

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Hızlı fare hareketinde Wayland input maskesi ile adanın iniş yay animasyonu arasındaki zamanlama yarışı; kesintisiz tepe-ada maske zarfı (`activeInputEnvelope`) ve 250ms reveal geçiş kilidi (`revealLatchTimer`) entegrasyonu ile tamamen ortadan kaldırıldı.

## 1. Problem ve Kök Neden
* Fare tepeye vurduğunda maske anında `island`'a geçiyordu; ancak ada henüz yukarıda (`y = -70`) olduğu için fare maske dışına düşüyor, `isHoveredOverall = false` oluyor ve ada daha inmeden yukarı kaçıp titriyordu (flicker loop).

## 2. Uygulanan Çözüm
* `activeInputEnvelope` ile ada açıkken tepeden adanın altına kadar kesintisiz birleşik maske alanı sağlandı (`height: island.y + island.height + 15`).
* `revealLatchTimer` (250ms) ile ada inerken erken kapanma engellendi.
* 450ms sakin debounce süresi ile farenin ayrılması son derece akıcı ve kararlı hale getirildi.

## 3. Güncellenen Dosyalar
* `shell/shell.qml`
