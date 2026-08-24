---
title: "Plan: Backend Network Details, DNS Management and Duplicate Profile Cleanup"
type: agent-thought
tags:
  - backend/go
  - services/wifi
  - network/dns
  - dbus/networkmanager
  - ipc/actions
created: 2026-08-23
updated: 2026-08-23
status: implemented
related_notes:
  - "[[Go-Daemon-Core]]"
  - "[[Wifi-Client-Service]]"
  - "[[Backend-Endpoints-Reference]]"
  - "[[IPC-Socket-Schema]]"
  - "[[System-Architecture]]"
---

# Plan: Backend Network Details, DNS Management and Duplicate Profile Cleanup

> [!NOTE]
> **Durum: TAMAMLANDI (Implemented)**
> NetworkManager D-Bus entegrasyonu tamamlandı. `GetNetworkDetails`, `SetConnectionDNS`, `SetConnectionIPv6`, `CleanupDuplicateProfiles` metotları ve IPC uçları eksiksiz uygulanıp unit testlerle doğrulandı.

## 1. Problem ve Kullanıcı İhtiyacı
1. **DPI Bypass (Zapret) ve DNS Zehirlemesi:** NetworkManager varsayılan olarak DHCP DNS kullanır ve bu durum ISP tarafından engelli sitelerin DNS aşamasında engellenmesine yol açar.
2. **Kopya Profiller:** Shell her yeni bağlantıda `AddAndActivateConnection` çağırdığında NetworkManager diskte aynı SSID için birden fazla `.nmconnection` kopyası oluşturur.
3. **Ayarlar Uygulaması İhtiyacı:** Geliştirilecek Ayarlar Uygulaması (Settings App) ve Wi-Fi görünümü için güvenli DNS (Cloudflare 1.1.1.1, Google 8.8.8.8, Quad9 9.9.9.9 vb.) atama ve IPv6 açma/kapama fonksiyonlarına ihtiyaç vardır.

## 2. Tasarlanan Backend Mimarisi

### 2.1. Eklenecek D-Bus Metotları (`WifiManager` Interface)
- `GetNetworkDetails(ctx, ssidOrUUID)`: Aktif veya seçilen ağın IP, Maske, Gateway, DNS sunucuları listesi, `ignore_auto_dns` ve `ipv6_method` durumunu döner.
- `SetConnectionDNS(ctx, req)`: Seçilen profile `ipv4.dns` (uint32 dönüşümüyle) ve `ipv4.ignore-auto-dns: true` yazar, aktifse anında `ActivateConnection`/`Reapply` ile uygular.
- `SetConnectionIPv6(ctx, req)`: IPv6'yı `"disabled"` veya `"auto"` olarak günceller.
- `CleanupDuplicateProfiles(ctx)`: Aynı SSID'ye ait eski kopya profilleri silip tek bir temiz profil bırakır.
- `Connect(ctx, req)`: Eğer o SSID için zaten kayıtlı bir profil varsa `AddAndActivateConnection` yerine doğrudan `ActivateConnection` çağırarak klon oluşumunu engeller.

### 2.2. IPC RPC Aksiyonları (`core/main.go`)
- `get_network_details` -> `network_details` event yayını
- `set_connection_dns` -> `network_details` ve `active_wifi` event yayını
- `set_connection_ipv6` -> `network_details` event yayını
- `cleanup_duplicate_profiles` -> `saved_wifi_profiles` event yayını

## 3. Etkilenen Dosyalar
- `core/services/wifi/types.go`
- `core/services/wifi/manager.go`
- `core/services/wifi/client_dbus.go`
- `core/services/wifi/client_mock.go`
- `core/services/wifi/wifi_test.go`
- `core/main.go`
- `.agents/BACKEND_ENDPOINTS.md`
- `ogsShell-qs_brain/01-Architecture/Backend-Endpoints-Reference.md`
- `ogsShell-qs_brain/02-Services/Wifi-Client-Service.md`
