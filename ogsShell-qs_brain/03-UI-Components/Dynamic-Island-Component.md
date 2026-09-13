---
title: "Dynamic Island Core QML Component"
type: ui-component
tags:
  - ui/dynamic-island
  - quickshell/qml
  - state-machine
  - animations
  - transient/notifications
  - hover-state
  - focus-mode
  - autohide
created: 2026-08-09
updated: 2026-08-16
status: active
related_notes:
  - "[[Apple-Dynamic-Island-HIG]]"
  - "[[Dynamic-Island-Physics-State-Machine]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Clock-Widget]]"
  - "[[Media-Widget]]"
  - "[[Connectivity-Status-Widget]]"
  - "[[Control-Center-Widget]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Notification-Card-View]]"
  - "[[Notification-Deck-Background]]"
---

# Dynamic Island Core QML Component

> [!NOTE]
> `shell/components/island/DynamicIsland.qml` contains the core UI container, reactive sizing calculations, spring animations, state machine (`IDLE`, `HOVER`, `EXPANDED`, `TRANSIENT`), D-Bus notification receiver, gesture handling, and smart Focus Mode (autohide) integration.

---

## 1. State Machine & Visual Layers

```mermaid
graph TD
    IDLE["IDLE State<br/>(180x36, Compact Clock)"] -->|Mouse Enter| HOVER["HOVER State<br/>(420x50, 3-Column Status Bar)"]
    HOVER -->|Mouse Exit| IDLE
    HOVER -->|Left Click Time| EXPANDED_CLOCK["EXPANDED State (Clock App)"]
    HOVER -->|Left Click Date| EXPANDED_CAL["EXPANDED State (Calendar App)"]
    HOVER -->|Right Click Island| EXPANDED_CC["EXPANDED State (Control Center)"]
    HOVER -->|Left Click Network Pill| EXPANDED_CC
    
    ANY["IDLE / HOVER"] -->|triggerNotification() / notify-send| TRANSIENT["TRANSIENT State<br/>(340x56, Notification Toast)"]
    TRANSIENT -->|transientTimer.onTriggered| IDLE
    TRANSIENT -->|Click Body| IDLE
```

---

## 2. Focus Modu & Akıllı Autohide (Smart Reveal Architecture)

1. **Sıfır Üst Kenar Boşluğu (Zero Top Exclusion Zone):** Focus Modu aktifken `reservedSpacerWindow`'ın `exclusionMode` özelliği `ExclusionMode.Ignore` yapılarak Hyprland pencerelerinin ekranın en üstüne (`y: 0`) kadar tam ekran büyümesi sağlanır.
2. **Akıllı Monitör Bazlı Tiling Tespiti (Per-Monitor Smart Tiling Detection):**
   - Her monitör (`screenScope`) için bağımsız `Hyprland.monitorFor(screen)` üzerinden aktif çalışma alanı çözümlenir.
   - İlgili monitörün aktif çalışma alanında **tiling (floating olmayan)** bir pencere varsa $\to$ Ada yalnızca o monitörde ekranın dışına (`y: -height - 12`) saklanır.
   - İlgili monitörde **tiling pencere yoksa** (boş masaüstü veya serbest pencereler) $\to$ Ada o monitörde masaüstünde estetik bir şekilde görünür kalır.
   - Detaylı plan: `[[Plan-Per-Monitor-Focus-Mode-Autohide]]`.
3. **Ekran Üst Kenar Reveal Hotspot:**
   - Fare ekranın en üst kenarına yaklaştığında (`topHotspotMouseArea`) ada `SpringAnimation` ile aşağı iner.
   - Fare ayrıldığında 350ms debounce ile tekrar yukarı saklanır.
   - `EXPANDED` veya `TRANSIENT` durumlarında ada kullanıcı işlemi bitene kadar açık kalır.

---

## 3. Geometry & Gesture Interactions

* **IDLE State:** `180-190px` $\times$ `34-36px`. Displays single-line `[[Clock-Widget]]`.
* **HOVER State:** `420-430px` $\times$ `48-50px`. Expands into a 3-column status bar with:
  * Left: `[[Media-Widget]]` (MPRIS Player & Animated Equalizer, Left-click toggles play/pause)
  * Center: `[[Clock-Widget]]` (Left-click Time opens Clock Suite, Left-click Date opens Calendar)
  * Right: `[[Connectivity-Status-Widget]]` (Wi-Fi & Bluetooth Button, Left-click opens Control Center)
  * **Ada Geneli Sağ Tık (Right-Click):** Hover durumundayken adanın herhangi bir yerine sağ tıklandığında anında `[[Control-Center-Widget]]` açılır.
