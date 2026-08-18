---
title: "Proposal: App Launcher Default Icon Resolution & Instant Wayland Keyboard Focus"
type: agent-thought
tags:
  - proposal/launcher
  - ui/launcher
  - icons/resolution
  - wayland/keyboard-focus
  - quickshell/qml
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[App-Launcher-Service]]"
  - "[[App-Launcher-Widget]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Style-Design-Tokens]]"
  - "[[Plan-Dynamic-Island-App-Launcher-Widget]]"
---

# Proposal: App Launcher Default Icon Resolution & Instant Wayland Keyboard Focus

> [!IDEA]
> Fixing the empty/invisible icon issue for desktop apps by enhancing backend XDG icon lookup, handling 0x0 empty pixmap fallback detection in QML, providing modern default SVG/PNG application icons, and enabling instant keyboard focus upon launcher opening via Wayland LayerShell `WlrKeyboardFocus.Exclusive` without requiring mouse clicks.

## Problem Analysis

1. **Missing / Blank Icons Issue:**
   - When Quickshell's image provider cannot find an icon in the theme, it returns a 0x0 empty texture with `Image.Ready`, causing `paintedWidth === 0`.
   - The QML fallback check previously only verified `status !== Image.Ready`, meaning 0x0 empty images were treated as "successfully rendered", resulting in completely invisible/blank icon slots.
   - Some `.desktop` files have extensions (`.png`/`.svg`), relative names in `/usr/share/pixmaps/`, or lack an `Icon=` field entirely (relying on app/binary name).
2. **Lack of Instant Keyboard Focus:**
   - In Wayland LayerShell, `WlrKeyboardFocus.OnDemand` requires a physical mouse click before keystrokes are routed to the surface.
   - Consequently, when opening the launcher via shortcut (`toggle_launcher.sh`), the user had to click the search bar before typing.

## Proposed Architecture & Improvements

1. **Wayland Keyboard Focus Fix (`shell/shell.qml` & `AppLauncherWidget.qml`)**:
   - Set `WlrLayershell.keyboardFocus: (island.stateMode === "EXPANDED" && island.expandedActiveTab === "LAUNCHER") ? WlrKeyboardFocus.Exclusive : ...`
   - Explicitly call `forceActiveFocus()` with lifecycle and deferred timer hooks on `searchInput`.
2. **Backend Icon Resolution (`core/services/launcher/parser.go`)**:
   - If `Icon=` is missing or empty, fallback to `ExecBinary` or base desktop ID.
   - Strip file extensions from icon names if looking up theme keys, and check `/usr/share/pixmaps/` for direct file paths.
3. **Multi-Tier Frontend Icon Fallback (`AppLauncherWidget.qml` & `shell/assets/icons/`)**:
   - True fallback condition: `appIcon.status !== Image.Ready || appIcon.paintedWidth === 0 || appIcon.paintedHeight === 0`.
   - Provide a sleek modern SVG/PNG default application icon in `shell/assets/icons/default_app.svg` and category-specific fallbacks.
   - Category-colored letter badges as ultimate fail-safe.
