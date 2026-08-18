import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."

Item {
  id: root

  property var ipc
  signal launchRequested()
  signal closeRequested()
  signal userActivity()

  property int selectedIndex: 0
  onSelectedIndexChanged: root.userActivity()
  focus: true

  readonly property var activeList: {
    if (searchInput.text.trim().length > 0) {
      return (ipc && ipc.launcherSearchResults) ? ipc.launcherSearchResults : []
    }
    return (ipc && ipc.launcherApps) ? ipc.launcherApps : []
  }

  onActiveListChanged: {
    if (selectedIndex >= activeList.length) {
      selectedIndex = Math.max(0, activeList.length - 1)
    }
    if (activeList.length > 0 && selectedIndex < 0) {
      selectedIndex = 0
    }
  }

  Timer {
    id: focusTimer
    interval: 30
    repeat: false
    onTriggered: searchInput.forceActiveFocus()
  }

  Component.onCompleted: {
    if (ipc) {
      ipc.requestAppsList(50)
    }
    searchInput.forceActiveFocus()
    focusTimer.restart()
  }

  onVisibleChanged: {
    if (visible) {
      searchInput.forceActiveFocus()
      focusTimer.restart()
      if (ipc) {
        ipc.requestAppsList(50)
      }
    }
  }

  function launchSelected() {
    if (activeList && activeList.length > 0 && selectedIndex >= 0 && selectedIndex < activeList.length) {
      let app = activeList[selectedIndex]
      if (ipc) {
        ipc.launchApp(app.id || "", app.exec || "")
      }
      root.launchRequested()
    } else if (searchInput.text.trim().length > 0) {
      if (ipc) {
        ipc.launchApp("", searchInput.text.trim())
      }
      root.launchRequested()
    }
  }

  // =========================================================================
  // 1. Top Search Bar Header (Anchored to Top)
  // =========================================================================
  Item {
    id: searchHeader
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 44

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      spacing: 12

      // Search Glyph
      Text {
        text: ""
        font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font, sans-serif"
        font.pixelSize: 15
        color: searchInput.text.length > 0 ? Style.accent : Style.textMuted
        Layout.alignment: Qt.AlignVCenter
      }

      // Main Text Input
      TextInput {
        id: searchInput
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: TextInput.AlignVCenter
        color: Style.textPrimary
        font.pixelSize: 14
        font.weight: Font.Medium
        font.family: "Inter, -apple-system, Roboto, sans-serif"
        clip: true
        selectByMouse: true
        selectionColor: Style.surfaceActive
        selectedTextColor: Style.textPrimary

        onTextChanged: {
          root.userActivity()
          selectedIndex = 0
          if (ipc) {
            ipc.searchApps(text.trim(), 30)
          }
        }

        Keys.onPressed: root.userActivity()

        Keys.onDownPressed: {
          root.userActivity()
          if (activeList.length > 0) {
            selectedIndex = (selectedIndex + 1) % activeList.length
            appList.positionViewAtIndex(selectedIndex, ListView.Contain)
          }
        }

        Keys.onUpPressed: {
          root.userActivity()
          if (activeList.length > 0) {
            selectedIndex = (selectedIndex - 1 + activeList.length) % activeList.length
            appList.positionViewAtIndex(selectedIndex, ListView.Contain)
          }
        }

        Keys.onReturnPressed: root.launchSelected()
        Keys.onEnterPressed: root.launchSelected()

        Keys.onEscapePressed: {
          root.userActivity()
          if (text.length > 0) {
            text = ""
          } else {
            root.closeRequested()
          }
        }

        // Placeholder Text
        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          text: "Uygulama ara..."
          color: Style.textMuted
          font.pixelSize: 14
          font.weight: Font.Normal
          font.family: parent.font.family
          visible: !parent.text && !parent.inputMethodComposing
        }
      }

      // Minimal Clear Button
      Rectangle {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        radius: 10
        color: clearHover.containsMouse ? Style.surfaceHover : "transparent"
        visible: searchInput.text.length > 0
        Layout.alignment: Qt.AlignVCenter

        Text {
          anchors.centerIn: parent
          text: "✕"
          font.pixelSize: 11
          color: Style.textMuted
        }

        MouseArea {
          id: clearHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            searchInput.text = ""
            searchInput.forceActiveFocus()
          }
        }
      }
    }
  }

  // Top Hairline Divider
  Rectangle {
    id: topDivider
    anchors.top: searchHeader.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    color: Style.border
    opacity: 0.5
  }

  // Bottom Hairline Divider
  Rectangle {
    id: bottomDivider
    anchors.bottom: footerRow.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    color: Style.border
    opacity: 0.5
  }

  // =========================================================================
  // 3. Quiet Minimalist Footer (Anchored to Bottom)
  // =========================================================================
  Item {
    id: footerRow
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 28

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 12

      Text {
        text: searchInput.text.trim().length > 0 ? (activeList.length + " sonuç") : (activeList.length + " uygulama")
        font.pixelSize: 11
        color: Style.textMuted
      }

      Item { Layout.fillWidth: true }

      Text {
        text: "↵ Aç  •  esc Kapat"
        font.pixelSize: 11
        color: Style.textMuted
      }
    }
  }

  // =========================================================================
  // 2. Application List View (Anchored between Header and Footer Dividers)
  // =========================================================================
  ListView {
    id: appList
    anchors.top: topDivider.bottom
    anchors.bottom: bottomDivider.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    anchors.leftMargin: 4
    anchors.rightMargin: 4
    spacing: 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    visible: root.activeList.length > 0
    model: root.activeList

    delegate: Rectangle {
      id: itemDelegate
      width: appList.width
      height: 48
      radius: 10

      readonly property bool isSelected: root.selectedIndex === index
      readonly property bool isHovered: itemMouseArea.containsMouse
      readonly property var currentApp: modelData || ({})

      color: isSelected ? Style.surfaceActive : (isHovered ? Style.surfaceHover : "transparent")

      Behavior on color { ColorAnimation { duration: 100 } }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 12

        // 1. Crisp 32x32 Desktop Icon
        Item {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          Layout.alignment: Qt.AlignVCenter

          Image {
            id: appIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            source: {
              let ic = currentApp.icon || ""
              if (!ic) return ""
              if (ic.startsWith("/") || ic.startsWith("file://")) {
                return ic.startsWith("file://") ? ic : ("file://" + ic)
              }
              return Quickshell.iconPath(ic)
            }
          }

          readonly property bool hasValidAppIcon: (appIcon.status === Image.Ready && appIcon.paintedWidth > 0 && appIcon.paintedHeight > 0)

          // Default SVG Fallback Asset
          Image {
            id: defaultFallbackIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: !parent.hasValidAppIcon
            source: {
              if (currentApp.terminal || (currentApp.categories && currentApp.categories.indexOf("TerminalEmulator") !== -1)) {
                return Qt.resolvedUrl("../../../assets/icons/default_terminal.svg")
              }
              return Qt.resolvedUrl("../../../assets/icons/default_app.svg")
            }
          }

          // Fail-safe Letter Badge
          Text {
            anchors.centerIn: parent
            visible: !parent.hasValidAppIcon && (defaultFallbackIcon.status !== Image.Ready || defaultFallbackIcon.paintedWidth === 0)
            text: (currentApp.name && currentApp.name.length > 0) ? currentApp.name.charAt(0).toUpperCase() : "󰵆"
            font.pixelSize: 15
            font.weight: Font.Bold
            color: Style.accent
          }
        }

        // 2. Title & Subtitle Info Column
        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          spacing: 2

          Text {
            text: currentApp.name || "Uygulama"
            font.pixelSize: 13
            font.weight: itemDelegate.isSelected ? Font.DemiBold : Font.Normal
            color: Style.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Text {
            text: {
              if (currentApp.generic_name && currentApp.generic_name.length > 0) {
                return currentApp.generic_name
              }
              if (currentApp.comment && currentApp.comment.length > 0) {
                return currentApp.comment
              }
              if (currentApp.categories && currentApp.categories.length > 0) {
                return currentApp.categories.join(" • ")
              }
              return currentApp.exec_binary || ""
            }
            font.pixelSize: 11
            color: Style.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text.length > 0
          }
        }

        // 3. Launch Count Indicator (if > 0)
        Rectangle {
          Layout.preferredHeight: 18
          Layout.preferredWidth: countText.implicitWidth + 10
          radius: 9
          color: Style.surfaceHover
          visible: currentApp.launch_count && currentApp.launch_count > 0
          Layout.alignment: Qt.AlignVCenter

          Text {
            id: countText
            anchors.centerIn: parent
            text: (currentApp.launch_count || 0) + "x"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Style.accent
          }
        }

        // 4. Subtle Selection Action Indicator
        Text {
          text: "↵"
          font.pixelSize: 13
          color: Style.textSecondary
          visible: itemDelegate.isSelected
          Layout.alignment: Qt.AlignVCenter
        }
      }

      MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.selectedIndex = index
        onClicked: {
          root.selectedIndex = index
          root.launchSelected()
        }
      }
    }
  }

  // Minimal Empty State
  Item {
    anchors.top: topDivider.bottom
    anchors.bottom: bottomDivider.top
    anchors.left: parent.left
    anchors.right: parent.right
    visible: root.activeList.length === 0

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: searchInput.text.length > 0 ? ("'" + searchInput.text + "' komutunu çalıştırmak için ↵ basın") : "Uygulama bulunamadı"
        font.pixelSize: 12
        color: Style.textMuted
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
