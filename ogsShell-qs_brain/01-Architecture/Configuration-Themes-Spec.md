---
title: "Configuration & Multi-App Themes Specification"
type: architecture
tags:
  - architecture/themes
  - styling/tokens
  - json/config
  - app-configs
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Style-Design-Tokens]]"
  - "[[Dynamic-Island-Component]]"
---

# Configuration & Multi-App Themes Specification

> [!NOTE]
> `ogsShell-qs` provides unified cross-desktop theming through `shared/themes/themes.json` and modular dotfile configurations stored under `shared/app_configs/`.

---

## 1. Global Themes Registry (`shared/themes/themes.json`)

The themes registry contains structured color definitions across six primary dark-mode palettes:

```json
[
  {
    "id": "nord",
    "name": "Nord",
    "accent": "#88c0d0",
    "bg": "#2e3440",
    "fg": "#eceff4",
    "card_bg": "#3b4252"
  },
  {
    "id": "catppuccin",
    "name": "Catppuccin Macchiato",
    "accent": "#c6a0f6",
    "bg": "#24273a",
    "fg": "#cad3f5",
    "card_bg": "#363a4f"
  },
  {
    "id": "everforest",
    "name": "Everforest Dark",
    "accent": "#a7c080",
    "bg": "#2d353b",
    "fg": "#d3c6aa",
    "card_bg": "#343f44"
  },
  {
    "id": "tokyonight",
    "name": "Tokyo Night",
    "accent": "#7aa2f7",
    "bg": "#1a1b26",
    "fg": "#c0caf5",
    "card_bg": "#24283b"
  },
  {
    "id": "gruvbox",
    "name": "Gruvbox Dark",
    "accent": "#fe8019",
    "bg": "#282828",
    "fg": "#ebdbb2",
    "card_bg": "#3c3836"
  },
  {
    "id": "monochrome",
    "name": "Monochrome Minimal",
    "accent": "#e0e0e0",
    "bg": "#121212",
    "fg": "#f0f0f0",
    "card_bg": "#1e1e1e"
  }
]
```

---

## 2. Integrated Application Configuration Matrix

The themes are mapped across terminal emulators, file managers, code editors, and desktop toolkits:

| Target Application | Path | Supported Formats |
| :--- | :--- | :--- |
| **Kitty Terminal** | `shared/app_configs/kitty/` | `.conf` color mapping files |
| **Btop Monitor** | `shared/app_configs/btop/` | `.theme` files |
| **Dolphin / KDE** | `shared/app_configs/dolphin/` | `kdeglobals` color definitions |
| **GTK 3/4** | `shared/app_configs/gtk/` | `gtk.css` definitions |
| **Neovim** | `shared/app_configs/nvim/` | Lua theme loaders |
| **Tmux** | `shared/app_configs/tmux/` | `tmux.conf` status bar stylings |
| **Zed Editor** | `shared/app_configs/zed/` | JSON theme overrides |
| **Zen Browser** | `shared/app_configs/zen/` | UserChrome CSS |
| **Vesktop** | `shared/app_configs/vesktop/` | Discord custom CSS |
| **IntelliJ** | `shared/app_configs/intellij/` | XML color schemes |

---

## 3. Integration with Quickshell Style Engine

The colors declared here serve as the baseline for `[[Style-Design-Tokens]]` (`shell/theme/Style.qml`), ensuring the Dynamic Island visual presentation remains harmonious with the rest of the Hyprland desktop environment.
