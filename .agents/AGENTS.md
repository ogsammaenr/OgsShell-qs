# 🤖 OGSSHELL-QS AGENT DIRECTIVES & OPERATIONAL RULES

Bu dosya, `ogsShell-qs` projesinde çalışan tüm AI Ajanları (Cursor, Windsurf, Claude Dev vb.) için **KESİN VE BĞLAYICI** çalışma kurallarını içerir.

---

## 1. Çalışma Sınırları ve Kapsam (Strict Scope)

* **SADECE FRONTEND (`shell/`):** Ajan yalnızca Quickshell QML katmanındaki (`shell/` dizini) arayüz, stil ve widget bileşenleri üzerinde düzenleme yapabilir.
* **BACKEND DOKUNULMAZLIĞI (`core/`):** Go ile yazılmış backend servislerine (`core/` dizini) **kullanıcı talebi olmadıkça dokunulmazdır**.
* **SETTINGS APP (`settings_app/`):** Kullanıcı açıkça talep etmediği sürece PySide6 ayarlar uygulamasına dokunulmaz.

---

## 2. Görev Öncesi ve Sonrası Yaşam Döngüsü (Pre & Post Task Lifecycle)

Ajan her yeni göreve başladığında ve görevi tamamladığında aşağıdaki adımları **sırasıyla** takip etmek zorundadır:

1. **[GÖREV ÖNCESİ - 1] Mimari Kontrolü:** İstisnasız her görevden önce `.agents/ARCHITECTURE.md` dosyası okunmalı ve mevcut mimari durum anlaşılmalıdır.
2. **[GÖREV ÖNCESİ - 2] Backend Erişim Uçları Kontrolü:** Frontend (`shell/`) veya IPC katmanında herhangi bir geliştirme/refactoring yapmadan önce `.agents/BACKEND_ENDPOINTS.md` dosyası incelenmeli, backend'in (`core/`) sunduğu RPC action'lar, yayınlanan event'ler ve payload şemaları teyit edilmelidir.
3. **[GÖREV ÖNCESİ - 3] Obsidian Doküman Kontrolü:** Düzenlenecek veya oluşturulacak bileşenlerle ilgili dokümantasyon `ogsShell-qs_brain/` dizininden okunmalıdır.
   * Eğer ilgili dosya/bileşen için Obsidian notu **yoksa**, ajan kodu yazmadan önce dokümanı oluşturmalıdır.
4. **[GÖREV ÖNCESİ - 4] Düşünce Günlüğü:** Karmaşık refactoring veya yeni UI bileşeni eklenmeden önce `ogsShell-qs_brain/05-Agent-Thoughts/` altına `status: proposed` durumunda bir plan notu yazılmalıdır.
5. **[GÖREV SONRASI - 1] Mimari ve Erişim Uçları Güncelleme:** Görev tamamlandıktan sonra yapılan tüm mimari güncellemeler `.agents/ARCHITECTURE.md` dosyasına ve yeni/güncellenen IPC uçları `.agents/BACKEND_ENDPOINTS.md` dosyasına işlenmelidir.
6. **[GÖREV SONRASI - 2] Dokümantasyon Güncelleme:** Yapılan kod değişiklikleri `ogsShell-qs_brain/` altındaki ilgili notlara yansıtılmalı ve düşünce günlüğü notunun durumu `status: implemented` olarak güncellenmelidir.

---

## 3. Frontend & Quickshell QML Mimari Kuralları

* **Dynamic Island Fiziği:** Ada boyutlandırılmasında reaktif `implicitWidth` ve `implicitHeight` kullanılacaktır. Boyut animasyonlarında `SpringAnimation` (`spring: 28.0`, `damping: 0.78`, `epsilon: 0.01`) tercih edilmelidir.
* **Wayland LayerShell Katmanı:** `PanelWindow` nesnesi `exclusionMode: ExclusionMode.Ignore` olarak yapılandırılmalıdır. Dynamic Island ekranın üstünde süzülen bir overlay'dir; Hyprland tiling pencerelerini aşağı itmemelidir.
* **Durum Öncelik Matrisi (State Priority Matrix):**
  $$\text{EXPANDED\_APP} > \text{TRANSIENT} > \text{HOVER} > \text{IDLE}$$
  Düşük öncelikli olaylar aktif kullanıcı etkileşimlerini (EXPANDED) ezemez.
