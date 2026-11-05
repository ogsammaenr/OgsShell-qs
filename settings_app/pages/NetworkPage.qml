import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../components"

Flickable {
  id: root

  property var ipc

  // Active sub-tab: "wifi" or "wired"
  property string activeTab: "wifi"
  property bool userSwitchedTab: false

  // ===========================================================================
  // Wi-Fi Telemetry & State
  // ===========================================================================
  readonly property var netDetails: (ipc && ipc.networkDetails) ? ipc.networkDetails : null
  readonly property string activeSsid: (netDetails && netDetails.ssid) ? netDetails.ssid : ((ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : "")
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && (ipc.wifi.connected || (ipc.net && ipc.net.is_connected && !hasActiveWired)))
  readonly property bool isWifiPowered: !ipc || !ipc.wifi || ipc.wifi.ssid !== "Kapalı"

  // Custom DNS input states (Wi-Fi)
  property bool showCustomDnsInput: false
  property string customDns1: "1.1.1.1"
  property string customDns2: "1.0.0.1"
  property string cleanupStatusMessage: ""

  // Active DNS Preset detection (Wi-Fi)
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

  // ===========================================================================
  // Wired (Ethernet) Telemetry & State
  // ===========================================================================
  readonly property var wiredList: (ipc && ipc.wiredConnections) ? ipc.wiredConnections : []
  property int selectedWiredIndex: 0
  readonly property var currentWired: (wiredList && wiredList.length > selectedWiredIndex) ? wiredList[selectedWiredIndex] : ((wiredList && wiredList.length > 0) ? wiredList[0] : null)
  readonly property string wiredTargetId: currentWired ? (currentWired.uuid || currentWired.name || currentWired.interface) : ""
  readonly property bool hasActiveWired: wiredList ? wiredList.some(w => !!w.is_connected) : false
  readonly property bool hasCarrierWired: wiredList ? wiredList.some(w => !!w.carrier) : false

  // Custom DNS input states (Wired)
  property bool showCustomWiredDnsInput: false
  property string customWiredDns1: "1.1.1.1"
  property string customWiredDns2: "1.0.0.1"
  property string wiredStatusMessage: ""

  // Active DNS Preset detection (Wired)
  readonly property string currentWiredDnsPreset: {
    if (!currentWired) return "dhcp"
    if (!currentWired.ignore_auto_dns || !currentWired.dns || currentWired.dns.length === 0) return "dhcp"
    let dnsStr = currentWired.dns.join(",")
    if (dnsStr.indexOf("1.1.1.1") !== -1 || dnsStr.indexOf("1.0.0.1") !== -1) return "cloudflare"
    if (dnsStr.indexOf("9.9.9.9") !== -1 || dnsStr.indexOf("149.112.112.112") !== -1) return "quad9"
    if (dnsStr.indexOf("94.140.14.14") !== -1 || dnsStr.indexOf("94.140.15.15") !== -1) return "adguard"
    if (dnsStr.indexOf("8.8.8.8") !== -1 || dnsStr.indexOf("8.8.4.4") !== -1) return "google"
    return "custom"
  }

  onHasActiveWiredChanged: {
    if (!userSwitchedTab && hasActiveWired && !isWifiConnected) {
      activeTab = "wired"
    }
  }

  contentWidth: width
  contentHeight: mainColumn.implicitHeight + 40
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  Component.onCompleted: {
    if (ipc) {
      ipc.requestNetworkDetails("")
      ipc.requestWiredConnections()
      ipc.sendAction("scan_wifi", {})
    }
    if (hasActiveWired && !isWifiConnected) {
      activeTab = "wired"
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
    function onWiredConnectionsUpdated() {
      if (root.currentWired && root.currentWired.dns && root.currentWired.dns.length > 0) {
        root.customWiredDns1 = root.currentWired.dns[0] || "1.1.1.1"
        root.customWiredDns2 = (root.currentWired.dns.length > 1) ? root.currentWired.dns[1] : ""
      }
    }
  }

  Timer {
    id: cleanupMessageTimer
    interval: 4000
    repeat: false
    onTriggered: root.cleanupStatusMessage = ""
  }

  Timer {
    id: wiredMessageTimer
    interval: 4000
    repeat: false
    onTriggered: root.wiredStatusMessage = ""
  }

  ColumnLayout {
    id: mainColumn
    width: parent.width - 24
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 16
    spacing: 20

    // =========================================================================
    // 0. Bağlantı Türü Seçici (Segmented Tab Bar)
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Tab 1: Wi-Fi
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 8
        color: root.activeTab === "wifi" ? Style.surfaceActive : (wifiHover.containsMouse ? Style.surfaceHover : Style.appCard)
        border.color: root.activeTab === "wifi" ? Style.accentCyan : Style.appBorder
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
          anchors.centerIn: parent
          spacing: 8

          Text {
            text: "󰤨"
            font.pixelSize: 15
            color: root.activeTab === "wifi" ? Style.accentCyan : Style.textPrimary
          }

          Text {
            text: "Wi-Fi (Kablosuz)"
            font.pixelSize: 13
            font.weight: root.activeTab === "wifi" ? Font.Bold : Font.Medium
            color: root.activeTab === "wifi" ? Style.accentCyan : Style.textPrimary
          }

          Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: root.isWifiConnected ? Style.accentGreen : Style.textMuted
          }
        }

        MouseArea {
          id: wifiHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.userSwitchedTab = true
            root.activeTab = "wifi"
          }
        }
      }

      // Tab 2: Kablolu Ağ (Ethernet)
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 8
        color: root.activeTab === "wired" ? Style.surfaceActive : (wiredHover.containsMouse ? Style.surfaceHover : Style.appCard)
        border.color: root.activeTab === "wired" ? Style.accentCyan : Style.appBorder
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
          anchors.centerIn: parent
          spacing: 8

          Text {
            text: "󰈀"
            font.pixelSize: 15
            color: root.activeTab === "wired" ? Style.accentCyan : Style.textPrimary
          }

          Text {
            text: "Kablolu Ağ (Ethernet)"
            font.pixelSize: 13
            font.weight: root.activeTab === "wired" ? Font.Bold : Font.Medium
            color: root.activeTab === "wired" ? Style.accentCyan : Style.textPrimary
          }

          Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: root.hasActiveWired ? Style.accentGreen : (root.hasCarrierWired ? Style.accentYellow : Style.textMuted)
          }
        }

        MouseArea {
          id: wiredHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.userSwitchedTab = true
            root.activeTab = "wired"
            if (ipc) ipc.requestWiredConnections()
          }
        }
      }
    }

    // #########################################################################
    // SECTION A: KABLOLU AĞ (ETHERNET) GÖRÜNÜMÜ
    // #########################################################################
    ColumnLayout {
      visible: root.activeTab === "wired"
      Layout.fillWidth: true
      spacing: 20

      // -----------------------------------------------------------------------
      // A1. Kablolu Donanım & Bağlantı Durumu
      // -----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
          Layout.fillWidth: true

          SettingsSectionHeader {
            titleText: "Kablolu Donanım & Bağlantı Durumu"
            Layout.fillWidth: true
          }

          SettingsButton {
            text: "Yenile"
            iconText: "󰑐"
            onClicked: {
              if (ipc) ipc.requestWiredConnections()
            }
          }
        }

        // Çoklu Profil / Kart Seçici (Eğer birden fazla kablolu bağlantı varsa)
        RowLayout {
          visible: root.wiredList && root.wiredList.length > 1
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: root.wiredList || []
            delegate: Rectangle {
              implicitWidth: profRow.implicitWidth + 20
              implicitHeight: 32
              radius: 6
              readonly property bool isSelected: root.selectedWiredIndex === index
              color: isSelected ? Style.surfaceActive : (profHover.containsMouse ? Style.surfaceHover : Style.appCard)
              border.color: isSelected ? Style.accentCyan : Style.appBorder
              border.width: 1

              RowLayout {
                id: profRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                  text: "󰈀"
                  font.pixelSize: 12
                  color: isSelected ? Style.accentCyan : Style.textPrimary
                }

                Text {
                  text: modelData.name || modelData.interface || `Bağlantı ${index + 1}`
                  font.pixelSize: 11
                  font.weight: isSelected ? Font.Bold : Font.Medium
                  color: isSelected ? Style.accentCyan : Style.textPrimary
                }

                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  color: modelData.is_connected ? Style.accentGreen : (modelData.carrier ? Style.accentYellow : Style.textMuted)
                }
              }

              MouseArea {
                id: profHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedWiredIndex = index
                  if (modelData.dns && modelData.dns.length > 0) {
                    root.customWiredDns1 = modelData.dns[0] || "1.1.1.1"
                    root.customWiredDns2 = (modelData.dns.length > 1) ? modelData.dns[1] : ""
                  }
                }
              }
            }
          }
        }

        // Kablolu Durum Kartı
        SettingsCard {
          visible: !!root.currentWired

          SettingsRow {
            iconText: "󰈀"
            iconColor: (root.currentWired && root.currentWired.is_connected) ? Style.accentGreen : ((root.currentWired && root.currentWired.carrier) ? Style.accentYellow : Style.textMuted)
            title: root.currentWired ? (root.currentWired.name || "Kablolu Bağlantı") : "Kablolu Ağ"
            subtitle: {
              if (!root.currentWired) return "Kablolu cihaz algılanamadı"
              if (root.currentWired.is_connected) {
                return `IP: ${root.currentWired.ip_address || "192.168.1.X"} • Ağ Geçidi: ${root.currentWired.gateway || "192.168.1.1"} • Arayüz: ${root.currentWired.interface || "eth0"}`
              }
              if (root.currentWired.carrier) {
                return `Kablo takılı • Bağlantı hazır (${root.currentWired.interface || "eth0"})`
              }
              return `Kablo takılı değil (${root.currentWired.interface || "eth0"})`
            }
            showDivider: true

            Rectangle {
              implicitWidth: wiredBadgeRow.implicitWidth + 14
              implicitHeight: 24
              radius: 12
              color: {
                if (root.currentWired && root.currentWired.is_connected) return Qt.rgba(0.2, 0.8, 0.4, 0.15)
                if (root.currentWired && root.currentWired.carrier) return Qt.rgba(0.9, 0.7, 0.2, 0.15)
                return Qt.rgba(0.5, 0.5, 0.5, 0.15)
              }
              border.color: {
                if (root.currentWired && root.currentWired.is_connected) return Qt.rgba(0.2, 0.8, 0.4, 0.4)
                if (root.currentWired && root.currentWired.carrier) return Qt.rgba(0.9, 0.7, 0.2, 0.4)
                return Qt.rgba(0.5, 0.5, 0.5, 0.3)
              }
              border.width: 1

              RowLayout {
                id: wiredBadgeRow
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  color: {
                    if (root.currentWired && root.currentWired.is_connected) return Style.accentGreen
                    if (root.currentWired && root.currentWired.carrier) return Style.accentYellow
                    return Style.textMuted
                  }
                }

                Text {
                  text: {
                    if (root.currentWired && root.currentWired.is_connected) {
                      return `Bağlı • ${root.currentWired.speed_mbps > 0 ? root.currentWired.speed_mbps + ' Mbps' : 'Aktif'}`
                    }
                    if (root.currentWired && root.currentWired.carrier) {
                      return "Kablo Takılı • Hazır"
                    }
                    return "Kablo Yok"
                  }
                  font.pixelSize: 11
                  font.weight: Font.Medium
                  color: {
                    if (root.currentWired && root.currentWired.is_connected) return Style.accentGreen
                    if (root.currentWired && root.currentWired.carrier) return Style.accentYellow
                    return Style.textMuted
                  }
                }
              }
            }
          }

          // Donanım Ayrıntıları Satırı
          SettingsRow {
            iconText: "󰢮"
            iconColor: Style.accentCyan
            title: `Arayüz Donanımı: ${root.currentWired ? root.currentWired.interface : "Ethernet"}`
            subtitle: `MAC: ${root.currentWired && root.currentWired.hw_address ? root.currentWired.hw_address : "Bilinmiyor"} • Hız: ${root.currentWired && root.currentWired.speed_mbps > 0 ? root.currentWired.speed_mbps + ' Mbps' : 'Otomatik'} • Taşıyıcı (Carrier): ${root.currentWired && root.currentWired.carrier ? "Aktif (Takılı)" : "Sinyal Yok"}`
            showDivider: false
          }
        }

        // Boş durum placeholder
        SettingsCard {
          visible: !root.currentWired || (root.wiredList && root.wiredList.length === 0)
          SettingsRow {
            iconText: "󰈂"
            iconColor: Style.textMuted
            title: "Kablolu Arayüz Bulunamadı"
            subtitle: "Sistemde yapılandırılmış bir Ethernet arayüzü veya kablolu profil tespit edilemedi."
            showDivider: false
          }
        }
      }

      // -----------------------------------------------------------------------
      // A2. Güvenli DNS Seçimi (Kablolu - DPI Bypass & Zapret Uyumu)
      // -----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "Güvenli DNS & DPI Bypass (Zapret - Kablolu Ağ)"
        }

        Text {
          text: "Kablolu bağlantınız üzerinden Zapret gibi DPI bypass araçlarının çalışabilmesi ve servis sağlayıcının DNS engellemelerini aşmak için güvenli bir DNS sunucusu seçin."
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
            isSelected: root.currentWiredDnsPreset === "cloudflare"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["1.1.1.1", "1.0.0.1"], true)
                root.wiredStatusMessage = "✓ Cloudflare DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          // Preset 2: Quad9
          SettingsDnsCard {
            title: "Quad9 DNS"
            dnsIps: "9.9.9.9 • 149.112.112.112"
            isSelected: root.currentWiredDnsPreset === "quad9"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["9.9.9.9", "149.112.112.112"], true)
                root.wiredStatusMessage = "✓ Quad9 DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          // Preset 3: AdGuard
          SettingsDnsCard {
            title: "AdGuard DNS"
            dnsIps: "94.140.14.14 • 94.140.15.15"
            isSelected: root.currentWiredDnsPreset === "adguard"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["94.140.14.14", "94.140.15.15"], true)
                root.wiredStatusMessage = "✓ AdGuard DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          // Preset 4: Google DNS
          SettingsDnsCard {
            title: "Google DNS"
            dnsIps: "8.8.8.8 • 8.8.4.4"
            isSelected: root.currentWiredDnsPreset === "google"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["8.8.8.8", "8.8.4.4"], true)
                root.wiredStatusMessage = "✓ Google DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          // Preset 5: Otomatik DHCP / Modem DNS
          SettingsDnsCard {
            title: "Otomatik (Modem / DHCP DNS)"
            dnsIps: "Servis Sağlayıcı Varsayılanı"
            isSelected: root.currentWiredDnsPreset === "dhcp" && !root.showCustomWiredDnsInput
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, [], false)
                root.wiredStatusMessage = "✓ Otomatik (DHCP) DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          // Preset 6: Özel / Manuel DNS
          SettingsDnsCard {
            title: "Özel (Manuel IP Girişi)"
            dnsIps: root.showCustomWiredDnsInput ? `${root.customWiredDns1}, ${root.customWiredDns2}` : "Kendi DNS sunucularınızı tanımlayın"
            isSelected: root.currentWiredDnsPreset === "custom" || root.showCustomWiredDnsInput
            onClicked: {
              root.showCustomWiredDnsInput = !root.showCustomWiredDnsInput
            }
          }

          // Özel DNS Giriş Alanı (Kablolu)
          Rectangle {
            visible: root.showCustomWiredDnsInput
            Layout.fillWidth: true
            implicitHeight: customWiredDnsCol.implicitHeight + 20
            radius: 10
            color: Style.appCard
            border.color: Style.accentCyan
            border.width: 1

            ColumnLayout {
              id: customWiredDnsCol
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
                      text: root.customWiredDns1
                      onTextChanged: root.customWiredDns1 = text
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
                      text: root.customWiredDns2
                      onTextChanged: root.customWiredDns2 = text
                    }
                  }
                }
              }

              SettingsButton {
                text: "Kablolu Ağ İçin Özel DNS'i Uygula"
                iconText: "✓"
                isAccent: true
                Layout.alignment: Qt.AlignRight
                onClicked: {
                  if (ipc && root.wiredTargetId) {
                    let arr = []
                    if (root.customWiredDns1.trim() !== "") arr.push(root.customWiredDns1.trim())
                    if (root.customWiredDns2.trim() !== "") arr.push(root.customWiredDns2.trim())
                    ipc.setConnectionDNS(root.wiredTargetId, arr, true)
                    root.wiredStatusMessage = "✓ Özel DNS kablolu bağlantıya uygulandı."
                    wiredMessageTimer.restart()
                  }
                }
              }
            }
          }
        }

        Text {
          visible: root.wiredStatusMessage !== ""
          text: root.wiredStatusMessage
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.accentGreen
          leftPadding: 4
        }
      }

      // -----------------------------------------------------------------------
      // A3. IPv6 Sızıntı Koruması (Kablolu)
      // -----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "IPv6 Sızıntı Koruması (Kablolu Ağ)"
        }

        SettingsCard {
          SettingsRow {
            iconText: "󰖪"
            iconColor: Style.accentYellow
            title: "IPv6 Trafiğini Devre Dışı Bırak"
            subtitle: "Zapret'in kablolu ağdaki tüm internet trafiğini eksiksiz yakalamasını sağlar ve IPv6 üzerinden oluşabilecek sansür sızıntılarını önler."
            showDivider: false

            SettingsToggle {
              checked: !!(root.currentWired && root.currentWired.ipv6_disabled)
              onToggled: isChecked => {
                if (ipc && root.wiredTargetId) {
                  ipc.setConnectionIPv6(root.wiredTargetId, isChecked)
                  root.wiredStatusMessage = isChecked ? "✓ IPv6 devre dışı bırakıldı." : "✓ IPv6 etkinleştirildi."
                  wiredMessageTimer.restart()
                }
              }
            }
          }
        }
      }
    }

    // #########################################################################
    // SECTION B: WI-FI (KABLOSUZ AĞ) GÖRÜNÜMÜ
    // #########################################################################
    ColumnLayout {
      visible: root.activeTab === "wifi"
      Layout.fillWidth: true
      spacing: 20

      // -----------------------------------------------------------------------
      // B1. Wi-Fi Donanım & Aktif Bağlantı Durumu
      // -----------------------------------------------------------------------
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

      // -----------------------------------------------------------------------
      // B2. Güvenli DNS Seçimi (Wi-Fi)
      // -----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "Güvenli DNS & DPI Bypass (Zapret - Wi-Fi)"
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

      // -----------------------------------------------------------------------
      // B3. IPv6 Sızıntı Koruması (Wi-Fi)
      // -----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "IPv6 Sızıntı Koruması (Wi-Fi)"
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

      // -----------------------------------------------------------------------
      // B4. Kullanılabilir Kablosuz Ağlar
      // -----------------------------------------------------------------------
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

      // -----------------------------------------------------------------------
      // B5. Ağ Profili Bakımı & Kopya Temizleyici
      // -----------------------------------------------------------------------
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
}
