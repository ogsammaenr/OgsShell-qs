import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../components"

Flickable {
  id: root

  property var ipc: null
  signal notifyToast(string msg, bool isErr)

  readonly property var btState: (ipc && ipc.bluetooth) ? ipc.bluetooth : ({ "adapter_powered": false, "discovering": false, "devices": [] })
  readonly property bool powered: !!btState.adapter_powered
  readonly property bool scanning: !!btState.discovering
  readonly property var devices: Array.isArray(btState.devices) ? btState.devices : []

  function deviceGlyph(iconName) {
    let n = (iconName || "").toLowerCase()
    if (n.indexOf("headset") !== -1 || n.indexOf("headphone") !== -1 || n.indexOf("audio") !== -1) return "󰋋"
    if (n.indexOf("keyboard") !== -1) return "󰌌"
    if (n.indexOf("mouse") !== -1) return "󰍽"
    if (n.indexOf("gaming") !== -1) return "󰊗"
    if (n.indexOf("phone") !== -1) return "󰏲"
    return "󰂯"
  }

  function refreshState() {
    if (ipc) ipc.sendAction("get_bluetooth_state", {})
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

    // 1. Adapter Power & Discovery
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Bluetooth Adaptörü"
      }

      SettingsCard {
        SettingsRow {
          iconText: root.powered ? "󰂯" : "󰂲"
          iconColor: root.powered ? Style.accent : Style.textMuted
          title: "Bluetooth Gücü"
          subtitle: root.powered
            ? (root.scanning ? "Yakındaki aygıtlar taranıyor..." : (root.devices.length + " aygıt listeleniyor"))
            : "Adaptör kapalı"
          showDivider: root.powered

          SettingsToggle {
            checked: root.powered
            onToggled: isChecked => {
              if (root.ipc) root.ipc.sendAction("toggle_bluetooth", { "enabled": isChecked })
              root.notifyToast(isChecked ? "Bluetooth açıldı." : "Bluetooth kapatıldı.", false)
            }
          }
        }

        SettingsRow {
          visible: root.powered
          iconText: "󰍉"
          title: "Cihaz Keşfi (Tarama)"
          subtitle: root.scanning ? "Yeni cihazlar aranıyor..." : "Yakındaki kulaklık, klavye ve aksesuarları tara."
          showDivider: false

          SettingsButton {
            text: root.scanning ? "Taramayı Durdur" : "Cihaz Ara"
            iconText: root.scanning ? "󰓛" : "󰑐"
            isAccent: !root.scanning
            onClicked: {
              if (!root.ipc) return
              if (root.scanning) {
                root.ipc.sendAction("stop_bluetooth_scan", {})
                root.notifyToast("Tarama durduruldu.", false)
              } else {
                root.ipc.sendAction("start_bluetooth_scan", {})
                root.notifyToast("Bluetooth taraması başlatıldı.", false)
              }
            }
          }
        }
      }
    }

    // 2. Devices List
    ColumnLayout {
      visible: root.powered
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Aygıtlar"
      }

      SettingsCard {
        innerPadding: 6

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Repeater {
            model: root.devices

            delegate: Rectangle {
              required property var modelData
              readonly property bool isConn: !!modelData.connected
              Layout.fillWidth: true
              implicitHeight: 50
              radius: 8
              color: isConn ? Qt.alpha(Style.accent, 0.12) : (devMouse.containsMouse ? Style.surfaceHover : "transparent")

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Rectangle {
                  width: 32
                  height: 32
                  radius: 8
                  color: isConn ? Qt.alpha(Style.accent, 0.18) : Style.surfaceVariant

                  Text {
                    anchors.centerIn: parent
                    text: root.deviceGlyph(modelData.icon)
                    font.pixelSize: 15
                    color: isConn ? Style.accent : Style.textSecondary
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    text: modelData.name || modelData.mac || "Bilinmeyen Cihaz"
                    font.family: Style.fontText
                    font.pixelSize: 13
                    font.weight: isConn ? Font.DemiBold : Font.Medium
                    color: isConn ? Style.accent : Style.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Text {
                    text: (isConn ? "Bağlı" : (modelData.paired ? "Eşleştirilmiş" : "Bulunan cihaz")) + "  •  " + (modelData.mac || "")
                    font.family: Style.fontText
                    font.pixelSize: 11
                    color: isConn ? Style.accentGreen : Style.textMuted
                  }
                }

                SettingsButton {
                  text: isConn ? "Kes" : "Bağlan"
                  isAccent: !isConn
                  isDanger: isConn
                  onClicked: {
                    if (!root.ipc || !modelData.mac) return
                    if (isConn) {
                      root.ipc.sendAction("disconnect_bluetooth", { "mac": modelData.mac })
                      root.notifyToast((modelData.name || "Cihaz") + " bağlantısı kesildi.", false)
                    } else {
                      root.ipc.sendAction("connect_bluetooth", { "mac": modelData.mac })
                      root.notifyToast((modelData.name || "Cihaz") + " bağlanıyor...", false)
                    }
                  }
                }
              }

              MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
              }
            }
          }

          Item {
            visible: root.devices.length === 0
            Layout.fillWidth: true
            implicitHeight: 72

            Text {
              anchors.centerIn: parent
              text: "Henüz cihaz listelenmedi. 'Cihaz Ara' butonunu kullanın."
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
