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
  visible: true
  color: "transparent"

  property string activeCategory: "network"

  FontLoader { source: Qt.resolvedUrl("assets/fonts/Inter.ttf") }
  FontLoader { source: Qt.resolvedUrl("assets/fonts/NotoSansDisplay.ttf") }

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
      // LEFT SIDEBAR (Width: 224px)
      // =======================================================================
      Rectangle {
        Layout.preferredWidth: 224
        Layout.fillHeight: true
        color: Style.appSidebar

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

          // Window Header with Title & Close Button
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "󰒓"
              font.pixelSize: 16
              color: Style.textSecondary
            }

            Text {
              text: "Ayarlar"
              font.family: Style.fontText
              font.pixelSize: 14
              font.weight: Font.DemiBold
              color: Style.textPrimary
              Layout.fillWidth: true
            }

            Rectangle {
              width: 24
              height: 24
              radius: 12
              color: closeHover.containsMouse ? Style.surfaceHover : "transparent"

              Behavior on color { ColorAnimation { duration: 120 } }

              Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.pixelSize: 12
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
            spacing: 3
            clip: true

            model: [
              { "id": "network",       "title": "Ağ ve Wi-Fi",        "icon": "󰛳" },
              { "id": "bluetooth",     "title": "Bluetooth",          "icon": "󰂯" },
              { "id": "appearance",    "title": "Görünüm ve Tema",    "icon": "󰏘" },
              { "id": "island",        "title": "Ada ve Çentik",      "icon": "󰘔" },
              { "id": "hyprland",      "title": "Hyprland & Efektler","icon": "󰖯" },
              { "id": "sound",         "title": "Ses ve Donanım",     "icon": "󰕾" },
              { "id": "notifications", "title": "Bildirimler",        "icon": "󰂚" },
              { "id": "keyboard",      "title": "Klavye ve Giriş",    "icon": "󰌌" },
              { "id": "about",         "title": "Sistem Hakkında",    "icon": "󰋼" }
            ]

            delegate: Rectangle {
              width: sidebarList.width
              height: 34
              radius: 7
              readonly property bool isSelected: rootWindow.activeCategory === modelData.id
              color: isSelected ? Qt.alpha(Style.accent, 0.14) : (itemMouse.containsMouse ? Style.surfaceHover : "transparent")

              Behavior on color { ColorAnimation { duration: 120 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Text {
                  text: modelData.icon
                  font.pixelSize: 14
                  color: isSelected ? Style.accent : Style.textSecondary
                  Layout.preferredWidth: 16
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  text: modelData.title
                  font.family: Style.fontText
                  font.pixelSize: 12
                  font.weight: isSelected ? Font.DemiBold : Font.Medium
                  color: isSelected ? Style.accent : Style.textPrimary
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
            implicitHeight: 46
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
                  if (rootWindow.activeCategory === "hyprland") return "Hyprland ve Efektler"
                  if (rootWindow.activeCategory === "sound") return "Ses ve Donanım"
                  if (rootWindow.activeCategory === "notifications") return "Bildirimler"
                  if (rootWindow.activeCategory === "keyboard") return "Klavye ve Giriş"
                  if (rootWindow.activeCategory === "about") return "Sistem Hakkında"
                  return "Ayarlar"
                }
                font.family: Style.fontText
                font.pixelSize: 15
                font.weight: Font.DemiBold
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

            NetworkPage {
              anchors.fill: parent
              ipc: ipcService
              visible: rootWindow.activeCategory === "network"
            }

            IslandPage {
              anchors.fill: parent
              ipc: ipcService
              visible: rootWindow.activeCategory === "island"
            }

            HyprlandPage {
              anchors.fill: parent
              ipc: ipcService
              visible: rootWindow.activeCategory === "hyprland"
            }

            SoundPage {
              anchors.fill: parent
              ipc: ipcService
              visible: rootWindow.activeCategory === "sound"
            }

            // Minimalist Empty State for Upcoming Categories
            Item {
              anchors.fill: parent
              visible: rootWindow.activeCategory !== "network" && rootWindow.activeCategory !== "island" && rootWindow.activeCategory !== "hyprland" && rootWindow.activeCategory !== "sound"

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                  Layout.alignment: Qt.AlignHCenter
                  width: 44
                  height: 44
                  radius: 10
                  color: Style.surfaceVariant
                  border.color: Style.appBorder
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    font.pixelSize: 20
                    color: Style.textMuted
                  }
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Bu bölüm henüz yapılandırılmadı"
                  font.family: Style.fontText
                  font.pixelSize: 13
                  font.weight: Font.DemiBold
                  color: Style.textPrimary
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "İlgili ayarlar sonraki güncellemelerde eklenecektir."
                  font.family: Style.fontText
                  font.pixelSize: 11
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
