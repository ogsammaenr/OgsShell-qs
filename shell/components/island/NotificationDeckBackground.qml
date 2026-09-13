import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import "../.."

Item {
  id: root

  property int tierLevel: 2 // 2 or 3
  property bool isNotch: Config.isNotch
  property real baseWidth: 360
  property real baseHeight: 56
  property real activeRadius: 28
  property color surfaceColor: Style.bgSecondary
  property bool visibleTier: false
  property string urgency: "normal"
  property real shiftProgress: 0.0 // 0.0 to 1.0 during deck transition
  property bool hasCardBehind: false // True if another card is stacked behind this tier

  // Width & height metrics based on tier, transition progress, and stack depth
  readonly property real widthRatio: {
    if (tierLevel === 2) return 0.91
    if (hasCardBehind) return 0.82
    return 0.82 + (0.09 * shiftProgress)
  }

  readonly property real islandYOffset: {
    if (tierLevel === 2) {
      if (hasCardBehind) return 8
      return Math.max(0, 8 * (1.0 - shiftProgress))
    }
    if (hasCardBehind) return 16
    return Math.max(8, 16 - (8 * shiftProgress))
  }

  readonly property real notchExtraHeight: {
    if (tierLevel === 2) {
      if (hasCardBehind) return 9
      return Math.max(0, 9 * (1.0 - shiftProgress))
    }
    if (hasCardBehind) return 17
    return Math.max(9, 17 - (8 * shiftProgress))
  }

  readonly property real targetOpacity: {
    if (!visibleTier) return 0.0
    if (tierLevel === 2) {
      if (hasCardBehind) return 0.75
      return Math.max(0.0, 0.75 * (1.0 - shiftProgress))
    }
    if (hasCardBehind) return 0.45
    return Math.min(0.75, 0.45 + (0.30 * shiftProgress))
  }

  readonly property color strokeColor: {
    if (urgency === "critical") {
      return tierLevel === 2 ? "#ed8796" : "#f38ba8"
    }
    return tierLevel === 2 ? "#585b70" : "#494d64"
  }

  readonly property real strokeWidth: tierLevel === 2 ? 1.2 : 1.0

  anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

  width: Math.round(baseWidth * widthRatio)
  height: isNotch ? Math.round(baseHeight + notchExtraHeight) : Math.round(baseHeight)
  y: isNotch ? 0 : islandYOffset

  opacity: targetOpacity
  visible: visibleTier && opacity > 0.001

  Behavior on opacity {
    enabled: root.shiftProgress === 0.0
    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
  }

  // =========================================================================
  // PRESENTATION 1: Island Mode (Organic Squircle Pill)
  // =========================================================================
  Rectangle {
    id: islandCardShape
    anchors.fill: parent
    visible: !root.isNotch
    radius: root.activeRadius
    color: Style.isOled ? "#000000" : root.surfaceColor
    border.color: root.strokeColor
    border.width: root.strokeWidth
    antialiasing: true
    smooth: true

    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on color { ColorAnimation { duration: 200 } }
  }

  // =========================================================================
  // PRESENTATION 2: Notch Mode (Ceiling-Hung Cascading Tier)
  // Flush with screen ceiling (y=0), bottom corners rounded with activeRadius
  // =========================================================================
  Shape {
    id: notchCardShape
    anchors.fill: parent
    visible: root.isNotch

    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    ShapePath {
      strokeWidth: root.strokeWidth
      strokeColor: root.strokeColor
      fillColor: Style.isOled ? "#000000" : root.surfaceColor
      startX: 0
      startY: 0

      Behavior on strokeColor { ColorAnimation { duration: 200 } }

      // Left vertical wall down towards bottom corner
      PathLine {
        x: 0
        y: Math.max(0, root.height - root.activeRadius)
      }

      // Bottom-Left corner arc
      PathArc {
        x: Math.min(root.activeRadius, root.width / 2)
        y: root.height
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Counterclockwise
      }

      // Bottom horizontal edge
      PathLine {
        x: Math.max(root.activeRadius, root.width - root.activeRadius)
        y: root.height
      }

      // Bottom-Right corner arc
      PathArc {
        x: root.width
        y: Math.max(0, root.height - root.activeRadius)
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Counterclockwise
      }

      // Right vertical wall up to ceiling (y=0)
      PathLine {
        x: root.width
        y: 0
      }

      // Top ceiling flush line
      PathLine {
        x: 0
        y: 0
      }
    }
  }
}
