---
title: "Tmux Dual-Capsule Minimalist Status Bar Design"
type: thought_log
tags:
  - tmux/capsules
  - tmux/status-bar
  - theme/tmux
  - indicators/ssh
  - indicators/copy-mode
  - indicators/sync-mode
  - obsidian-glossary
created: 2026-08-30
updated: 2026-08-30
status: implemented
related_notes:
  - "[[Theme-Service]]"
  - "[[Plan-Tmux-Prefix-Window-Color-Highlight]]"
  - "[[Plan-Fix-Tmux-Theme-Adapter]]"
  - "[[Plan-Fix-Terminal-And-Tmux-Theme-Sync]]"
---

# Tmux Dual-Capsule Minimalist Status Bar Design

## Overview
Tmux durum çubuğunu (status bar) %100 yerel ve eklentisiz mimaride tutarak, sol tarafta dinamik prefix destekli **Oturum Kapsülü (Session Capsule)** ve sağ tarafta **Copy Mode**, **Sync Mode** ve **SSH/Local Bağlantı Durumu** gösteren akıllı rozetlere sahip **Çift Kapsül (Dual-Pill)** mimarisine kavuşturulması sağlandı.

## Layout & Components

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                       TMUX STATUS BAR                                           │
├──────────────────────────────┬───────────────────────────────┬──────────────────────────────────┤
│         status-left          │          status-center        │           status-right           │
│   (Oturum / Session Pill)    │    (Pencere / Window Pills)   │   (Copy / Sync / SSH Badges)     │
├──────────────────────────────┼───────────────────────────────┼──────────────────────────────────┤
│    󰒋 #S                    │    1:zsh   2:nvim 󰊓   3:git  │     󰆏 COPY    󰒍 SSH         │
└──────────────────────────────┴───────────────────────────────┴──────────────────────────────────┘
```

## Detailed Specifications

1. **Sol Kapsül (`status-left`):**
   - Oturum adını yuvarlak uçlu (` 󰒋 #S `) bir kapsül içinde sunar.
   - Normal çalışma anında aktif temanın rengindedir (`#{@minimal-tmux-bg}`).
   - Prefix tuşuna (`Ctrl + Space`) basıldığında SADECE bu oturum adası canlı prefix rengine (`#{@minimal-tmux-prefix-bg}`) dönerek net bir prefix uyarısı verir.

2. **Orta Alan (`window-status-current-format` & `window-status-format`):**
   - `status-justify absolute-centre` ile status bar'ın tam ortasında hizalanır.
   - Aktif ve inaktif pencereler sabit tema renklerinde kalır, prefix tuşuna basıldığında renk değiştirmez.
   - Aktif pencere kapsülü zoom ikonu (`󰊓`) ve SSH tespiti ile zenginleştirilmiştir.

3. **Sağ Kapsül (`status-right`):**
   - **Copy Mode:** `#{?pane_in_mode,...}` ile kullanıcı metin seçtiğinde veya arama moduna girdiğinde sarı/altın ` 󰆏 COPY ` kapsülü belirir.
   - **Sync Mode:** `#{?pane_synchronized,...}` ile paneller senkronize moddayken kırmızı ` 󰓦 SYNC ` kapsülü yanar.
   - **SSH / Local:** `#{?#{||:#{m:ssh*,#{pane_current_command}},#{!=:#{SSH_CLIENT},}},...}` koşuluyla yerel oturumlarda ` 󰌢 local `, SSH bağlantısı yapıldığında otomatik olarak ` 󰒍 SSH ` rozetine geçer.

## Integration & Verification
- `~/.tmux.conf` güncellendi ve `tmux source-file ~/.tmux.conf` ile uygulandı.
- `core/services/theme/adapters/tmux.go` içerisinde tema değişiminde `~/.tmux.conf`'un her zaman en son kaynak (master authority) olarak yüklenmesi sağlandı.
- `~/.tmux/plugins/minimal-tmux-status/minimal.tmux` dosyası da çift kapsüllü mimariyle senkronize edilerek harici tetiklemelerde formatların ezilmesi tamamen önlendi.
- Tüm göstergeler test edilerek hatasız çalıştığı teyit edildi.
