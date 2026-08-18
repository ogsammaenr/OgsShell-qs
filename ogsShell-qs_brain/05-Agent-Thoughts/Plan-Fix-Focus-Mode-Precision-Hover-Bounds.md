---
title: "Plan: Fix Focus Mode Precision Hover Bounds"
type: agent-thought
tags:
  - ui/focus-mode
  - bugfix/hover-bounds
  - wayland/input-mask
  - quickshell/qml
  - dynamic-island/geometry
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Plan-Ultra-Smooth-Focus-Mode-Animation]]"
  - "[[Plan-Fix-Focus-Mode-Fast-Mouse-Flicker]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Focus Mode Precision Hover Bounds

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Focus Mode aktifken farenin adanın dışına çıkmasına rağmen ekranın üst yarısında adanın kapanmaması sorunu, hover alanını tam adanın gövdesi (`island.isIslandHovered`) ve 12px ince tepe şeridi ile sınırlandırılarak kesin olarak çözüldü.

## 1. Problem ve Kök Neden
* `activeInputEnvelope` yüksekliği `360px` yapılmış ve `envelopeMouseArea` bu tüm 360 piksellik devasa dikdörtgeni kaplamıştı. Bu nedenle fare adanın çok aşağısında gezinirken dahi ada açık kalıyordu.

## 2. Uygulanan Çözüm
* `topHotspot` sadece 12px'lik ince üst şeridi izleyecek şekilde sınırlandırıldı.
* Ada gövdesi üzerindeki hover adanın kendi `island.isIslandHovered` özelliği ile takip edilir.
* Wayland maske alanı (`activeInputEnvelope`) adanın gerçek boyutuna tam oturtuldu (`island.y + island.height + 6`).
* Fare adadan çıktığı an 350ms içinde ada yukarı saklanır.

## 3. Güncellenen Dosyalar
* `shell/shell.qml`
