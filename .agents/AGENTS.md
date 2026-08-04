# OgsShell-qs Geliştirme Kuralları (AGENTS.md)

Bu kurallar, OgsShell-qs projesinde kod yazacak veya değişiklik yapacak tüm yapay zeka (AI) geliştirici ajanlar ve yazılımcılar için bağlayıcıdır.

---

## 1. Mimari Standartlar
* **Modüler Yapıya Bağlılık:** Kod eklerken veya değiştirirken kesinlikle monolitik yapılar kurmayın. Projedeki tüm kodlar [ARCHITECTURE.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ARCHITECTURE.md) dosyasında tanımlanan **Servis-Pencere-Bileşen (Service-Window-Component)** desenine uymalıdır.
  - Veri işleme, C daemons, dbus ve süreç yönetimi -> `services/`
  - Quickshell `PanelWindow` tanımları -> `windows/`
  - Görsel arayüzler ve widget'lar -> `components/`

* **Ekran/Monitör Yüklemesi:** Yeni bir pencere (Window) eklerken, bunu doğrudan `shell.qml` içinde tekil olarak değil, her monitör için çoğaltılabilmesi için `windows/MonitorGroup.qml` içine dahil edin (Sadece güç menüsü gibi sistem geneli tekil pencereler hariç).

---

## 2. Kodlama Kuralları ve Önlemler
* **Shadowing Önleme Kuralı:** Quickshell pencerelerinde `screen` isminde özel bir property tanımlamayın. Yerleşik `screen` özelliğiyle çakışmayı önlemek için daima `targetScreen` ismini kullanın ve `screen: targetScreen` bağlamasını yapın.
* **Global Servislere Erişim:** Yeni eklenen özellikleri doğrudan alt bileşenlerde `Process` olarak başlatmak yerine `services/` altında global bir servis tanımlayarak veriyi oradan bind edin.
* **Hizalamalar ve anchors:** Yeni bir ada veya widget'ı bar içine yerleştirirken `TopBarWindow.qml` içindeki anchors kurallarını milimetrik olarak belirtin. `anchors` belirtilmemiş bileşenler bar hizalamasını bozacaktır.

---

## 3. Çalışmaya Başlamadan Önce
* Proje dosyalarında herhangi bir değişiklik yapmadan önce daima [ARCHITECTURE.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/ARCHITECTURE.md) dosyasını okuyun ve projenin mevcut güncel yapısını analiz edin.

---

## 4. Dosya ve Bileşen Sözlüğü (GLOSSARY.md) Kullanımı
Projeye yeni bir dosya eklemeden, mevcut bir dosyada değişiklik yapmadan veya hata ayıklamaya başlamadan önce daima [.agents/GLOSSARY.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/GLOSSARY.md) sözlüğünü okuyun.
* **Bileşen/Servis Keşfi:** Yeni bir UI elemanı eklerken veya sistem verisine ihtiyaç duyduğunuzda, ilgili bileşenin veya servisin adını ve konumunu sözlükten bulun.
* **Arayüzlerin Kontrolü:** Servislerin dışa aktardığı özellikleri (`properties`), sinyalleri (`signals`) ve fonksiyonları sözlükten inceleyerek veri bağlamalarını (binding) doğru şekilde yapın.
* **Sözlüğün Güncel Tutulması:** Projeye yeni bir QML dosyası, servis, pencere veya C fonksiyonu eklediğinizde, bu dosyanın amacını ve özelliklerini mutlaka [.agents/GLOSSARY.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/GLOSSARY.md) dosyasına ekleyerek güncelleyin.

---

## 5. Obsidian Brain ve Dokümantasyon Yönetimi (`obsidian-glossary`)
Projeyle ilgili mimari dokümantasyon, servis tanımları, UI bileşenleri veya ajan düşünce günlükleri (`ogsShell-qs_brain/` dizini) yazılırken veya güncellenirken daima [.agents/skills/obsidian-glossary/SKILL.md](file:///home/excalibur/WorkSpace/projects/OgsShell-qs/.agents/skills/obsidian-glossary/SKILL.md) dosyasında tanımlı `obsidian-glossary` skill kurallarına uyulması ZORUNLUDUR:
* **Dizin Yapısı:** `ogsShell-qs_brain/` altında `01-Architecture/`, `02-Services/`, `03-UI-Components/`, `04-Agent-Rules/` ve `05-Agent-Thoughts/` klasör yapısına sadık kalın.
* **Wikilink Bağlantıları:** Oluşturulan ve güncellenen tüm notlarda diğer ilgili notlara `[[Not-Adı]]` biçiminde Obsidian Wikilink bağlantısı verin. Bağlantısız (yetim) not oluşturmayın.
* **Obsidian Standartları:** Notların başında YAML frontmatter (`title`, `type`, `tags`, `created`, `updated`, `status`, `related_notes`) kullanın ve callout bloklarını (`> [!NOTE]`, `> [!WARNING]`, `> [!IDEA]`) uygulayın.
* **Düşünce Günlüğü (`05-Agent-Thoughts/`):** Karmaşık refactoring ve mimari değişikliklerden önce bir plan/proposal notu oluşturun; işlem tamamlandığında notun durumunu `status: implemented` olarak güncelleyin.
