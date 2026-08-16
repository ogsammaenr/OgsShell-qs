---
title: "Style Design Tokens Specification"
type: ui-component
tags:
  - ui/styling
  - theme/dynamic-sync
  - oled/pure-black
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
---

# Style Design Tokens Specification

> [!NOTE]
> Centralized design token system ([Style.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/theme/Style.qml)) managing dynamic theme color synchronization, geometry constants, and spring/bezier animation parameters.

---

## 1. Pure OLED Black Silhouette & Dynamic Accent Architecture

Adanın ve ada içerisindeki tüm bileşenlerin tema mimarisi iki temel prensibe dayanır:
1. **Tavizsiz Saf Siyah Arka Plan (`#000000`):** Apple Dynamic Island HIG standartlarına uygun olarak ada gövdesi (`bgPrimary` ve `bgSecondary`) hangi sistem teması seçilirse seçilsin daima `#000000` saf OLED siyah kalır.
2. **Reaktif Cam Katmanları & Vurgular:** Kenarlıklar, cam paneller (`surface`, `surfaceVariant`, `surfaceActive`), tipografi ve semantik butonlar seçilen temanın renk paletine anında uyum sağlar.

---

## 2. Token Sözlüğü (Token Matrix)

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

## 3. Desteklenen Sistem Temaları

1. **Everforest Dark (`everforest`):** `#a7c080` (Accent), `#d3c6aa` (FG), `#83c092` (Cyan)
2. **Catppuccin Macchiato (`catppuccin`):** `#c6a0f6` (Mauve Accent), `#cad3f5` (FG), `#8aadf4` (Blue)
3. **Tokyo Night (`tokyonight`):** `#7aa2f7` (Tokyo Blue), `#c0caf5` (FG), `#7dcfff` (Cyan)
4. **Nord (`nord`):** `#88c0d0` (Frost Cyan), `#eceff4` (FG), `#8fbcbb` (Ice)
5. **Gruvbox Dark (`gruvbox`):** `#fe8019` (Orange Accent), `#ebdbb2` (FG), `#8ec07c` (Aqua)
6. **Monochrome Minimal (`monochrome`):** `#e0e0e0` (Silver White), `#f0f0f0` (FG), `#ffffff` (White)

---

## 4. İlgili Bağlantılar

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Dynamic Notch: `[[Dynamic-Notch-Design-Specification]]`
* Tema Servisi: `[[Theme-Service]]`
* IPC İstemcisi: `[[Daemon-IPC-Client]]`
