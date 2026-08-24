import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../backend"
import "pages"

Item {
  id: root

  property var ipc

  anchors.fill: parent
  focus: SettingsService.isOpen

  Keys.onEscapePressed: SettingsService.close()

  // Fullscreen Dimmed Backdrop
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: "#77000000"
    opacity: SettingsService.isOpen ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: SettingsService.close()
    }
  }

  // Central Modal Dialog Container
  Rectangle {
    id: modalContainer
    anchors.centerIn: parent
    width: 840
    height: 560
    radius: 16
    color: Style.surface
    border.color: Style.border
    border.width: 1
    clip: true

    scale: SettingsService.isOpen ? 1.0 : 0.95
    opacity: SettingsService.isOpen ? 1.0 : 0.0

    Behavior on scale {
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
      NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    // Block clicks inside the dialog from closing it
    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // =======================================================================
      // LEFT SIDEBAR (Width: 230px)
      // =======================================================================
      Rectangle {
        Layout.preferredWidth: 230
        Layout.fillHeight: true
        color: Style.surfaceVariant
        border.color: Style.border
        border.width: 0

        Rectangle {
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 1
          color: Style.border
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 12

          // Window Title Header
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "⚙️"
              font.pixelSize: 18
            }

            Text {
              text: "Ayarlar"
              font.pixelSize: 15
              font.weight: Font.Bold
              color: Style.textPrimary
              Layout.fillWidth: true
            }

            // Close button (✕)
            Rectangle {
              width: 24
              height: 24
              radius: 12
              color: closeHover.containsMouse ? Style.surfaceActive : "transparent"

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 11
                color: Style.textMuted
              }

              MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SettingsService.close()
              }
            }
          }

          // Sidebar Navigation List
          ListView {
            id: sidebarList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            clip: true

            model: [
              { "id": "network",       "title": "Ağ ve Wi-Fi",        "icon": "🌐" },
              { "id": "bluetooth",     "title": "Bluetooth",          "icon": "󰂯" },
              { "id": "appearance",    "title": "Görünüm ve Tema",    "icon": "🎨" },
              { "id": "island",        "title": "Ada ve Çentik",      "icon": "🏝️" },
              { "id": "sound",         "title": "Ses ve Donanım",     "icon": "🔊" },
              { "id": "notifications", "title": "Bildirimler",        "icon": "🔔" },
              { "id": "keyboard",      "title": "Klavye ve Giriş",    "icon": "⌨️" },
              { "id": "about",         "title": "Sistem Hakkında",    "icon": "ℹ️" }
            ]

            delegate: Rectangle {
              width: sidebarList.width
              height: 38
              radius: 8
              readonly property bool isSelected: SettingsService.activeCategory === modelData.id
              color: isSelected ? Style.surfaceActive : (itemMouse.containsMouse ? Style.surfaceHover : "transparent")

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text {
                  text: modelData.icon
                  font.pixelSize: 14
                  color: isSelected ? Style.accentCyan : Style.textPrimary
                }

                Text {
                  text: modelData.title
                  font.pixelSize: 12
                  font.weight: isSelected ? Font.Bold : Font.Medium
                  color: isSelected ? Style.accentCyan : Style.textPrimary
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SettingsService.activeCategory = modelData.id
              }
            }
          }
        }
      }

      // =======================================================================
      // RIGHT DETAIL PANE (Width: 610px)
      // =======================================================================
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

        ColumnLayout {
          anchors.fill: parent
          spacing: 0

          // Top Header Bar of Right Pane
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            color: "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 20
              anchors.rightMargin: 20
              spacing: 10

              Text {
                text: {
                  if (SettingsService.activeCategory === "network") return "Ağ ve Wi-Fi"
                  if (SettingsService.activeCategory === "bluetooth") return "Bluetooth"
                  if (SettingsService.activeCategory === "appearance") return "Görünüm ve Tema"
                  if (SettingsService.activeCategory === "island") return "Ada ve Çentik"
                  if (SettingsService.activeCategory === "sound") return "Ses ve Donanım"
                  if (SettingsService.activeCategory === "notifications") return "Bildirimler"
                  if (SettingsService.activeCategory === "keyboard") return "Klavye ve Giriş"
                  if (SettingsService.activeCategory === "about") return "Sistem Hakkında"
                  return "Ayarlar"
                }
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Style.textPrimary
              }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.left: parent.left
              anchors.right: parent.right
              height: 1
              color: Style.border
            }
          }

          // Content Pages Loader / Container
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Page 1: Network & DNS Page
            NetworkPage {
              anchors.fill: parent
              ipc: root.ipc
              visible: SettingsService.activeCategory === "network"
            }

            // Placeholder for other pages
            Item {
              anchors.fill: parent
              visible: SettingsService.activeCategory !== "network"

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "🛠️"
                  font.pixelSize: 36
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Bu modül yakında eklenecek"
                  font.pixelSize: 14
                  font.weight: Font.Bold
                  color: Style.textPrimary
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Bu kategori için görsel ayarlar çok yakında kullanıma sunulacaktır."
                  font.pixelSize: 12
                  color: Style.textMuted
                }
              }
            }
          }
        }
      }
    }
  }
}
