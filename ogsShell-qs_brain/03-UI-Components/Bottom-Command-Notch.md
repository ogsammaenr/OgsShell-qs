---
title: "Inverted Bottom Notch & Shell Command Runner Component"
type: ui-component
tags:
  - quickshell/qml
  - bottom-notch
  - command-palette
  - wayland/layershell
  - ui/widgets
status: active
---

# Inverted Bottom Notch & Shell Command Runner Component

Ekranın en alt kenarına oturan, üstteki Dinamik Ada'nın `notch` formuyla **birebir aynı açı, $G^2$ Bézier kulak eğimleri ve köşe yuvarlatmalarına sahip** "Ters Çentik (Inverted Bottom Notch)" ve içerisinde çalışan tek satırlık minimalist "Shell Komut Paleti (Command Runner)" bileşeni.

> [!NOTE]
> Bu bileşen, macOS tarzı üst çentik tasarımını ekranın alt tabanına kusursuz bir ayna simetrisiyle yansıtarak, klavye odaklı hızlı komut yürütme (tema, duvar kağıdı, sistem ayarları ve güç yönetimi) imkanı sunar.

---

## 1. Mimari ve Dosya Konumları

* **QML UI Bileşeni:** `shell/components/bottomnotch/BottomCommandNotch.qml`
* **Durum Singleton Servisi:** `shell/backend/BottomNotchService.qml`
* **Wayland LayerShell Entegrasyonu:** `shell/shell.qml` (`bottomNotchWindow`)
* **Tetikleme Betiği:** `~/.config/ogsShell/ogsshell.sh toggle_bottom_notch` (veya `ogsshell.sh notch`)

---

## 2. Aynalanmış Bézier Kavisleri (Exact Inverted Geometry)

Üst çentik (`[[Dynamic-Notch-Design-Specification]]`) üst kenardan ($y = 0$) aşağıya doğru nasıl iniyorsa, alt çentik de ekranın en alt tabanından ($y = H$) yukarıya doğru **aynı Bézier kulak genişliği ($E_w = 5\text{px}$), kulak eğimi ($E_h \approx 16\text{px}$) ve köşe yarıçapları ($R = 20-26\text{px}$)** ile yükselir.

```text
           (E+R, 0)-----------------------------------------------(E+W-R, 0)
             / (PathArc: Clockwise)             (PathArc: Clockwise) \
            /                                                         \
         (E, R)                                                    (E+W, R)
            |                                                         |
            | (Sol Dikey Duvar)                         (Sağ Dikey)   |
            |                                                         |
          (E, H-Eh)                                                (E+W, H-Eh)
            /  (PathCubic Slope: 5px x 16px)     (PathCubic Slope: 5px x 16px)\
Taban -----/                                                          \-----
       (0, H)                                                    (2E+W, H)
```

### Vektör Yol Topolojisi (`ShapePath`):
1. **Sol Kulak:** `(0, H)` noktasından başlar. `control1: (Ew*0.35, H)` ve `control2: (Ew, H - Eh*0.65)` kontrol noktaları ile `(Ew, H - Eh)` noktasına $dy/dx = 0$ yatay teğetle bağlanır.
2. **Sol Dikey Duvar:** `(Ew, R)` noktasına uzanır.
3. **Sol Üst Köşe Kavis:** `PathArc { radius: R, direction: PathArc.Clockwise }` ile saat yönünde `(Ew + R, 0)` tavanına döner.
4. **Üst Tavan Çizgisi:** `(Ew + W - R, 0)` noktasına kadar uzanır.
5. **Sağ Üst Köşe Kavis:** `PathArc { radius: R, direction: PathArc.Clockwise }` ile saat yönünde `(Ew + W, R)` noktasına döner.
6. **Sağ Dikey Duvar:** `(Ew + W, H - Eh)` noktasına iner.
7. **Sağ Kulak:** `control1: (Ew + W, H - Eh*0.65)` ve `control2: (Ew + W + Ew*0.65, H)` ile `(2*Ew + W, H)` tabanına $dy/dx = 0$ ile oturur.
8. **Taban Kapatma:** `(0, H)` çizgisi ile ekran tabanına sıfır boşlukla kapanır.
9. **Retina Anti-Aliasing:** `layer.enabled: true`, `layer.samples: 4`, `layer.smooth: true` ile 4x/8x MSAA kenar yumuşatma uygulanır.

---

