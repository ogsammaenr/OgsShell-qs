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

  // Wi-Fi Telemetry & State
  readonly property var netDetails: (ipc && ipc.networkDetails) ? ipc.networkDetails : null
  readonly property string activeSsid: (netDetails && netDetails.ssid) ? netDetails.ssid : ((ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : "")
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && (ipc.wifi.connected || (ipc.net && ipc.net.is_connected && !hasActiveWired)))
  readonly property bool isWifiPowered: !ipc || !ipc.wifi || ipc.wifi.ssid !== "Kapalı"

  property bool showCustomDnsInput: false
  property string customDns1: "1.1.1.1"
  property string customDns2: "1.0.0.1"
  property string cleanupStatusMessage: ""

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

  // Wired (Ethernet) Telemetry & State
  readonly property var wiredList: (ipc && ipc.wiredConnections) ? ipc.wiredConnections : []
  property int selectedWiredIndex: 0
  readonly property var currentWired: (wiredList && wiredList.length > selectedWiredIndex) ? wiredList[selectedWiredIndex] : ((wiredList && wiredList.length > 0) ? wiredList[0] : null)
  readonly property string wiredTargetId: currentWired ? (currentWired.uuid || currentWired.name || currentWired.interface) : ""
  readonly property bool hasActiveWired: wiredList ? wiredList.some(w => !!w.is_connected) : false
  readonly property bool hasCarrierWired: wiredList ? wiredList.some(w => !!w.carrier) : false

  property bool showCustomWiredDnsInput: false
  property string customWiredDns1: "1.1.1.1"
  property string customWiredDns2: "1.0.0.1"
  property string wiredStatusMessage: ""

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
        root.cleanupStatusMessage = `${payload.deleted_count || 0} adet kopya profil temizlendi.`
        cleanupMessageTimer.restart()
      }
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

  // Reusable Custom DNS Input Box
  component CustomDnsInputCard: Rectangle {
    id: dnsInputCard
    property string primaryDns: "1.1.1.1"
    property string secondaryDns: "1.0.0.1"
    property string applyLabel: "Özel DNS'i Uygula"
    signal primaryEdited(string text)
    signal secondaryEdited(string text)
    signal applyClicked(string dns1, string dns2)

    Layout.fillWidth: true
    implicitHeight: customCol.implicitHeight + 24
    radius: 10
    color: Style.appCard
    border.color: Style.borderHover
    border.width: 1

    ColumnLayout {
      id: customCol
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          Text {
            text: "Birincil DNS"
            font.family: Style.fontText
            font.pixelSize: 11
            color: Style.textMuted
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 7
            color: Style.appBackground
            border.color: dns1Field.activeFocus ? Style.accent : Style.appBorder
            border.width: 1

            TextInput {
              id: dns1Field
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              verticalAlignment: TextInput.AlignVCenter
              color: Style.textPrimary
              font.family: "Monospace"
              font.pixelSize: 12
              text: dnsInputCard.primaryDns
              selectByMouse: true
              onTextChanged: dnsInputCard.primaryEdited(text)
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          Text {
            text: "İkincil DNS"
            font.family: Style.fontText
            font.pixelSize: 11
            color: Style.textMuted
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 7
            color: Style.appBackground
            border.color: dns2Field.activeFocus ? Style.accent : Style.appBorder
            border.width: 1

            TextInput {
              id: dns2Field
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              verticalAlignment: TextInput.AlignVCenter
              color: Style.textPrimary
              font.family: "Monospace"
              font.pixelSize: 12
              text: dnsInputCard.secondaryDns
              selectByMouse: true
              onTextChanged: dnsInputCard.secondaryEdited(text)
            }
          }
        }
      }

      SettingsButton {
        text: dnsInputCard.applyLabel
        iconText: "󰄬"
        isAccent: true
        Layout.alignment: Qt.AlignRight
        onClicked: dnsInputCard.applyClicked(dns1Field.text.trim(), dns2Field.text.trim())
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    width: parent.width - 40
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 20
    spacing: 18

    // =========================================================================
    // 0. SLIDING SEGMENTED CONTROL (Wi-Fi vs Ethernet)
    // =========================================================================
    Rectangle {
      id: segmentedTrack
      Layout.fillWidth: true
      implicitHeight: 36
      radius: 9
      color: Style.surfaceVariant
      border.color: Style.appBorder
      border.width: 1

      readonly property real segmentWidth: (width - 6) / 2

      // Spring-animated sliding thumb capsule
      Rectangle {
        y: 3
        x: root.activeTab === "wifi" ? 3 : (3 + segmentedTrack.segmentWidth)
        width: segmentedTrack.segmentWidth
        height: parent.height - 6
        radius: 7
        color: Style.appCard
        border.color: Style.appBorder
        border.width: 1

        Behavior on x {
          SpringAnimation {
            spring: 28.0
            damping: 0.78
            epsilon: 0.01
          }
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          RowLayout {
            anchors.centerIn: parent
            spacing: 7

            Text {
              text: "󰤨"
              font.pixelSize: 14
              color: root.activeTab === "wifi" ? Style.accent : Style.textMuted
            }

            Text {
              text: "Wi-Fi (Kablosuz)"
              font.family: Style.fontText
              font.pixelSize: 12
              font.weight: root.activeTab === "wifi" ? Font.DemiBold : Font.Medium
              color: root.activeTab === "wifi" ? Style.textPrimary : Style.textMuted
            }

            Rectangle {
              width: 6
              height: 6
              radius: 3
              color: root.isWifiConnected ? Style.accentGreen : Style.textMuted
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.userSwitchedTab = true
              root.activeTab = "wifi"
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          RowLayout {
            anchors.centerIn: parent
            spacing: 7

            Text {
              text: "󰈀"
              font.pixelSize: 14
              color: root.activeTab === "wired" ? Style.accent : Style.textMuted
            }

            Text {
              text: "Kablolu (Ethernet)"
              font.family: Style.fontText
              font.pixelSize: 12
              font.weight: root.activeTab === "wired" ? Font.DemiBold : Font.Medium
              color: root.activeTab === "wired" ? Style.textPrimary : Style.textMuted
            }

            Rectangle {
              width: 6
              height: 6
              radius: 3
              color: root.hasActiveWired ? Style.accentGreen : (root.hasCarrierWired ? Style.accentOrange : Style.textMuted)
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.userSwitchedTab = true
              root.activeTab = "wired"
              if (ipc) ipc.requestWiredConnections()
            }
          }
        }
      }
    }

    // #########################################################################
    // SECTION A: WIRED (ETHERNET)
    // #########################################################################
    ColumnLayout {
      visible: root.activeTab === "wired"
      Layout.fillWidth: true
      spacing: 18

      // A1. Wired Hardware & Status
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
          Layout.fillWidth: true

          SettingsSectionHeader {
            titleText: "Kablolu Donanım"
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

        RowLayout {
          visible: root.wiredList && root.wiredList.length > 1
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: root.wiredList || []
            delegate: Rectangle {
              implicitWidth: profRow.implicitWidth + 18
              implicitHeight: 30
              radius: 7
              readonly property bool isSelected: root.selectedWiredIndex === index
              color: isSelected ? Qt.alpha(Style.accent, 0.14) : (profHover.containsMouse ? Style.surfaceHover : Style.appCard)
              border.color: isSelected ? Style.accent : Style.appBorder
              border.width: 1

              RowLayout {
                id: profRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                  text: "󰈀"
                  font.pixelSize: 12
                  color: isSelected ? Style.accent : Style.textSecondary
                }

                Text {
                  text: modelData.name || modelData.interface || `Bağlantı ${index + 1}`
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: isSelected ? Font.DemiBold : Font.Medium
                  color: isSelected ? Style.accent : Style.textPrimary
                }

                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  color: modelData.is_connected ? Style.accentGreen : (modelData.carrier ? Style.accentOrange : Style.textMuted)
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

        SettingsCard {
          visible: !!root.currentWired

          SettingsRow {
            iconText: "󰈀"
            iconColor: (root.currentWired && root.currentWired.is_connected) ? Style.accentGreen : ((root.currentWired && root.currentWired.carrier) ? Style.accentOrange : Style.textMuted)
            title: root.currentWired ? (root.currentWired.name || "Kablolu Bağlantı") : "Kablolu Ağ"
            subtitle: {
              if (!root.currentWired) return "Kablolu cihaz algılanamadı"
              if (root.currentWired.is_connected) {
                return `IP: ${root.currentWired.ip_address || "-"} • Ağ Geçidi: ${root.currentWired.gateway || "-"} • ${root.currentWired.interface || "eth0"}`
              }
              if (root.currentWired.carrier) {
                return `Kablo takılı • Hazır (${root.currentWired.interface || "eth0"})`
              }
              return `Kablo takılı değil (${root.currentWired.interface || "eth0"})`
            }
            showDivider: true

            Rectangle {
              implicitWidth: wiredBadgeRow.implicitWidth + 12
              implicitHeight: 22
              radius: 6
              color: {
                if (root.currentWired && root.currentWired.is_connected) return Qt.alpha(Style.accentGreen, 0.14)
                if (root.currentWired && root.currentWired.carrier) return Qt.alpha(Style.accentOrange, 0.14)
                return Style.surfaceVariant
              }

              RowLayout {
                id: wiredBadgeRow
                anchors.centerIn: parent
                spacing: 5

                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  color: {
                    if (root.currentWired && root.currentWired.is_connected) return Style.accentGreen
                    if (root.currentWired && root.currentWired.carrier) return Style.accentOrange
                    return Style.textMuted
                  }
                }

                Text {
                  text: {
                    if (root.currentWired && root.currentWired.is_connected) {
                      return root.currentWired.speed_mbps > 0 ? `${root.currentWired.speed_mbps} Mbps` : "Bağlı"
                    }
                    return (root.currentWired && root.currentWired.carrier) ? "Hazır" : "Kablo Yok"
                  }
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: Font.Medium
                  color: {
                    if (root.currentWired && root.currentWired.is_connected) return Style.accentGreen
                    if (root.currentWired && root.currentWired.carrier) return Style.accentOrange
                    return Style.textMuted
                  }
                }
              }
            }
          }

          SettingsRow {
            iconText: "󰢮"
            title: `Arayüz: ${root.currentWired ? root.currentWired.interface : "Ethernet"}`
            subtitle: `MAC: ${root.currentWired && root.currentWired.hw_address ? root.currentWired.hw_address : "-"} • Hız: ${root.currentWired && root.currentWired.speed_mbps > 0 ? root.currentWired.speed_mbps + ' Mbps' : 'Otomatik'}`
            showDivider: false
          }
        }

        SettingsCard {
          visible: !root.currentWired || (root.wiredList && root.wiredList.length === 0)
          SettingsRow {
            iconText: "󰈂"
            iconColor: Style.textMuted
            title: "Kablolu Arayüz Bulunamadı"
            subtitle: "Sistemde yapılandırılmış bir Ethernet arayüzü tespit edilemedi."
            showDivider: false
          }
        }
      }

      // A2. Wired DNS
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "Güvenli DNS (Kablolu)"
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 6

          SettingsDnsCard {
            title: "Cloudflare DNS"
            dnsIps: "1.1.1.1 • 1.0.0.1"
            isSelected: root.currentWiredDnsPreset === "cloudflare"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["1.1.1.1", "1.0.0.1"], true)
                root.wiredStatusMessage = "Cloudflare DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          SettingsDnsCard {
            title: "Quad9 DNS"
            dnsIps: "9.9.9.9 • 149.112.112.112"
            isSelected: root.currentWiredDnsPreset === "quad9"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["9.9.9.9", "149.112.112.112"], true)
                root.wiredStatusMessage = "Quad9 DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          SettingsDnsCard {
            title: "AdGuard DNS"
            dnsIps: "94.140.14.14 • 94.140.15.15"
            isSelected: root.currentWiredDnsPreset === "adguard"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["94.140.14.14", "94.140.15.15"], true)
                root.wiredStatusMessage = "AdGuard DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          SettingsDnsCard {
            title: "Google DNS"
            dnsIps: "8.8.8.8 • 8.8.4.4"
            isSelected: root.currentWiredDnsPreset === "google"
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, ["8.8.8.8", "8.8.4.4"], true)
                root.wiredStatusMessage = "Google DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          SettingsDnsCard {
            title: "Otomatik (DHCP DNS)"
            dnsIps: "Servis Sağlayıcı Varsayılanı"
            isSelected: root.currentWiredDnsPreset === "dhcp" && !root.showCustomWiredDnsInput
            onClicked: {
              root.showCustomWiredDnsInput = false
              if (ipc && root.wiredTargetId) {
                ipc.setConnectionDNS(root.wiredTargetId, [], false)
                root.wiredStatusMessage = "Otomatik DHCP DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }

          SettingsDnsCard {
            title: "Özel DNS"
            dnsIps: root.showCustomWiredDnsInput ? `${root.customWiredDns1}, ${root.customWiredDns2}` : "Manuel DNS sunucusu tanımlayın"
            isSelected: root.currentWiredDnsPreset === "custom" || root.showCustomWiredDnsInput
            onClicked: root.showCustomWiredDnsInput = !root.showCustomWiredDnsInput
          }

          CustomDnsInputCard {
            visible: root.showCustomWiredDnsInput
            primaryDns: root.customWiredDns1
            secondaryDns: root.customWiredDns2
            applyLabel: "Kablolu Ağ İçin Uygula"
            onPrimaryEdited: text => root.customWiredDns1 = text
            onSecondaryEdited: text => root.customWiredDns2 = text
            onApplyClicked: (d1, d2) => {
              if (ipc && root.wiredTargetId) {
                let arr = []
                if (d1 !== "") arr.push(d1)
                if (d2 !== "") arr.push(d2)
                ipc.setConnectionDNS(root.wiredTargetId, arr, true)
                root.wiredStatusMessage = "Özel DNS kablolu bağlantıya uygulandı."
                wiredMessageTimer.restart()
              }
            }
          }
        }

        Text {
          visible: root.wiredStatusMessage !== ""
          text: root.wiredStatusMessage
          font.family: Style.fontText
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.accentGreen
          leftPadding: 2
        }
      }

      // A3. Wired IPv6 Protection
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "IPv6 Koruması (Kablolu)"
        }

        SettingsCard {
          SettingsRow {
            iconText: "󰖪"
            title: "IPv6 Trafiğini Devre Dışı Bırak"
            subtitle: "Zapret uyumluluğu ve IPv6 DNS sızıntısını önlemek için IPv6'yı kapatır."
            showDivider: false

            SettingsToggle {
              checked: !!(root.currentWired && root.currentWired.ipv6_disabled)
              onToggled: isChecked => {
                if (ipc && root.wiredTargetId) {
                  ipc.setConnectionIPv6(root.wiredTargetId, isChecked)
                  root.wiredStatusMessage = isChecked ? "IPv6 devre dışı bırakıldı." : "IPv6 etkinleştirildi."
                  wiredMessageTimer.restart()
                }
              }
            }
          }
        }
      }
    }

    // #########################################################################
    // SECTION B: WI-FI
    // #########################################################################
    ColumnLayout {
      visible: root.activeTab === "wifi"
      Layout.fillWidth: true
      spacing: 18

      // B1. Wi-Fi Hardware & Active Connection
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "Wi-Fi & Bağlantı"
        }

        SettingsCard {
          SettingsRow {
            iconText: "󰤨"
            iconColor: root.isWifiConnected ? Style.accent : Style.textMuted
            title: "Wi-Fi Donanımı"
            subtitle: root.isWifiConnected ? `Bağlı: ${root.activeSsid}` : "Kablosuz ağ adaptörü"
            showDivider: root.isWifiConnected

            SettingsToggle {
              checked: root.isWifiPowered
              onToggled: isChecked => {
                if (ipc) ipc.sendAction("set_wifi_enabled", { "enabled": isChecked })
              }
            }
          }

          SettingsRow {
            visible: root.isWifiConnected
            iconText: "󰩠"
            iconColor: Style.accentGreen
            title: root.activeSsid
            subtitle: `IP: ${root.netDetails && root.netDetails.ip_address ? root.netDetails.ip_address : "-"} • Ağ Geçidi: ${root.netDetails && root.netDetails.gateway ? root.netDetails.gateway : "-"}`
            showDivider: false

            Rectangle {
              implicitWidth: statusRow.implicitWidth + 12
              implicitHeight: 22
              radius: 6
              color: Qt.alpha(Style.accentGreen, 0.14)

              RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 5

                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  color: Style.accentGreen
                }

                Text {
                  text: `%${root.netDetails && root.netDetails.signal ? root.netDetails.signal : ((ipc && ipc.wifi) ? ipc.wifi.signal : 80)}`
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: Font.Medium
                  color: Style.accentGreen
                }
              }
            }
          }
        }
      }

      // B2. Wi-Fi DNS
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "Güvenli DNS (Wi-Fi)"
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 6

          SettingsDnsCard {
            title: "Cloudflare DNS"
            dnsIps: "1.1.1.1 • 1.0.0.1"
            isSelected: root.currentDnsPreset === "cloudflare"
            onClicked: {
              root.showCustomDnsInput = false
              if (ipc && root.activeSsid) ipc.setConnectionDNS(root.activeSsid, ["1.1.1.1", "1.0.0.1"], true)
            }
          }

          SettingsDnsCard {
            title: "Quad9 DNS"
            dnsIps: "9.9.9.9 • 149.112.112.112"
            isSelected: root.currentDnsPreset === "quad9"
            onClicked: {
              root.showCustomDnsInput = false
              if (ipc && root.activeSsid) ipc.setConnectionDNS(root.activeSsid, ["9.9.9.9", "149.112.112.112"], true)
            }
          }

          SettingsDnsCard {
            title: "AdGuard DNS"
            dnsIps: "94.140.14.14 • 94.140.15.15"
            isSelected: root.currentDnsPreset === "adguard"
            onClicked: {
              root.showCustomDnsInput = false
              if (ipc && root.activeSsid) ipc.setConnectionDNS(root.activeSsid, ["94.140.14.14", "94.140.15.15"], true)
            }
          }

          SettingsDnsCard {
            title: "Google DNS"
            dnsIps: "8.8.8.8 • 8.8.4.4"
            isSelected: root.currentDnsPreset === "google"
            onClicked: {
              root.showCustomDnsInput = false
              if (ipc && root.activeSsid) ipc.setConnectionDNS(root.activeSsid, ["8.8.8.8", "8.8.4.4"], true)
            }
          }

          SettingsDnsCard {
            title: "Otomatik (DHCP DNS)"
            dnsIps: "Servis Sağlayıcı Varsayılanı"
            isSelected: root.currentDnsPreset === "dhcp" && !root.showCustomDnsInput
            onClicked: {
              root.showCustomDnsInput = false
              if (ipc && root.activeSsid) ipc.setConnectionDNS(root.activeSsid, [], false)
            }
          }

          SettingsDnsCard {
            title: "Özel DNS"
            dnsIps: root.showCustomDnsInput ? `${root.customDns1}, ${root.customDns2}` : "Manuel DNS sunucusu tanımlayın"
            isSelected: root.currentDnsPreset === "custom" || root.showCustomDnsInput
            onClicked: root.showCustomDnsInput = !root.showCustomDnsInput
          }

          CustomDnsInputCard {
            visible: root.showCustomDnsInput
            primaryDns: root.customDns1
            secondaryDns: root.customDns2
            applyLabel: "Özel DNS'i Uygula"
            onPrimaryEdited: text => root.customDns1 = text
            onSecondaryEdited: text => root.customDns2 = text
            onApplyClicked: (d1, d2) => {
              if (ipc && root.activeSsid) {
                let arr = []
                if (d1 !== "") arr.push(d1)
                if (d2 !== "") arr.push(d2)
                ipc.setConnectionDNS(root.activeSsid, arr, true)
              }
            }
          }
        }
      }

      // B3. Wi-Fi IPv6 Protection
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "IPv6 Koruması (Wi-Fi)"
        }

        SettingsCard {
          SettingsRow {
            iconText: "󰖪"
            title: "IPv6 Trafiğini Devre Dışı Bırak"
            subtitle: "Zapret uyumluluğu ve IPv6 DNS sızıntısını önlemek için IPv6'yı kapatır."
            showDivider: false

            SettingsToggle {
              checked: !!(root.netDetails && root.netDetails.ipv6_disabled)
              onToggled: isChecked => {
                if (ipc && root.activeSsid) ipc.setConnectionIPv6(root.activeSsid, isChecked)
              }
            }
          }
        }
      }

      // B4. Available Networks
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
            text: "Yenile"
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
            implicitHeight: Math.min(220, Math.max(76, count * 40))
            clip: true
            spacing: 2
            model: {
              if (!ipc || !ipc.wifi) return []
              let aps = ipc.wifi.access_points || ipc.wifi.scan_results || []
              return Array.isArray(aps) ? aps : []
            }

            delegate: Rectangle {
              width: apListView.width
              height: 38
              radius: 7
              readonly property bool isActive: !!(modelData.is_active || modelData.is_connected)
              color: isActive ? Qt.alpha(Style.accent, 0.14) : (itemHover.containsMouse ? Style.surfaceHover : "transparent")

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text {
                  text: (modelData.signal >= 70) ? "󰤨" : ((modelData.signal >= 45) ? "󰤥" : ((modelData.signal >= 20) ? "󰤢" : "󰤟"))
                  font.pixelSize: 14
                  color: isActive ? Style.accent : Style.textSecondary
                }

                Text {
                  text: modelData.ssid || "Gizli Ağ"
                  font.family: Style.fontText
                  font.pixelSize: 12
                  font.weight: isActive ? Font.DemiBold : Font.Medium
                  color: isActive ? Style.accent : Style.textPrimary
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  text: `${modelData.band || "2.4/5GHz"} • %${modelData.signal || 0}`
                  font.family: Style.fontText
                  font.pixelSize: 10
                  color: Style.textMuted
                }

                Text {
                  visible: isActive
                  text: "󰄬"
                  font.pixelSize: 13
                  color: Style.accent
                }
              }

              MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (isActive) return
                  if (ipc) ipc.sendAction("connect_wifi", { "ssid": modelData.ssid, "password": "" })
                }
              }
            }

            Item {
              anchors.centerIn: parent
              visible: apListView.count === 0
              Text {
                anchors.centerIn: parent
                text: "Ağlar taranıyor veya bulunamadı..."
                font.family: Style.fontText
                color: Style.textMuted
                font.pixelSize: 12
              }
            }
          }
        }
      }

      // B5. Profile Cleanup
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        SettingsSectionHeader {
          titleText: "Profil Bakımı"
        }

        SettingsCard {
          SettingsRow {
            iconText: "󰃢"
            title: "Kopya Bağlantı Profillerini Temizle"
            subtitle: "Birikmiş eski .nmconnection kopyalarını temizler ve ana profili korur."
            showDivider: false

            SettingsButton {
              text: "Temizle"
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
          font.family: Style.fontText
          font.pixelSize: 12
          font.weight: Font.Medium
          color: Style.accentGreen
          leftPadding: 2
        }
      }
    }
  }
}
