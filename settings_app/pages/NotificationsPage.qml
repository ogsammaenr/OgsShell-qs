import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../backend"
import "../components"

Flickable {
  id: root

  property var ipc: null
  signal notifyToast(string msg, bool isErr)

  readonly property bool dndEnabled: !!(ipc && ipc.dndEnabled)
  readonly property int totalCount: (ipc && ipc.notifications) ? ipc.notifications.length : 0
  readonly property int unreadCount: (ipc && ipc.unreadNotificationCount) ? ipc.unreadNotificationCount : 0
  readonly property var appRules: (ipc && ipc.notificationRules) ? ipc.notificationRules : []

  readonly property bool popupsEnabled: (Config.notifications && Config.notifications.enabled !== undefined) ? Config.notifications.enabled : true
  readonly property int timeoutMs: (Config.notifications && Config.notifications.default_timeout_ms) ? Config.notifications.default_timeout_ms : 3500

  function refreshState() {
    if (ipc) {
      ipc.requestNotifications()
      ipc.requestNotificationRules()
    }
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

    // 1. Focus & DND
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Bildirim Davranışı"
      }

      SettingsCard {
        SettingsRow {
          iconText: root.dndEnabled ? "󰂛" : "󰂚"
          iconColor: root.dndEnabled ? Style.accentOrange : Style.textSecondary
          title: "Rahatsız Etme Modu (DND)"
          subtitle: "Açıkken geçici bildirim kartları gizlenir (kritik uyarılar hariç)."
          showDivider: true

          SettingsToggle {
            checked: root.dndEnabled
            onToggled: isChecked => {
              if (root.ipc) root.ipc.toggleDND(isChecked)
              root.notifyToast(isChecked ? "Rahatsız Etme modu açıldı." : "Rahatsız Etme modu kapatıldı.", false)
            }
          }
        }

        SettingsRow {
          iconText: "󰍡"
          title: "Ada / Çentik Bildirim Kartları"
          subtitle: "Yeni bildirim geldiğinde üst çentikte 3D kart destesi olarak gösterir."
          showDivider: true

          SettingsToggle {
            checked: root.popupsEnabled
            onToggled: isChecked => {
              Config.saveConfig({ "notifications": { "enabled": isChecked } })
              root.notifyToast(isChecked ? "Bildirim kartları açıldı." : "Bildirim kartları kapatıldı.", false)
            }
          }
        }

        SettingsSliderRow {
          visible: root.popupsEnabled
          iconText: "󰔛"
          title: "Ekranda Kalma Süresi"
          subtitle: "Geçici bildirim kartının otomatik kapanma süresi."
          value: root.timeoutMs
          minValue: 1500; maxValue: 10000; step: 500; unit: "ms"
          showDivider: false
          onValueModified: val => Config.saveConfig({ "notifications": { "default_timeout_ms": Math.round(val) } })
        }
      }
    }

    // 2. Notification History Summary
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Bildirim Geçmişi"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰎟"
          title: root.totalCount + " kayıtlı bildirim"
          subtitle: root.unreadCount > 0 ? (root.unreadCount + " okunmamış bildirim bekliyor.") : "Tüm bildirimler okundu."
          showDivider: false

          SettingsButton {
            text: "Geçmişi Temizle"
            iconText: "󰩹"
            isDanger: true
            enabled: root.totalCount > 0
            onClicked: {
              if (root.ipc) {
                root.ipc.clearNotifications()
                root.notifyToast("Bildirim geçmişi temizlendi.", false)
              }
            }
          }
        }
      }
    }

    // 3. Per-App Rules
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Uygulama Kuralları"
      }

      SettingsCard {
        innerPadding: 6

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Repeater {
            model: root.appRules

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: 46
              radius: 8
              color: "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text { text: "󰀻"; font.pixelSize: 14; color: Style.textSecondary }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    text: modelData.app_name || "Uygulama"
                    font.family: Style.fontText; font.pixelSize: 13; font.weight: Font.Medium
                    color: Style.textPrimary
                  }
                  Text {
                    text: "Kural: " + (modelData.mode || "normal")
                    font.family: Style.fontText; font.pixelSize: 11; color: Style.textMuted
                  }
                }

                SettingsButton {
                  text: "Kaldır"
                  isDanger: true
                  onClicked: {
                    if (root.ipc && modelData.app_name) {
                      root.ipc.deleteNotificationRule(modelData.app_name)
                      root.notifyToast(modelData.app_name + " kuralı silindi.", false)
                    }
                  }
                }
              }
            }
          }

          Item {
            visible: root.appRules.length === 0
            Layout.fillWidth: true
            implicitHeight: 62

            Text {
              anchors.centerIn: parent
              text: "Tanımlı uygulama filtresi yok (tüm uygulamalar standart modda)."
              font.family: Style.fontText
              font.pixelSize: 12
              color: Style.textMuted
            }
          }
        }
      }
    }
  }
}
