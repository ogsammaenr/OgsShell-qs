---
title: "Power Overlay Component Specification"
type: ui-component
tags:
  - ui/power-menu
  - ui/session-overlay
  - quickshell/layershell
  - pure-black/glass
created: 2026-08-16
updated: 2026-08-16
status: active
related_notes:
  - "[[Control-Center-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[System-Architecture]]"
---

# Power Overlay Component Specification

> [!NOTE]
> Fullscreen Wayland LayerShell Overlay modal ([PowerOverlay.qml](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/shell/components/widgets/controlcenter/PowerOverlay.qml)) providing high-contrast dark glass background and central large action cards for system session management.

---

## 1. Mimari Genel Bakış

Eski dar adaya gömülü liste yerine, sistem genelinde tam ekran katman (`WlrLayershell.layer: WlrLayer.Overlay`) olarak açılan, hafif karartılmış saydam cam arka plan üzerinde ortalanmış 4 ana aksiyon kartı sunan modern güç menüsü.

```text
┌────────────────────────────────────────────────────────┐
│  Dark Translucent Backdrop (Qt.rgba(0, 0, 0, 0.72))    │
│                                                        │
│       ┌─────────────────────────────────────────┐      │
│       │           Güç ve Oturum Kartı           │      │
│       │  [Kapat] [Yeniden Başlat] [Uyku] [Çıkış]│      │
│       │               [Vazgeç (ESC)]            │      │
│       └─────────────────────────────────────────┘      │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 2. Eylemler ve Sistem Komutları

| Buton | Vurgu Rengi | Sistem Komutu | Kısayol |
| :--- | :--- | :--- | :--- |
| **Kapat** | `Style.accentRed` | `systemctl poweroff` | `P` |
| **Yeniden Başlat** | `Style.accentOrange` | `systemctl reboot` | `R` |
| **Uyku Modu** | `Style.accentCyan` | `systemctl suspend` | `S` |
| **Oturumu Kapat** | `Style.accent` | `hyprctl dispatch exit` | `L` / `E` |
| **Vazgeç** | `Style.textSecondary` | Modal Kapatma (`close()`) | `Escape` |

---

## 3. Etkileşim ve Klavye Odak Yönetimi

* **`PowerService.qml` Singleton:** Açılış ve kapanış durumunu yönetir.
* **`WlrKeyboardFocus.Exclusive`:** Açıldığında klavye odağını anında alarak `Esc` veya hızlı kısayol tuşlarıyla anında etkileşim sağlar.
* **Arka Plan Tıklaması:** Kart dışındaki karartılmış cam alana tıklandığında menü yumuşakça kapanır.

---

## 4. İlgili Bağlantılar

* Kontrol Merkezi: `[[Control-Center-Widget]]`
* Kabuk Kök Pencere: `[[Shell-Root-PanelWindow]]`
* Tasarım Tokenleri: `[[Style-Design-Tokens]]`
