---
title: "Plan: Global Real-Time Audio Volume Change Feedback Sound"
type: agent-thought
tags:
  - plan/audio-feedback
  - pipewire/quickshell
  - system-sounds/xdg
  - config/schema
created: 2026-09-06
updated: 2026-09-06
status: implemented
related_notes:
  - "[[Configuration-System-Spec]]"
  - "[[Audio-Feedback-Service]]"
  - "[[Control-Center-Widget]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[System-Architecture]]"
---

# Plan: Global Real-Time Audio Volume Change Feedback Sound

> [!IDEA]
> Implementing a global real-time audio volume change feedback sound ensures users get immediate, pleasant acoustic confirmation when adjusting volume via physical keyboard keys, terminal tools (`wpctl`, `pactl`), or shell sliders.

## Problem Statement
When adjusting sound volume, especially via hardware function keys or global Hyprland keybinds, visual HUD confirmation alone can be missed if the user is focused on full-screen media or an IDE. Standard desktop environments (macOS, GNOME) emit a short, crisp "pop" or "blip" sound.

## Implementation Architecture
1. **Root Audio Service (`AudioFeedbackService.qml`):**
   - Singleton tracking `Pipewire.defaultAudioSink` via `PwObjectTracker`.
   - Listens to `onVolumeChanged` globally.
   - Ignores changes during 1s startup cooldown and when muted.
   - 100ms throttle timer coalesces rapid slider dragging and held keys.
2. **Audio Backend:**
   - Primary: `canberra-gtk-play -i audio-volume-change -d 'volume-change'`.
   - Fallback: `pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga`.
   - Custom: user-defined sound file path.
3. **Configuration (`config.json`):**
   - Controlled via `"audio_feedback"` schema block.
