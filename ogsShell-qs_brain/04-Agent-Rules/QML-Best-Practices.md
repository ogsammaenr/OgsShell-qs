---
title: "Quickshell QML Best Practices & UI Standards"
type: rule
tags:
  - rules/qml
  - frontend/standards
  - quickshell
  - physics/animations
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Style-Design-Tokens]]"
  - "[[Agent-Workflow-Directives]]"
---

# Quickshell QML Best Practices & UI Standards

> [!NOTE]
> This document sets the declarative architecture, animation physics, Wayland LayerShell rules, and component standards for all Quickshell QML code under `shell/`.

---

## 1. Declarative Architecture & Reactive Bindings

1. **Declarative First:** Prefer declarative property bindings over imperative JavaScript loops and procedural event triggers.
2. **Implicit Geometry:** Every reusable widget must define its own `implicitWidth` and `implicitHeight` rather than hardcoding static coordinates.
3. **Modular Slot Pattern:** Widgets intended for the Dynamic Island must reside under `shell/components/widgets/` as standalone components, never embedded directly inside `DynamicIsland.qml`.

---

## 2. Animation & Physics Rules

1. **Spring Dynamics:** Following `[[Apple-Dynamic-Island-HIG]]`, avoid linear transitions. Always use `SpringAnimation` or `SmoothedAnimation` with the constants defined in `[[Style-Design-Tokens]]` (`spring: 28.0`, `damping: 0.78`, `epsilon: 0.01`).
2. **Smooth Reversing:** Enable `reversingMode: SmoothedAnimation.Eased` to ensure that interrupted animations redirect naturally without jump cuts.

---

## 3. Wayland LayerShell Standards

1. **Zero Tiling Disruption:** Always configure the top-level `PanelWindow` with `exclusionMode: ExclusionMode.Ignore`.
2. **Accurate Quickshell APIs:** Only use real Quickshell C++ bindings. Never hallucinate non-existent properties (such as `exclusionZone` or `WlrLayers.layer`).

---

## 4. Related Links

* Design System: `[[Style-Design-Tokens]]`
* Island Component: `[[Dynamic-Island-Component]]`
* Agent Workflow: `[[Agent-Workflow-Directives]]`
