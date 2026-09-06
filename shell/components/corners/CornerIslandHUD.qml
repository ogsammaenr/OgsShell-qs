import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../.."
import "../../theme"

Item {
  id: root

  property var hudService: null
  property var localEvent: null
  property int radius: 14
  property color cornerColor: "#000000"

  readonly property var activeEvent: localEvent !== null ? localEvent : (hudService ? hudService.activeEvent : null)
  readonly property bool isExpanded: activeEvent !== null && Config.cornerHudEnabled

  readonly property real targetWidth: isExpanded ? Math.max((activeEvent && activeEvent.type === "WORKSPACE") ? 95 : 165, Math.min(contentRow.implicitWidth + 30, 320)) : root.radius
  readonly property real targetHeight: isExpanded ? Config.cornerHudHeight : root.radius

  Timer {
    id: localDismissTimer
    interval: (Config.cornerHudTimeoutMs !== undefined && Config.cornerHudTimeoutMs > 0) ? Config.cornerHudTimeoutMs : 1200
    repeat: false
    onTriggered: {
      root.localEvent = null
    }
  }

  function showWorkspaceHUD(activeWsId, displayTitle, workspacesList) {
    if (!Config.cornerHudEnabled || !Config.cornerHudWorkspace) return

    root.localEvent = {
      "type": "WORKSPACE",
      "icon": "󱂬",
      "title": displayTitle || "Workspace",
      "subtitle": "" + activeWsId,
      "activeWsId": activeWsId,
      "workspaces": workspacesList && workspacesList.length > 0 ? workspacesList : [activeWsId],
      "badgeColor": Style.accentBlue
    }

    localDismissTimer.interval = (Config.cornerHudTimeoutMs > 0) ? Config.cornerHudTimeoutMs : 1200
    localDismissTimer.restart()
  }

  property real animWidth: root.radius
  property real animHeight: root.radius

  // Top-Right & Bottom-Left Outward Concave Ear Dimensions
  readonly property real earW: 16
  readonly property real earH: 16
  readonly property real br: 14
  readonly property real leftEarW: 12
  readonly property real leftEarH: 12

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
  height: animHeight + leftEarH

  // =========================================================================
  // 1. IDLE State: Concave Screen Corner Cutout Shape (14px)
  // =========================================================================
  Shape {
    id: idleCutout
    anchors.top: parent.top
    anchors.left: parent.left
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
      startX: 0
      startY: 0

      PathLine { x: root.radius; y: 0 }
      PathArc {
        x: 0
        y: root.radius
        radiusX: root.radius
        radiusY: root.radius
        direction: PathArc.Counterclockwise
      }
      PathLine { x: 0; y: 0 }
    }
  }

  // =========================================================================
  // 2. EXPANDED State: Seamless Borderless OLED Black Vector Capsule
  // Features Outward Concave Ear at Top-Right and Bottom-Left
  // =========================================================================
  Shape {
    id: expandedShape
    anchors.top: parent.top
    anchors.left: parent.left
    width: root.animWidth + root.earW + 20
    height: root.animHeight + root.leftEarH + 20
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
      startX: 0
      startY: 0

      // 1. Top horizontal line to the start of top-right outward ear
      PathLine {
        x: root.animWidth + root.earW
        y: 0
      }

      // 2. Top-Right Outward Concave Slope (Ear)
      PathCubic {
        x: root.animWidth
        y: root.earH
        control1X: root.animWidth + root.earW * 0.55
        control1Y: 0
        control2X: root.animWidth
        control2Y: root.earH * 0.45
      }

      // 3. Right Vertical Wall
      PathLine {
        x: root.animWidth
        y: Math.max(root.earH, root.animHeight - root.br)
      }

      // 4. Bottom-Right Convex Rounded Corner
      PathArc {
        x: root.animWidth - root.br
        y: root.animHeight
        radiusX: root.br
        radiusY: root.br
        direction: PathArc.Clockwise
      }

      // 5. Bottom Horizontal Line to left outward ear
      PathLine {
        x: root.leftEarW
        y: root.animHeight
      }

      // 6. Bottom-Left Outward Concave Slope connecting to left screen edge
      PathCubic {
        x: 0
        y: root.animHeight + root.leftEarH
        control1X: root.leftEarW * 0.45
        control1Y: root.animHeight
        control2X: 0
        control2Y: root.animHeight + root.leftEarH * 0.55
      }

      // 7. Left Vertical Line up to top-left corner
      PathLine {
        x: 0
        y: 0
      }
    }
  }

  // =========================================================================
  // 3. Content View: Dynamic Event Slots (Clean, Crisp Typography)
  // =========================================================================
  Item {
    id: contentContainer
    anchors.top: parent.top
    anchors.left: parent.left
    width: root.animWidth
    height: root.animHeight
    opacity: (root.isExpanded && root.animWidth > (root.radius + 15)) ? 1.0 : 0.0
    scale: root.isExpanded ? 1.0 : 0.92
    transformOrigin: Item.TopLeft
    visible: opacity > 0.01

    Behavior on opacity {
      NumberAnimation { duration: root.isExpanded ? 220 : 140; easing.type: Easing.OutQuad }
    }

    Behavior on scale {
      NumberAnimation { duration: root.isExpanded ? 300 : 160; easing.type: Easing.OutCubic }
    }

    RowLayout {
      id: contentRow
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.right: parent.right
      anchors.rightMargin: 14
      spacing: 9

      // Icon Container
      Rectangle {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        radius: 5
        color: (activeEvent && activeEvent.badgeColor) ? Qt.alpha(activeEvent.badgeColor, 0.22) : Style.surfaceVariant

        Text {
          anchors.centerIn: parent
          text: activeEvent ? activeEvent.icon : ""
          font.pixelSize: 12
          color: (activeEvent && activeEvent.badgeColor) ? activeEvent.badgeColor : Style.accent
        }
      }

      // Slot 1: Volume Slider & Percentage
      RowLayout {
        visible: activeEvent ? (activeEvent.type === "VOLUME") : false
        spacing: 8

        // Track bar
        Rectangle {
          Layout.preferredWidth: 65
          Layout.preferredHeight: 4
          radius: 2
          color: Qt.alpha(Style.textPrimary, 0.18)

          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, parent.width * (activeEvent ? activeEvent.progress : 0))
            radius: 2
            color: (activeEvent && activeEvent.badgeColor) ? activeEvent.badgeColor : Style.accent

            Behavior on width {
              NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
            }
          }
        }

        Text {
          text: activeEvent ? activeEvent.subtitle : ""
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Style.textPrimary
        }
      }

      // Slot 2: Workspace Dots Indicator (Per-Monitor Isolated Workspaces, No Text)
      Row {
        visible: activeEvent ? (activeEvent.type === "WORKSPACE") : false
        spacing: 5
        Layout.alignment: Qt.AlignVCenter

        Repeater {
          model: (activeEvent && activeEvent.workspaces) ? activeEvent.workspaces : []

          Rectangle {
            id: wsDot
            required property var modelData

            readonly property bool isActive: (activeEvent && activeEvent.activeWsId === modelData)

            width: isActive ? 18 : 6
            height: 6
            radius: 3
            color: isActive ? Style.accentBlue : Qt.alpha(Style.textPrimary, 0.28)

            Behavior on width {
              SpringAnimation {
                spring: 26.0
                damping: 0.75
                epsilon: 0.01
              }
            }

            Behavior on color {
              ColorAnimation {
                duration: 180
                easing.type: Easing.OutQuad
              }
            }
          }
        }
      }

      // Slot 3: Caps Lock Badge
      RowLayout {
        visible: activeEvent ? (activeEvent.type === "CAPSLOCK") : false
        spacing: 6

        Text {
          text: "Caps Lock"
          font.pixelSize: 11
          color: Style.textMuted
        }

        Rectangle {
          Layout.preferredHeight: 18
          Layout.preferredWidth: capsText.implicitWidth + 10
          radius: 4
          color: (activeEvent && activeEvent.isCaps) ? Qt.alpha(Style.accentGreen, 0.25) : Qt.alpha(Style.surfaceVariant, 0.6)

          Text {
            id: capsText
            anchors.centerIn: parent
            text: activeEvent ? activeEvent.subtitle : ""
            font.pixelSize: 10
            font.weight: Font.Bold
            color: (activeEvent && activeEvent.isCaps) ? Style.accentGreen : Style.textMuted
          }
        }
      }

      // Slot 4: Microphone Status
      RowLayout {
        visible: activeEvent ? (activeEvent.type === "MIC") : false
        spacing: 6

        Text {
          text: "Mikrofon"
          font.pixelSize: 11
          color: Style.textMuted
        }

        Rectangle {
          Layout.preferredHeight: 18
          Layout.preferredWidth: micText.implicitWidth + 10
          radius: 4
          color: (activeEvent && activeEvent.isMuted) ? Qt.alpha(Style.accentOrange, 0.25) : Qt.alpha(Style.accentGreen, 0.25)

          Text {
            id: micText
            anchors.centerIn: parent
            text: activeEvent ? activeEvent.subtitle : ""
            font.pixelSize: 10
            font.weight: Font.Bold
            color: (activeEvent && activeEvent.isMuted) ? Style.accentOrange : Style.accentGreen
          }
        }
      }

      // Slot 5: Clipboard Copied Toast
      ColumnLayout {
        visible: activeEvent ? (activeEvent.type === "CLIPBOARD") : false
        spacing: 1

        Text {
          text: "Pano Kopyalandı"
          font.pixelSize: 10
          font.weight: Font.DemiBold
          color: Style.accentMagenta
        }

        Text {
          text: activeEvent ? activeEvent.subtitle : ""
          font.pixelSize: 11
          color: Style.textPrimary
          elide: Text.ElideRight
          Layout.maximumWidth: 170
        }
      }
    }
  }
}
