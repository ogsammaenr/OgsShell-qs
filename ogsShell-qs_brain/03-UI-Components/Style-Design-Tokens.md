---
title: "Style Design Tokens Specification"
type: ui-component
tags:
  - ui/styling
  - theme/dynamic-sync
  - oled/pure-black
  - ui/typography
  - animation/spring
created: 2026-08-09
updated: 2026-08-16
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Theme-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Control-Center-Widget]]"
  - "[[Clock-Manager]]"
  - "[[Plan-Typography-Scale-And-Readability-Optimization]]"
---

# Style Design Tokens Specification

> [!NOTE]
> Centralized design token system ([Style.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/theme/Style.qml)) managing dynamic theme color synchronization, typography scale hierarchy, geometry constants, and spring/bezier animation parameters.

---

## 1. Pure OLED Black Silhouette & Dynamic Accent Architecture

Adanın ve ada içerisindeki tüm bileşenlerin tema mimarisi iki temel prensibe dayanır:
1. **Tavizsiz Saf Siyah Arka Plan (`#000000`):** Apple Dynamic Island HIG standartlarına uygun olarak ada gövdesi (`bgPrimary` ve `bgSecondary`) hangi sistem teması seçilirse seçilsin daima `#000000` saf OLED siyah kalır.
2. **Reaktif Cam Katmanları & Vurgular:** Kenarlıklar, cam paneller (`surface`, `surfaceVariant`, `surfaceActive`), tipografi ve semantik butonlar seçilen temanın renk paletine anında uyum sağlar.

---

## 2. Tipografi Ölçeği (Typography Scale Hierarchy)

| Tipografi Düzeyi | Boyut (`pixelSize`) | Yazı Tipi Ağırlığı | Kullanım Alanı |
| :--- | :--- | :--- | :--- |
| **Micro Caption / Status** | `10px - 10.5px` | `Font.Medium` | Zaman damgaları, alt ipuçları, rozetler |
| **Subtext / List Caption** | `10.5px - 11.5px`| `Font.Medium / Bold` | Pano karakter sayısı, Wi-Fi sinyali, DND butonu |
| **Body / List Item** | `12px - 12.5px` | `Font.Medium / DemiBold`| Pano önizleme metni, bildirim başlığı, Wi-Fi adı |
| **Section Title** | `12.5px - 13.5px`| `Font.Bold` | Modül başlıkları, alt uygulama başlıkları, diyalog butonları |
| **Modal / Window Title** | `14px - 16px` | `Font.Bold` | Güç menüsü başlığı, Ay/Yıl takvim başlığı, Pano tam ekran başlığı |
| **Glyph / Vector Icon** | `13px - 22px` | `Nerd Font` | Aksiyon ikonları, telemetri sembolleri, ada HUD glifleri |

---

## 3. Renk Token Sözlüğü (Color Token Matrix)

| Token | Değer / Davranış | Kullanım Amacı |
| :--- | :--- | :--- |
| `bgPrimary` | `#000000` (Değişmez) | Ada ve Notch için saf OLED siyah arka plan silüeti |
| `bgSecondary` | `#000000` (Değişmez) | Genişletilmiş (EXPANDED) modal kart zemin rengi |
| `surface` | `Qt.rgba(textPrimary, 0.06)` | Saydam cam widget konteyner arka planı |
| `surfaceVariant`| `Qt.rgba(textPrimary, 0.10)` | İkincil interaktif kart ve girdi alanı zemini |
| `surfaceHover` | `Qt.rgba(textPrimary, 0.16)` | Hover durumunda cam parlaklığı |
| `surfaceActive`| `Qt.rgba(accent, 0.24)` | Aktif / seçili buton ve segment zemin dolgusu |
| `border` | `Qt.rgba(textPrimary, 0.12)` | İç kart ve ayraç kenarlıkları |
| `borderHover` | `Qt.rgba(accent, 0.40)` | Hover kenarlık vurgusu |
| `textPrimary` | `activePalette.fg` | Temanın birincil yüksek kontrastlı metin rengi |
| `textSecondary`| `Qt.rgba(textPrimary, 0.68)` | İkincil açıklama ve etiket metinleri |
| `textMuted` | `Qt.rgba(textPrimary, 0.42)` | Pasif / sönük durum metinleri |
| `accent` | `activePalette.accent` | Temanın ana semantik vurgusu |
| `accentSecondary`| `activePalette.accentSecondary` | İkincil vurgu tonu |
| `accentCyan` | `activePalette.accentCyan` | Saat, Wi-Fi ve canlı durum vurguları |
| `accentGreen` | `activePalette.accentGreen` | Kronometre, RAM ve aktif telemetri |
| `accentOrange` | `activePalette.accentOrange` | Pomodoro, GPU ve uyarılar |
| `accentRed` | `activePalette.accentRed` | Alarm, iptal, silme ve tehlike aksiyonları |

---

## 4. Desteklenen Sistem Temaları

1. **Everforest Dark (`everforest`):** `#a7c080` (Accent), `#d3c6aa` (FG), `#83c092` (Cyan)
2. **Catppuccin Macchiato (`catppuccin`):** `#c6a0f6` (Mauve Accent), `#cad3f5` (FG), `#8aadf4` (Blue)
3. **Tokyo Night (`tokyonight`):** `#7aa2f7` (Tokyo Blue), `#c0caf5` (FG), `#7dcfff` (Cyan)
4. **Nord (`nord`):** `#88c0d0` (Frost Cyan), `#eceff4` (FG), `#8fbcbb` (Ice)
5. **Gruvbox Dark (`gruvbox`):** `#fe8019` (Orange Accent), `#ebdbb2` (FG), `#8ec07c` (Aqua)
6. **Monochrome Minimal (`monochrome`):** `#e0e0e0` (Silver White), `#f0f0f0` (FG), `#ffffff` (White)

---

## 5. İlgili Bağlantılar

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Dynamic Notch: `[[Dynamic-Notch-Design-Specification]]`
* Tema Servisi: `[[Theme-Service]]`
* IPC İstemcisi: `[[Daemon-IPC-Client]]`
* Tipografi Planı: `[[Plan-Typography-Scale-And-Readability-Optimization]]`
