---
title: "Plan: Minimalist Circular Power & Session Overlay Redesign"
type: agent-thought
tags:
  - ui/power-menu
  - ui/session-overlay
  - quickshell/qml
  - minimal/design
created: 2026-08-18
updated: 2026-08-18
status: implemented
related_notes:
  - "[[Power-Overlay-Component]]"
  - "[[Control-Center-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Plan: Minimalist Circular Power & Session Overlay Redesign

> [!IDEA]
> Güç ve oturum menüsünü (`PowerOverlay.qml`) ağır kutusal kart tasarımından arındırarak, hafif karartılmış/blurlu saydam tam ekran zemin üzerinde ortalanmış 4 zarif yuvarlak buton ve butonların üzerine gelindiğinde (hover) yumuşakça beliren metin etiketlerinden oluşan minimalist bir yapıya dönüştürmek.

## User Request & Vision

1. **Arka Plan:** Hafif koyu, saydam ve blurlu tam ekran zemin (boşluğa tıklanınca menü kapanacak).
2. **Ortalanmış 4 Yuvarlak Buton:**
   - 󰐥 **Kapat** (`systemctl poweroff` - Kısayol: `P`)
   - 󰜉 **Yeniden Başlat** (`systemctl reboot` - Kısayol: `R`)
   - 󰤄 **Uyku Modu** (`systemctl suspend` - Kısayol: `S`)
   - 󰍃 **Oturumu Kapat** (`hyprctl dispatch exit` - Kısayol: `L` / `E`)
3. **Hover Dinamiği:** Butonun üzerine gelindiğinde altındaki açıklama metni yumuşak bir fade/slide animasyonu ile görünür olacak; buton hafifçe büyüyecek (`scale: 1.12`) ve vurgu rengiyle parlayacak.

## Technical Design & Architecture

1. **Tam Ekran Katman (`PowerOverlay.qml`):**
   - Dış çerçeve ve ağır `dialogCard` dikdörtgeni tamamen kaldırıldı.
   - `backdrop`: Hafif koyu, saydam cam zemin (`Qt.rgba(6/255, 7/255, 10/255, 0.72)`). Boş alana tıklanması durumunda `PowerService.close()` çağrılır.
2. **Merkezi Dairesel Buton Grubu:**
   - Ekranın tam ortasında yatay `RowLayout` düzeninde 4 dairesel aksiyon düğmesi (`width: 72`, `height: 72`, `radius: 36`).
   - Buton stili:
     - Normal: `Qt.rgba(24/255, 26/255, 32/255, 0.75)`, ince saydam kenarlık (`border: 1px`, `Qt.rgba(255, 255, 255, 0.12)`).
     - Hover: Aksiyon rengine göre boyanmış arka plan (`Qt.rgba(accent.r, accent.g, accent.b, 0.22)`), parlayan renkli kenarlık (`accent`), `scale: 1.12`.
     - Icon: 28px Nerd Font glifi, hover durumunda aksiyon rengine bürünür.
3. **Alt Etiket Alanı (On-Hover Reveal):**
   - Her düğmenin altında sabit aralıklı metin alanı.
   - Normalde `opacity: 0.0`, `y: 4px`.
   - Hover durumunda `opacity: 1.0`, `y: 0px` (yumuşak `Easing.OutCubic` geçişi).
4. **Klavye Desteği:**
   - `ESC`: Kapat / İptal
   - `P`, `R`, `S`, `L` / `E`: İlgili eylemi tetikler.
5. **Alt İptal İpucu:**
   - Ekranın alt kısmında çok hafif ve zarif bir "İptal etmek için ESC tuşuna basın veya boşluğa tıklayın" ipucu.

## Implementation Summary & Verification

- **QML Yeniden Tasarlandı:** [`PowerOverlay.qml`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/PowerOverlay.qml) dosyası kutusal karttan arındırılarak 4 adet 72x72px yuvarlak buton ve on-hover dinamik alt etiketlerle güncellendi.
- **Doğrulama:** `qmllint` sözdizim testinden başarıyla geçti. Quickshell servisi yeniden başlatıldı, hiçbir hata veya uyarı üretmeden canlı olarak yüklendi.
- **Dokümantasyon:** `[[Power-Overlay-Component]]` ve `.agents/ARCHITECTURE.md` güncellendi.
