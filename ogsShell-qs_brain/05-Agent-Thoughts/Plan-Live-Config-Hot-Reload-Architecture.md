---
title: "Plan: Live Config Hot-Reload Architecture"
type: agent-thought
tags:
  - architecture/config
  - config/json
  - quickshell/qml
  - hot-reload
  - dynamic-island
  - dynamic-notch
created: 2026-08-26
updated: 2026-08-26
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Dynamic-Notch-Design-Specification]]"
  - "[[Style-Design-Tokens]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Live Config Hot-Reload Architecture

> [!IDEA]
> Implement a 100% pure QML live hot-reloading architecture in `Config.qml` that instantaneously applies edits in `shell/config.json` (form factor, theme, geometry, typography, animation) to all active windows and widgets with zero shell restart and complete inotify inode-safety.

## 1. Problem Statement
When developers or users modify `shell/config.json` (e.g. changing `"form_factor": "notch"` or `"theme": "nord"` or adjusting typography sizes), the shell must react instantly. Inode swaps by certain editors and sub-object property evaluation in QML can sometimes prevent immediate visual feedback unless direct reactive bindings and inode-safe watchers are in place.

## 2. Solution Architecture
1. **First-Class Typed Reactive Properties in `Config.qml`:**
   Expose direct reactive properties for typography, geometry, form factor, and animation to guarantee immediate Qt Quick binding propagation.
2. **Direct Theme Binding:**
   Hook `theme` changes directly into `Style.applyThemeById(root.theme)`.
3. **Resilient Inode-Safe File Watching:**
   Maintain two `FileView` watchers (`shell/config.json` and `~/.config/ogsShell/config.json`) backed by a lightweight debounce sync and reload fallback.
4. **Window and Spacer Dynamic Adaptation:**
   Ensure `reservedSpacerWindow`, `activeInputEnvelope`, and `DynamicIsland` vector shapes react smoothly to form factor and height changes.

## 3. Affected Components
- `[[Configuration-System-Spec]]` (`shell/backend/Config.qml`)
- `[[Style-Design-Tokens]]` (`shell/theme/Style.qml`)
- `[[Dynamic-Island-Component]]` (`shell/components/island/DynamicIsland.qml`)
- `[[Shell-Root-PanelWindow]]` (`shell/shell.qml`)

## 4. Implementation Summary
- Refactored `[[Configuration-System-Spec]]` (`shell/backend/Config.qml`) with first-class typed properties (`islandIdleHeight`, `notchIdleHeight`, `clockIdleSize`, etc.), hash-guarded two-way disk synchronization, and an inode-safe heartbeat checker.
- Integrated automatic theme dispatch: changing `"theme"` in `config.json` directly invokes `Style.applyThemeById()`.
- Updated `[[Shell-Root-PanelWindow]]` (`shell/shell.qml`), `[[Dynamic-Island-Component]]` (`shell/components/island/DynamicIsland.qml`), and widgets (`ClockWidget`, `PinnedMetricsWidget`, `ConnectivityStatusWidget`, `MediaWidget`) to bind directly to typed `Config` properties.
- Verified 100% clean `qmllint` across all shell components with zero warnings.
