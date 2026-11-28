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
  implicitWidth: 980
  implicitHeight: 680
  visible: true
  color: "transparent"

  property string activeCategory: "appearance"
  property string searchQuery: ""
  property string toastMessage: ""
  property bool toastIsError: false

  function showToast(msg, isErr) {
    toastMessage = msg || ""
    toastIsError = !!isErr
    toastTimer.restart()
  }

  Timer {
    id: toastTimer
    interval: 2600
    repeat: false
    onTriggered: rootWindow.toastMessage = ""
  }

  FontLoader { source: Qt.resolvedUrl("assets/fonts/Inter.ttf") }
  FontLoader { source: Qt.resolvedUrl("assets/fonts/NotoSansDisplay.ttf") }
  FontLoader { source: Qt.resolvedUrl("assets/fonts/Outfit.ttf") }
  FontLoader { source: Qt.resolvedUrl("assets/fonts/PlusJakartaSans.ttf") }

  // IPC Service instance to communicate with Go daemon
  DaemonIPC {
    id: ipcService
  }

  readonly property var allCategories: [
    {
      "id": "appearance",
      "group": "Kabuk ve Görünüm",
      "title": "Görünüm ve Tema",
      "subtitle": "Renk paletleri, duvar kağıdı, tipografi ve ekran köşeleri",
      "icon": "󰏘",
      "keywords": "tema renk palet duvar kagidi wallpaper font yazi tipi kose golge monochrome catppuccin everforest nord gruvbox tokyo rose"
    },
    {
      "id": "island",
      "group": "Kabuk ve Görünüm",
      "title": "Ada ve Çentik",
      "subtitle": "Dynamic Notch / Island sunum modu, odak modu ve boyutlar",
      "icon": "󰘔",
      "keywords": "ada centik notch island focus odak metrik cpu ram gpu boyut yaricap animasyon"
    },
    {
      "id": "lockscreen",
      "group": "Kabuk ve Görünüm",
      "title": "Kilit Ekranı",
      "subtitle": "Saat fontu, bulanıklık, karartma ve kilit ekranı bileşenleri",
      "icon": "󰌾",
      "keywords": "kilit lock lockscreen saat tarih blur bulanik sf pro rounded pam medya guc"
    },
    {
      "id": "hyprland",
      "group": "Kabuk ve Görünüm",
      "title": "Hyprland",
      "subtitle": "Pencere profilleri, kenarlık geometrisi ve Bézier animasyonları",
      "icon": "󰖯",
      "keywords": "hyprland pencere kenarlik border gaps bosluk golge opaklik animasyon bezier profil"
    },
    {
      "id": "network",
      "group": "Bağlantı ve Donanım",
      "title": "Ağ ve DNS",
      "subtitle": "Wi-Fi, kablolu Ethernet, güvenli DNS ve IPv6 koruması",
      "icon": "󰛳",
      "keywords": "ag wifi ethernet kablolu internet dns cloudflare quad9 adguard google ipv6 zapret"
    },
    {
      "id": "bluetooth",
      "group": "Bağlantı ve Donanım",
      "title": "Bluetooth",
      "subtitle": "Kablosuz aygıt tarama, eşleştirme ve bağlantı yönetimi",
      "icon": "󰂯",
      "keywords": "bluetooth kulaklik klavye fare cihaz tarama baglan"
    },
    {
      "id": "sound",
      "group": "Bağlantı ve Donanım",
      "title": "Ses",
      "subtitle": "Çıkış düzeyi, %150 ses yükseltme ve geri bildirim efektleri",
      "icon": "󰕾",
      "keywords": "ses hoparlor kulaklik pipewire 150 over amplification yukseltme pop osd hud"
    },
    {
      "id": "notifications",
      "group": "Sistem",
      "title": "Bildirimler",
      "subtitle": "Rahatsız Etme (DND), pop-up süresi ve uygulama filtreleri",
      "icon": "󰂚",
      "keywords": "bildirim dnd rahatsiz etme sure gecmis temizle kural mute"
    },
    {
      "id": "system",
      "group": "Sistem",
      "title": "Klavye ve Sistem",
      "subtitle": "Klavye dili, döviz çevirici ayarları ve kabuk bilgileri",
      "icon": "󰌌",
      "keywords": "klavye dil layout tr us doviz kur currency hakkinda surum yeniden yukle reload"
    }
  ]

  readonly property var filteredCategories: {
    let q = (searchQuery || "").trim().toLowerCase()
    if (q.length === 0) return allCategories
    let out = []
    for (let i = 0; i < allCategories.length; i++) {
      let c = allCategories[i]
      let hay = (c.title + " " + c.subtitle + " " + c.group + " " + c.keywords).toLowerCase()
      if (hay.indexOf(q) !== -1) out.push(c)
    }
    return out
  }

  readonly property var activeCategoryObj: {
    for (let i = 0; i < allCategories.length; i++) {
      if (allCategories[i].id === activeCategory) return allCategories[i]
    }
    return allCategories[0]
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
      // LEFT SIDEBAR (Width: 244px — Grouped Navigation + Instant Search)
      // =======================================================================
      Rectangle {
        Layout.preferredWidth: 244
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
          spacing: 12

          // App Title & Close Button
          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 8
              color: Qt.alpha(Style.accent, 0.14)
              border.color: Qt.alpha(Style.accent, 0.28)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "󰒓"
                font.pixelSize: 15
                color: Style.accent
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Text {
                text: "ogsShell"
                font.family: Style.fontDisplay
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Style.textPrimary
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              Text {
                text: "Sistem Ayarları"
                font.family: Style.fontText
                font.pixelSize: 10
                color: Style.textMuted
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }

            Rectangle {
              Layout.preferredWidth: 26
              Layout.preferredHeight: 26
              Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
              radius: 13
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

          // Instant Search Box
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 8
            color: Style.appBackground
            border.color: searchInput.activeFocus ? Style.accent : Style.appBorder
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 7

              Text {
                text: "󰍉"
                font.pixelSize: 13
                color: searchInput.activeFocus ? Style.accent : Style.textMuted
              }

              TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: Style.textPrimary
                font.family: Style.fontText
                font.pixelSize: 12
                clip: true
                selectByMouse: true
                text: rootWindow.searchQuery
                onTextChanged: rootWindow.searchQuery = text

                Keys.onEscapePressed: {
                  rootWindow.searchQuery = ""
                  focus = false
                }

                Text {
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  text: "Ayar ara..."
                  font.family: Style.fontText
                  font.pixelSize: 12
                  color: Style.textMuted
                  visible: searchInput.text.length === 0
                }
              }

              Text {
                visible: rootWindow.searchQuery.length > 0
                text: "󰅖"
                font.pixelSize: 11
                color: Style.textMuted

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: rootWindow.searchQuery = ""
                }
              }
            }
          }

          // Grouped Sidebar Navigation
          Flickable {
            id: sidebarFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: navCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
              id: navCol
              width: sidebarFlick.width
              spacing: 3

              Repeater {
                model: rootWindow.filteredCategories

                delegate: ColumnLayout {
                  required property var modelData
                  required property int index
                  readonly property bool showGroupHeader: index === 0 || rootWindow.filteredCategories[index - 1].group !== modelData.group
                  readonly property bool isSelected: rootWindow.activeCategory === modelData.id

                  Layout.fillWidth: true
                  spacing: 3

                  Text {
                    visible: showGroupHeader
                    text: modelData.group.toUpperCase()
                    font.family: Style.fontText
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                    color: Style.textMuted
                    topPadding: index === 0 ? 2 : 12
                    bottomPadding: 3
                    leftPadding: 8
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: isSelected
                      ? Qt.alpha(Style.accent, 0.14)
                      : (itemMouse.containsMouse ? Style.surfaceHover : "transparent")
                    border.color: isSelected ? Qt.alpha(Style.accent, 0.25) : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    // Subtle Active Left Indicator Bar
                    Rectangle {
                      visible: isSelected
                      width: 3
                      height: 16
                      radius: 2
                      anchors.left: parent.left
                      anchors.leftMargin: 3
                      anchors.verticalCenter: parent.verticalCenter
                      color: Style.accent
                    }

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 12
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
                        color: isSelected ? Style.textPrimary : Style.textSecondary
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

              // Empty Search State
              Text {
                visible: rootWindow.filteredCategories.length === 0
                text: "Eşleşen ayar bulunamadı"
                font.family: Style.fontText
                font.pixelSize: 12
                color: Style.textMuted
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                topPadding: 24
              }
            }
          }

          // Sidebar Bottom Status Summary Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: 9
            color: Style.appCard
            border.color: Style.appBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 8

              Rectangle {
                width: 10
                height: 10
                radius: 5
                color: Style.accent
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                  text: Style.activeThemeName || Config.theme
                  font.family: Style.fontText
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                  color: Style.textPrimary
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: Config.isNotch ? "Dynamic Notch" : "Dynamic Island"
                  font.family: Style.fontText
                  font.pixelSize: 10
                  color: Style.textMuted
                }
              }
            }
          }
        }
      }

      // =======================================================================
      // RIGHT DETAIL PANE (Header + Lazy Page Container + Floating Toast)
      // =======================================================================
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          anchors.fill: parent
          spacing: 0

          // Page Title & Plain-Language Description Header
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 62
            color: "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 24
              anchors.rightMargin: 24
              spacing: 12

              Rectangle {
                width: 34
                height: 34
                radius: 9
                color: Qt.alpha(Style.accent, 0.12)
                border.color: Qt.alpha(Style.accent, 0.24)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: rootWindow.activeCategoryObj.icon
                  font.pixelSize: 16
                  color: Style.accent
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: rootWindow.activeCategoryObj.title
                  font.family: Style.fontDisplay
                  font.pixelSize: 16
                  font.weight: Font.DemiBold
                  color: Style.textPrimary
                }

                Text {
                  text: rootWindow.activeCategoryObj.subtitle
                  font.family: Style.fontText
                  font.pixelSize: 11
                  color: Style.textMuted
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
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

          // Active Page Content (Lazy loaded per category)
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
              id: pageLoader
              anchors.fill: parent

              readonly property string targetPageUrl: {
                if (rootWindow.activeCategory === "appearance") return "pages/AppearancePage.qml"
                if (rootWindow.activeCategory === "island") return "pages/IslandPage.qml"
                if (rootWindow.activeCategory === "lockscreen") return "pages/LockScreenPage.qml"
                if (rootWindow.activeCategory === "hyprland") return "pages/HyprlandPage.qml"
                if (rootWindow.activeCategory === "network") return "pages/NetworkPage.qml"
                if (rootWindow.activeCategory === "bluetooth") return "pages/BluetoothPage.qml"
                if (rootWindow.activeCategory === "sound") return "pages/SoundPage.qml"
                if (rootWindow.activeCategory === "notifications") return "pages/NotificationsPage.qml"
                if (rootWindow.activeCategory === "system") return "pages/SystemPage.qml"
                return "pages/AppearancePage.qml"
              }

              function loadActivePage() {
                setSource(targetPageUrl, { "ipc": ipcService })
              }

              onTargetPageUrlChanged: loadActivePage()
              Component.onCompleted: loadActivePage()

              onLoaded: {
                if (item) {
                  if (item.hasOwnProperty("ipc") && item.ipc !== ipcService) {
                    item.ipc = ipcService
                  }
                  if (item.hasOwnProperty("notifyToast")) {
                    item.notifyToast.connect(function(msg, isErr) {
                      rootWindow.showToast(msg, isErr)
                    })
                  }
                }
              }
            }
          }
        }

        // Floating Non-Intrusive Toast Feedback Pill
        Rectangle {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: 20
          anchors.bottomMargin: 18
          implicitWidth: toastRow.implicitWidth + 24
          implicitHeight: 34
          radius: 17
          color: Style.appCard
          border.color: rootWindow.toastIsError ? Qt.alpha(Style.accentRed, 0.5) : Qt.alpha(Style.accentGreen, 0.45)
          border.width: 1
          opacity: rootWindow.toastMessage.length > 0 ? 1.0 : 0.0
          visible: opacity > 0.01
          z: 50

          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: 8

            Text {
              text: rootWindow.toastIsError ? "󰀪" : "󰄬"
              font.pixelSize: 13
              color: rootWindow.toastIsError ? Style.accentRed : Style.accentGreen
            }

            Text {
              text: rootWindow.toastMessage
              font.family: Style.fontText
              font.pixelSize: 12
              font.weight: Font.Medium
              color: Style.textPrimary
            }
          }
        }
      }
    }
  }
}
