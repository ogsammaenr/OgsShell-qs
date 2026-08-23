---
title: "Media Widget Component (MPRIS)"
type: ui-component
tags:
  - ui/widget
  - widget/media
  - quickshell/qml
  - mpris/player
created: 2026-08-12
updated: 2026-08-23
status: active
related_notes:
  - "[[Dynamic-Island-Component]]"
  - "[[Media-Player-View]]"
  - "[[Clock-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Plan-Dynamic-Island-Idle-And-Hover-Typography-Enlargement]]"
---

# Media Widget Component (MPRIS)

> [!NOTE]
> `shell/components/widgets/MediaWidget.qml` integrates directly with `Quickshell.Services.Mpris` to display live media metadata (Track Title, Artist/App), an animated 3-bar sound equalizer, interactive left-click play/pause toggling, and right-click expansion to the full [[Media-Player-View]] application.

---

## 1. Features & Architecture

* **Active Player Resolution:** Dynamically scans `Mpris.players.values`, prioritizing active playing sessions (`MprisPlaybackState.Playing`).
* **Animated Sound Equalizer:** Utilizes 3 independent `SequentialAnimation` bars (heights 11-13px, width 2.5px) inside a `26x26px` circular badge with staggered sine easing to visually indicate active playback.
* **Refined Typography Scale:**
  - Track Title: **`12px DemiBold`** with auto-elide.
  - Artist / Identity: **`11px Normal`** in muted secondary text color.
  - Placeholder & Status Icons: **`11px / 14px`** glyphs.
* **Idle & Fallback States:** Renders a clean placeholder icon (`󰎆`) and localized text (`"Medya Yok"` / `"Çalınmıyor"`) when no media is playing.
* **Dual Click Gestures:**
  - **Sol Tık (Left Click):** Medyayı duraklatır veya oynatır (`player.togglePlaying()`).
  - **Sağ Tık (Right Click):** Dynamic Island'ı genişleterek (`390x170px`) tam özellikli `[[Media-Player-View]]` uygulamasını açar (`mediaRightClicked()` sinyali).

---

## 2. Component Properties & Signals

| Property / Signal | Type | Description |
| :--- | :--- | :--- |
| `activePlayer` | `MprisPlayer` | Reference to currently active or playing MPRIS player object |
| `hasMedia` | `bool` | True if a player with track title or active playback exists |
| `isPlaying` | `bool` | True if the current player is playing audio/video |
| `title` | `string` | Track title |
| `artist` | `string` | Artist name or application identity string |
| `mediaRightClicked()` | `signal` | Emitted on right click to expand the full Media Player view |

---

## 3. Related Links

* Media Player View: `[[Media-Player-View]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Connectivity Status Widget: `[[Connectivity-Status-Widget]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Typography Plan: `[[Plan-Dynamic-Island-Idle-And-Hover-Typography-Enlargement]]`

