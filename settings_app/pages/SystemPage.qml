import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"
import "../backend"
import "../components"

Flickable {
  id: root

  property var ipc: null
  signal notifyToast(string msg, bool isErr)

  readonly property var kb: (ipc && ipc.keyboardLayout) ? ipc.keyboardLayout : ({ "current_keymap": "Turkish", "current_short_code": "TR" })
  readonly property var currencyTargets: ["TRY", "USD", "EUR", "GBP"]

  Process { id: shellActionProc }

  function runOgsshell(arg) {
    shellActionProc.running = false
    shellActionProc.command = ["ogsshell", arg]
    shellActionProc.running = true
  }

  function refreshState() {
    if (ipc) ipc.requestKeyboardLayout()
  }

  onIpcChanged: refreshState()
  Component.onCompleted: refreshState()

  contentWidth: width
  contentHeight: mainCol.implicitHeight + 48
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  ColumnLayout {
    id: mainCol
    width: parent.width - 48
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 22
    spacing: 20

    // 1. Keyboard Layout
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Klavye Düzeni"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰌌"
          iconColor: Style.accent
          title: root.kb.current_keymap || "Türkçe"
          subtitle: "Aktif kısa kod: " + ((root.kb.current_short_code || "TR").toUpperCase())
          showDivider: false

          SettingsButton {
            text: "Sonraki Dile Geç"
            iconText: "󰗊"
            isAccent: true
            onClicked: {
              if (root.ipc) {
                root.ipc.switchKeyboardLayout("next")
                root.notifyToast("Klavye düzeni değiştirildi.", false)
              }
            }
          }
        }
      }
    }

    // 2. Currency Converter (Launcher Engine)
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Başlatıcı Döviz Çevirici"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰠓"
          title: "Otomatik Kur Çevirici"
          subtitle: "Uygulama başlatıcıda '100 usd' gibi ifadeleri anında çevirir."
          showDivider: true

          SettingsToggle {
            checked: Config.currencyEnabled
            onToggled: isChecked => {
              Config.saveConfig({ "currency": { "enabled": isChecked } })
              root.notifyToast("Döviz çevirici ayarı güncellendi.", false)
            }
          }
        }

        SettingsRow {
          visible: Config.currencyEnabled
          iconText: "󰄬"
          title: "Varsayılan Hedef Para Birimi"
          subtitle: "Hedef belirtilmediğinde çevrilecek para birimi."
          showDivider: true

          RowLayout {
            spacing: 4

            Repeater {
              model: root.currencyTargets
              delegate: Rectangle {
                required property string modelData
                readonly property bool isSel: Config.currencyDefaultTarget === modelData
                width: 44
                height: 26
                radius: 6
                color: isSel ? Qt.alpha(Style.accent, 0.16) : (cMouse.containsMouse ? Style.surfaceHover : Style.appBackground)
                border.color: isSel ? Style.accent : Style.appBorder
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: modelData
                  font.family: Style.fontDisplay; font.pixelSize: 11; font.weight: isSel ? Font.DemiBold : Font.Normal
                  color: isSel ? Style.accent : Style.textSecondary
                }

                MouseArea {
                  id: cMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Config.saveConfig({ "currency": { "default_target": modelData } })
                    if (root.ipc) root.ipc.sendAction("reload_currency_config", {})
                    root.notifyToast("Varsayılan kur: " + modelData, false)
                  }
                }
              }
            }
          }
        }

        SettingsRow {
          visible: Config.currencyEnabled
          iconText: "󰑐"
          title: "Kurları Şimdi Eşitle"
          subtitle: "Güncel döviz ve kripto kurlarını anında yeniler."
          showDivider: false

          SettingsButton {
            text: "Güncelle"
            iconText: "󰑐"
            onClicked: {
              if (root.ipc) {
                root.ipc.sendAction("sync_currency_rates", {})
                root.notifyToast("Döviz kurları güncelleniyor...", false)
              }
            }
          }
        }
      }
    }

    // 3. System Overview & Quick Actions
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "ogsShell Hakkında"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰣇"
          iconColor: Style.accent
          title: "ogsShell-qs"
          subtitle: "Hyprland + Quickshell QML + Go IPC Daemon"
          showDivider: true

          SettingsButton {
            text: "Kabuğu Yeniden Yükle"
            iconText: "󰑐"
            onClicked: {
              root.runOgsshell("reload")
              root.notifyToast("ogsShell yeniden yükleniyor...", false)
            }
          }
        }

        SettingsRow {
          iconText: "󰌾"
          title: "Konfigürasyon Dizini"
          subtitle: "~/.config/ogsShell/config.json"
          showDivider: false

          SettingsButton {
            text: "Ekranı Kilitle"
            iconText: "󰌾"
            onClicked: {
              if (root.ipc) root.ipc.sendAction("open_app", { "app": "lock" })
            }
          }
        }
      }
    }
  }
}
