---
title: "Keyring Prompter Service (C Helper & Go Supervisor)"
type: service
tags:
  - security/keyring
  - gcr/prompter
  - go/daemon
status: active
---

# Keyring Prompter Service

GNOME Keyring ve Freedesktop Secret Service kimlik doğrulama istemlerini kabuk içine entegre eden alt sistem.

## Mimari Genel Bakış

1. **Bağımsız C Prompter Ajanı (`services/keyring_prompter/`):**
   * GNOME'un resmi `libgcr-3` (`GcrSystemPrompter` ve `GcrPromptIface`) kütüphanesini kullanır.
   * D-Bus oturum yolunda `org.gnome.keyring.SystemPrompter` ve `org.gnome.keyring.PrivatePrompter` isimlerini üzerine alır.
   * Harici GTK3 penceresini (`/usr/lib/gcr-prompter`) tamamen devre dışı bırakır.
   * Standart G/Ç (`stdin` / `stdout`) üzerinden NDJSON konuşur.
2. **Go Backend Supervisor (`core/services/keyring/`):**
   * `bin/ogsshell-keyring-prompter` sürecini alt süreç olarak yönetir (`exec.CommandContext`).
   * C ajanı çıktısını `bufio.Scanner` ile okuyup Unix soketi üzerinden `keyring_prompt_requested` olayını yayınlar.
   * Frontend'den gelen `keyring_submit_response` ve `keyring_cancel_response` RPC komutlarını C sürecine iletir.
   * Go daemon kapandığında veya çöktüğünde C süreci de temiz bir şekilde sonlanır (`SIGTERM` / Pipe EOF).

## Bağımlılıklar

* `gcr-3` (`libgcr-base-3`, `libgcr-ui-3`)
* `json-glib-1.0`
* `gio-unix-2.0`
* Go 1.24+

## IPC Soket Şeması

### Yayınlanan Olay (`keyring_prompt_requested`):
```json
{
  "type": "keyring_prompt_requested",
  "payload": {
    "id": "prompt_1729780000_1",
    "is_password": true,
    "title": "Giriş Anahtarlığının Kilidini Aç",
    "description": "Google Chrome kayıtlı şifrelerinize erişmek istiyor.",
    "warning": "",
    "choice_label": "Oturum açıldığında bu anahtarlığı otomatik aç",
    "choice_chosen": true,
    "password_new": false,
    "continue_label": "Kilidi Aç",
    "cancel_label": "Vazgeç"
  }
}
```

### İstemci Yanıtı (`keyring_submit_response`):
```json
{
  "name": "keyring_submit_response",
  "args": {
    "id": "prompt_1729780000_1",
    "password": "secretpassword",
    "remember": true
  }
}
```

## İlgili Dokümantasyon

* UI Bileşeni: `[[Keyring-Prompt-Modal]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* IPC İstemcisi: `[[Daemon-IPC-Client]]`
* Uç Noktalar Referansı: `[[Backend-Endpoints-Reference]]`
* Sistem Mimarisi: `[[System-Architecture]]`
