---
title: "Tmux Prefix Window Color Dynamic Highlight"
type: thought_log
tags:
  - tmux/prefix
  - theme/tmux
  - status-bar/styling
  - obsidian-glossary
created: 2026-08-30
updated: 2026-08-30
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Plan-Fix-Tmux-Theme-Adapter]]"
  - "[[Plan-Fix-Terminal-And-Tmux-Theme-Sync]]"
---

# Tmux Prefix Window Color Dynamic Highlight

## Problem Description
Kullanıcı tmux prefix tuş kombinasyonuna (örneğin `Ctrl + Space`) bastığında, bekleme durumunda aktif ve inaktif pencere isimlerinin (window status / tab) renklerinin dinamik olarak değişmesini ve prefix durumuna özel bir vurgu rengine geçmesini talep etti.

## Implementation Details

1. **`minimal-tmux-status` Eklentisi Güncellemesi (`~/.tmux/plugins/minimal-tmux-status/minimal.tmux`):**
   - `@minimal-tmux-prefix-bg` ve `@minimal-tmux-prefix-fg` değişkenleri eklendi.
   - `window-status-current-format` ve `window-status-format` değişkenleri tmux'un yerleşik `#{?client_prefix,...}` koşullu formatlama motoru ile güncellendi:
     ```bash
     normal_current="#[fg=${bg}]${larrow}#[bg=${bg}]#[fg=${fg}]${window_status_format}#{?window_zoomed_flag,${expanded_icon},}#[fg=${bg}]#[bg=default]${rarrow}"
     prefix_current="#[fg=${prefix_bg}]${larrow}#[bg=${prefix_bg}]#[fg=${prefix_fg}]#[bold]${window_status_format}#{?window_zoomed_flag,${expanded_icon},}#[fg=${prefix_bg}]#[bg=default]${rarrow}"
     tmux set-option -g window-status-current-format "#{?client_prefix,${prefix_current},${normal_current}}"
     ```
   - Inaktif pencereler için de prefix basıldığında renk vurgusu (`window-status-format`) bağlandı.

2. **Tema Entegrasyonu (`shared/app_configs/tmux/*.conf`):**
   - Tüm temalara (`rosepine`, `catppuccin`, `everforest`, `gruvbox`, `monochrome`, `nord`, `tokyonight`) palete uygun prefix renkleri tanımlandı:
     - **Rosé Pine:** `prefix_bg: #F6C177` (Gold), `prefix_fg: #191724`
     - **Catppuccin:** `prefix_bg: #FAB387` (Peach), `prefix_fg: #1E1E2E`
     - **Everforest:** `prefix_bg: #E69875` (Orange), `prefix_fg: #2D353B`
     - **Gruvbox:** `prefix_bg: #FE8019` (Orange), `prefix_fg: #282828`
     - **Nord:** `prefix_bg: #EBCB8B` (Yellow), `prefix_fg: #2E3440`
     - **Tokyo Night:** `prefix_bg: #FF9E64` (Orange), `prefix_fg: #1A1B26`
     - **Monochrome:** `prefix_bg: #666666`, `prefix_fg: #FFFFFF`

3. **Canlı Senkronizasyon ve Test:**
   - `~/.tmux/current-theme.conf` ve `~/.config/tmux/current-theme.conf` güncellendi.
   - `tmux source-file ~/.tmux.conf` çalıştırılarak canlı tmux oturumunda prefix renk geçişi doğrulandı.

4. **100% Native ve Pluginsiz Mimariye Geçiş (`~/.tmux.conf`):**
   - TPM ve harici eklentiler (`tpm`, `minimal-tmux-status`, `tmux-sensible`, `tmux-cpu`) kaldırılarak tüm işlevler doğrudan saf Tmux direktifleri ve format değişkenleri (`#{@minimal-tmux-bg}`, `#{@minimal-tmux-prefix-bg}`) ile yerel olarak kodlandı.
   - Sıfır eklenti bağımlılığı, anında başlangıç süresi ve saf tmux ortamı sağlandı.

