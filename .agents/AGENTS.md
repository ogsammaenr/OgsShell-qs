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