* **Modüler Slot Mimarisi:** Adanın içine girecek her içerik `shell/components/widgets/` altında modüler birer QML bileşeni (`Widget`) olarak tasarlanmalıdır. `DynamicIsland.qml` içerisine monolitik kod gömülmemelidir.
* **Tek Yönlü Veri Akışı:** IPC üzerinden gelen Go verileri reaktif olarak okunmalı; QML doğrudan soket durumunu manipüle etmeye çalışmamalıdır.

---

## 4. Modül & Import Standartları

* Singleton erişimlerinde (örneğin `Style.qml`) göreli dizin yapısına (`import "../.."`) veya `qmldir` kurallarına harfiyen uyulmalıdır.
* Olmayan Quickshell API property'leri (örneğin `exclusionZone`, `WlrLayers.layer`, `Socket.active`) **uydurulmamalı (hallucinate edilmemeli)**, Quickshell'in güncel C++ bağlama dokümantasyonu esas alınmalıdır.

---

## 5. Obsidian Brain ve Dokümantasyon Yönetimi (`obsidian-glossary`)

Projeyle ilgili mimari dokümantasyon, servis tanımları, UI bileşenleri veya ajan düşünce günlükleri (`ogsShell-qs_brain/` dizini) yazılırken veya güncellenirken daima [.agents/skills/obsidian-glossary/SKILL.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/skills/obsidian-glossary/SKILL.md) dosyasında tanımlı `obsidian-glossary` skill kurallarına uyulması ZORUNLUDUR:

* **Dizin Yapısı:** `ogsShell-qs_brain/` altında `01-Architecture/`, `02-Services/`, `03-UI-Components/`, `04-Agent-Rules/` ve `05-Agent-Thoughts/` klasör yapısına sadık kalın.
* **Wikilink Bağlantıları:** Oluşturulan ve güncellenen tüm notlarda diğer ilgili notlara `[[Not-Adı]]` biçiminde Obsidian Wikilink bağlantısı verin. Bağlantısız (yetim) not oluşturmayın.
* **Obsidian Standartları:** Notların başında YAML frontmatter (`title`, `type`, `tags`, `created`, `updated`, `status`, `related_notes`) kullanın ve callout bloklarını (`> [!NOTE]`, `> [!WARNING]`, `> [!IDEA]`) uygulayın.
* **Düşünce Günlüğü (`05-Agent-Thoughts/`):** Karmaşık refactoring ve mimari değişikliklerden önce bir plan/proposal notu oluşturun; işlem tamamlandığında notun durumunu `status: implemented` olarak güncellenin.

---

## 6. Kanonik Konfigürasyon Dizini ve Harf Duyarlılığı Standartları (Strict XDG Standard)

Tüm AI Ajanları konfigürasyon ve kalıcı veri dosyalarına erişirken aşağıdaki kurallara **İSTİSNASIZ** uymak zorundadır:

* **TEK GEÇERLİ KONFİGÜRASYON DİZİNİ:** Kullanıcı bazlı tüm çalışma zamanı, tema ve ayar JSON dosyaları İSTİSNASIZ `$XDG_CONFIG_HOME/ogsShell/` (varsayılan: `~/.config/ogsShell/`) altında saklanmalıdır.
* **KESİN HARF DUYARLILIĞI KURALI (Case-Sensitivity):** Dizin adı daima **`ogsShell`** (büyük `S` ile) olmalıdır.
  - ❌ **YASAK:** `~/.config/ogsshell`, `~/.config/ogs-shell`, `~/.config/ogs_shell` vb. alternatif dizinler oluşturulamaz, okunamaz ve kodlanamaz.
  - ✅ **ZORUNLU:** `~/.config/ogsShell/`
* **Standart JSON Dosya İsimleri ve Sorumlulukları:**
  - `config.json`: Shell HUD, Ada/Çentik geometrisi, tipografi ve animasyon ayarları.
  - `theme_config.json`: Aktif tema seçimi ve etkin uygulama adaptörleri listesi.
  - `wallpaper_state.json`: Aktif duvar kağıdı ve temalara özel seçilmiş görsel yolları.
  - `alarms.json`: Kayıtlı alarmlar ve zamanlayıcılar.
  - `calendar_events.json`: Takvim etkinlikleri, hatırlatıcılar ve tatiller.
  - `notifications.json` & `notification_rules.json`: Bildirim geçmişi ve uygulama bazlı kurallar.
  - `keyboard_config.json`: Yapılandırılmış ve aktif klavye düzenleri.
  - `launcher_stats.json`: Uygulama kullanım sıklığı (frecency) istatistikleri.
  - `clipboard_pinned.json`: Panoya sabitlenmiş favori metin parçacıkları.

