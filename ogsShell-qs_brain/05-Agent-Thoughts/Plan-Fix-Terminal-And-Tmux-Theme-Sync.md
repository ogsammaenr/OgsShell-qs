---
title: "Plan: Fix Terminal and Tmux Theme Synchronization"
type: agent-thought
tags:
  - theme/kitty
  - theme/tmux
  - adapters/terminal
  - go/daemon
created: 2026-08-18
updated: 2026-08-18
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Go-Daemon-Core]]"
  - "[[Plan-Fix-Tmux-Theme-Adapter]]"
  - "[[Plan-Shared-Directory-Theme-Engine]]"
  - "[[System-Architecture]]"
---

# Plan: Fix Terminal and Tmux Theme Synchronization

> [!IDEA]
> Go daemon backend'indeki `GetSharedDir()` konumlandırma mantığını ikili dosya (`os.Executable`) ve çoklu dizin tarama stratejisiyle güçlendirerek, Kitty terminalinde `kitty.conf` touch/mtime tetiklemesi ve Tmux'ta oturum kontrolü + plugin yeniden çalıştırma + `refresh-client` akışını kusursuz hale getirmek.

## Problem Statement

1. **Shared Dizin Tespiti Eksikliği:** Go daemon (`ogsshell-core`) sistem başlatıldığında veya çalışma dizini proje kökü dışında olduğunda (`/home/excalibur` gibi) `theme.GetSharedDir()` fonksiyonu `shared/` klasörünü bulamamakta ve varsayılan göreli `"shared"` yoluna düşmektedir. Bu durum `GetSharedAppConfigFile` çağrılarının hata vermesine (`tema yapılandırma dosyası bulunamadı`) ve başta Kitty ve Tmux olmak üzere tüm adaptörlerin dosya kopyalamayı ve canlı güncellemeyi atlamasına neden olmaktadır.
2. **Kitty Canlı Yenileme:** Kitty terminali, `current-theme.conf` dosyasındaki değişiklikleri `kitty.conf` ana dosyasının değişiklik zamanı (`mtime`) güncellenmedikçe `kitten __watch_conf__` ile fark etmemektedir. Sadece `pkill -SIGUSR1` göndermek Kitty'nin yeni sürümlerinde temanın anında değişmesi için yetersiz kalmaktadır.
3. **Tmux Canlı Yenileme ve Eklenti Durumu:** Tmux adaptöründe `shared` dosyasının bulunamaması nedeniyle konfigürasyon yazılamamakta, aktif tmux oturumlarında `minimal-tmux-status` renk değişkenleri güncellenmemektedir.

## Proposed Solution

1. **`GetSharedDir()` İyileştirmesi (`core/services/theme/storage.go`):**
   - `os.Getenv("OGSSHELL_SHARED_DIR")` kontrolü.
   - `os.Executable()` üzerinden ikili dosyanın bulunduğu dizinden yukarı doğru `shared/themes/themes.json` arama.
   - `os.Getwd()` üzerinden mevcut çalışma dizininden yukarı doğru arama.
   - `~/.local/share/ogsShell/shared`, `~/.config/ogsShell/shared`, `/usr/share/ogsshell/shared` yollarını kontrol etme.
2. **Kitty Adaptörü Güçlendirmesi (`core/services/theme/adapters/kitty.go`):**
   - `current-theme.conf` dosyasına yazıldıktan sonra ana `kitty.conf` dosyasının `os.Chtimes` ve `touch` ile güncelleme zamanı tazelenerek `kitten __watch_conf__` tetiklenecek.
   - Varsa `kitty @ load-config` ve POSIX sinyalleri (`pkill -SIGUSR1 -x kitty`, `pkill -USR1 -x kitty`) ile çoklu güvence sağlanacak.
3. **Tmux Adaptörü Güçlendirmesi (`core/services/theme/adapters/tmux.go`):**
   - Kaynak dosya kontrolü ve hedef konfigürasyon dosyalarına (`~/.tmux/current-theme.conf`, `~/.tmux/theme.conf`, `~/.config/tmux/current-theme.conf`, `~/.config/tmux/theme.conf`) hatasız kopyalama.
   - `tmux has-session` kontrolü yapılarak aktif oturum varsa doğrudan `tmux source-file`, ana konfigürasyon dosyası reload, `minimal-tmux-status` plugin reload ve `tmux refresh-client -S` / `tmux refresh-client` zincirinin sırayla işletilmesi.
4. **Derleme & Canlı Doğrulama:**
   - Go backend derlenecek (`go build`).
   - Çalışan daemon yeniden başlatılacak veya test edilecek.
   - Tema değişimi IPC komutu ile denenip hem Kitty hem Tmux canlı olarak doğrulanacak.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/storage.go`, `core/services/theme/adapters/kitty.go`, `core/services/theme/adapters/tmux.go`)
- `[[Go-Daemon-Core]]` (`core/main.go`)

## Implementation Summary & Verification

- **Shared Directory Auto-Discovery:** `theme.GetSharedDir()` fonksiyonu, ikili dosyanın bulunduğu dizinden yukarı doğru tarama, `os.Getwd()`, `~/.local/share/ogsShell/shared` ve ortam değişkeni kontrolleriyle donatıldı. Daemon `/home/excalibur` dizininden başlatılsa dahi `shared/` dizinini hatasız tespit etmektedir.
- **Kitty Terminal:** `~/.config/kitty/current-theme.conf` güncellendikten sonra ana `kitty.conf` dosyasının zaman damgası güncellenerek (`mtime`/`touch`) `kitten __watch_conf__` mekanizması anında tetiklenmekte; ayrıca `kitty @ load-config` ve POSIX sinyalleri ile tüm Kitty pencereleri anında yeni temaya geçmektedir.
- **Tmux Multiplexer:** Tema dosyaları `~/.tmux/current-theme.conf`, `~/.tmux/theme.conf`, `~/.config/tmux/current-theme.conf` ve `~/.config/tmux/theme.conf` konumlarına yazılmakta, aktif tmux sunucusuna `source-file`, `minimal-tmux-status` plugin reload ve `refresh-client -S` gönderilerek durum çubuğu ve panel kenarlık renkleri anında güncellenmektedir.
- **Doğrulama:** `tokyonight`, `catppuccin` ve `everforest` temaları IPC soketi üzerinden denenmiş; Kitty ve Tmux'un renklerinin anında değiştiği doğrulanmıştır.
