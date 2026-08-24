import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../theme"
import "../components"

Flickable {
  id: root

  property var ipc

  readonly property var netDetails: (ipc && ipc.networkDetails) ? ipc.networkDetails : null
  readonly property string activeSsid: (netDetails && netDetails.ssid) ? netDetails.ssid : ((ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : "")
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && (ipc.wifi.connected || (ipc.net && ipc.net.is_connected)))
  readonly property bool isWifiPowered: !ipc || !ipc.wifi || ipc.wifi.ssid !== "Kapalı"

  // Custom DNS input states
  property bool showCustomDnsInput: false
  property string customDns1: "1.1.1.1"
  property string customDns2: "1.0.0.1"
  property string cleanupStatusMessage: ""

  // Active DNS Preset detection
  readonly property string currentDnsPreset: {
    if (!netDetails) return "dhcp"
    if (!netDetails.ignore_auto_dns || !netDetails.dns || netDetails.dns.length === 0) return "dhcp"
    let dnsStr = netDetails.dns.join(",")
    if (dnsStr.indexOf("1.1.1.1") !== -1 || dnsStr.indexOf("1.0.0.1") !== -1) return "cloudflare"
    if (dnsStr.indexOf("9.9.9.9") !== -1 || dnsStr.indexOf("149.112.112.112") !== -1) return "quad9"
    if (dnsStr.indexOf("94.140.14.14") !== -1 || dnsStr.indexOf("94.140.15.15") !== -1) return "adguard"
    if (dnsStr.indexOf("8.8.8.8") !== -1 || dnsStr.indexOf("8.8.4.4") !== -1) return "google"
    return "custom"
  }

  contentWidth: width
  contentHeight: mainColumn.implicitHeight + 40
  boundsBehavior: Flickable.StopAtBounds
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  Component.onCompleted: {
    if (ipc) {
      ipc.requestNetworkDetails("")
      ipc.sendAction("scan_wifi", {})
    }
  }

  Connections {
    target: ipc ? ipc : null
    function onCleanupDuplicatesCompleted(payload) {
      if (payload) {
        root.cleanupStatusMessage = `✓ ${payload.deleted_count || 0} adet kopya profil başarıyla temizlendi.`
        cleanupMessageTimer.restart()
      }
    }
    function onNetworkDetailsUpdated() {
      // Trigger reactive refresh
    }
  }

  Timer {
    id: cleanupMessageTimer
    interval: 4000
    repeat: false
    onTriggered: root.cleanupStatusMessage = ""
  }

  ColumnLayout {
    id: mainColumn
    width: parent.width - 24
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 16
    spacing: 20

    // =========================================================================
    // 1. Wi-Fi Donanım & Aktif Bağlantı Durumu
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Wi-Fi & Bağlantı Durumu"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰤨"
          iconColor: root.isWifiConnected ? Style.accentCyan : Style.textMuted
          title: "Wi-Fi Donanımı"
          subtitle: root.isWifiConnected ? `Bağlı: ${root.activeSsid}` : "Kablosuz ağ kartı aktif"
          showDivider: root.isWifiConnected

          SettingsToggle {
            checked: root.isWifiPowered
            onToggled: isChecked => {
              if (ipc) ipc.sendAction("set_wifi_enabled", { "enabled": isChecked })
            }
          }
        }

        // Aktif Bağlantı Detayları (IP, Gateway, Sinyal)
        SettingsRow {
          visible: root.isWifiConnected
          iconText: "󰩠"
          iconColor: Style.accentGreen
          title: root.activeSsid
          subtitle: `IP: ${root.netDetails && root.netDetails.ip_address ? root.netDetails.ip_address : "192.168.1.X"} • Ağ Geçidi: ${root.netDetails && root.netDetails.gateway ? root.netDetails.gateway : "192.168.1.1"}`
          showDivider: false

          Rectangle {
            implicitWidth: statusRow.implicitWidth + 14
            implicitHeight: 24
            radius: 12
            color: Qt.rgba(0.2, 0.8, 0.4, 0.15)
            border.color: Qt.rgba(0.2, 0.8, 0.4, 0.4)
            border.width: 1

            RowLayout {
              id: statusRow
              anchors.centerIn: parent
              spacing: 6

              Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Style.accentGreen
              }

              Text {
                text: `Bağlı • %${root.netDetails && root.netDetails.signal ? root.netDetails.signal : ((ipc && ipc.wifi) ? ipc.wifi.signal : 80)}`
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Style.accentGreen
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 2. Güvenli DNS Seçimi (DPI Bypass & Zapret Uyumu)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Güvenli DNS & DPI Bypass (Zapret)"
      }

      Text {
        text: "Zapret gibi DPI bypass araçlarının çalışabilmesi ve servis sağlayıcının DNS zehirlemesini engellemek için güvenli bir DNS sunucusu seçin."
        font.pixelSize: 12
        color: Style.textMuted
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        leftPadding: 4
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        // Preset 1: Cloudflare
        SettingsDnsCard {
          title: "Cloudflare DNS"
          dnsIps: "1.1.1.1 • 1.0.0.1"
          isSelected: root.currentDnsPreset === "cloudflare"
          onClicked: {
            root.showCustomDnsInput = false
            if (ipc && root.activeSsid) {
              ipc.setConnectionDNS(root.activeSsid, ["1.1.1.1", "1.0.0.1"], true)
            }
          }
        }

        // Preset 2: Quad9
        SettingsDnsCard {
          title: "Quad9 DNS"
          dnsIps: "9.9.9.9 • 149.112.112.112"
          isSelected: root.currentDnsPreset === "quad9"
          onClicked: {
            root.showCustomDnsInput = false
            if (ipc && root.activeSsid) {
              ipc.setConnectionDNS(root.activeSsid, ["9.9.9.9", "149.112.112.112"], true)
            }
          }
        }

        // Preset 3: AdGuard
        SettingsDnsCard {
          title: "AdGuard DNS"
          dnsIps: "94.140.14.14 • 94.140.15.15"
          isSelected: root.currentDnsPreset === "adguard"
          onClicked: {
            root.showCustomDnsInput = false
            if (ipc && root.activeSsid) {
              ipc.setConnectionDNS(root.activeSsid, ["94.140.14.14", "94.140.15.15"], true)
            }
          }
        }

        // Preset 4: Google DNS
        SettingsDnsCard {
          title: "Google DNS"
          dnsIps: "8.8.8.8 • 8.8.4.4"
          isSelected: root.currentDnsPreset === "google"
          onClicked: {
            root.showCustomDnsInput = false
            if (ipc && root.activeSsid) {
              ipc.setConnectionDNS(root.activeSsid, ["8.8.8.8", "8.8.4.4"], true)
            }
          }
        }

        // Preset 5: Otomatik DHCP / Modem DNS
        SettingsDnsCard {
          title: "Otomatik (Modem / DHCP DNS)"
          dnsIps: "Servis Sağlayıcı Varsayılanı"
          isSelected: root.currentDnsPreset === "dhcp" && !root.showCustomDnsInput
          onClicked: {
            root.showCustomDnsInput = false
            if (ipc && root.activeSsid) {
              ipc.setConnectionDNS(root.activeSsid, [], false)
            }
          }
        }

        // Preset 6: Özel / Manuel DNS
        SettingsDnsCard {
          title: "Özel (Manuel IP Girişi)"
          dnsIps: root.showCustomDnsInput ? `${root.customDns1}, ${root.customDns2}` : "Kendi DNS sunucularınızı tanımlayın"
          isSelected: root.currentDnsPreset === "custom" || root.showCustomDnsInput
          onClicked: {
            root.showCustomDnsInput = !root.showCustomDnsInput
          }
        }

        // Özel DNS Giriş Alanı
        Rectangle {
          visible: root.showCustomDnsInput
          Layout.fillWidth: true
          implicitHeight: customDnsCol.implicitHeight + 20
          radius: 10
          color: Style.appCard
          border.color: Style.accentCyan
          border.width: 1

          ColumnLayout {
            id: customDnsCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Birincil DNS:"; font.pixelSize: 11; color: Style.textMuted }
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 32
                  radius: 6
                  color: Style.appBackground
                  border.color: Style.appBorder
                  border.width: 1
                  TextInput {
                    anchors.fill: parent
                    anchors.margins: 6
                    color: Style.textPrimary
                    font.pixelSize: 12
                    text: root.customDns1
                    onTextChanged: root.customDns1 = text
                  }
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "İkincil DNS:"; font.pixelSize: 11; color: Style.textMuted }
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 32
                  radius: 6
                  color: Style.appBackground
                  border.color: Style.appBorder
                  border.width: 1
                  TextInput {
                    anchors.fill: parent
                    anchors.margins: 6
                    color: Style.textPrimary
                    font.pixelSize: 12
                    text: root.customDns2
                    onTextChanged: root.customDns2 = text
                  }
                }
              }
            }

            SettingsButton {
              text: "Özel DNS'i Uygula"
              iconText: "✓"
              isAccent: true
              Layout.alignment: Qt.AlignRight
              onClicked: {
                if (ipc && root.activeSsid) {
                  let arr = []
                  if (root.customDns1.trim() !== "") arr.push(root.customDns1.trim())
                  if (root.customDns2.trim() !== "") arr.push(root.customDns2.trim())
                  ipc.setConnectionDNS(root.activeSsid, arr, true)
                }
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 3. IPv6 Sızıntı Koruması
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "IPv6 Sızıntı Koruması"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰖪"
          iconColor: Style.accentYellow
          title: "IPv6 Trafiğini Devre Dışı Bırak"
          subtitle: "Zapret'in tüm internet trafiğini eksiksiz yakalamasını sağlar ve IPv6 üzerinden oluşabilecek sansür sızıntılarını önler."
          showDivider: false

          SettingsToggle {
            checked: !!(root.netDetails && root.netDetails.ipv6_disabled)
            onToggled: isChecked => {
              if (ipc && root.activeSsid) {
                ipc.setConnectionIPv6(root.activeSsid, isChecked)
              }
            }
          }
        }
      }
    }

    // =========================================================================
    // 4. Kullanılabilir Kablosuz Ağlar
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      RowLayout {
        Layout.fillWidth: true

        SettingsSectionHeader {
          titleText: "Kullanılabilir Ağlar"
          Layout.fillWidth: true
        }

        SettingsButton {
          text: "Ağları Yenile"
          iconText: "󰑐"
          onClicked: {
            if (ipc) ipc.sendAction("scan_wifi", {})
          }
        }
      }

      SettingsCard {
        innerPadding: 6

        ListView {
          id: apListView
          Layout.fillWidth: true
          implicitHeight: Math.min(220, Math.max(80, count * 44))
          clip: true
          spacing: 2
          model: {
            if (!ipc || !ipc.wifi) return []
            let aps = ipc.wifi.access_points || ipc.wifi.scan_results || []
            return Array.isArray(aps) ? aps : []
          }

          delegate: Rectangle {
            width: apListView.width
            height: 40
            radius: 8
            readonly property bool isActive: !!(modelData.is_active || modelData.is_connected)
            color: isActive ? Style.surfaceActive : (itemHover.containsMouse ? Style.surfaceHover : "transparent")

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10

              Text {
                text: (modelData.signal >= 70) ? "󰤨" : ((modelData.signal >= 45) ? "󰤥" : ((modelData.signal >= 20) ? "󰤢" : "󰤟"))
                font.pixelSize: 15
                color: isActive ? Style.accentCyan : Style.textPrimary
              }

              Text {
                text: modelData.ssid || "Gizli Ağ"
                font.pixelSize: 12
                font.weight: isActive ? Font.Bold : Font.Medium
                color: isActive ? Style.accentCyan : Style.textPrimary
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              Text {
                text: `${modelData.band || "2.4/5GHz"} • %${modelData.signal || 0}`
                font.pixelSize: 10
                color: Style.textMuted
              }

              Text {
                visible: isActive
                text: "✓"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Style.accentCyan
              }
            }

            MouseArea {
              id: itemHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (isActive) return
                if (ipc) {
                  ipc.sendAction("connect_wifi", { "ssid": modelData.ssid, "password": "" })
                }
              }
            }
          }

          // Boş durum placeholder
          Item {
            anchors.centerIn: parent
            visible: apListView.count === 0
            Text {
              anchors.centerIn: parent
              text: "Ağlar taranıyor veya bulunamadı..."
              color: Style.textMuted
              font.pixelSize: 12
            }
          }
        }
      }
    }

    // =========================================================================
    // 5. Ağ Profili Bakımı & Kopya Temizleyici
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      SettingsSectionHeader {
        titleText: "Ağ Profili Bakımı"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰃢"
          iconColor: Style.accentGreen
          title: "Kopya Bağlantı Profillerini Temizle"
          subtitle: "NetworkManager'da birikmiş aynı ada sahip eski kopya (.nmconnection) dosyalarını siler ve ana profilinizi korur."
          showDivider: false

          SettingsButton {
            text: "Kopyaları Temizle"
            iconText: "󰩹"
            onClicked: {
              if (ipc) ipc.cleanupDuplicateProfiles("")
            }
          }
        }
      }

      Text {
        visible: root.cleanupStatusMessage !== ""
        text: root.cleanupStatusMessage
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Style.accentGreen
        leftPadding: 4
      }
    }
  }
}
