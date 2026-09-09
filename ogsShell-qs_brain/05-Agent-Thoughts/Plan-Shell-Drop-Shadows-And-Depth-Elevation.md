---
title: "Plan: Shell Drop Shadows and Depth Elevation (Gölge ve Derinlik Mimarisi)"
type: agent-thought
tags:
  - plan/shadows
  - quickshell/qml
  - graphical-effects
  - dynamic-island/ui
  - corner-hud
  - config/schema
created: 2026-09-07
updated: 2026-09-07
status: implemented
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Corner-Island-HUD-Component]]"
  - "[[Screen-Corners-Component]]"
  - "[[Pinned-Metrics-Widget]]"
  - "[[Configuration-System-Spec]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Shell Drop Shadows and Depth Elevation (Gölge ve Derinlik Mimarisi)

> [!IDEA]
> ogsShell arayüz bileşenlerini (Floating Dynamic Island, Dynamic Notch, Corner Island HUD, Pinned Metrics) masaüstü duvar kağıdından optik olarak ayıran, Apple HIG standartlarında çift katmanlı (Key + Ambient) donanım hızlandırmalı yumuşak gölge (Drop Shadow & Glow Elevation) mimarisi eklemek.

---

## 1. Problem ve Tasarım Vizyonu

Mevcut durumda arayüz bileşenleri saf OLED siyah (`#000000`) gövdeye sahiptir ancak duvar kağıdının üzerinde doğrudan sıfır derinlikle durmaktadır.
Özellikle koyu renkli veya detaylı duvar kağıtlarında bileşenlerin sınırları silikleşebilmekte ve "havada süzülen yüzen arayüz (floating island)" hissi yeterince belirgin olmamaktadır.

### Hedefler:
1. **Masaüstünden Ayrılma (Floating Elevation):** Adaya ve köşe HUD'ına derinlik kazandırarak duvar kağıdından fiziksel olarak birkaç milimetre yukarıda süzülüyormuş hissi vermek.
2. **Duruma Göre Büyüyen Derinlik (Dynamic State Elevation):**
   - **IDLE/HOVER:** Kompakt gölge (`radius: 20px`, `offsetY: 4px`, `opacity: 0.45`).
   - **EXPANDED (Modallar/Uygulamalar):** Genişleyen modal kartı için derin masaüstü gölgesi (`radius: 36px`, `offsetY: 10px`, `opacity: 0.65`).
3. **Sıfır Tıklama Engeli (%100 Click-Through):** Gölgelerin taştığı Wayland katman alanları `mask: Region { item: activeInputEnvelope }` sayesinde alttaki uygulamaların tıklanmasını kesinlikle engellemez.
4. **Yapılandırılabilir ve Kapatılabilir (`config.json`):** Düşük donanımlı sistemler veya minimalist tercihler için gölgeler tek bir JSON anahtarı ile kapatılabilir veya opaklık/yarıçap ayarlanabilir.

---

## 2. Mimari Bileşenler ve Teknik Uygulama

* **`RectangularGlow` / `DropShadow` Entegrasyonu:**
  - `Qt5Compat.GraphicalEffects` / `QtQuick.Effects` modülleri kullanılarak GPU shader seviyesinde sıfır CPU yüküyle render edilir.
* **`DynamicIsland.qml`:**
  - Floating squircle ve genişletilmiş durumlar için reaktif `RectangularGlow` gölge katmanı.
  - Notch modunda alt yay ve dikey duvarlar için yumuşak falloff gölgesi.
* **`CornerIslandHUD.qml`:**
  - Sol-üst köşede açılan HUD kapsülü için alt/sağ yönlü dışbükey gölge.
* **`PinnedMetricsWidget.qml`:**
  - Pinned telemetry hapı için kompakt yumuşak gölge.
* **`shell/backend/Config.qml` & `shell/config.json`:**
  - `"shadows"` şema bloğu ve typed getter'lar.

---

## 3. İlgili Notlar

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Corner HUD: `[[Corner-Island-HUD-Component]]`
* Konfigürasyon Şeması: `[[Configuration-System-Spec]]`
* Shell Pencere Hiyerarşisi: `[[Shell-Root-PanelWindow]]`
