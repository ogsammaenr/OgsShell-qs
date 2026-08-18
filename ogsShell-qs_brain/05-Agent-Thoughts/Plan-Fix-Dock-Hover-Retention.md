---
title: "Plan: Fix Dock Hover Retention and State Lock"
type: agent-thought
tags:
  - ui/dock
  - quickshell/mousearea
  - hover/retention
  - autohide/latch
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

# Plan: Fix Dock Hover Retention and State Lock

> [!IDEA]
> Çocuk `DockItem` fare alanlarının üst kapsayıcıdan fare olayını yutması nedeniyle yaşanan erken kapanma sorununu reaktif `activeHoverCount` sayacı ve 400ms geçiş mandalı (reveal latch) ile kökten çözmek.

## 1. Kök Neden Analizi
* `DockItem` içindeki `itemMouseArea` nesneleri `containsMouse = true` aldığında, Qt Quick olay hiyerarşisi nedeniyle alttaki `pillMouseArea` ve pencere genelindeki `dockOverallHoverArea` `containsMouse = false` durumuna düşmekteydi.
* `bottomHotspotMouseArea` (4px) alanından yukarı ikonlara geçildiği anda sistem "fare ayrıldı" algılayarak 350ms sayacı başlatıyor ve fare ikon üzerindeyken Dock kayboluyordu.

## 2. Mimari Çözüm
1. **Reaktif İkon Hover Sayacı (`activeHoverCount` in `Dock.qml`):**
   - `Dock.qml` üzerinde `property int activeHoverCount: 0` tanımlanır.
   - Her `DockItem`'ın `isItemHovered` durumu değiştiğinde bu sayaç güncellenir.
   - `readonly property bool isDockHovered: pillMouseArea.containsMouse || activeHoverCount > 0`.
2. **Geçiş Mandalı (400ms Reveal Latch):**
   - Fare alta çarptığı an 400ms boyunca Dock zorunlu açık tutulur; bu süre farenin 4px hotspot'tan ikonların üzerine geçmesi için güvenli bir köprü oluşturur.
3. **Yumuşak Kapanış Gecikmesi (450ms Dismiss Debounce):**
   - Fare Dock'tan çıktığında 450ms bekleme süresi verilir.

## 3. Uygulama Adımları
1. `shell/components/dock/DockItem.qml` ve `Dock.qml` sayaç entegrasyonu.
2. `shell/shell.qml` zamanlayıcı ve zarf güncellemeleri.
3. Canlı test ve Obsidian dokümantasyonu.
