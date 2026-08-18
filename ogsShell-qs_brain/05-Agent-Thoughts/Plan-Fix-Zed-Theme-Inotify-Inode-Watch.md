---
title: "Plan: Fix Zed Editor Inotify Inode Break on Multiple Theme Switches"
type: agent-thought
tags:
  - theme/zed
  - linux/inotify
  - filesystem/inode
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

# Plan: Fix Zed Editor Inotify Inode Break on Multiple Theme Switches

> [!IDEA]
> Zed editöründe temanın yalnızca ilk değişimde canlı güncellenip sonraki değişimlerde tepki vermemesinin temel nedeni, dosya yazımında kullanılan `os.Rename` (atomik yer değiştirme) işleminin dosya inode numarasını değiştirmesi ve Linux inotify dosya izleyicisinin (Zed'in Rust `notify` dinleyicisi) bağlantısını koparmasıdır. `settings.json` ve `themes/ogsshell.json` dosyalarının inode'u koruyacak şekilde yerinde (`in-place` truncate/write) güncellenmesi sağlanacaktır.

## Problem Analysis

1. **Inotify Inode Unlinking:**
   - Zed editörü çalışırken `~/.config/zed/settings.json` ve `~/.config/zed/themes/` dosyalarını Linux inotify mekanizmasıyla izler.
   - Önceki kod, `settings.json.tmp` oluşturup `os.Rename("settings.json.tmp", "settings.json")` yapmaktaydı.
   - Linux çekirdeğinde `rename(2)` çağrısı eski inode'u boşa çıkarır (`IN_IGNORED` / `IN_MOVE_SELF`).
   - Zed ilk dosya değişimini işler; ancak izlenen orijinal inode unlinked duruma düştüğü için sonraki hiçbir `settings.json` değişikliğini yakalayamaz. Zed yeniden başlatılana kadar dinleyici bağlanamaz.
2. **Kullanıcı Geri Bildirimi:**
   - "zedi açıp bir kere tema değiştirirsem eğer kapatıp açmama gerek kalmadan tema anlık olarak değişiyor ama 1den fazla kez yaparsam değişiklik olmuyor kapatıp açmam gerekiyor."

## Proposed Solution

1. **`WriteFileInPlace` & `CopyFileInPlace` Eklenmesi (`core/services/theme/adapters/adapter.go`):**
   - Dosyayı geçici bir dosyadan `rename` etmek yerine, mevcut dosya tanıtıcısını (`os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)`) açarak yerinde üzerine yazan fonksiyonlar tanımlanacak.
   - Bu sayede dosyanın `inode` numarası asla değişmez; Linux inotify her zaman `IN_MODIFY` sinyali üretir ve Zed'in dosya izleyicisi asla kopmaz.
2. **`ZedAdapter` Güncellemesi (`core/services/theme/adapters/zed.go`):**
   - `themes/ogsshell.json` ve tüm tema şablonları `CopyFileInPlace` ile kopyalanacak.
   - `settings.json` dosyası `WriteFileInPlace` ile inode korunarak güncellenecek.
3. **Canlı Doğrulama:**
   - Zed çalıştırılacak ve peş peşe 5-6 farklı tema (`Tokyo Night` -> `Gruvbox` -> `Catppuccin` -> `Everforest` -> `Nord` -> `Monochrome`) seçilecek.
   - Her tema değişiminde Zed'in anlık ve kesintisiz olarak renk değiştirdiği doğrulanacak.
4. **Obsidian ve Master Dokümantasyon Güncellemesi:**
   - `[[Theme-Service]]`, `.agents/ARCHITECTURE.md` güncellenecek ve bu not `status: implemented` yapılacak.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/adapters/zed.go`, `core/services/theme/adapters/adapter.go`)

## Implementation Summary & Verification

- **In-Place Yazım Fonksiyonları:** [`adapter.go`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/core/services/theme/adapters/adapter.go) içerisine dosya inode'unu koruyan `WriteFileInPlace` ve `CopyFileInPlace` eklendi.
- **ZedAdapter Güncellemesi:** [`zed.go`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/core/services/theme/adapters/zed.go) içerisinde `settings.json` ve `themes/ogsshell.json` yazımları `WriteFileInPlace` ile güncellendi; 6 temel tema şablonunun `~/.config/zed/themes/` klasöründe hazır bulunması sağlandı.
- **Doğrulama:** 5 ardışık tema değişimi (`Tokyo Night`, `Gruvbox`, `Catppuccin`, `Everforest`, `Nord`) gerçekleştirildi. `settings.json` dosyasının inode numarasının (`10125375`) her değişimde sabit kaldığı ve temanın her seferinde kapatıp açmaya gerek kalmadan canlı olarak değiştiği teyit edildi.
