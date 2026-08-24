---
title: "WiFi & Secrets Client Service (Go Daemon)"
type: service
tags:
  - service/wifi
  - service/secrets
  - networkmanager/dbus
  - dbus/secret-agent
  - go/interface
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[System-Architecture]]"
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Socket-Schema]]"
  - "[[IPC-Server-Service]]"
  - "[[Plan-Modular-WiFi-Settings-And-Secrets-Client]]"
---

# WiFi & Secrets Client Service (`core/services/wifi/`)

> [!NOTE]
> An interface-driven, modular Go client providing hardware-level Wi-Fi management, NetworkManager D-Bus profile manipulation, and an in-process headless **SecretAgent** that intercepts and satisfies credential queries without external desktop popups (e.g. `kded` / `kwallet`).

---

## 1. Secret Agent & KDED Popup Suppression

To prevent desktop environments (such as KDE Plasma / `kded` or GNOME Keyring) from intercepting Wi-Fi connections and displaying unwanted GUI password prompt dialogs:

1. **`psk-flags: 0` (`NM_SETTING_SECRET_FLAG_NONE`):** All connection profiles explicitly set secret flags to `0` (system-wide keyfile storage), informing NetworkManager not to query external desktop secret agents.
2. **Headless `SecretAgent` (`agent.go`):** The daemon exports an in-process D-Bus Secret Agent (`org.freedesktop.NetworkManager.SecretAgent`) registered with NetworkManager's `AgentManager`. If NetworkManager ever queries credentials during connection negotiation, our agent answers directly from memory in the background.
3. **Empty Permissions (`permissions: []`):** Profiles are marked system-wide, eliminating per-user desktop agent permission dialogs.

---

## 2. Component Modules

| File | Purpose |
| :--- | :--- |
| `types.go` | Canonical JSON-serializable data structs (`AccessPoint`, `WifiProfile`, `WifiSecrets`, etc.) |
| `manager.go` | `WifiManager` interface definition |
| `client_dbus.go` | Production NetworkManager D-Bus client with automatic AP object resolution |
| `agent.go` | Headless in-process D-Bus `SecretAgent` suppressing KDE/GNOME popups |
| `builder.go` | Settings dictionary generator (`psk-flags: 0`), IP parser, frequency-to-channel mapper |
| `client_mock.go` | Thread-safe, in-memory mock client for unit testing and offline development |
| `wifi_test.go` | Full unit test suite and host D-Bus integration tests |

---

## 3. DNS, IPv6 & Profile Lifecycle Architecture

* **Kalıcı DNS Yapılandırması (`SetConnectionDNS`):** NetworkManager D-Bus `ipv4.dns` (uint32 Little/Big-Endian) ve `ipv4.ignore-auto-dns` ayarlarını diske yazar; bağlantı aktifse `ActivateConnection` ile `/etc/resolv.conf`'u anında günceller.
* **D-Bus Ayar Sanitizasyonu (`SanitizeSettingsForUpdate`):** `GetSettings` ile okunan profillerin `Update` edilirken `ipv6.addresses` veya `ipv4.addresses` tuple tip uyumsuzluğu (`a(ayuay)` vs `aav`) vermemesi için boş veya `auto`/`disabled` metoduna sahip eski adres dizilerini temizler.
* **IPv6 Kontrolü (`SetConnectionIPv6`):** DPI Bypass (Zapret) sızıntılarını önlemek için tek hamlede `ipv6.method: disabled` veya `auto` ataması yapar.
* **Kopya Profil Temizliği (`CleanupDuplicateProfiles`):** Aynı SSID için birikmiş redundant `.nmconnection` klonlarını tespit eder, özel DNS'e sahip olanı veya aktif olanı koruyup diğerlerini siler.
* **Akıllı Bağlantı (`Connect`):** Ağ profili zaten mevcutsa `AddAndActivateConnection` çağırmaz, mevcut profili aktive ederek özel ayarların ezilmesini önler.

---

## 4. Related Links

* Daemon Architecture: `[[Go-Daemon-Core]]`
* IPC Schema: `[[IPC-Socket-Schema]]`
* Proposal Note: `[[Plan-Modular-WiFi-Settings-And-Secrets-Client]]`
* DNS Proposal Note: `[[Plan-Backend-Network-Details-And-DNS-Management]]`

