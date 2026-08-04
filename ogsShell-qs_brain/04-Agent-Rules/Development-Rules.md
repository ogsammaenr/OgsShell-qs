---
title: "Development Rules & Coding Standards"
type: rule
tags:
  - rules/development
  - rules/coding
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[Obsidian-Brain-Rules]]"
---

# Development Rules & Coding Standards

> [!IMPORTANT]
> Mandatory coding guidelines for all human developers and AI coding agents working on the OgsShell-qs repository.

## 1. Architectural Standards

- **Service-Window-Component Pattern:** Monolithic QML structures are strictly prohibited.
  - Data processing, C daemons, D-Bus, and process management -> `shell/services/`
  - Quickshell `PanelWindow` definitions -> `shell/windows/`
  - Visual interfaces and widgets -> `shell/components/`
- **Multi-Monitor Window Registration:** Every window must be registered inside `shell/windows/MonitorGroup.qml` to replicate across connected displays (except global singletons like power menu).

## 2. Coding Rules & Shadowing Prevention

- **Screen Property Shadowing Rule:** Do NOT define custom QML properties named `screen` inside Quickshell windows. Always use `targetScreen` property and bind `screen: targetScreen`.
- **Global Service Access:** Sub-components must not spawn inline `Process` daemons directly. Declare a global service in `shell/services/` and bind properties centrally.
- **Dynamic Binary Paths:** Always resolve binaries via `binDir` (`Quickshell.env("ROOT_DIR") + "/bin"`).

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Obsidian Brain Rules: `[[Obsidian-Brain-Rules]]`
