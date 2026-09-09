---
title: "Plan: Embedded WiFi Authentication and KDE Popup Suppression"
type: agent-thought
tags:
  - service/wifi
  - ui/controlcenter
  - dbus/networkmanager
  - secret-agent
created: 2026-09-09
updated: 2026-09-09
status: implemented
related_notes:
  - "[[Network-Manager]]"
  - "[[ControlCenter-Component]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Configuration-System-Spec]]"
  - "[[System-Architecture]]"
---

# Plan: Embedded WiFi Authentication and KDE Popup Suppression

> [!IDEA]
> NetworkManager üzerinden otomatik bağlanan ancak kimlik bilgisi eksik olan (`psk-flags: 1`) ağlar (örn. `SUPERONLINE_WiFi_5G_0744`), `SecretAgent` içerisinde şifre bulunamadığında harici `kded6` (KDE Wi-Fi password dialog) penceresini tetiklemektedir. Bu plan, tüm kimlik doğrulama süreçlerinin ogsShell içerisine gömülü (embedded) olarak çalışmasını, şifresiz profillerin yetkisiz otomatik bağlanmasının engellenmesini ve harici KDE pencerelerinin bastırılmasını hedefler.

## 1. Tespit Edilen Kök Nedenler (Root Causes)

1. **`SUPERONLINE_WiFi_5G_0744` Profili:**
   - `connection.autoconnect: yes` ve `802-11-wireless-security.psk-flags: 1` (agent-owned) olarak kayıtlı.
   - NetworkManager periyodik olarak veya sinyal tespit ettiğinde bu ağa otomatik bağlanmaya çalışıyor.
   - `SecretAgent.GetSecrets` çağrıldığında ogsShell önbelleğinde şifre olmadığı için `NoSecrets` hatası dönüyor.
   - NetworkManager D-Bus üzerinde kayıtlı diğer Secret Agent'lara (`kded6` / `plasma-nm`) soruyor ve KDE'nin harici şifre penceresi ekranda beliriyor.
2. **Frontend UI Şifre Akışı Eksikliği:**
   - `WifiView.qml` ve `NetworkPage.qml`, `is_saved: true` olan ağlarda şifre olup olmadığını (`has_password`) doğrulamadan boş şifre ile doğrudan `connect_wifi` tetikliyor.
3. **`SecretAgent` Hata Davranışı:**
   - Önbellekte şifre bulunmayan ağlar için `NoSecrets` yerine `UserCanceled` veya kontrollü iptal dönülerek harici KDE/kwallet pencerelerinin açılması önlenmelidir.

## 2. Uygulama Adımları

1. **Sistem Ağ Profillerinin Düzeltilmesi:**
   - `SUPERONLINE_WiFi_5G_0744` ve şifresi sistemde olmayan `psk-flags: 1` profillerinin `connection.autoconnect` değeri `no` yapılarak istenmeyen otomatik bağlantı denemeleri durdurulacak.
2. **Backend (`core/services/wifi/`):**
   - `GetSavedProfiles` ve `ScanNetworks` metotlarında `has_password` kontrolü `psk-flags == 0` veya önbellek durumuna göre netleştirilecek.
   - `SecretAgent.GetSecrets` içinde şifre yoksa harici popup tetiklememesi için `UserCanceled` / `AgentCanceled` hatası ile NM'ye kontrollü yanıt verilecek.
3. **Frontend (`shell/components/widgets/controlcenter/views/WifiView.qml` & `shell/components/settings/pages/NetworkPage.qml`):**
   - Şifresi olmayan (`has_password: false` veya kaydedilmemiş güvenlikli) ağlara tıklandığında dahili şifre modalı açılacak.
   - Şifre girildiğinde `connect_wifi` üzerinden bağlantı kurulacak ve `UpdateProfileSecrets` ile `psk-flags: 0` olarak kaydedilecek.
4. **Arayüz ve Mimari Doğrulama:**
   - Quickshell ve Go testleri ile sistem doğrulaması yapılacak.
