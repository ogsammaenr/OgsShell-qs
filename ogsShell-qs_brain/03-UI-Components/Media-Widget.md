---
title: "Media Widget Component (MPRIS)"
type: ui-component
tags:
  - ui/widget
  - widget/media
  - quickshell/qml
  - mpris/player
created: 2026-08-12
updated: 2026-08-12
status: active
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Clock-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-Dynamic-Island-HIG]]"
---

# Media Widget Component (MPRIS)

> [!NOTE]
> `shell/components/widgets/MediaWidget.qml` integrates directly with `Quickshell.Services.Mpris` to display live media metadata (Track Title, Artist/App), an animated 3-bar sound equalizer, and interactive play/pause toggling in the Dynamic Island / Notch hover bar.

---

## 1. Features & Architecture

* **Active Player Resolution:** Dynamically scans `Mpris.players.values`, prioritizing active playing sessions (`MprisPlaybackState.Playing`).
* **Animated Sound Equalizer:** Utilizes 3 independent `SequentialAnimation` bars with staggered sine easing to visually indicate active playback.
* **Idle & Fallback States:** Renders a clean placeholder icon (`󰎆`) and localized text (`"Medya Yok"` / `"Çalınmıyor"`) when no media is playing.
* **Interactive Control:** Clicking anywhere on the widget toggles playback (`player.togglePlaying()`).

---

## 2. Component Properties

| Property | Type | Description |
| :--- | :--- | :--- |
| `activePlayer` | `MprisPlayer` | Reference to currently active or playing MPRIS player object |
| `hasMedia` | `bool` | True if a player with track title or active playback exists |
| `isPlaying` | `bool` | True if the current player is playing audio/video |
| `title` | `string` | Track title (elided for clean presentation) |
| `artist` | `string` | Artist name or application identity string |

---

## 3. Related Links

* Dynamic Island: `[[Dynamic-Island-Component]]`
* Connectivity Status Widget: `[[Connectivity-Status-Widget]]`
* Design Tokens: `[[Style-Design-Tokens]]`
