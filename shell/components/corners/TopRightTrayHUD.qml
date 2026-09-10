import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell.Services.SystemTray
import "../.."
import "../../theme"

Item {
  id: root

  property int radius: Config.screenCornersRadius || 14
  property color cornerColor: Config.screenCornersColor || "#000000"
  property bool isExpanded: false

  readonly property int trayCount: {
    if (!SystemTray.items) return 0
    if (typeof SystemTray.items.count === "number") return SystemTray.items.count
    if (SystemTray.items.values && Array.isArray(SystemTray.items.values)) return SystemTray.items.values.length
    return 0
  }

  // Auto-calculated expanded width based on number of active tray apps
  readonly property real targetWidth: isExpanded ? Math.max(76, (trayCount * 28) + 26) : root.radius
  readonly property real targetHeight: isExpanded ? (Config.cornerTrayHeight || 34) : root.radius

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
      duration: root.isExpanded ? 340 : 260
      easing.type: root.isExpanded ? Easing.OutCubic : Easing.InOutQuad
    }
  }

  Behavior on animHeight {
    NumberAnimation {
      duration: root.isExpanded ? 300 : 240
      easing.type: root.isExpanded ? Easing.OutCubic : Easing.InOutQuad
    }
  }

  width: animWidth + earW
  height: animHeight + rightEarH

  function toggle() {
    isExpanded = !isExpanded
  }

  function expand() {
    isExpanded = true
  }

  function collapse() {
    isExpanded = false
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
      NumberAnimation { duration: root.isExpanded ? 180 : 220; easing.type: Easing.OutQuad }
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

  // Top-Right Corner Hotspot MouseArea (Triggers expansion when clicked or hovered)
  MouseArea {
    id: cornerHotspot
    anchors.top: parent.top
    anchors.right: parent.right
    width: Math.max(root.radius + 10, 24)
    height: Math.max(root.radius + 10, 24)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    visible: !root.isExpanded

    onClicked: {
      root.toggle()
    }
  }

  // =========================================================================
  // 2. EXPANDED State: Seamless OLED Black Pill with Concave Outward Ears
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
    width: root.animWidth + root.earW + 20
    height: root.animHeight + root.rightEarH + 20
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
      startX: expandedShape.width
      startY: 0

      // 1. Top horizontal line extending leftwards along display top bezel
      PathLine {
        x: expandedShape.width - (root.animWidth + root.earW)
        y: 0
      }

      // 2. Top-Left Outward Concave Ear (Smooth cubic drape down and right)
      PathCubic {
        x: expandedShape.width - root.animWidth
        y: root.earH
        control1X: expandedShape.width - (root.animWidth + root.earW * 0.55)
        control1Y: 0
        control2X: expandedShape.width - root.animWidth
        control2Y: root.earH * 0.45
      }

      // 3. Left Vertical Wall
      PathLine {
        x: expandedShape.width - root.animWidth
        y: Math.max(root.earH, root.animHeight - root.br)
      }

      // 4. Bottom-Left Convex Rounded Corner (Curves smoothly clockwise)
      PathArc {
        x: expandedShape.width - (root.animWidth - root.br)
        y: root.animHeight
        radiusX: root.br
        radiusY: root.br
        direction: PathArc.Clockwise
      }

      // 5. Bottom Horizontal Line to right outward ear
      PathLine {
        x: expandedShape.width - root.rightEarW
        y: root.animHeight
      }

      // 6. Bottom-Right Outward Concave Ear connecting to right screen bezel
      PathCubic {
        x: expandedShape.width
        y: root.animHeight + root.rightEarH
        control1X: expandedShape.width - (root.rightEarW * 0.45)
        control1Y: root.animHeight
        control2X: expandedShape.width
        control2Y: root.animHeight + root.rightEarH * 0.55
      }

      // 7. Right Vertical Line up along display bezel back to (width, 0)
      PathLine {
        x: expandedShape.width
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
      anchors.centerIn: parent
      visible: root.trayCount === 0
      spacing: 6

      Text {
        text: "󰣖"
        font.pixelSize: 13
        color: Style.accent
      }

      Text {
        text: "Boş"
        font.pixelSize: 11
        font.weight: Font.Medium
        color: Style.textMuted
      }
    }

    // B. Active Tray App Icons List
    Row {
      id: itemsRow
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 10
      spacing: 5
      visible: root.trayCount > 0

      Repeater {
        model: SystemTray.items

        delegate: Rectangle {
          id: itemPill
          width: 24
          height: 24
          radius: 6
          color: itemMouseArea.containsMouse ? Style.surfaceHover : "transparent"

          readonly property var trayItem: modelData
          readonly property string itemIcon: (trayItem && trayItem.icon) ? ("" + trayItem.icon) : ""
          readonly property string itemTitle: (trayItem && trayItem.title) ? ("" + trayItem.title) : (trayItem && trayItem.id ? ("" + trayItem.id) : "App")
          readonly property string itemTooltip: (trayItem && trayItem.tooltipTitle) ? ("" + trayItem.tooltipTitle) : itemTitle

          // Resolves system icon path, direct file URI, or icon theme name
          readonly property string resolvedSource: {
            if (!itemIcon || itemIcon.length === 0) return ""
            if (itemIcon.startsWith("/")) return "file://" + itemIcon
            if (itemIcon.startsWith("file://") || itemIcon.startsWith("image://")) return itemIcon
            return "image://icon/" + itemIcon
          }

          Image {
            id: iconImg
            anchors.centerIn: parent
            width: 17
            height: 17
            source: itemPill.resolvedSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: status === Image.Ready && source !== ""
          }

          // Fallback Monogram Badge
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
                if (trayItem && typeof trayItem.activate === "function") {
                  trayItem.activate()
                }
              } else if (mouse.button === Qt.RightButton) {
                if (trayItem && typeof trayItem.display === "function") {
                  trayItem.display(root, mouse.x, mouse.y)
                } else if (trayItem && typeof trayItem.secondaryActivate === "function") {
                  trayItem.secondaryActivate()
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
}
