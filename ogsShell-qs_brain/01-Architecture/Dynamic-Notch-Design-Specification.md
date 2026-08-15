---
title: "Dynamic Notch Design Specification & Top-Bezel Integration"
type: architecture
tags:
  - architecture/notch
  - ui/dynamic-notch
  - macos/notch-design
  - quickshell/qml
  - anti-aliasing/msaa
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[System-Architecture]]"
  - "[[Configuration-System-Spec]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Plan-High-DPI-Anti-Aliasing-And-Proportional-Notch-Slope]]"
---

# Dynamic Notch Design Specification & Top-Bezel Integration

> [!NOTE]
> This document specifies the geometry, tall-slope $G^2$ Cubic Bézier vector topology, 8x MSAA high-DPI rendering, and state behaviors for the **Dynamic Notch** form-factor in `ogsShell-qs`.

---

## 1. Proportional Tall-Slope $G^2$ Bézier Curvature

To prevent excessive lateral extension and eliminate visual sharpness along the upper body, the top slope is engineered with a **tight horizontal spread** ($E_w = 5\text{px}$) and a **generous vertical drape** ($E_h \approx 45\%$ of notch height):

```text
       (0, 0)                                                    (2E+W, 0)
Tavan -----\                                                          /-----
            \  (Tall G2 Slope: 5px x 16px)      (Tall G2 Slope: 5px x 16px)/
          (E, E)                                                   (E+W, E)
            |                                                         |
            | (Left Wall)                                (Right Wall) |
            |                                                         |
        (E, H-R)                                                   (E+W, H-R)
            \                                                         /
             \ (Bottom-Left Corner: R)       (Bottom-Right Corner: R)/
           (E+R, H)-----------------------------------------------(E+W-R, H)
                                 (Bottom Edge)
```

---

## 2. 8x MSAA High-DPI Vector Anti-Aliasing

To guarantee razor-sharp Retina / 4K subpixel curve rendering without pixelation or aliasing artifacts:

```qml
layer.enabled: true
layer.samples: 8
layer.smooth: true
```

---

## 3. Related Links

* Dynamic Island Component: `[[Dynamic-Island-Component]]`
* Configuration Specification: `[[Configuration-System-Spec]]`
* Implementation Proposal: `[[Plan-High-DPI-Anti-Aliasing-And-Proportional-Notch-Slope]]`
