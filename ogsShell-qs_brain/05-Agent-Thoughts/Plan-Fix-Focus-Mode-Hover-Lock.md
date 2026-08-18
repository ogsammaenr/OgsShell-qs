---
title: "Plan: Fix Focus Mode Dynamic Island Hover Lock"
type: agent-thought
tags:
  - ui/focus-mode
  - bugfix/hover-lock
  - quickshell/qml
  - dynamic-island/autohide
created: 2026-08-16
updated: 2026-08-16
status: implemented
related_notes:
  - "[[Plan-Focus-Mode-And-Smart-Autohide]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Focus Mode Dynamic Island Hover Lock

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Focus Mode açıkken adanın üzerinde fare gezdirildikten sonra adanın takılı kalıp kapanmaması sorunu, tekil reaktif koordinatör (`isHoveredOverall`), yaşam döngüsü senkronizasyonu ve `autoHideTimer` sinyal mekanizması ile kesin olarak çözüldü.

## 1. Problem ve Kök Neden
* `isTopHotspotHovered` ve `island.isIslandHovered` durumları arasındaki asenkron zamanlama uyuşmazlığı nedeniyle timer tetiklendiğinde `isTopHotspotHovered` durumu `true` olarak kilitleniyor ve ada bir daha yukarı saklanmıyordu.

## 2. Uygulanan Çözüm
* `isHoveredOverall: (topHotspotMouseArea && topHotspotMouseArea.containsMouse) || island.isIslandHovered` tekil reaktif durum değişkeni tanımlandı.
* `onIsHoveredOverallChanged`, `onShouldAutoHideChanged` ve `island.onStateModeChanged` sinyalleri ile `autoHideTimer` senkronize edildi.
* Hotspot algılama yüksekliği `12px`'e çıkarıldı.
* Ada `EXPANDED` modundan `IDLE` moduna döndüğünde fare adanın üzerinde değilse otomatik saklanma akışı sağlandı.

## 3. Güncellenen Dosyalar
* `shell/shell.qml`
