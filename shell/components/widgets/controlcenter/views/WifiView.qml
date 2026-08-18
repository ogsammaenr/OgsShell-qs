import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property bool showPasswordModal: false
  property string selectedSsid: ""
  property string wifiPasswordInput: ""

  function rescanWifi() {
    if (ipc) {
      ipc.sendAction("scan_wifi", {})
      ipc.sendAction("get_active_wifi", {})
    }
  }

  Component.onCompleted: {
    rescanWifi()
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // Header Row
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back Button
      Rectangle {
        width: 24
        height: 24
        radius: 12
        color: backHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "‹"
          font.pixelSize: 16
          font.weight: Font.Bold
          color: Style.textPrimary
        }

        MouseArea {
          id: backHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.backRequested()
        }
      }

      Text {
        text: "Wi-Fi Ağları"
        color: Style.textPrimary
        font.pixelSize: 13
        font.weight: Font.Bold
        Layout.fillWidth: true
      }

      // Rescan Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: scanHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: "↻"
          font.pixelSize: 14
          color: Style.textPrimary
        }

        MouseArea {
          id: scanHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.rescanWifi()
        }
      }
    }

    // Active Connection Banner
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 44
      radius: 8
      color: Style.surfaceVariant
      border.color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : Style.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Text {
          text: (ipc && ipc.wifi && ipc.wifi.connected) ? "󰤨" : "󰤮"
          font.pixelSize: 18
          color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : Style.textMuted
        }

        Column {
          Layout.fillWidth: true
          spacing: 1
          Text {
            text: (ipc && ipc.wifi && ipc.wifi.ssid && ipc.wifi.ssid !== "Kapalı") ? ipc.wifi.ssid : ((ipc && ipc.wifi && ipc.wifi.connected) ? "Bağlı Ağ" : "Bağlantı Yok")
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Style.textPrimary
            elide: Text.ElideRight
          }
          Text {
            text: (ipc && ipc.wifi && ipc.wifi.connected) ? `Sinyal Gücü: %${ipc.wifi.signal || 75}` : "Kullanılabilir bir ağ seçip bağlanın"
            font.pixelSize: 10
            color: (ipc && ipc.wifi && ipc.wifi.connected) ? Style.accentCyan : Style.textMuted
          }
        }

        // Disconnect Button
        Rectangle {
          visible: !!(ipc && ipc.wifi && ipc.wifi.connected)
          Layout.preferredHeight: 26
          Layout.preferredWidth: 80
          radius: 6
          color: disHover.containsMouse ? Style.surfaceActive : Style.surface
          border.color: Style.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Bağlantıyı Kes"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Style.accentRed
          }

          MouseArea {
            id: disHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (ipc) ipc.sendAction("disconnect_wifi", {})
            }
          }
        }
      }
    }

    // Scanned Access Points List
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      radius: 10
      color: Style.surface
      border.color: Style.border
      border.width: 1
      clip: true

      ListView {
        id: wifiList
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4
        reuseItems: true
        cacheBuffer: 60
        model: {
          if (!ipc || !ipc.wifi) return []
          let res = ipc.wifi.access_points || ipc.wifi.scan_results || []
          return Array.isArray(res) ? res : []
        }

        delegate: Rectangle {
          width: wifiList.width
          height: 44
          radius: 8
          readonly property bool isActive: !!(modelData.is_active || modelData.is_connected)
          color: isActive ? Style.surfaceActive : (itemHover.containsMouse ? Style.surfaceVariant : "transparent")
          border.color: isActive ? Style.accentCyan : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            // Signal Icon
            Text {
              text: (modelData.signal >= 70) ? "󰤨" : ((modelData.signal >= 45) ? "󰤥" : ((modelData.signal >= 20) ? "󰤢" : "󰤟"))
              font.pixelSize: 16
              color: isActive ? Style.accentCyan : Style.textPrimary
            }

            // Network Name & Info
            Column {
              Layout.fillWidth: true
              spacing: 1
              Text {
                text: modelData.ssid || "Gizli Ağ (Hidden)"
                font.pixelSize: 12
                font.weight: isActive ? Font.Bold : Font.Medium
                color: isActive ? Style.accentCyan : Style.textPrimary
                elide: Text.ElideRight
                width: wifiList.width - 120
              }
              Text {
                text: `${modelData.band || "2.4/5GHz"} • Sinyal: %${modelData.signal || 0}`
                font.pixelSize: 10
                color: Style.textMuted
              }
            }

            // Security Badge / Icon
            Rectangle {
              visible: !!(modelData.security && modelData.security !== "OPEN")
              Layout.preferredHeight: 20
              Layout.preferredWidth: 46
              radius: 4
              color: Style.surfaceVariant

              Text {
                anchors.centerIn: parent
                text: modelData.security || "WPA2"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Style.textMuted
              }
            }

            // Active Checkmark
            Text {
              visible: isActive
              text: "✓"
              font.pixelSize: 13
              color: Style.accentCyan
              font.weight: Font.Bold
            }
          }

          MouseArea {
            id: itemHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (isActive) return
              root.selectedSsid = modelData.ssid || ""
              if (modelData.security === "OPEN" || modelData.is_saved) {
                if (ipc) ipc.sendAction("connect_wifi", { "ssid": modelData.ssid, "password": "" })
              } else {
                root.wifiPasswordInput = ""
                root.showPasswordModal = true
              }
            }
          }
        }

        // Empty state placeholder
        Item {
          anchors.centerIn: parent
          visible: wifiList.count === 0
          Column {
            anchors.centerIn: parent
            spacing: 4
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Ağlar Taranıyor..."
              color: Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.Bold
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Çevredeki Wi-Fi ağları aranıyor, lütfen bekleyin."
              color: Style.textMuted
              font.pixelSize: 10
            }
          }
        }
      }
    }

    // Inline Password Input Sheet
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 42
      radius: 8
      color: Style.surfaceActive
      border.color: Style.accentCyan
      border.width: 1
      visible: root.showPasswordModal

      RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        TextInput {
          id: passInput
          Layout.fillWidth: true
          verticalAlignment: TextInput.AlignVCenter
          color: Style.textPrimary
          font.pixelSize: 12
          echoMode: TextInput.Password
          text: root.wifiPasswordInput
          onTextChanged: root.wifiPasswordInput = text
          focus: root.showPasswordModal

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: `${root.selectedSsid} ağ parolası...`
            color: Style.textMuted
            font.pixelSize: 12
            visible: !passInput.text && !passInput.activeFocus
          }
        }

        // Connect Button
        Rectangle {
          Layout.preferredWidth: 68
          Layout.preferredHeight: 28
          radius: 6
          color: Style.accent

          Text {
            anchors.centerIn: parent
            text: "Bağlan"
            font.pixelSize: 11
            font.weight: Font.Bold
            color: "#ffffff"
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (ipc && root.selectedSsid) {
                ipc.sendAction("connect_wifi", { "ssid": root.selectedSsid, "password": root.wifiPasswordInput })
              }
              root.showPasswordModal = false
            }
          }
        }

        // Cancel Button
        Rectangle {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
          radius: 6
          color: Style.surfaceVariant

          Text {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: 11
            color: Style.textMuted
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showPasswordModal = false
          }
        }
      }
    }
  }
}
