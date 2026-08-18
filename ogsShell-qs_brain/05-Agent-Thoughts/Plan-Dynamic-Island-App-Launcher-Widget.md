---
title: "Proposal: Dynamic Island Integrated App Launcher Widget & Global Script Trigger"
type: agent-thought
tags:
  - proposal/launcher
  - ui/launcher
  - dynamic-island/expanded
  - quickshell/qml
  - scripts/trigger
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[App-Launcher-Service]]"
  - "[[App-Launcher-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Backend-Endpoints-Reference]]"
---

# Proposal: Dynamic Island Integrated App Launcher Widget & Global Script Trigger

> [!IDEA]
> Expanding the Quickshell `DynamicIsland.qml` container into an intelligent, keyboard-navigable, sub-millisecond App Launcher view (`AppLauncherWidget.qml`) connected to the Go daemon launcher backend (`core/services/launcher`), and providing a standalone trigger script (`scripts/toggle_launcher.sh`) for global desktop keybindings.

## Problem Statement
While the Go daemon provides a sub-millisecond fuzzy search and launch backend, users need an intuitive, gorgeous frontend interface that opens from the Dynamic Island, provides instant keyboard focus, live fuzzy search results, keyboard arrow navigation, frecency badges, and a universal script to bind to Super/D or Super/Space shortcuts in Hyprland.

## Proposed Solution & UI Architecture

1. **Modular App Launcher Widget (`shell/components/widgets/launcher/AppLauncherWidget.qml`)**:
   - High-contrast search input with search glyph, live character reaction, clear button, and result counts.
   - Live synchronization with `DaemonIPC.qml` (`ipc.searchApps(query, 20)` and `ipc.requestAppsList(50)`).
   - Full keyboard navigation: Up/Down arrow selection, Enter to launch, Escape to dismiss/clear.
   - Smooth item delegates featuring desktop application icons, application name, generic category subtitles, and usage frecency indicators (`"Nx"`).
   - Clean empty state with helpful tips when no apps match.
2. **Dynamic Island Integration (`shell/components/island/DynamicIsland.qml`)**:
   - Support `expandedActiveTab: "LAUNCHER"`.
   - Dedicated geometric sizing: `width: 540`, `height: 460`.
   - Lazy-loaded `Loader` hosting `AppLauncherWidget`.
   - Reacting to IPC `toggle_launcher` / `open_launcher` signals.
3. **Wayland Input & Keyboard Focus (`shell/shell.qml`)**:
   - Expanded input envelope height adjusted to cover 460px+ height.
   - Proper `WlrKeyboardFocus.OnDemand` focus propagation.
4. **Trigger Script (`scripts/toggle_launcher.sh` & `scripts/open_launcher.sh`)**:
   - Lightweight bash script transmitting `{"name":"toggle_launcher","args":{}}` over `$XDG_RUNTIME_DIR/ogs_shell.sock`.
   - Ready to bind in Hyprland (`bind = $mainMod, Space, exec, .../scripts/toggle_launcher.sh`).

## Affected Components
- `shell/components/widgets/launcher/AppLauncherWidget.qml`
- `shell/components/island/DynamicIsland.qml`
- `shell/backend/DaemonIPC.qml`
- `shell/shell.qml`
- `core/main.go` (handling `toggle_launcher` and `open_launcher` RPC actions)
- `scripts/toggle_launcher.sh` & `scripts/open_launcher.sh`
- Documentation (`ogsShell-qs_brain/03-UI-Components/App-Launcher-Widget.md`, `.agents/BACKEND_ENDPOINTS.md`)