---

## 7. Konfigürasyon Sistemi Mimarisi ve Geliştirme Kuralları (`config.json`)

`ogsShell-qs`, arayüzün (HUD, Dynamic Island/Notch, tipografi, animasyon ve geometriler) tek bir merkezden kod değiştirmeden yönetilmesini sağlayan reaktif ve çift yönlü bir konfigürasyon motoruna sahiptir.

### 7.1. Çalışma Prensibi ve Çift Yönlü Canlı Eşitleme (Dual Reactive Sync)

1. **İki Dosya İzleyicisi:** `shell/backend/Config.qml` singleton'ı iki `FileView` barındırır:
   - `workspaceConfigFile`: Proje çalışma dizinindeki `shell/config.json` dosyasını izler.
   - `configFile`: Kullanıcının `$XDG_CONFIG_HOME/ogsShell/config.json` dosyasını izler.
2. **Otomatik Senkronizasyon:** `shell/config.json` değiştirildiğinde (geliştirici veya kullanıcı tarafından düzenlendiğinde), `Config.qml` yeni verileri okur ve `syncToUserConfig()` aracılığıyla `$XDG_CONFIG_HOME/ogsShell/config.json` dosyasını da anında günceller.
3. **Canlı Yeniden Yükleme (Hot-Reload):** `Config.qml` içindeki `configRevision` sayacı artırılarak tüm pencere katmanları (`reservedSpacerWindow`), giriş maskeleri (`activeInputEnvelope`), vektör çizimleri (`notchVectorShape`) ve QML metin boyutları kabuk kapatılmadan anında yeniden hesaplanır.

### 7.2. Mevcut `config.json` Şema Blokları

* `"form_factor"`: `"island"` (süzülen kapsül) veya `"notch"` (üst panele yapışık çentik).
* `"theme"`: Renk paleti (`catppuccin`, `nord`, `tokyonight`, `everforest`, `gruvbox`, `monochrome`).
* `"typography"`: Font ve ikon boyutları (`clock_idle_size`, `clock_hover_size`, `date_hover_size`, `media_title_size`, `media_artist_size`, `connectivity_text_size`, `connectivity_icon_size`, `notification_title_size`, `notification_body_size`, `pinned_metrics_size`, `pinned_metrics_icon_size`).
* `"island"`: Floating Island modu genişlik, yükseklik, kenar boşluğu ve köşe yarıçapları.
* `"notch"`: Dynamic Notch modu genişlik, yükseklik ve alt Bézier kavis yarıçapları.
* `"notifications"`: Bildirim motoru ayarları (`enabled`, `default_timeout_ms`).
* `"animation"`: Geçiş süreleri ve yay katsayıları (`duration_compact`, `duration_transient`, `duration_expanded`, `overshoot_factor`).

### 7.3. Gelecekte Yeni Bir Konfigürasyon Özelliği Eklerken Zorunlu Adımlar

Bir AI Ajanı yeni bir UI/HUD özelliği veya ayarlanabilir bir parametre eklerken **aşağıdaki 4 adımı eksiksiz uygulamalıdır**:

1. **`shell/backend/Config.qml`:**
   - Yeni kategori için varsayılan değerleri içeren bir `property var <kategori>` nesnesi tanımlayın.
   - `loadConfigString(jsonStr)` fonksiyonunda `if (cfg.<kategori>) root.<kategori> = Object.assign({}, root.<kategori>, cfg.<kategori>)` ile parse adımını ekleyin.
2. **JSON Şablonlarını Güncelleyin:**
   - Hem `shell/config.json` hem de `shared/app_configs/shell/config.json` dosyalarına yeni anahtarları varsayılan değerleriyle ekleyin.
3. **QML Bileşenlerinde Reaktif Bağlama (Binding):**
   - İlgili QML bileşeninde değerleri ASLA sabit (hardcoded) yazmayın. Daima `Config.<kategori>.<anahtar> || <varsayılan_değer>` şeklinde bağlayın.
4. **Obsidian Bilgi Bankasını Güncelleyin:**
   - `ogsShell-qs_brain/01-Architecture/Configuration-System-Spec.md` dosyasına yeni şema özelliklerini ve tiplerini işleyin.

