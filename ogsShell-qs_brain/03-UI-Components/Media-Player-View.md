---
title: "Media Player View Component Specification"
type: ui-component
tags:
  - ui/media-player
  - dynamic-island/expanded
  - mpris/player
  - apple-hig/material-ui
  - marquee/animation
created: 2026-08-18
updated: 2026-08-18
status: active
related_notes:
  - "[[Media-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Apple-HIG-Minimal-Design-System]]"
  - "[[Style-Design-Tokens]]"
  - "[[Plan-Dynamic-Island-Media-Player-App]]"
---

# Media Player View Component Specification

> [!NOTE]
> `shell/components/widgets/media/MediaPlayerView.qml` provides an Apple HIG and Material Design 3 inspired rich media player experience inside the expanded Dynamic Island (`390x170px`), featuring album cover art, animated marquee title scrolling, track duration/progress tracking, and playback controls.

---

## 1. Mimari ve Düzen Yapısı

Medya oynatıcısı, Dynamic Island `EXPANDED` durumuna geçtiğinde sol tarafta 84x84px albüm kapağı ve sağ tarafta parça detayları, kayan başlık, süre çubuğu ve kontrol düğmelerinden oluşan iki sütunlu bir kart düzeni kullanır:

```text
┌────────────────────────────────────────────────────────┐
│  ┌──────────┐  Mönülerin gizemi (Marquee Scroll) ──►  │
│  │          │  hafif programming             [Firefox] │
│  │  Cover   │  ━━━━━━━━━━●━━━━━━━━━━━━━━━━━            │
│  │   Art    │  01:14                             04:07 │
│  │ (84x84)  │                                          │
│  │          │          (󰒮)      (󰏤)      (󰒭)          │
│  └──────────┘         [Geri]  [Oynat]   [İleri]        │
└────────────────────────────────────────────────────────┘
```

---

## 2. Temel Yetenekler ve Tasarım Standartları

1. **Albüm Kapağı (Cover Art & Fallback):**
   - `MprisPlayer.trackArtUrl` (veya `artUrl`) adresi üzerinden kapağı `Image.PreserveAspectCrop` ile yükler.
   - Kapak bulunmadığında veya yüklenemediğinde degradeli yüzey üzerinde `󰝚` müzik ikonu gösterilir.
2. **Kayan Yazı (Marquee Text Engine):**
   - Şarkı başlığı ayrılan genişliği aştığında (`implicitWidth > marqueeContainer.width`) ve parça oynatılıyorsa (`isPlaying`), `SequentialAnimation` metni sağdan sola akıcı bir şekilde kaydırır (`Math.max(2500, overflowWidth * 35)` ms).
   - Başta ve sonda 1.8 saniye duraklayarak okuma kolaylığı sağlar; duraklatıldığında başlık sıfırlanır (`x = 0`).
3. **İnteraktif Zaman Çubuğu:**
   - Şarkının geçen süresi (`formatTime(position)`) ve toplam süresi (`formatTime(length)`) görüntülenir.
   - İlerleme çubuğuna tıklandığında `activePlayer.setPosition(targetPos)` çağrılarak şarkı sarılabilir.
4. **Oynatma Kontrolleri:**
   - **Geri (`󰒮`):** Önceki parçaya geçer (`previous()`).
   - **Oynat / Duraklat (`󰐊` / `󰏤`):** 38x38px dairesel vurgulu ana buton (`togglePlaying()`).
   - **İleri (`󰒭`):** Sonraki parçaya geçer (`next()`).
5. **Boş Durum (Empty State):**
   - Çalan bir medya veya aktif oynatıcı bulunmadığında "Medya Çalınmıyor" durum kartı görüntülenir.

---

## 3. İlgili Bağlantılar

* Medya Durum Widget'ı: `[[Media-Widget]]`
* Dinamik Ada Ana Bileşeni: `[[Dynamic-Island-Component]]`
* Tasarım Tokenleri: `[[Style-Design-Tokens]]`
* Plan Düşünce Notu: `[[Plan-Dynamic-Island-Media-Player-App]]`
