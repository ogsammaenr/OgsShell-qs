---
title: "Dynamic Island App Launcher Widget"
type: ui-component
tags:
  - ui/launcher
  - dynamic-island/expanded
  - quickshell/qml
  - fuzzy/search
  - keyboard/navigation
created: 2026-08-17
updated: 2026-08-17
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Component]]"
  - "[[App-Launcher-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[Plan-Dynamic-Island-App-Launcher-Widget]]"
---

# Dynamic Island App Launcher Widget

Quickshell QML user interface component embedded in the **Dynamic Island** (`expandedActiveTab === "LAUNCHER"`), providing instantaneous in-memory fuzzy search, keyboard navigation, desktop icon rendering, and detached application execution.

## UI Architecture & Features

1. **Morphing Container (`DynamicIsland.qml`)**:
   - Expands dynamically with spring physics to `520x440` pixels.
   - Automatically collapses upon application launch, clicking outside, or pressing `Escape`.
2. **Apple Spotlight Minimalist Search Header (`AppLauncherWidget.qml`)**:
   - Focuses automatically on presentation with zero initial mouse clicks required.
   - Edge-to-edge layout with spacious 14px typography and monochrome search glyph.
   - Single continuous canvas: All nested card rectangles and noisy outline borders removed.
   - Hairline 1px translucent separator (`Style.border` at 0.6 opacity).
3. **Application List View & Multi-Tier Icon Engine**:
   - Single-canvas 48px item rows without outer box frames.
   - Robust 3-tier desktop icon resolution directly on surface:
     1. Primary desktop theme icon (`Quickshell.iconPath` / absolute pixmap file path).
     2. Vector default application assets (Official Hyprland geometric logo `default_app.svg` / Terminal chevron `default_terminal.svg`).
     3. Category-styled initials fallback badge if no vector icon renders.
   - Soft translucent background pill (`Style.surfaceActive`) on hover/selection with zero harsh neon borders.
   - Application display name with right-aligned muted category subtitle.
   - Full keyboard navigation (`Up`/`Down`, `Enter` to launch, `Escape` to dismiss).
4. **Wayland Instant Keyboard Focus (`WlrKeyboardFocus.Exclusive`)**:
   - When the Island expands to `LAUNCHER`, `islandWindow` switches to `WlrKeyboardFocus.Exclusive`, routing all keystrokes directly to `TextInput` without requiring any mouse click.
   - Focus is automatically released back to the active Hyprland window upon launcher dismissal.
5. **Quiet Minimalist Footer**:
   - Displays subtle item counts (`248 uygulama` / `3 sonuç`) and understated action hints (`↵ Aç • esc Kapat`).
6. **Global Keybinding Script (`scripts/toggle_launcher.sh`)**:
   - Transmits `{"name":"toggle_launcher","args":{}}` to `$XDG_RUNTIME_DIR/ogs_shell.sock`.
   - Hyprland shortcut example: `bind = $mainMod, Space, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_launcher.sh`.

---

## Related Documentation

* Backend Service: `[[App-Launcher-Service]]`
* Dynamic Island Core: `[[Dynamic-Island-Component]]`
* Design System & Anti-AI-Slop: `[[Apple-HIG-Minimal-Design-System]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Thought Logs: `[[Plan-Dynamic-Island-App-Launcher-Widget]]`, `[[Plan-App-Launcher-Icon-Resolution-And-Keyboard-Focus]]`, `[[Plan-Launcher-Activity-Inactivity-Reset]]`, `[[Plan-Per-Monitor-Launcher-Focus]]`, `[[Plan-Apple-Spotlight-Minimalist-Launcher-Redesign]]`, `[[Plan-Fix-Launcher-List-View]]`
