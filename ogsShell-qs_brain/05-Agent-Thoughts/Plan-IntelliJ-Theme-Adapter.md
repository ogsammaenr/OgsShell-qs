---
title: "Plan: Dynamic IntelliJ IDEA & JetBrains IDEs Theme Adapter"
type: agent-thought
tags:
  - theme/intellij
  - adapters/jetbrains
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

# Plan: Dynamic IntelliJ IDEA & JetBrains IDEs Theme Adapter

> [!IDEA]
> IntelliJ IDEA ve JetBrains tabanlı IDE'ler için `core/services/theme/adapters/intellij.go` adaptörü oluşturarak, `shared/app_configs/intellij/*.icls` şablonlarını tüm `~/.config/JetBrains/*` ve Flatpak dizinlerine dağıtmak ve `colors.scheme.xml` dosyasını güncelleyerek dinamik tema senkronizasyonunu sağlamak.

## Problem Statement

1. **Eksik IntelliJ Adaptörü:** `shared/app_configs/intellij/` altında 6 temel tema için hazırlanmış `.icls` (IntelliJ Color Scheme) dosyaları (`catppuccin.icls`, `everforest.icls`, `gruvbox.icls`, `monochrome.icls`, `nord.icls`, `tokyonight.icls`) bulunmasına rağmen, Go backend tarafında (`core/services/theme/adapters/`) bu dosyaları JetBrains yapılandırma dizinlerine kopyalayan ve `options/colors.scheme.xml` dosyasını güncelleyen bir adaptör bulunmamaktadır.
2. **Kullanıcı Talebi:** Sistem teması değiştiğinde IntelliJ IDEA renk şeması değişmemektedir.

## Proposed Solution

1. **`IntelliJAdapter` Oluşturulması (`core/services/theme/adapters/intellij.go`):**
   - `AppAdapter` arayüzünü (`ID()`, `Name()`, `IsInstalled()`, `Apply()`) uygulayan yeni bir yapı tanımlanacak.
   - `IsInstalled()`: `~/.config/JetBrains` veya Flatpak dizinlerinin varlığını denetleyecek.
   - `Apply(palette)`:
     - Tema kimliğine göre scheme adını belirleyecek (`tokyonight` -> `OgsTokyoNight`, `catppuccin` -> `OgsCatppuccin`, `everforest` -> `OgsEverforest`, `gruvbox` -> `OgsGruvbox`, `nord` -> `OgsNord`, `monochrome` -> `OgsMonochrome`).
     - `GetSharedAppConfigFile` ile `shared/app_configs/intellij/<theme_id>.icls` kaynağını bulacak.
     - Mevcut tüm JetBrains ürün dizinlerini (`~/.config/JetBrains/IntelliJIdea*`, `PyCharm*`, `GoLand*` vb.) tarayacak.
     - Her dizin için `colors/<SchemeName>.icls` dosyasına şemayı kopyalayacak.
     - `options/colors.scheme.xml` dosyasını atomik olarak `<global_color_scheme name="<SchemeName>" />` şeklinde güncelleyecek.
2. **Adaptörün Backend'e Kaydedilmesi (`core/main.go`):**
   - `themeMgr.RegisterAdapters(...)` zincirine `adapters.NewIntelliJAdapter()` eklenecek.
3. **Obsidian ve Sistem Belgelerinin Güncellenmesi:**
   - [`.agents/ARCHITECTURE.md`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/ARCHITECTURE.md), [`.agents/BACKEND_ENDPOINTS.md`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/BACKEND_ENDPOINTS.md) ve [`Theme-Service.md`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ogsShell-qs_brain/02-Services/Theme-Service.md) güncellenecek.
4. **Test ve Canlı Doğrulama:**
   - Go backend derlenip yeniden başlatılacak.
   - Tema değişimi yapılarak `~/.config/JetBrains/IntelliJIdea2026.1/options/colors.scheme.xml` ve `colors/` dosyalarının anında güncellendiği teyit edilecek.

## Affected Components

- `[[Theme-Service]]` (`core/services/theme/adapters/intellij.go` [NEW], `core/main.go`)
- `[[Configuration-Themes-Spec]]` (`shared/app_configs/intellij/`)

## Implementation Summary & Verification

- **IntelliJAdapter Gerçekleştirimi:** [`intellij.go`](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/core/services/theme/adapters/intellij.go) oluşturuldu. `~/.config/JetBrains/IntelliJIdea2026.1` ve sistemdeki diğer JetBrains IDE konfigürasyon dizinlerini dinamik olarak tarayarak `colors/<SchemeName>.icls` dosyasını konumlandırmakta ve `options/colors.scheme.xml` dosyasını atomik olarak güncellemektedir.
- **Backend Kaydı:** `core/main.go` içerisinde `themeMgr.RegisterAdapters(...)` zincirine eklendi.
- **Doğrulama:** `tokyonight` ve `gruvbox` temaları denenmiş; `~/.config/JetBrains/IntelliJIdea2026.1/options/colors.scheme.xml` dosyasının sırasıyla `OgsTokyoNight` ve `OgsGruvbox` olarak anında güncellendiği doğrulanmıştır.