## 3. Wayland LayerShell ve Odak Mimarisi

Bileşen `[[Shell-Root-PanelWindow]]` içerisinde bağımsız bir `PanelWindow` olarak barındırılır:

* **Katman:** `WlrLayershell.layer: WlrLayer.Overlay`
* **Exclusion Modu:** `exclusionMode: ExclusionMode.Ignore` (Pencereleri yukarı itmez, overlay olarak süzülür).
* **Klavye Odağı:** Çentik açıldığında `WlrKeyboardFocus.Exclusive` ile klavye girdilerini devralır, kapandığında `WlrKeyboardFocus.None` ile serbest bırakır.
* **Girdi Maskesi (`mask: Region`):** Pencerelerin tıklanmasını engellememek için `activeBottomInputEnvelope` ile **yalnızca alt çentiğin ve öneri listesinin fiziksel pikselleri** tıklanabilir tutulur.
* **Arka Plan Tıklama İptali:** `backdropWindow` ile çentik dışındaki herhangi bir yere tıklandığında veya `Escape` basıldığında çentik aşağı çekilerek kapanır.

---

## 4. Shell Komut Paleti (Command Runner) Yetenekleri

Çentik içinde tek satırlık minimalist bir komut girişi (`TextInput`) ve üzerinde/içinde açılan reaktif bir öneri listesi (`ListView`) yer alır:

### 1. 🎨 Tema Yönetimi (`:theme`)
* `:theme <isim>` -> `[[Theme-Service]]` üzerinden `DaemonIPC.setActiveTheme(themeId)` tetikler.
* `:theme ` -> Sistemdeki tüm temaları listeler. Ok tuşlarıyla gezinirken temaların 4 ana renk palet küpü (`accent`, `accentSecondary`, `green/cyan`, `surface/bg`) dinamik olarak gösterilir.

### 2. 🖼️ Duvar Kağıdı Yönetimi (`:wall`)
* `:wall next` -> `DaemonIPC.nextWallpaper()` ile sıradaki görsele geçer.
* `:wall <isim>` -> Aktif temanın duvar kağıtlarını listeler ve sağ tarafta mini thumbnail görsel önizlemesi sunar.

### 3. ⚙️ Ayarlar & Konfigürasyon (`:set`)
* `:set focus on/off` -> `[[Configuration-System-Spec]]` Focus Modunu açar/kapatır.
* `:set factor island/notch` -> Dinamik Ada ve Çentik form faktörünü anında değiştirir.
* `:set corners on/off` -> `[[Screen-Corners-Component]]` ekran köşe yuvarlatmalarını açar/kapatır.
* `:set dnd on/off` -> Rahatsız Etme (DND) modunu değiştirir (`toggle_dnd`).
* `:set volume <0-100>` -> PipeWire ve `pamixer` üzerinden ses seviyesini ayarlar.
* `:mute` -> Ses çıkışını susturur / açar.

### 4. ⚡ Oturum & Güç Yönetimi
* `:lock` -> `hyprlock` ile oturumu kilitler (`[[Power-Overlay-Component]]`).
* `:sleep` -> `systemctl suspend` ile uyku moduna alır.
* `:reboot` -> `systemctl reboot` ile sistemi yeniden başlatır.
* `:shutdown` -> `systemctl poweroff` ile bilgisayarı kapatır.

### 5. 󰌒 Akıllı Otomatik Tamamlama (`Tab`)
* Kullanıcı bir komutun veya argümanın ön ekini yazarken `Tab` tuşuna bastığında, seçili öneri otomatik olarak metin satırına tamamlanır.

---

## 5. İlgili Dokümantasyon & Bağlantılar

* Üst Çentik Tasarım Şartnamesi: `[[Dynamic-Notch-Design-Specification]]`
* Dinamik Ada Bileşeni: `[[Dynamic-Island-Component]]`
* Shell Root Pencere Katmanı: `[[Shell-Root-PanelWindow]]`
* IPC İstemci Mimarisi: `[[Daemon-IPC-Client]]`
* Tema Dağıtıcı Servisi: `[[Theme-Service]]`
* Güç & Oturum Menüsü: `[[Power-Overlay-Component]]`
* Stil & Tasarım Belirteçleri: `[[Style-Design-Tokens]]`
* Konfigürasyon Şartnamesi: `[[Configuration-System-Spec]]`
* Uygulama Başlatıcı: `[[App-Launcher-Widget]]`
