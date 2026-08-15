---
title: "Proposal: True Asymmetrical Notch Curvature & Top-Bezel Integration"
type: agent-thought
tags:
  - proposal/notch-geometry
  - ui/asymmetrical-radius
  - macos/notch-fillets
  - quickshell/qml
created: 2026-08-09
updated: 2026-08-09
status: implemented
related_notes:
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Configuration-System-Spec]]"
---

# Proposal: True Asymmetrical Notch Curvature & Top-Bezel Integration

> [!NOTE]
> Implementation completed. The Dynamic Notch now implements authentic asymmetrical corner curvature: flat top edge with zero top radius, seamless bezel merger (no top border line), curved bottom corners, and concave lateral ear fillets transitioning smoothly into the screen ceiling.

## 1. Summary of Delivered Fixes
1. **Asymmetrical Corner Radius:** Utilized negative top margin clipping (`anchors.topMargin: Config.isNotch ? -activeRadius : 0`) inside a clipped viewport to clip the top rounded corners and top border stroke, creating a 100% straight edge against the monitor bezel while keeping bottom corners rounded ($20\text{px}-26\text{px}$).
2. **Concave Ear Fillets:** Rendered dynamic $14\text{px}$ Canvas ear fillets at the top-left and top-right junctions with keyline strokes, replicating MacBook Pro / NotchNook hardware integration.
3. **Seamless Theme Synchronization:** Canvas ear colors and border lines automatically re-paint when the island theme or state changes.

## 2. Status
* **Status:** `implemented`
