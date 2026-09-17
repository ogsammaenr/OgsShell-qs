---
title: "Dynamic Island App Launcher Widget"
type: ui-component
tags:
  - ui/launcher
  - dynamic-island/expanded
  - quickshell/qml
  - fuzzy/search
  - keyboard/navigation
created: 2026-08-17
updated: 2026-08-17
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Component]]"
  - "[[App-Launcher-Service]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Style-Design-Tokens]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[Currency-Service]]"
  - "[[Plan-Dynamic-Island-App-Launcher-Widget]]"
---

# Dynamic Island App Launcher Widget

Quickshell QML user interface component embedded in the **Dynamic Island** (`expandedActiveTab === "LAUNCHER"`), providing instantaneous in-memory fuzzy search, keyboard navigation, desktop icon rendering, and detached application execution.

## UI Architecture & Features

1. **Morphing Container (`DynamicIsland.qml`)**:
   - Expands dynamically with spring physics to `520x440` pixels.
   - Automatically collapses upon application launch, clicking outside, or pressing `Escape`.
2. **Apple Spotlight Minimalist Search Header (`AppLauncherWidget.qml`)**:
   - Focuses automatically on presentation with zero initial mouse clicks required.
   - Edge-to-edge layout with spacious 14px typography and monochrome search glyph.
   - Single continuous canvas: All nested card rectangles and noisy outline borders removed.
   - Hairline 1px translucent separator (`Style.border` at 0.6 opacity).
3. **Application List View & Multi-Tier Icon Engine**:
   - Single-canvas 48px item rows without outer box frames.
   - Robust 3-tier desktop icon resolution directly on surface:
     1. Primary desktop theme icon (`Quickshell.iconPath` / absolute pixmap file path).
     2. Vector default application assets (Official Hyprland geometric logo `default_app.svg` / Terminal chevron `default_terminal.svg`).
     3. Category-styled initials fallback badge if no vector icon renders.
   - Soft translucent background pill (`Style.surfaceActive`) on hover/selection with zero harsh neon borders.
   - Application display name with right-aligned muted category subtitle.
   - Full keyboard navigation (`Up`/`Down`, `Enter` to launch, `Escape` to dismiss).
4. **Wayland Instant Keyboard Focus (`WlrKeyboardFocus.Exclusive`)**:
   - When the Island expands to `LAUNCHER`, `islandWindow` switches to `WlrKeyboardFocus.Exclusive`, routing all keystrokes directly to `TextInput` without requiring any mouse click.
   - Focus is automatically released back to the active Hyprland window upon launcher dismissal.
5. **Akıllı Girdi Ayrıştırıcı & Matematik Motoru (`MathEvaluator.js`)**:
   - Klavyeden kopmadan anında matematiksel ifade değerlendirmesi. Hesap makinesi modu arama kutusunda açıkça `=` ile başlayan sorgularda tetiklenir (örn: `= 5+5`, `= 15 * 300`, `= sqrt(144)`).
   - Temel operatörler (`+`, `-`, `*`, `/`, `^`, `%`, `x`, `×`, `÷`), yüzde hesaplamaları (`= 100 + 20%`, `= 15% of 200`), matematik fonksiyonları (`sqrt`, `cbrt`, `sin`, `cos`, `tan`, `abs`, `log`, `ln`, `pow`), açı dereceleri (`sin(90 deg)`) ve sabitler (`pi`, `e`).
   - Sıfır `eval()` bağımlılığı ile AST/operatör öncelikli güvenli hesaplama; eksik veya hatalı sözdizimlerinde sessizce `null` döner.
6. **Canlı ve Önbellekli Kur Çevirici Motoru (`CurrencyEngine.qml` & `[[Currency-Service]]`)**:
   - **Python-Free Native Go Mimarisi:** Python ve harici komut bağımlılığı tamamen kaldırılmıştır. Kurların periyodik senkronizasyonu doğrudan Go daemon arka plan servisi (`core/services/currency/`) tarafından yürütülür.
   - **Reaktif Konfigürasyon (`config.json`):** Kur çekme aralığı (`currency.sync_interval_min`, varsayılan: 30 dk) ve varsayılan hedef para birimi (`currency.default_target`, örn: `"TRY"`, `"EUR"`) `config.json` dosyasından dinamik olarak yapılandırılır. Örneğin varsayılan hedef `EUR` yapıldığında `10 usd` yazımı anında Euro'ya çevrilir.
   - **Kanonik Depolama:** `$XDG_CONFIG_HOME/ogsShell/currency_rates.json` dosyası `FileView` ile izlenir; aynı zamanda Go daemon `currency_rates_update` soket yayını ile verileri RAM üzerinde anında günceller.
   - **Esnek Şablon Desteği:** `100 usd`, `50 eur to try`, `25 gbp`, `1000 try in eur`, `0.5 btc`, `$100`, `50€`, `1000₺`, `100 dolar`, `25 sterlin`.
7. **Hero Result Kartı & Klavye Kopyalama (`HeroResultCard.qml`)**:
   - Arama çubuğunun hemen altında yüksek kontrastlı ve zarif Apple HIG uyumlu kart.
   - Matematik için sol tarafta hesap makinesi ikonu `󰃬` ve büyük okunaklı sonuç (`= 4,500`), kur için döviz ikonu `󱁉`, dönüştürülen tutar (`= 4.859,60 ₺`) ve parite bilgisi (`1 USD = 48.60 ₺ • Son güncelleme: 17:07`).
   - Sonuç kartı aktifken `selectedIndex = -1` olarak atanır; `Enter` tuşuna basıldığında sonuç hem `[[Clipboard-Service]]` (`DaemonIPC.copyClipboardItem`) hem de `wl-copy` ile sistem panosuna kopyalanır, `✓ Kopyalandı!` animasyonu gösterilir ve launcher kapanır (`root.launchRequested()`).
   - `Up`/`Down` tuşlarıyla Hero kartı ve uygulama listesi arasında kesintisiz geçiş.
8. **Quiet Minimalist Footer**:
   - Hero sonuç varken mod adını (`Hesap Makinesi` / `Döviz Dönüştürücü`) ve `↵ Kopyala • esc Kapat` ipuçlarını gösterir; standart modda uygulama/sonuç sayısını ve `↵ Aç • esc Kapat` ipuçlarını sunar.
9. **Global Keybinding Script (`~/.config/ogsShell/ogsshell.sh toggle_launcher`)**:
   - Transmits `{"name":"toggle_launcher","args":{}}` to `$XDG_RUNTIME_DIR/ogs_shell.sock`.
   - Hyprland shortcut example: `bind = $mainMod, Space, exec, ~/.config/ogsShell/ogsshell.sh toggle_launcher`.

---

## Related Documentation

* Backend Service: `[[App-Launcher-Service]]`
* Clipboard Service: `[[Clipboard-Service]]`
* Dynamic Island Core: `[[Dynamic-Island-Component]]`
* Design System & Anti-AI-Slop: `[[Apple-HIG-Minimal-Design-System]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* Configuration System: `[[Configuration-System-Spec]]`
* Thought Logs: `[[Plan-Dynamic-Island-App-Launcher-Widget]]`, `[[Plan-App-Launcher-Icon-Resolution-And-Keyboard-Focus]]`, `[[Plan-Launcher-Activity-Inactivity-Reset]]`, `[[Plan-Per-Monitor-Launcher-Focus]]`, `[[Plan-Apple-Spotlight-Minimalist-Launcher-Redesign]]`, `[[Plan-Fix-Launcher-List-View]]`
