---
title: "Plan: Fix Pinned Metrics Canvas Width Clipping in Hover Mode"
type: agent-thought
tags:
  - ui/widgets
  - quickshell/qml
  - metrics/hud
  - dynamic-island/ui
  - layout/clipping
created: 2026-08-30
updated: 2026-08-30
status: implemented
related_notes:
  - "[[Pinned-Metrics-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Control-Center-Widget]]"
  - "[[Configuration-System-Spec]]"
---

# Plan: Fix Pinned Metrics Canvas Width Clipping in Hover Mode

> [!IDEA]
> `shell/shell.qml` içerisindeki `islandWindow` PanelWindow bileşeninin sabit `implicitWidth: 1200` genişlik kısıtlamasını kaldırıp `anchors { top: true; left: true; right: true }` olarak güncelleyerek, Dynamic Island / Notch hover durumuna geçtiğinde genişleyen adanın sağında konumlanan `PinnedMetricsWidget` bileşeninin ve özellikle en sağdaki Ağ (NET) telemetri verisinin pencere sınırları tarafından kırpılmasını ("görünmez duvar" hissi) ortadan kaldırmak.

## Problem Statement

1. **Sabit 1200px Pencere Genişliği:** `islandWindow` `implicitWidth: 1200` ile ekranın ortasında sabit genişlikte bir Wayland katmanı oluşturmaktadır.
2. **Hover Modunda Taşma ve Kırpılma:**
   - Dynamic Island / Notch HOVER moduna geçtiğinde adanın genişliği ~490px'e çıkar.
   - Adanın merkezi x=600 noktasında olduğu için adanın sağ kenarı `x = 600 + 245 = 845px` olur.
   - `pinnedMetrics` (yaklaşık ~460px-480px genişliğinde) adanın sağ kenarından başladığında `x = 845 + 12 = 857px` noktasından `x = 1317px - 1337px` noktasına kadar uzanır.
   - Pencerenin sağ sınırı `x = 1200px` olduğu için aradaki 120px-140px'lik alan (en sağdaki `󰛳 NET <Hız>` göstergesi) pencere yüzey sınırının dışında kalarak görünmez hale gelir.

## Proposed Solution

1. **Tam Ekran Genişliğinde PanelWindow:**
   - `shell/shell.qml` içerisindeki `islandWindow` bileşeninin `anchors` bloğuna `left: true` ve `right: true` eklenerek katmanın monitör genişliğinin tamamını kaplaması sağlanır.
   - `mask: Region { item: activeInputEnvelope }` yapısı korunduğu için tam ekran genişliğinde bile tıklamalar arka plandaki pencerelere engelsizce aktarılır.
2. **Kırpılmasız Telemetri Görünümü:**
   - Ada genişlediğinde `pinnedMetrics` sağa doğru itilirken monitör sınırları içerisinde hiçbir "görünmez duvar" veya yüzey kırpılmasına takılmadan tüm CPU, RAM, GPU ve NET metriklerini net bir şekilde görüntüler.

## Affected Components

- `[[Shell-Root-PanelWindow]]` (`shell/shell.qml`)
- `[[Pinned-Metrics-Widget]]` (`shell/components/widgets/PinnedMetricsWidget.qml`)
- `[[Dynamic-Island-Component]]` (`shell/components/island/DynamicIsland.qml`)

## Implementation & Verification

1. **`shell/shell.qml` Güncellemesi:** `islandWindow` katmanının `anchors` bloğuna `left: true` ve `right: true` eklenip sabit `implicitWidth: 1200` kısıtı kaldırıldı.
2. **Kırpılmasız Görüntüleme:** Dynamic Island / Notch hover durumuna geçtiğinde adanın genişlemesiyle sağa doğru itilen `PinnedMetricsWidget` (özellikle en sağdaki Ağ / NET hız metriği) monitörün tam genişliği boyunca engelsizce ve görünmez duvara çarpmadan görüntülendi.
3. **Tıklama Geçirgenliği:** `mask: Region { item: activeInputEnvelope }` yapısı korunduğu için ada dışındaki tüm şeffaf alanlarda tıklamaların alt pencerelere engelsiz iletilmesi sağlandı.
