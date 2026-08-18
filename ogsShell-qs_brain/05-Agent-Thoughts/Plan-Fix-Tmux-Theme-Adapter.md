---
title: "Plan: Fix Tmux Theme Adapter and Dynamic Live Reload"
type: agent-thought
tags:
  - theme/tmux
  - adapters/tmux
  - go/daemon
  - bugfix/theming
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Configuration-Themes-Spec]]"
  - "[[Go-Daemon-Core]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Tmux Theme Adapter and Dynamic Live Reload

> [!IDEA]
> Tmux tema adaptörünü (`core/services/theme/adapters/tmux.go`) hem geleneksel `~/.tmux/current-theme.conf` hem de modern `~/.config/tmux/` yollarını destekleyecek, aktif tmux oturumlarına doğrudan `tmux source-file`, `minimal-tmux-status` plugin tetikleyicisi ve `tmux refresh-client -S` göndererek temayı anında yenileyecek şekilde güçlendirmek.

## 1. Problem Tanımı
* Kullanıcı kontrol merkezinden veya tema arayüzünden tema değiştirdiğinde Tmux teması değişmemektedir.
* **Kök Neden:**
  1. `TmuxAdapter` yalnızca `~/.config/tmux/theme.conf` dosyasına yazmaktaydı. Ancak kullanıcının `~/.tmux.conf` dosyası `source-file ~/.tmux/current-theme.conf` satırını çalıştırmaktaydı.
  2. `TmuxAdapter` yeniden yükleme komutu olarak `tmux source-file ~/.config/tmux/tmux.conf` çalıştırmaktaydı; kullanıcı sisteminde ana konfigürasyon `~/.tmux.conf` konumunda olduğu için bu komut hata verip hiçbir oturumu yenilememekteydi.
  3. `minimal-tmux-status` gibi durum çubuğu eklentileri çalışma anında renk değişkenleri değiştiğinde scriptlerinin yeniden yürütülmesine veya `refresh-client -S` çağrısına ihtiyaç duymaktadır.

## 2. Uygulanacak Çözüm
1. **Çoklu Konum Desteği:**
   - Tema dosyası hem `~/.tmux/current-theme.conf` / `~/.tmux/theme.conf` hem de `~/.config/tmux/current-theme.conf` / `~/.config/tmux/theme.conf` yollarına kopyalanacak.
2. **Canlı Sunucu Entegrasyonu:**
   - Aktif tmux sunucusuna doğrudan `tmux source-file <srcFile>` ile renk ve stil değişkenleri anında enjekte edilecek.
   - Ana konfigürasyon dosyası tespit edilerek (`~/.tmux.conf` veya `~/.config/tmux/tmux.conf`) yeniden kaynak gösterilecek (`source-file`).
   - `~/.tmux/plugins/minimal-tmux-status/minimal.tmux` eklentisi mevcutsa `tmux run-shell` ile yeniden tetiklenecek.
   - `tmux refresh-client -S` ve `tmux refresh-client` komutları ile tüm bağlı terminallerde durum çubuğu ve pencere sınırları gecikmesiz yenilenecek.

## 3. Etkilenen Dosyalar
* `core/services/theme/adapters/tmux.go`
* `ogsShell-qs_brain/02-Services/Theme-Service.md`
* `.agents/ARCHITECTURE.md`
