---
title: "Power Overlay Component Specification"
type: ui-component
tags:
  - ui/power-menu
  - ui/session-overlay
  - quickshell/layershell
  - pure-black/glass
created: 2026-08-16
updated: 2026-08-18
status: active
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
  - "[[Plan-Minimalist-Circular-Power-Overlay]]"
---

# Power Overlay Component Specification

> [!NOTE]
> Fullscreen Wayland LayerShell Overlay modal ([PowerOverlay.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/PowerOverlay.qml)) providing a minimalist dark glass background with 4 floating circular action buttons and on-hover dynamic labels for system session management.

---

## 1. Mimari Genel Bakış

Kutusal ağır kart yapısı yerine, sistem genelinde tam ekran katman (`WlrLayershell.layer: WlrLayer.Overlay`) olarak açılan, karartılmış ve saydam cam zemin üzerinde ortalanmış 4 dairesel aksiyon düğmesi ve üzerlerine gelindiğinde yumuşakça beliren alt etiketlerden oluşan minimalist güç menüsü.

```text
┌────────────────────────────────────────────────────────┐
│  Dark Translucent Backdrop (Qt.rgba(6, 7, 10, 0.72))   │
│                                                        │
│             (󰐥)       (󰜉)       (󰤄)       (󰍃)         │
│           [Kapat]   [Reboot]   [Uyku]    [Çıkış]       │
│                                                        │
│       [İptal için ESC tuşuna basın veya tıklayın]     │
└────────────────────────────────────────────────────────┘
```

---

## 2. Eylemler ve Sistem Komutları

| Buton | Glif | Vurgu Rengi | Sistem Komutu | Kısayol | Hover Etiketi |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Kapat** | `󰐥` | `Style.accentRed` | `systemctl poweroff` | `P` | Kapat |
| **Yeniden Başlat** | `󰜉` | `Style.accentOrange` | `systemctl reboot` | `R` | Yeniden Başlat |
| **Uyku Modu** | `󰤄` | `Style.accentCyan` | `systemctl suspend` | `S` | Uyku Modu |
| **Oturumu Kapat** | `󰍃` | `Style.accent` | `hyprctl dispatch exit` | `L` / `E` | Oturumu Kapat |

---

## 3. Etkileşim ve Klavye Odak Yönetimi

* **Dairesel Butonlar (96x96px):** Geniş yuvarlak cam tasarım (`radius: 48`), 38px ikonlar, hover durumunda ilgili tema aksiyon rengiyle parlar ve `scale: 1.10` büyür.
* **Dinamik Alt Etiketler:** Butonun üzerine gelindiğinde `opacity: 0.0 -> 1.0` ve `y: +4px -> 0px` animasyonu ile başlık pürüzsüzce açığa çıkar.
* **`PowerService.qml` Singleton:** Açılış ve kapanış durumunu yönetir.
* **`WlrKeyboardFocus.Exclusive`:** Açıldığında klavye odağını anında alarak `Esc` veya hızlı kısayol tuşlarıyla anında etkileşim sağlar.
* **Arka Plan Tıklaması:** Butonlar dışındaki karartılmış cam alana tıklandığında menü yumuşakça kapanır.

---

## 4. İlgili Bağlantılar

* Kontrol Merkezi: `[[Control-Center-Widget]]`
* Kabuk Kök Pencere: `[[Shell-Root-PanelWindow]]`
* Tasarım Tokenleri: `[[Style-Design-Tokens]]`
