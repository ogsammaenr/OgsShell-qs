---
title: "Plan: System Settings Application Framework and Network & DNS Settings Page"
type: agent-thought
tags:
  - frontend/qml
  - settings/app
  - network/dns
  - quickshell/layershell
  - apple/hig
created: 2026-08-23
updated: 2026-08-23
status: implemented
related_notes:
  - "[[System-Architecture]]"
  - "[[Style-Design-Tokens]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Wifi-Client-Service]]"
  - "[[Settings-Application-Component]]"
  - "[[Plan-Backend-Network-Details-And-DNS-Management]]"
---

# Plan: System Settings Application Framework and Network & DNS Settings Page

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> Apple HIG tarzı minimalist SettingsWindow, reusable Settings bileşenleri ve NetworkPage başarıyla geliştirilip test edildi.

## 1. Tasarım Felsefesi ve İlkeler
- **Anti-AI-Slop:** Aşırı neon parlamalar, gereksiz gradyan karmaşası ve karmaşık süslemeler yerine Apple HIG tarzı sessiz, dengeli ve işlevsel tipografi.
- **Gruplanmış Kartlar (Inset Grouped Cards):** `Style.surface` ve ince 1px `Style.border` ile sınırlandırılmış ferah kartlar.
- **Akıcı Animasyonlar:** Toggle ve sayfa geçişlerinde pürüzsüz `SpringAnimation` ve `Easing.OutCubic` hareket fiziği.
- **Canlı ve Reaktif:** Go IPC soketinden gelen DNS, IP ve Wi-Fi telemetrisiyle anında senkronize çalışma.

## 2. Modüler Bileşen Yapısı

```text
shell/
├── backend/
│   ├── SettingsService.qml              # Pencere açık/kapalı durumu ve aktif sayfa singleton'ı
│   └── DaemonIPC.qml                    # DNS, IPv6 ve kopya profil IPC yardımcıları
├── components/
│   └── settings/
│       ├── SettingsWindow.qml           # Ana Modal Overlay Penceresi (Sidebar + Content)
│       ├── components/
│       │   ├── SettingsSectionHeader.qml # Başlık etiketi
│       │   ├── SettingsCard.qml         # Yuvarlatılmış kart kutusu
│       │   ├── SettingsRow.qml          # Satır (İkon, Başlık, Açıklama, Kontrol Slotu)
│       │   ├── SettingsToggle.qml       # iOS tarzı yay animasyonlu Switch
│       │   ├── SettingsButton.qml       # Minimalist buton
│       │   └── SettingsDnsCard.qml      # DNS sağlayıcı seçim kartı
│       └── pages/
│           └── NetworkPage.qml          # Ağ, Wi-Fi, Güvenli DNS ve IPv6 sayfası
└── qmldir                               # singleton SettingsService kaydı
```

## 3. Ağ & DNS Sayfası İçeriği
1. **Aktif Bağlantı Durumu Kartı:** Wi-Fi güç switch'i, bağlı SSID, yeşil durum noktası, IP ve Gateway telemetrisi.
2. **Güvenli DNS Kartı (DPI Bypass & Zapret):**
   - Cloudflare (`1.1.1.1`), Quad9 (`9.9.9.9`), AdGuard (`94.140.14.14`), Google (`8.8.8.8`), Otomatik DHCP ve Özel DNS seçicisi.
   - IPv6 Sızıntı Koruması Toggle'ı (`set_connection_ipv6`).
3. **Kullanılabilir Ağlar Listesi:** Çevredeki Wi-Fi ağları, sinyal seviyeleri ve şifreyle bağlanma.
4. **Profil Bakımı Kartı:** Kopya `.nmconnection` dosyalarını temizleme butonu (`cleanup_duplicate_profiles`).
