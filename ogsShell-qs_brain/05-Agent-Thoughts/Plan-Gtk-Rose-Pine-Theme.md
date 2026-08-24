---
title: "Plan: Rosé Pine Theme Integration for GTK 3.0 & GTK 4.0 Applications"
type: agent-thought
tags:
  - theme/rose-pine
  - ui/gtk
  - libadwaita
  - adapters/gtk
created: 2026-08-24
updated: 2026-08-24
status: implemented
related_notes:
  - "[[Configuration-Themes-Spec]]"
  - "[[Theme-Service]]"
  - "[[Plan-Rose-Pine-Theme-Integration]]"
  - "[[System-Architecture]]"
---

# Plan: Rosé Pine Theme Integration for GTK 3.0 & GTK 4.0 Applications

> [!NOTE]
> Rosé Pine theme integration for GTK 3.0 and GTK 4.0 applications has been successfully implemented via `shared/app_configs/gtk/rosepine.css` and `shared/app_configs/gtk/rosepine.ini`, managed by `GtkAdapter`.

## 1. Problem Statement
The user requested adding Rosé Pine theme support for **GTK** applications. In `ogsShell-qs`, GTK theming is handled by `GtkAdapter` (`core/services/theme/adapters/gtk.go`), which deploys `gtk.css` to `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/`, as well as `settings.ini` to `~/.config/gtk-3.0/`.

## 2. Color Mapping for GTK (Libadwaita Named Colors)
* **Accent Color (`accent_color`, `accent_bg_color`):** `#ebbcba` (Rose)
* **Accent Foreground (`accent_fg_color`):** `#191724` (Base)
* **Window Background (`window_bg_color`, `dialog_bg_color`, `popover_bg_color`):** `#191724` (Base)
* **Window / View Foreground (`window_fg_color`, `view_fg_color`):** `#e0def4` (Text)
* **View Background (`view_bg_color`):** `#1f1d2e` (Surface)
* **Card & Headerbar Border (`card_bg_color`, `headerbar_border_color`):** `#26233a` (Overlay)

## 3. Implementation Steps & Verification

1. **GTK CSS Definition (`shared/app_configs/gtk/rosepine.css`):**
   - Defined Libadwaita color variables matching Rosé Pine palette.

2. **GTK Settings INI (`shared/app_configs/gtk/rosepine.ini`):**
   - Created standard dark-mode GTK configuration.

3. **Testing:**
   - Executed Go unit tests in `core/` with 100% pass rate.