* **EXPANDED State:** Full modal with Clock Suite, Calendar & Events, or Control Center Suite.
  * **5-Saniye Odak/Ayrılma Zaman Aşımı (5s Unfocus Auto-Collapse):** Ada genişletilmiş moddayken fare imleci adanın dışına çıktığında 5 saniyelik bir geri sayım başlar. İmleç 5 saniye dolmadan adaya geri dönerse sayaç sıfırlanır; 5 saniye boyunca dönmezse ada kendiliğinden `IDLE` moduna kapanır.
* **TRANSIENT State:** `340-350px` $\times$ `56-58px`. Çoklu bildirim geldiğinde 3D Katmanlı Kart Destesi mimarisine geçer:
  * **1. Katman (Ön/Aktif):** Genişlik %100, Y=0, Opacity 1.0. Uygulama ikonu / aciliyet halkası, başlık, gövde ve `[+X Deste]` rozeti içerir (`[[Notification-Card-View]]`).
  * **2. Katman (Orta):** Genişlik %91, Opacity 0.75. Island modunda +8px, Notch modunda tavandan +9px aşağı sarkar (`NotificationDeckBackground`).
  * **3. Katman (Dip):** Genişlik %82, Opacity 0.45. Island modunda +16px, Notch modunda tavandan +17px aşağı sarkar.
  * **Aciliyet Önceliği (Critical Urgency Preemption):** `urgency === "critical"` bildirimler kuyruğu atlayarak en başa fırlar ve kırmızı uyarı tonlarıyla anında gösterilir.
  * **Animasyon Koreografisi & Çift Kart Kayma Geçişi (Dual-Card Slide Transition):**
    - **Eşzamanlı Dikey Kayma (`transitionToNextSequence`):** Mevcut bildirim yukarı doğru kayarak (`y: 0 -> -36px`, `opacity: 1.0 -> 0.0`) çıkarken, sıradaki bildirim aynı anda alttan yukarı kayarak (`y: +36px -> 0px`, `opacity: 0.0 -> 1.0`) merkeze yerleşir (260ms `Easing.OutCubic`). Bildirimler arasında asla boş siyah katman boşluğu oluşmaz; mekanik ve akıcı bir sayaç/ticker hissi sağlar.
    - **Fiziksel Deste Senkronizasyonu (`shiftProgress` & `hasCardBehind`):** Yalnızca 2 bildirim varken Katman 2 yukarı toplanarak (`9px -> 0px`) Notch ile birleşir. 3 bildirim varken (`hasCardBehind: true`), Katman 2 +9px'de sabit kalırken Katman 3 destesi alttan (+17px) pürüzsüzce yukarı kayarak (`17px -> 9px`, `%82 -> %91`, `%45 -> %75`) Katman 2'nin arkasına yerleşir ve birleşir. Animasyon bitiminde re-spring / sekme yaşanmaz.
    - **Atomik Durum Değişimi & Sıfır Glitch:** Animasyon tamamlandığında (`onFinished`) `performStackShift()` çalıştırılarak yeni bildirime geçilir. Gelen kart (`incomingCardContainer`) ve ön kart (`currentCardContainer`) animasyon bitiminde birebir aynı koordinatlarda ve metin içeriklerinde olduğundan anlık sıçrama veya titreşim (glitch) %100 engellenir.
    - **Son Kart Kapanışı (`dismissLastSequence`):** Kuyruktaki tek/son bildirim kapandığında yukarı doğru kayıp (`y: 0 -> -32px`) söner ve ada pürüzsüzce `IDLE` boyutlarına küçülür; kapanan bildirim asla tekrar anlık görünmez.
    - **Uygulama Focus / Sol Tık (`focusLaunchSequence`):** Sol tıklandığında kart 75ms'de hafifçe basılır (`scale: 0.94`), Hyprland penceresi odaklanır / uygulama başlatılır. Destede başka bildirim varsa çift kart kayma geçişi başlar; son bildirimse yukarı süzülerek ada `IDLE` moduna döner.
    - **Hover:** Fare kartların üzerindeyken otomatik kapanma zamanlayıcısı duraklatılır, fare ayrıldığında süre devam eder.
    - **Sağ Tık:** Tüm desteyi tek seferde temizler (`clearNotificationStack()`).
  * **Wayland Giriş Maskesi:** `activeInputEnvelope` yüksekliği, sarkan katmanları (+18px) da kapsayacak şekilde dinamik genişler.

---

## 4. Related Links

* Shell Root: `[[Shell-Root-PanelWindow]]`
* Notification Card View: `[[Notification-Card-View]]`
* Notification Deck Background: `[[Notification-Deck-Background]]`
* Clock Widget: `[[Clock-Widget]]`
* Media Widget: `[[Media-Widget]]`
* Connectivity Status Widget: `[[Connectivity-Status-Widget]]`
* Control Center: `[[Control-Center-Widget]]`
* Design Tokens: `[[Style-Design-Tokens]]`
* State Machine & Physics: `[[Dynamic-Island-Physics-State-Machine]]`

