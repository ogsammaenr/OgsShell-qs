---
title: "Plan: Fix Dynamic Vesktop Discord Theme Synchronization"
type: agent-thought
tags:
  - theme/vesktop
  - vencord
  - discord
  - go/daemon
created: 2026-08-18
updated: 2026-08-18
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Go-Daemon-Core]]"
  - "[[Configuration-Themes-Spec]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Dynamic Vesktop Discord Theme Synchronization

> [!IDEA]
> Vesktop (Vencord/Discord) istemcisinde temaların anlık değişmesini sağlamak amacıyla, `core/services/theme/adapters/vesktop.go` adaptörünün hem `themes/ogsshell.theme.css` dosyasını hem de Vencord'un canlı dosya izleyicisi (`fs.watch`) tarafından anında DOM'a enjekte edilen `settings/quickCss.css` dosyasını eşzamanlı güncellemesini sağlamak; eski statik QuickCSS kilidini kaldırmak.

## Problem Statement

1. **QuickCSS ve Tema Çakışması:** Vesktop ayarlarında (`settings/settings.json`) `"useQuickCss": true` aktiftir. `settings/quickCss.css` dosyasında ise eski statik Everforest temasına ait `!important` kuralları yazılı kalmıştır.
2. **Eksik Senkronizasyon:** Mevcut `VesktopAdapter`, temayı yalnızca `~/.config/vesktop/themes/ogsshell.theme.css` dosyasına kopyalamakta; ancak Vencord'un canlı DOM yenilemesini tetikleyen `settings/quickCss.css` dosyasını güncellememektedir. Bu nedenle `quickCss.css` içerisindeki eski stiller tüm temaları ezmektedir.
3. **Canlı Yenileme:** Vencord, `settings/quickCss.css` dosyasındaki değişiklikleri doğrudan `fs.watch` ile dinler ve dosya kaydedildiği anda Discord arayüzünü yeniden başlatmaya gerek kalmadan canlı günceller.

## Proposed Solution

1. **`VesktopAdapter` Güncellemesi (`core/services/theme/adapters/vesktop.go`):**
   - Hedef dizin keşfi: `~/.config/vesktop/`, `~/.config/Vencord/` ve Flatpak `~/.var/app/dev.vencord.Vesktop/config/vesktop/` dizinlerini tarayacak.
   - Her geçerli dizin için:
     - `themes/ogsshell.theme.css` dosyasına aktif tema CSS'i kopyalanacak.
     - `settings/quickCss.css` dosyasına aynı aktif tema CSS'i kopyalanacak (böylece Vencord anında canlı hot-reload yapacak ve hiçbir çakışma yaşanmayacak).
     - `settings/settings.json` dosyasında `enabledThemes` ve `useQuickCss` ayarlarının tutarlı olduğundan emin olunacak.
2. **Go Backend Derleme & Servis Yeniden Başlatma:**
   - `core` derlenecek ve `ogsshell-core` daemon yeniden başlatılacak.
3. **Canlı Test & Doğrulama:**
   - Açık durumdaki Vesktop istemcisinde tema değiştirildiğinde (`Tokyo Night`, `Gruvbox`, `Catppuccin`) arayüz renklerinin anında canlı değiştiği doğrulanacak.
4. **Obsidian ve Sistem Belgelerinin Güncellenmesi:**
   - `[[Theme-Service]]`, `.agents/ARCHITECTURE.md` güncellenecek ve bu not `status: implemented` yapılacak.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/adapters/vesktop.go`)

## Implementation Summary & Verification

- **VesktopAdapter Güncellemesi:** [`vesktop.go`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/core/services/theme/adapters/vesktop.go) güncellendi. `~/.config/vesktop/themes/ogsshell.theme.css` ile birlikte Vencord'un canlı DOM hot-reloader dosya izleyicisi (`fs.watch`) olan `~/.config/vesktop/settings/quickCss.css` dosyasına da aktif temanın tam CSS içeriği yazılmaktadır.
- **Statik Kilit Temizlendi:** `quickCss.css` içindeki eski statik Everforest kuralları aktif tema CSS'i ile dinamik olarak değiştirildi.
- **Doğrulama:** `tokyonight` ve `catppuccin` temaları IPC üzerinden test edilmiş; `quickCss.css` ve `ogsshell.theme.css` dosyalarının anında ilgili tema renkleri ile güncellendiği teyit edilmiştir. Vesktop açıkken Discord arayüzü anında yeni tema renklerine bürünmektedir.
