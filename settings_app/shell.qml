import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "theme"
import "backend"
import "components"
import "pages"

FloatingWindow {
  id: rootWindow

  title: "ogsShell Ayarlar"
  implicitWidth: 880
  implicitHeight: 580
  width: 880
  height: 580
  visible: true
  color: "transparent"

  property string activeCategory: "network"

  // IPC Service instance to communicate with Go daemon
  DaemonIPC {
    id: ipcService
  }

  // Root Content Container
  Rectangle {
    anchors.fill: parent
    color: Style.appBackground
    border.color: Style.appBorder
    border.width: 1
    radius: 12
    clip: true

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // =======================================================================
      // LEFT SIDEBAR (Width: 230px)
      // =======================================================================
      Rectangle {
        Layout.preferredWidth: 230
        Layout.fillHeight: true
        color: Style.appSidebar

        // Right separator border
        Rectangle {
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 1
          color: Style.appBorder
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 14

          // Window Header with Title & Close (X) Button
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "⚙️"
              font.pixelSize: 17
            }

            Text {
              text: "Ayarlar"
              font.pixelSize: 15
              font.weight: Font.Bold
              color: Style.textPrimary
              Layout.fillWidth: true
            }

            // Minimalist Close (✕) Button
            Rectangle {
              width: 26
              height: 26
              radius: 13
              color: closeHover.containsMouse ? Style.surfaceActive : "transparent"
              border.color: closeHover.containsMouse ? Style.appBorder : "transparent"
              border.width: 1

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on border.color { ColorAnimation { duration: 120 } }

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: closeHover.containsMouse ? Style.accentRed : Style.textMuted
              }

              MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.quit()
              }
            }
          }

          // Sidebar Navigation Categories
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
              readonly property bool isSelected: rootWindow.activeCategory === modelData.id
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
                onClicked: rootWindow.activeCategory = modelData.id
              }
            }
          }
        }
      }

      // =======================================================================
      // RIGHT DETAIL PANE (Width: Fill)
      // =======================================================================
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

        ColumnLayout {
          anchors.fill: parent
          spacing: 0

          // Header Bar of Detail Pane
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
                  if (rootWindow.activeCategory === "network") return "Ağ ve Wi-Fi"
                  if (rootWindow.activeCategory === "bluetooth") return "Bluetooth"
                  if (rootWindow.activeCategory === "appearance") return "Görünüm ve Tema"
                  if (rootWindow.activeCategory === "island") return "Ada ve Çentik"
                  if (rootWindow.activeCategory === "sound") return "Ses ve Donanım"
                  if (rootWindow.activeCategory === "notifications") return "Bildirimler"
                  if (rootWindow.activeCategory === "keyboard") return "Klavye ve Giriş"
                  if (rootWindow.activeCategory === "about") return "Sistem Hakkında"
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
              color: Style.appBorder
            }
          }

          // Detail Content Pages
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Page 1: Network & DNS Page
            NetworkPage {
              anchors.fill: parent
              ipc: ipcService
              visible: rootWindow.activeCategory === "network"
            }

            // Page 2: Dynamic Island & Notch Configuration Page
            IslandPage {
              anchors.fill: parent
              ipc: ipcService
              visible: rootWindow.activeCategory === "island"
            }

            // Placeholder for other upcoming pages
            Item {
              anchors.fill: parent
              visible: rootWindow.activeCategory !== "network" && rootWindow.activeCategory !== "island"

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "🛠️"
                  font.pixelSize: 36
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Bu modül yakında eklenecek"
                  font.pixelSize: 14
                  font.weight: Font.Bold
                  color: Style.textPrimary
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
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
