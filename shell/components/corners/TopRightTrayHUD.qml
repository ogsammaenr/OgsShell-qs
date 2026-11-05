import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../.."
import "../../theme"

Item {
  id: root

  property var parentWindow: null
  property int radius: Config.screenCornersRadius || 14
  property color cornerColor: Config.screenCornersColor || "#000000"
  property bool isExpanded: false
  property var activeContextMenuApp: null
  readonly property bool isMenuOpen: activeContextMenuApp !== null

  // Reactive access to SystemTray items
  readonly property var trayItems: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values : []
  readonly property int trayCount: Math.max(trayRepeater.count, trayItems.length)

  // Auto-calculated expanded width matching CornerIslandHUD proportions
  readonly property real targetWidth: isExpanded ? Math.max(trayCount === 0 ? 135 : (isMenuOpen ? 145 : 95), Math.min((trayCount * 30) + 36, 360)) : root.radius
  readonly property real targetHeight: isExpanded ? (Config.cornerTrayHeight || Config.cornerHudHeight || 34) : root.radius

  property real animWidth: root.radius
  property real animHeight: root.radius

  // Outward concave ear curve dimensions (Mirrored for Top-Right Corner)
  readonly property real earW: 16
  readonly property real earH: 16
  readonly property real br: 14
  readonly property real rightEarW: 12
  readonly property real rightEarH: 12

  onTargetWidthChanged: animWidth = targetWidth
  onTargetHeightChanged: animHeight = targetHeight

  Behavior on animWidth {
    NumberAnimation {
      duration: root.isExpanded ? 360 : 280
      easing.type: root.isExpanded ? Easing.OutCubic : Easing.InOutQuad
    }
  }

  Behavior on animHeight {
    NumberAnimation {
      duration: root.isExpanded ? 320 : 260
      easing.type: root.isExpanded ? Easing.OutCubic : Easing.InOutQuad
    }
  }

  width: animWidth + earW
  height: animHeight + rightEarH

  function closeMenu() {
    activeContextMenuApp = null
  }

  function toggle() {
    if (isExpanded) {
      collapse()
    } else {
      expand()
    }
  }

  function expand() {
    isExpanded = true
  }

  function collapse() {
    closeMenu()
    isExpanded = false
  }

  Process {
    id: appCloseProc
  }

  function closeApp(target) {
    if (!target) return
    let id = target.id || ""
    let title = target.title || ""
    let tooltip = target.tooltip || ""
    console.log("[TopRightTrayHUD] Requesting close for tray application:", id, title, tooltip)

    let home = Quickshell.env("HOME") || "/home/excalibur"
    let scriptPath = home + "/Workspace/projects/OgsShell-qs/scripts/close_tray_app.sh"
    let userScriptPath = home + "/.config/ogsShell/scripts/close_tray_app.sh"

    let cmd = "if [ -x '" + scriptPath + "' ]; then '" + scriptPath + "' '" + id + "' '" + title + "' '" + tooltip + "'; elif [ -x '" + userScriptPath + "' ]; then '" + userScriptPath + "' '" + id + "' '" + title + "' '" + tooltip + "'; fi"

    appCloseProc.command = ["bash", "-c", cmd]
    appCloseProc.running = true
  }

  // =========================================================================
  // 1. IDLE State: Top-Right Inverted Corner Cutout (Matches display bezel)
  // =========================================================================
  Shape {
    id: idleCutout
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.radius
    height: root.radius
    opacity: root.isExpanded ? 0.0 : 1.0
    visible: opacity > 0.01

    Behavior on opacity {
      NumberAnimation { duration: root.isExpanded ? 200 : 240; easing.type: Easing.OutQuad }
    }

    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    ShapePath {
      fillColor: root.cornerColor
      strokeColor: "transparent"
      strokeWidth: 0
      startX: root.radius
      startY: 0

      PathLine { x: 0; y: 0 }
      PathArc {
        x: root.radius
        y: root.radius
        radiusX: root.radius
        radiusY: root.radius
        direction: PathArc.Clockwise
      }
      PathLine { x: root.radius; y: 0 }
    }
  }

  // Top-Right Corner Hotspot MouseArea (Triggers expansion when clicked)
  MouseArea {
    id: cornerHotspot
    anchors.top: parent.top
    anchors.right: parent.right
    width: Math.max(root.radius + 12, 28)
    height: Math.max(root.radius + 12, 28)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    visible: !root.isExpanded

    onClicked: {
      root.toggle()
    }
  }

  // =========================================================================
  // 2. EXPANDED State: Seamless OLED Black Pill with Concave Outward Ears
  // Exact 1:1 Mirrored Geometry of CornerIslandHUD
  // =========================================================================
  RectangularGlow {
    id: cornerTrayShadowGlow
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.animWidth
    height: root.animHeight
    anchors.topMargin: (Config.shadowsEnabled && Config.shadowCornerHud) ? Config.shadowVerticalOffset : 0
    anchors.rightMargin: (Config.shadowsEnabled && Config.shadowCornerHud) ? Math.round(Config.shadowVerticalOffset * 0.5) : 0
    glowRadius: (Config.shadowsEnabled && Config.shadowCornerHud) ? Math.round(Config.shadowBlurRadius * 0.8) : 0
    spread: Config.shadowSpread
    color: Qt.rgba(0, 0, 0, (Config.shadowsEnabled && Config.shadowCornerHud && root.isExpanded) ? (Config.shadowOpacity * 0.85) : 0)
    cornerRadius: root.br + glowRadius
    opacity: root.isExpanded && root.animWidth > (root.radius + 10) ? 1.0 : 0.0
    visible: opacity > 0.01 && (Config.shadowsEnabled && Config.shadowCornerHud)
    z: -1

    Behavior on opacity {
      NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
    }
  }

  Shape {
    id: expandedShape
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.width
    height: root.height
    opacity: root.isExpanded ? 1.0 : 0.0
    visible: opacity > 0.01

    Behavior on opacity {
      NumberAnimation { duration: root.isExpanded ? 240 : 180; easing.type: Easing.OutQuad }
    }

    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    ShapePath {
      fillColor: "#000000"
      strokeColor: "transparent"
      strokeWidth: 0
      startX: root.width
      startY: 0

      // 1. Top horizontal line extending leftwards along display top bezel
      PathLine {
        x: 0
        y: 0
      }

      // 2. Top-Left Outward Concave Ear (Smooth cubic drape down into left vertical wall)
      PathCubic {
        x: root.earW
        y: root.earH
        control1X: root.earW * 0.45
        control1Y: 0
        control2X: root.earW
        control2Y: root.earH * 0.45
      }

      // 3. Left Vertical Wall
      PathLine {
        x: root.earW
        y: Math.max(root.earH, root.animHeight - root.br)
      }

      // 4. Bottom-Left Convex Rounded Corner (Curves counter-clockwise into bottom horizontal line)
      PathArc {
        x: root.earW + root.br
        y: root.animHeight
        radiusX: root.br
        radiusY: root.br
        direction: PathArc.Counterclockwise
      }

      // 5. Bottom Horizontal Line to right outward ear
      PathLine {
        x: root.width - root.rightEarW
        y: root.animHeight
      }

      // 6. Bottom-Right Outward Concave Ear connecting to right screen bezel
      PathCubic {
        x: root.width
        y: root.animHeight + root.rightEarH
        control1X: root.width - (root.rightEarW * 0.45)
        control1Y: root.animHeight
        control2X: root.width
        control2Y: root.animHeight + root.rightEarH * 0.55
      }

      // 7. Right Vertical Line up along display bezel back to (width, 0)
      PathLine {
        x: root.width
        y: 0
      }
    }
  }

  // =========================================================================
  // 3. Content View: System Tray Items Container
  // =========================================================================
  Item {
    id: contentContainer
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.animWidth
    height: root.animHeight
    opacity: (root.isExpanded && root.animWidth > (root.radius + 15)) ? 1.0 : 0.0
    scale: root.isExpanded ? 1.0 : 0.92
    transformOrigin: Item.TopRight
    visible: opacity > 0.01

    Behavior on opacity {
      NumberAnimation { duration: root.isExpanded ? 220 : 140; easing.type: Easing.OutQuad }
    }

    Behavior on scale {
      NumberAnimation { duration: root.isExpanded ? 300 : 160; easing.type: Easing.OutCubic }
    }

    // A. Empty State (When no background daemon apps are running)
    RowLayout {
      id: emptyStateRow
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.left: parent.left
      anchors.leftMargin: 12
      visible: root.trayCount === 0
      spacing: 8

      Rectangle {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        radius: 5
        color: Qt.alpha(Style.accent, 0.22)

        Text {
          anchors.centerIn: parent
          text: "󰣖"
          font.pixelSize: 12
          color: Style.accent
        }
      }

      Text {
        text: "Arka Plan Boş"
        font.family: Style.fontDisplay
        font.pixelSize: 11
        font.weight: Style.fontWeightDisplay
        color: Style.textMuted
      }
    }

    // B. Active Tray App Icons List
    Row {
      id: itemsRow
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 12
      spacing: 6
      visible: root.trayCount > 0

      Repeater {
        id: trayRepeater
        model: SystemTray.items

        delegate: Rectangle {
          id: itemPill
          required property var modelData
          readonly property var trayItem: modelData
          readonly property bool isSelectedForMenu: root.activeContextMenuApp && root.activeContextMenuApp.id === ((trayItem && trayItem.id) ? ("" + trayItem.id) : itemPill.itemTitle)

          width: 24
          height: 24
          radius: 6
          color: isSelectedForMenu ? Qt.rgba(237/255, 135/255, 150/255, 0.24) : (itemMouseArea.containsMouse ? Style.surfaceHover : "transparent")
          border.width: isSelectedForMenu ? 1 : 0
          border.color: isSelectedForMenu ? Qt.rgba(237/255, 135/255, 150/255, 0.7) : "transparent"

          readonly property string itemIcon: (trayItem && trayItem.icon) ? ("" + trayItem.icon) : ""
          readonly property string itemTitle: (trayItem && trayItem.title) ? ("" + trayItem.title) : (trayItem && trayItem.id ? ("" + trayItem.id) : "App")
          readonly property string itemTooltip: (trayItem && trayItem.tooltipTitle) ? ("" + trayItem.tooltipTitle) : itemTitle

          // Resolves system icon path, direct file URI, or icon theme name
          readonly property string resolvedSource: {
            if (!itemIcon || itemIcon.length === 0) return ""
            if (itemIcon.startsWith("/") || itemIcon.startsWith("file://") || itemIcon.startsWith("image://")) return itemIcon
            return Quickshell.iconPath(itemIcon)
          }

          Image {
            id: iconImg
            anchors.centerIn: parent
            width: 16
            height: 16
            source: itemPill.resolvedSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: status === Image.Ready && source !== ""
          }

          // Fallback Monogram Badge when icon fails to load
          Rectangle {
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 4
            color: Style.surfaceVariant
            visible: !iconImg.visible

            Text {
              anchors.centerIn: parent
              text: itemPill.itemTitle.length > 0 ? itemPill.itemTitle.charAt(0).toUpperCase() : "󰣖"
              font.family: Style.fontDisplay
              font.pixelSize: 10
              font.weight: Font.Bold
              color: Style.accent
            }
          }

          MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: mouse => {
              if (mouse.button === Qt.LeftButton) {
                if (root.isMenuOpen) {
                  root.closeMenu()
                }
                if (trayItem && typeof trayItem.activate === "function") {
                  trayItem.activate()
                }
              } else if (mouse.button === Qt.RightButton) {
                let thisId = (trayItem && trayItem.id) ? ("" + trayItem.id) : itemPill.itemTitle
                if (root.activeContextMenuApp && root.activeContextMenuApp.id === thisId) {
                  root.closeMenu()
                } else {
                  let globalPos = itemPill.mapToItem(root, itemPill.width / 2, itemPill.height)
                  root.activeContextMenuApp = {
                    id: thisId,
                    title: itemPill.itemTitle,
                    tooltip: itemPill.itemTooltip,
                    iconSource: itemPill.resolvedSource,
                    centerX: globalPos.x,
                    bottomY: globalPos.y
                  }
                }
              } else if (mouse.button === Qt.MiddleButton) {
                if (trayItem && typeof trayItem.secondaryActivate === "function") {
                  trayItem.secondaryActivate()
                }
              }
            }
          }
        }
      }
    }
  }

  // =========================================================================
  // 4. Context Menu / Close Button Popover
  // Appears below the right-clicked tray icon with animated reveal
  // =========================================================================
  Item {
    id: closeMenuContainer
    anchors.top: parent.top
    anchors.right: parent.right
    width: root.width
    height: root.animHeight + 72
    visible: root.isExpanded && root.isMenuOpen && (closeMenuCard.opacity > 0.01)

    // Backdrop dismissal inside the tray HUD bounds
    MouseArea {
      anchors.fill: parent
      z: 0
      onClicked: root.closeMenu()
    }

    Rectangle {
      id: closeMenuCard
      z: 10
      width: 136
      height: 60
      radius: 9
      color: "#0a0b10"
      border.width: 1
      border.color: Qt.rgba(255, 255, 255, 0.14)

      // Calculate x position centered on the right-clicked icon, clamped nicely inside root bounds
      readonly property real targetX: root.activeContextMenuApp ? (root.activeContextMenuApp.centerX - width / 2) : (root.width - width - 8)
      x: Math.max(8, Math.min(targetX, root.width - width - 8))
      y: root.animHeight + 6

      opacity: (root.isExpanded && root.isMenuOpen) ? 1.0 : 0.0
      scale: (root.isExpanded && root.isMenuOpen) ? 1.0 : 0.88
      transformOrigin: Item.Top

      Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
      }

      Behavior on scale {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }

      Behavior on x {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // App Header Row (Title & Icon)
        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Image {
            Layout.preferredWidth: 13
            Layout.preferredHeight: 13
            source: root.activeContextMenuApp ? (root.activeContextMenuApp.iconSource || "") : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: status === Image.Ready && source !== ""
          }

          Text {
            Layout.fillWidth: true
            text: root.activeContextMenuApp ? (root.activeContextMenuApp.title || root.activeContextMenuApp.tooltip || "Uygulama") : ""
            font.family: Style.fontDisplay
            font.pixelSize: 10
            font.weight: Style.fontWeightDisplay
            color: Style.textMuted
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }

        // Close Action Button
        Rectangle {
          id: closeBtn
          Layout.fillWidth: true
          Layout.preferredHeight: 26
          radius: 6
          color: closeBtnMouse.pressed
                 ? Qt.rgba(237/255, 135/255, 150/255, 0.45)
                 : (closeBtnMouse.containsMouse
                    ? Qt.rgba(237/255, 135/255, 150/255, 0.28)
                    : Qt.rgba(237/255, 135/255, 150/255, 0.14))
          border.width: 1
          border.color: closeBtnMouse.containsMouse
                        ? Style.accentRed
                        : Qt.rgba(237/255, 135/255, 150/255, 0.35)

          Behavior on color {
            ColorAnimation { duration: 120 }
          }
          Behavior on border.color {
            ColorAnimation { duration: 120 }
          }

          RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
              text: "󰅖"
              font.pixelSize: 12
              color: Style.accentRed
            }

            Text {
              text: "Kapat"
              font.family: Style.fontDisplay
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: closeBtnMouse.containsMouse ? "#ffffff" : Style.accentRed
            }
          }

          MouseArea {
            id: closeBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              if (root.activeContextMenuApp) {
                root.closeApp(root.activeContextMenuApp)
                root.closeMenu()
              }
            }
          }
        }
      }
    }
  }
}
