import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../components"

Flickable {
  id: root

  property var ipc: null
  signal notifyToast(string msg, bool isErr)

  property string activeTab: "wifi"
  property bool userSwitchedTab: false

  // Wi-Fi State
  readonly property var netDetails: (ipc && ipc.networkDetails) ? ipc.networkDetails : null
  readonly property string activeSsid: (netDetails && netDetails.ssid) ? netDetails.ssid : ((ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : "")
  readonly property bool isWifiConnected: !!(ipc && ipc.wifi && (ipc.wifi.connected || (ipc.net && ipc.net.is_connected && !hasActiveWired)))
  readonly property bool isWifiPowered: !ipc || !ipc.wifi || ipc.wifi.ssid !== "Kapalı"

  // Wired State
  readonly property var wiredList: (ipc && ipc.wiredConnections) ? ipc.wiredConnections : []
  property int selectedWiredIndex: 0
  readonly property var currentWired: (wiredList && wiredList.length > selectedWiredIndex) ? wiredList[selectedWiredIndex] : ((wiredList && wiredList.length > 0) ? wiredList[0] : null)
  readonly property string wiredTargetId: currentWired ? (currentWired.uuid || currentWired.name || currentWired.interface) : ""
  readonly property bool hasActiveWired: wiredList ? wiredList.some(w => !!w.is_connected) : false
  readonly property bool hasCarrierWired: wiredList ? wiredList.some(w => !!w.carrier) : false

  // Shared DNS Custom Inputs
  property bool showCustomDns: false
  property string customDns1: "1.1.1.1"
  property string customDns2: "1.0.0.1"

  readonly property var activeConnObj: activeTab === "wired" ? currentWired : netDetails
  readonly property string activeTargetId: activeTab === "wired" ? wiredTargetId : activeSsid

  readonly property string activeDnsPreset: {
    let c = activeConnObj
    if (!c || !c.ignore_auto_dns || !c.dns || c.dns.length === 0) return "dhcp"
    let dnsStr = c.dns.join(",")
    if (dnsStr.indexOf("1.1.1.1") !== -1 || dnsStr.indexOf("1.0.0.1") !== -1) return "cloudflare"
    if (dnsStr.indexOf("9.9.9.9") !== -1 || dnsStr.indexOf("149.112.112.112") !== -1) return "quad9"
    if (dnsStr.indexOf("94.140.14.14") !== -1 || dnsStr.indexOf("94.140.15.15") !== -1) return "adguard"
    if (dnsStr.indexOf("8.8.8.8") !== -1 || dnsStr.indexOf("8.8.4.4") !== -1) return "google"
    return "custom"
  }

  readonly property var dnsPresets: [
    { "id": "cloudflare", "title": "Cloudflare", "ips": "1.1.1.1 • 1.0.0.1",         "arr": ["1.1.1.1", "1.0.0.1"],         "manual": true },
    { "id": "quad9",      "title": "Quad9",      "ips": "9.9.9.9 • 149.112.112.112", "arr": ["9.9.9.9", "149.112.112.112"], "manual": true },
    { "id": "adguard",    "title": "AdGuard",    "ips": "94.140.14.14 • 94.140.15.15","arr": ["94.140.14.14", "94.140.15.15"], "manual": true },
    { "id": "google",     "title": "Google",     "ips": "8.8.8.8 • 8.8.4.4",         "arr": ["8.8.8.8", "8.8.4.4"],         "manual": true },
    { "id": "dhcp",       "title": "Otomatik",   "ips": "DHCP Varsayılanı",          "arr": [],                              "manual": false },
    { "id": "custom",     "title": "Özel DNS",   "ips": "Manuel IP girin",           "arr": [],                              "manual": true }
  ]

  onHasActiveWiredChanged: {
    if (!userSwitchedTab && hasActiveWired && !isWifiConnected) {
      activeTab = "wired"
    }
  }

  function refreshState() {
    if (ipc) {
      ipc.requestNetworkDetails("")
      ipc.requestWiredConnections()
      ipc.sendAction("scan_wifi", {})
    }
    if (hasActiveWired && !isWifiConnected) {
      activeTab = "wired"
    }
  }

  onIpcChanged: refreshState()
  Component.onCompleted: refreshState()

  Connections {
    target: ipc ? ipc : null
    function onCleanupDuplicatesCompleted(payload) {
      if (payload) {
        root.notifyToast((payload.deleted_count || 0) + " adet kopya profil temizlendi.", false)
      }
    }
  }

  contentWidth: width
  contentHeight: mainColumn.implicitHeight + 48
  boundsBehavior: Flickable.StopAtBounds
  acceptedButtons: Qt.NoButton
  clip: true

  ScrollBar.vertical: ScrollBar {
    policy: ScrollBar.AsNeeded
    width: 6
  }

  ColumnLayout {
    id: mainColumn
    width: parent.width - 48
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 22
    spacing: 20

    // =========================================================================
    // 1. CONNECTION TYPE SWITCHER (Wi-Fi vs Ethernet)
    // =========================================================================
    SettingsSegmentedTabs {
      activeId: root.activeTab
      tabs: [
        {
          "id": "wifi",
          "label": "Wi-Fi (Kablosuz)",
          "icon": "󰤨",
          "dotColor": root.isWifiConnected ? Style.accentGreen : Style.textMuted
        },
        {
          "id": "wired",
          "label": "Kablolu (Ethernet)",
          "icon": "󰈀",
          "dotColor": root.hasActiveWired ? Style.accentGreen : (root.hasCarrierWired ? Style.accentOrange : Style.textMuted)
        }
      ]
      onTabSelected: id => {
        root.userSwitchedTab = true
        root.activeTab = id
        root.showCustomDns = false
        if (id === "wired" && root.ipc) root.ipc.requestWiredConnections()
      }
    }

    // =========================================================================
    // 2. ACTIVE HARDWARE & CONNECTION SUMMARY
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      RowLayout {
        Layout.fillWidth: true

        SettingsSectionHeader {
          titleText: root.activeTab === "wired" ? "Ethernet Durumu" : "Wi-Fi Durumu"
          Layout.fillWidth: true
        }

        SettingsButton {
          text: "Yenile"
          iconText: "󰑐"
          onClicked: {
            if (!root.ipc) return
            if (root.activeTab === "wired") root.ipc.requestWiredConnections()
            else {
              root.ipc.requestNetworkDetails("")
              root.ipc.sendAction("scan_wifi", {})
            }
            root.notifyToast("Ağ durumu yenilendi.", false)
          }
        }
      }

      // Multi-Interface Picker for Wired
      Flow {
        visible: root.activeTab === "wired" && root.wiredList && root.wiredList.length > 1
        Layout.fillWidth: true
        spacing: 6

        Repeater {
          model: root.wiredList || []
          delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool isSelected: root.selectedWiredIndex === index
            implicitWidth: profRow.implicitWidth + 18
            height: 30
            radius: 7
            color: isSelected ? Qt.alpha(Style.accent, 0.14) : (profHover.containsMouse ? Style.surfaceHover : Style.appCard)
            border.color: isSelected ? Style.accent : Style.appBorder
            border.width: 1

            RowLayout {
              id: profRow
              anchors.centerIn: parent
              spacing: 6
              Text { text: "󰈀"; font.pixelSize: 12; color: isSelected ? Style.accent : Style.textSecondary }
              Text {
                text: modelData.name || modelData.interface || ("Bağlantı " + (index + 1))
                font.family: Style.fontText; font.pixelSize: 11; font.weight: isSelected ? Font.DemiBold : Font.Medium
                color: isSelected ? Style.accent : Style.textPrimary
              }
            }

            MouseArea {
              id: profHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedWiredIndex = index
            }
          }
        }
      }

      // Wi-Fi Card
      SettingsCard {
        visible: root.activeTab === "wifi"

        SettingsRow {
          iconText: "󰤨"
          iconColor: root.isWifiConnected ? Style.accent : Style.textMuted
          title: "Wi-Fi Adaptörü"
          subtitle: root.isWifiConnected
            ? (root.activeSsid + "  •  IP: " + (root.netDetails && root.netDetails.ip_address ? root.netDetails.ip_address : "-"))
            : "Kablosuz ağ bağlantısı"
          showDivider: false

          SettingsToggle {
            checked: root.isWifiPowered
            onToggled: isChecked => {
              if (root.ipc) root.ipc.sendAction("set_wifi_enabled", { "enabled": isChecked })
              root.notifyToast(isChecked ? "Wi-Fi açıldı." : "Wi-Fi kapatıldı.", false)
            }
          }
        }
      }

      // Wired Card
      SettingsCard {
        visible: root.activeTab === "wired"

        SettingsRow {
          iconText: root.currentWired ? "󰈀" : "󰈂"
          iconColor: (root.currentWired && root.currentWired.is_connected) ? Style.accentGreen : Style.textMuted
          title: root.currentWired ? (root.currentWired.name || "Ethernet") : "Kablolu Arayüz Bulunamadı"
          subtitle: {
            if (!root.currentWired) return "Yapılandırılmış bir Ethernet kartı algılanamadı."
            if (root.currentWired.is_connected) {
              return "IP: " + (root.currentWired.ip_address || "-") + "  •  " + (root.currentWired.interface || "eth0") + (root.currentWired.speed_mbps > 0 ? ("  •  " + root.currentWired.speed_mbps + " Mbps") : "")
            }
            return root.currentWired.carrier ? ("Kablo takılı (" + root.currentWired.interface + ")") : ("Kablo takılı değil (" + root.currentWired.interface + ")")
          }
          showDivider: false
        }
      }
    }

    // =========================================================================
    // 3. COMPACT 2x3 SECURE DNS SELECTOR (Unified for Active Connection)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Güvenli DNS ve DPI Koruması"
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
          model: root.dnsPresets

          delegate: SettingsDnsCard {
            required property var modelData
            title: modelData.title
            dnsIps: modelData.ips
            isSelected: modelData.id === "custom"
              ? (root.activeDnsPreset === "custom" || root.showCustomDns)
              : (root.activeDnsPreset === modelData.id && !root.showCustomDns)
            onClicked: {
              if (modelData.id === "custom") {
                root.showCustomDns = !root.showCustomDns
                return
              }
              root.showCustomDns = false
              if (root.ipc && root.activeTargetId) {
                root.ipc.setConnectionDNS(root.activeTargetId, modelData.arr, modelData.manual)
                root.notifyToast(modelData.title + " DNS uygulandı.", false)
              } else {
                root.notifyToast("Önce aktif bir bağlantı bulunmalıdır.", true)
              }
            }
          }
        }
      }

      // Custom DNS Expandable Box
      SettingsCard {
        visible: root.showCustomDns
        innerPadding: 12
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { text: "Birincil DNS"; font.family: Style.fontText; font.pixelSize: 11; color: Style.textMuted }
            Rectangle {
              Layout.fillWidth: true; implicitHeight: 32; radius: 7
              color: Style.appBackground
              border.color: dns1In.activeFocus ? Style.accent : Style.appBorder; border.width: 1
              TextInput {
                id: dns1In; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter; color: Style.textPrimary
                font.family: "Monospace"; font.pixelSize: 12; text: root.customDns1; selectByMouse: true
                onTextChanged: root.customDns1 = text
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { text: "İkincil DNS"; font.family: Style.fontText; font.pixelSize: 11; color: Style.textMuted }
            Rectangle {
              Layout.fillWidth: true; implicitHeight: 32; radius: 7
              color: Style.appBackground
              border.color: dns2In.activeFocus ? Style.accent : Style.appBorder; border.width: 1
              TextInput {
                id: dns2In; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter; color: Style.textPrimary
                font.family: "Monospace"; font.pixelSize: 12; text: root.customDns2; selectByMouse: true
                onTextChanged: root.customDns2 = text
              }
            }
          }
        }

        SettingsButton {
          text: "Özel DNS'i Uygula"
          iconText: "󰄬"
          isAccent: true
          Layout.alignment: Qt.AlignRight
          onClicked: {
            if (root.ipc && root.activeTargetId) {
              let arr = []
              if (root.customDns1.trim() !== "") arr.push(root.customDns1.trim())
              if (root.customDns2.trim() !== "") arr.push(root.customDns2.trim())
              root.ipc.setConnectionDNS(root.activeTargetId, arr, true)
              root.notifyToast("Özel DNS uygulandı.", false)
            }
          }
        }
      }
    }

    // =========================================================================
    // 4. PRIVACY & MAINTENANCE (IPv6 + Profile Cleanup)
    // =========================================================================
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Gizlilik ve Bakım"
      }

      SettingsCard {
        SettingsRow {
          iconText: "󰖪"
          title: "IPv6 Trafiğini Devre Dışı Bırak"
          subtitle: "DNS sızıntısını önlemek ve Zapret uyumluluğu için IPv6'yı kapatır."
          showDivider: root.activeTab === "wifi"

          SettingsToggle {
            checked: !!(root.activeConnObj && root.activeConnObj.ipv6_disabled)
            onToggled: isChecked => {
              if (root.ipc && root.activeTargetId) {
                root.ipc.setConnectionIPv6(root.activeTargetId, isChecked)
                root.notifyToast(isChecked ? "IPv6 kapatıldı." : "IPv6 açıldı.", false)
              }
            }
          }
        }

        SettingsRow {
          visible: root.activeTab === "wifi"
          iconText: "󰃢"
          title: "Kopya Ağ Profillerini Temizle"
          subtitle: "Birikmiş eski .nmconnection kopyalarını silerek ana profili korur."
          showDivider: false

          SettingsButton {
            text: "Temizle"
            iconText: "󰩹"
            onClicked: {
              if (root.ipc) root.ipc.cleanupDuplicateProfiles("")
            }
          }
        }
      }
    }

    // =========================================================================
    // 5. NEARBY WI-FI NETWORKS (Wi-Fi Tab Only)
    // =========================================================================
    ColumnLayout {
      visible: root.activeTab === "wifi"
      Layout.fillWidth: true
      spacing: 8

      SettingsSectionHeader {
        titleText: "Çevredeki Wi-Fi Ağları"
      }

      SettingsCard {
        innerPadding: 6

        ListView {
          id: apListView
          Layout.fillWidth: true
          implicitHeight: Math.min(200, Math.max(68, count * 40))
          clip: true
          spacing: 2
          model: {
            if (!root.ipc || !root.ipc.wifi) return []
            let aps = root.ipc.wifi.access_points || root.ipc.wifi.scan_results || []
            return Array.isArray(aps) ? aps : []
          }

          delegate: Rectangle {
            required property var modelData
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
                text: (modelData.band || "Wi-Fi") + " • %" + (modelData.signal || 0)
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
                if (!isActive && root.ipc) {
                  root.ipc.sendAction("connect_wifi", { "ssid": modelData.ssid, "password": "" })
                  root.notifyToast(modelData.ssid + " ağına bağlanılıyor...", false)
                }
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: apListView.count === 0
            text: "Ağ bulunamadı veya taranıyor..."
            font.family: Style.fontText
            font.pixelSize: 12
            color: Style.textMuted
          }
        }
      }
    }
  }
}
