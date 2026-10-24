---
title: "Hyprland Profile, Decoration & Bezier Physics Service (Go Backend Daemon)"
type: service
tags:
  - service/hyprland
  - hyprland/lua
  - physics/bezier
  - ui/decoration
  - ipc/events
created: 2026-09-23
updated: 2026-09-23
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Settings-Application-Component]]"
  - "[[Theme-Service]]"
---

# Hyprland Profile, Decoration & Bezier Physics Service (`core/services/hyprland/`)

> [!NOTE]
> `ogsShell-qs` Go daemon katmanında çalışan, Hyprland'in yerel Lua ayrıştırıcısı (`hyprland.lua`) ile Quickshell QML arayüzleri ([[Settings-Application-Component]]) arasında köprü kuran yüksek performanslı servis.

---

## 1. Mimari Genel Bakış

Servis, Hyprland'in modern Lua tabanlı yapılandırma ağacını (`~/.config/hypr/lua/`) yönetir. Dış süreç (process fork) açma maliyetlerini ortadan kaldırarak bellek üzerinden doğrudan Unix Domain Socket IPC ([[Daemon-IPC-Client]]) ile iletişim kurar.

```text
┌────────────────────────────────────────────────────────┐
│      ogsShell Ayarlar Uygulaması (settings_app/)       │
│  - CubicBezierEditor.qml (İnteraktif Eğri Editörü)     │
│  - HyprlandPage.qml (Kenarlık & Animasyon Ayarları)    │
└───────────────────────────┬────────────────────────────┘
                            │ NDJSON RPC Komutları
                            │ (/run/user/1000/ogs_shell.sock)
┌───────────────────────────▼────────────────────────────┐
│         Hyprland Manager (core/services/hyprland)      │
│  - Inode File Watcher (fsnotify on active_state.lua)   │
│  - Atomic Disk Commits (active_state, custom_curves)   │
│  - 0ms Zero-Latency Runtime Preview (hyprctl eval)     │
└──────────────┬──────────────────────────┬──────────────┘
               │ hyprctl reload / eval    │ Disk Senkronizasyonu
┌──────────────▼─────────────┐ ┌──────────▼──────────────┐
│     Hyprland Compositor    │ │ ~/.config/hypr/lua/     │
│       (Canlı Oturum)       │ │ ├── active_state.lua    │
│                            │ │ ├── profiles/borders/   │
│                            │ │ └── profiles/animations/│
└────────────────────────────┘ └─────────────────────────┘
```

---

## 2. Temel Fonksiyonlar ve Yetenekler

### 1. Çift Yönlü Reaktif Durum Takibi (`active_state.lua`)
* `fsnotify` izleyicisi ile `~/.config/hypr/lua/active_state.lua` dosyasındaki değişiklikler (terminalden, scriptlerden veya kısayollardan yapılsa dahi) 150ms debouncing ile dinlenir.
* Değişiklik anında sokete bağlı tüm arayüzlere `hypr_state_update` yayını (broadcast) yapılır.

### 2. Canlı 0ms Önizleme (`preview_hypr_eval`)
* Kullanıcı ayar arayüzünde kaydırıcıları sürüklerken veya Bézier tutamaçlarını oynatırken diske dosya yazılmaz.
* Doğrudan `hyprctl eval` aracılığıyla `hl.config(...)` veya `hl.curve(...)` çalıştırılarak pencerelerin gecikmesiz olarak yeni parametreleri alması sağlanır.

### 3. Özel Bézier Eğrileri Kütüğü (`custom_curves.lua`)
* [[Settings-Application-Component]] içerisindeki Cubic Bézier jeneratöründen üretilen eğriler atomik olarak `~/.config/hypr/lua/profiles/animations/custom_curves.lua` dosyasına işlenir ve çalışan kompozitör oturumuna anında enjekte edilir.

### 4. Özel Kenarlık Profilleri (`custom_<name>.lua`)
* Kullanıcı tarafından oluşturulan kenarlık kalınlığı, squircle köşe yarıçapı (`rounding_power`), boşluklar ve gölge değerleri yeni bir profil dosyası olarak kaydedilir ve atomik olarak aktif edilir.

---

## 3. Desteklenen IPC Uçları

* **`get_hypr_state`**: Aktif ve diskteki tüm mevcut profil listelerini döner.
* **`set_hypr_profile`**: Belirtilen kategorideki profili aktif eder ve `hyprctl reload` tetikler.
* **`preview_hypr_eval`**: 0ms canlı test için Lua kodunu çalıştırır.
* **`save_custom_curve`**: Yeni Bézier eğrisini kaydeder ve kompozitöre bildirir.
* **`save_custom_border`**: Yeni özel dekorasyon profilini oluşturur ve seçer.

---

## 4. İlgili Bağlantılar

* Sistem Mimarisi: [[System-Architecture]]
* Backend IPC Referansı: [[Backend-Endpoints-Reference]]
* Frontend IPC İstemcisi: [[Daemon-IPC-Client]]
* Ayarlar Uygulaması: [[Settings-Application-Component]]
* Tema Servisi: [[Theme-Service]]
