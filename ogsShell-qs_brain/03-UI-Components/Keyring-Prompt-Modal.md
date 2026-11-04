---
title: "Keyring Prompt Modal Component"
type: ui-component
tags:
  - quickshell/qml
  - dynamic-island
  - security/keyring
status: active
---

# Keyring Prompt Modal Component

Dynamic Island ve Wayland LayerShell katmanında açılan, parola ve onay istemi modalı.

## Dosya Konumu
* `shell/components/widgets/keyring/KeyringPromptModal.qml`

## Özellikler ve Davranış

1. **State & Priority:**
   * Bir istem geldiğinde `DynamicIsland` doğrudan `EXPANDED` durumuna geçer (`expandedActiveTab = "KEYRING"`).
   * Boyutlar: Genişlik `430px`, Yükseklik `220px`.
   * Boyut geçişlerinde `SpringAnimation { spring: 28.0; damping: 0.78; epsilon: 0.01 }` kullanılır.
2. **Wayland LayerShell Odağı & Otomatik Odaklanma (Auto-Focus Engine):**
   * `islandWindow` üzerinde `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` aktifleşir.
   * `Loader` (`keyringPromptLoader`) ve kök `FocusScope` üzerinde `focus: true` zinciri kurulmuştur.
   * Wayland yüzey odaklanma gecikmelerini (compositor roundtrip latency) tolere etmek amacıyla 30ms aralıklı akıllı `focusTimer` döngüsü (`grabInputFocus`) kullanılır.
   * Şifre alanı açıldığı anda kullanıcı müdahalesine veya mouse tıklamasına gerek kalmadan doğrudan `passwordInput.activeFocus` durumuna geçer.
   * Parola kutusu dışına/içine tıklandığında `inputContainer` MouseArea'sı da odağı şifre alanına iletir.
3. **Klavye Etkileşimi:**
   * `Enter` / `Return`: Şifreyi doğrular ve `keyring_submit_response` gönderir.
   * `Escape`: İptal eder ve `keyring_cancel_response` gönderir.
4. **Tasarım Token'ları:**
   * İkon: 🔒 `Style.accentMagenta` dairesel rozet.
   * Giriş: `Style.surfaceVariant`, odak kenarlığı `Style.accent`.
   * Buton: "Kilidi Aç" `Style.accent`, "Vazgeç" `Style.surfaceVariant`.
   * Göster / Gizle: 👁️ / 🙈 ikonu ile `echoMode` geçişi.

## İlgili Bağlantılar

* Servis Tanımı: `[[Keyring-Prompter-Service]]`
* Dynamic Island: `[[Dynamic-Island-Component]]`
* Tasarım Token'ları: `[[Style-Design-Tokens]]`
* IPC İstemcisi: `[[Daemon-IPC-Client]]`
