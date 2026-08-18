---
title: "Plan: Remove Dock Component and Restore Clean Minimalist Shell"
type: agent-thought
tags:
  - ui/dock
  - refactor/cleanup
  - quickshell/panelwindow
created: 2026-08-17
updated: 2026-08-17
status: implemented
related_notes:
  - "[[Dock-Component]]"
  - "[[Shell-Root-PanelWindow]]"
  - "[[Dynamic-Island-Component]]"
  - "[[Configuration-System-Spec]]"
  - "[[System-Architecture]]"
---

# Plan: Remove Dock Component and Restore Clean Minimalist Shell

> [!IDEA]
> Kullanıcı talebi doğrultusunda, ekranın altındaki `dockWindow` katmanı, `shell/components/dock/` bileşenleri ve `config.json` içerisindeki dock yapılandırması tamamen kaldırılarak projenin orijinal minimalist Dynamic Island / Notch odaklı arayüz yapısına geri dönülmesi.

## 1. Kaldırılacak Bileşenler ve Kod Alanları
1. **`shell/shell.qml`:**
   - `dockWindow` `PanelWindow` nesnesi.
   - `screenScope` içerisindeki `dockShouldAutoHide`, `dockIsHoveredOverall`, `dockIsRevealed`, `dockRevealLatchTimer`, `dockAutoHideTimer` tanımları.
2. **`shell/config.json` & `shell/backend/Config.qml`:**
   - `"dock"` yapılandırma bloğu ve QML varsayılan özellikleri.
3. **`shell/components/dock/`:**
   - `Dock.qml`, `DockItem.qml`, `DockPreviewCard.qml` dosyaları.
4. **Obsidian Vault & Mimari:**
   - `[[Dock-Component]]` durumu `deprecated` / `removed` olarak işaretlenir.
   - `[[Shell-Root-PanelWindow]]` ve `.agents/ARCHITECTURE.md` güncellenir.

## 2. Uygulama Sırası
1. `shell/shell.qml` içerisinden dock ile ilgili tüm `PanelWindow`, timer ve property'leri temizleme.
2. `shell/config.json` ve `shell/backend/Config.qml` içerisinden dock tanımlarını kaldırma.
3. `shell/components/dock/` dizinini silme.
4. Quickshell sözdizimi doğrulama ve yeniden başlatma.
5. Obsidian notlarını ve mimari dokümantasyonu güncelleme.
