---
title: "Plan: Fix Vesktop Inotify Inode Disconnect on Multiple Theme Changes"
type: agent-thought
tags:
  - theme/vesktop
  - vencord
  - filesystem/inode
  - linux/inotify
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

# Plan: Fix Vesktop Inotify Inode Disconnect on Multiple Theme Changes

> [!IDEA]
> Vesktop (Vencord/Discord) istemcisinde temanın ilk değişimde canlı güncellenip ardışık değişimlerde yanıt vermemesinin nedeni, `CopyFile` ve `ensureSettings` fonksiyonlarının `os.Rename` kullanarak `settings/quickCss.css`, `themes/ogsshell.theme.css` ve `settings/settings.json` dosyalarının inode numaralarını değiştirmesidir. Dosyaların yerinde (`in-place`) yazılması sağlanarak Vencord'un `fs.watch` dinleyicisinin inode bağlantısı sürekli korunacaktır.

## Problem Analysis

1. **Vencord Node.js `fs.watch` Inode Unlink:**
   - Vencord, `~/.config/vesktop/settings/quickCss.css` dosyasını Node.js `fs.watch` (Linux inotify) ile izler.
   - `vesktop.go` içerisindeki `CopyFile` çağrıları `quickCss.css.tmp` oluşturup `os.Rename` ile hedef dosyanın üzerine yazar.
   - Bu işlem hedef dosyanın inode numarasını değiştirir. İlk tema değişiminde dosya izleyici `rename` olayını yakalar; fakat sonraki değişimlerde izleyici eski/unlinked inode üzerinde kaldığı için yeni değişimleri asla algılayamaz.
   - Vesktop kapatılıp açılana kadar yeni `fs.watch` dinleyicisi kurulamaz.
2. **Kullanıcı Geri Bildirimi:**
   - "vesktop da aynı şekilde ilk tema değişiminden sonra uygulamayı kapatıp açmak gerekiyor"

## Proposed Solution

1. **`VesktopAdapter` Güncellemesi (`core/services/theme/adapters/vesktop.go`):**
   - `themes/ogsshell.theme.css` dosyasına kopyalama işlemi `CopyFileInPlace` ile yapılacak.
   - `settings/quickCss.css` dosyasına kopyalama işlemi `CopyFileInPlace` ile yapılacak.
   - `settings/settings.json` dosyasının güncellenmesi `WriteFileInPlace` ile yapılacak.
2. **Canlı Doğrulama:**
   - Vesktop açıkken peş peşe 5 farklı tema (`Tokyo Night` -> `Gruvbox` -> `Catppuccin` -> `Everforest` -> `Nord`) değiştirilecek.
   - `ls -i ~/.config/vesktop/settings/quickCss.css` ile inode numarasının her değişimde sabit kaldığı ve Vesktop arayüzünün her seferinde kapatıp açmaya gerek kalmadan canlı olarak güncellendiği teyit edilecek.
3. **Obsidian ve Sistem Belgelerinin Güncellenmesi:**
   - `[[Theme-Service]]`, `.agents/ARCHITECTURE.md` güncellenecek ve bu not `status: implemented` yapılacak.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/adapters/vesktop.go`)

## Implementation Summary & Verification

- **In-Place Yazım Uygulandı:** [`vesktop.go`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/core/services/theme/adapters/vesktop.go) adaptöründe `themes/ogsshell.theme.css`, `settings/quickCss.css` ve `settings/settings.json` dosyalarının güncellenmesi `CopyFileInPlace` ve `WriteFileInPlace` ile gerçekleştirildi.
- **Doğrulama:** 5 ardışık tema değişimi (`Tokyo Night`, `Gruvbox`, `Catppuccin`, `Everforest`, `Nord`) gerçekleştirildi. `quickCss.css` dosyasının inode numarasının (`10409179`) her değişimde %100 sabit kaldığı ve Vencord'un `fs.watch` dinleyicisinin bağlantısını hiç kaybetmeden Vesktop arayüzünü her seferinde anında yeniden renklendirdiği doğrulandı.
