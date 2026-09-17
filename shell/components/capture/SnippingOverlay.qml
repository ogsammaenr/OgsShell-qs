import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../.."
import "../../backend"
import "../../theme"

PanelWindow {
  id: root

  property string monitorName: ""
  property var hyprMonitor: null
  property var ipc: null
  property bool isFocusedScreen: true

  // Multi-Monitor Geometry Awareness
  readonly property real monitorGlobalX: SnippingService.getMonitorX(root.monitorName)
  readonly property real monitorGlobalY: SnippingService.getMonitorY(root.monitorName)

  // State
  property bool isSelecting: false
  property real startX: 0
  property real startY: 0
  property real currentX: 0
  property real currentY: 0
  property real mouseX: 0
  property real mouseY: 0
  property bool ctrlPressed: false
  property var snappedWindow: null

  // Selection calculations
  readonly property real rawBoxX: isSelecting ? Math.min(startX, currentX) : (snappedWindow ? snappedWindow.localX : 0)
  readonly property real rawBoxY: isSelecting ? Math.min(startY, currentY) : (snappedWindow ? snappedWindow.localY : 0)
  readonly property real rawBoxW: isSelecting ? Math.abs(currentX - startX) : (snappedWindow ? snappedWindow.width : 0)
  readonly property real rawBoxH: isSelecting ? Math.abs(currentY - startY) : (snappedWindow ? snappedWindow.height : 0)

  // Bound to screen dimensions
  readonly property real boxX: Math.max(0, Math.min(root.width, rawBoxX))
  readonly property real boxY: Math.max(0, Math.min(root.height, rawBoxY))
  readonly property real boxW: Math.max(0, Math.min(root.width - boxX, rawBoxW))
  readonly property real boxH: Math.max(0, Math.min(root.height - boxY, rawBoxH))
  readonly property bool hasActiveBox: (isSelecting && boxW > 4 && boxH > 4) || (snappedWindow !== null && boxW > 4 && boxH > 4)

  visible: SnippingService.isOpen
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore

  onVisibleChanged: {
    if (visible) {
      keyHandler.forceActiveFocus();
      isSelecting = false;
      snappedWindow = null;
      ctrlPressed = false;
    }
  }

  // 1. Frozen Screen Background Image (Per-Monitor 1:1 Match)
  Image {
    id: freezeImage
    anchors.fill: parent
    source: {
      if (!SnippingService.isOpen) return "";
      let mon = root.monitorName;
      if (mon && mon.length > 0) {
        return "file:///tmp/ogs_freeze_" + mon + ".png?" + SnippingService.freezeTimestamp;
      }
      return "file:///tmp/ogs_freeze.png?" + SnippingService.freezeTimestamp;
    }
    cache: false
    fillMode: Image.PreserveAspectCrop
    asynchronous: false

    onStatusChanged: {
      if (status === Image.Error) {
        console.warn("[SnippingOverlay] Failed loading freeze image for", root.monitorName, source);
      }
    }
  }

  // 2. Dimming & Cutout Mask (4-Rectangle Matte for 100% Crisp Center)
  Item {
    id: dimmingMatte
    anchors.fill: parent

    // Top dim
    Rectangle {
      visible: root.hasActiveBox
      x: 0
      y: 0
      width: root.width
      height: root.boxY
      color: "#000000"
      opacity: 0.35
    }

    // Bottom dim
    Rectangle {
      visible: root.hasActiveBox
      x: 0
      y: root.boxY + root.boxH
      width: root.width
      height: Math.max(0, root.height - (root.boxY + root.boxH))
      color: "#000000"
      opacity: 0.35
    }

    // Left dim
    Rectangle {
      visible: root.hasActiveBox
      x: 0
      y: root.boxY
      width: root.boxX
      height: root.boxH
      color: "#000000"
      opacity: 0.35
    }

    // Right dim
    Rectangle {
      visible: root.hasActiveBox
      x: root.boxX + root.boxW
      y: root.boxY
      width: Math.max(0, root.width - (root.boxX + root.boxW))
      height: root.boxH
      color: "#000000"
      opacity: 0.35
    }

    // Fullscreen dim when no active selection box
    Rectangle {
      visible: !root.hasActiveBox
      anchors.fill: parent
      color: "#000000"
      opacity: 0.35
    }
  }

  // 3. Highlighted Selection Bounding Box
  Rectangle {
    id: selectionBorder
    visible: root.hasActiveBox
    x: root.boxX
    y: root.boxY
    width: root.boxW
    height: root.boxH
    color: root.snappedWindow ? Qt.rgba(137/255, 180/255, 250/255, 0.08) : "transparent"
    border.color: Style.accent || "#89b4fa"
    border.width: 2
    radius: root.snappedWindow ? 6 : 2

    // Outer Glow / Accent Edge
    Rectangle {
      anchors.fill: parent
      anchors.margins: -1
      color: "transparent"
      border.color: Qt.rgba(137/255, 180/255, 250/255, 0.4)
      border.width: 1
      radius: parent.radius + 1
    }
  }

  // 4. Real-time Pixel Dimension Badge
  Rectangle {
    id: dimensionBadge
    visible: root.hasActiveBox && (root.boxW > 20 && root.boxH > 20)
    x: Math.max(16, Math.min(root.width - width - 16, root.boxX + (root.boxW - width) / 2))
    y: {
      if (root.boxY + root.boxH + 12 + height < root.height) {
        return root.boxY + root.boxH + 12;
      } else if (root.boxY - height - 12 > 0) {
        return root.boxY - height - 12;
      }
      return root.boxY + 12;
    }
    implicitWidth: badgeRow.implicitWidth + 24
    implicitHeight: 28
    radius: 14
    color: Style.surface || "#181825"
    border.color: Style.accent || "#89b4fa"
    border.width: 1

    Row {
      id: badgeRow
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: Math.round(root.boxW) + " × " + Math.round(root.boxH)
        color: Style.fg || "#cdd6f4"
        font.pixelSize: 12
        font.bold: true
        font.family: "Outfit, Inter, sans-serif"
      }

      Text {
        visible: root.snappedWindow !== null && (root.snappedWindow.className || "") !== ""
        text: "• " + (root.snappedWindow ? root.snappedWindow.className : "")
        color: Style.accent || "#89b4fa"
        font.pixelSize: 12
        font.family: "Outfit, Inter, sans-serif"
      }
    }
  }

  // 5. Interactive Mouse Capture Area
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    cursorShape: Qt.CrossCursor
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onPositionChanged: mouse => {
      root.mouseX = mouse.x;
      root.mouseY = mouse.y;

      if (mouse.modifiers & Qt.ControlModifier) {
        root.ctrlPressed = true;
      }

      if (root.isSelecting) {
        root.currentX = mouse.x;
        root.currentY = mouse.y;
      } else if (root.ctrlPressed) {
        root.updateSnappedWindow(mouse.x, mouse.y);
      }
    }

    onPressed: mouse => {
      keyHandler.forceActiveFocus();
      root.mouseX = mouse.x;
      root.mouseY = mouse.y;

      // Right-click handling: Cancel active selection box, or close overlay if idle
      if (mouse.button === Qt.RightButton) {
        if (root.isSelecting || root.hasActiveBox || root.snappedWindow !== null) {
          root.isSelecting = false;
          root.startX = 0;
          root.startY = 0;
          root.currentX = 0;
          root.currentY = 0;
          root.snappedWindow = null;
        } else {
          SnippingService.close();
        }
        return;
      }

      if ((mouse.modifiers & Qt.ControlModifier) || root.ctrlPressed) {
        root.updateSnappedWindow(mouse.x, mouse.y);
        if (root.snappedWindow) {
          let geom = root.snappedWindow.globalX + "," + root.snappedWindow.globalY + " " + root.snappedWindow.width + "x" + root.snappedWindow.height;
          root.dispatchAction({
            geometry: geom,
            monitor: root.monitorName,
            local_x: Math.round(root.snappedWindow.localX),
            local_y: Math.round(root.snappedWindow.localY),
            width: Math.round(root.snappedWindow.width),
            height: Math.round(root.snappedWindow.height)
          });
          SnippingService.close();
          return;
        }
      }

      root.snappedWindow = null;
      root.startX = mouse.x;
      root.startY = mouse.y;
      root.currentX = mouse.x;
      root.currentY = mouse.y;
      root.isSelecting = true;
    }

    onReleased: mouse => {
      if (mouse.button === Qt.RightButton) {
        return;
      }

      if (!root.isSelecting) return;
      root.isSelecting = false;

      let w = Math.round(Math.abs(root.currentX - root.startX));
      let h = Math.round(Math.abs(root.currentY - root.startY));

      if (w >= 6 && h >= 6) {
        let minX = Math.round(Math.min(root.startX, root.currentX));
        let minY = Math.round(Math.min(root.startY, root.currentY));
        let globalX = Math.round(root.monitorGlobalX + minX);
        let globalY = Math.round(root.monitorGlobalY + minY);
        let geom = globalX + "," + globalY + " " + w + "x" + h;
        root.dispatchAction({
          geometry: geom,
          monitor: root.monitorName,
          local_x: minX,
          local_y: minY,
          width: w,
          height: h
        });
        SnippingService.close();
      } else {
        // Very small click (under 6px) - do not capture, allow retry
        root.startX = 0;
        root.startY = 0;
        root.currentX = 0;
        root.currentY = 0;
      }
    }
  }

  // 6. Shell-Integrated Dynamic Capture HUD (Notch & Island Native Silhouette)
  Item {
    id: captureIslandHud
    anchors.top: parent.top
    anchors.topMargin: Config.isNotch ? 0 : Config.islandTopMargin
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.max(480, contentCol.implicitWidth + 56)
    height: Config.isNotch ? (Config.notchHoverHeight || 56) : (Config.islandHoverHeight || 58)

    // Geometry properties matching DynamicIsland
    readonly property real activeRadius: Config.isNotch ? Config.notchBottomRadius : Config.islandRadiusFull
    readonly property real notchEarW: 5
    readonly property real notchEarH: Math.min(16, height * 0.45)
    readonly property color surfaceColor: Style.bgPrimary || "#000000"

    // Fades immediately to 0.0 when user starts dragging to select, visible across monitors
    opacity: !root.isSelecting ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    Behavior on y {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutCubic
      }
    }

    // Depth Elevation Drop Shadow (Matching Shell Shadow)
    RectangularGlow {
      id: captureShadowGlow
      anchors.fill: parent
      anchors.topMargin: (Config.shadowsEnabled && (Config.isNotch ? Config.shadowNotch : Config.shadowIsland)) ? Config.shadowVerticalOffset : 0
      anchors.bottomMargin: (Config.shadowsEnabled && (Config.isNotch ? Config.shadowNotch : Config.shadowIsland)) ? -Config.shadowVerticalOffset : 0
      glowRadius: (Config.shadowsEnabled && (Config.isNotch ? Config.shadowNotch : Config.shadowIsland)) ? Config.shadowBlurRadius : 0
      spread: Config.shadowSpread
      color: Qt.rgba(0, 0, 0, (Config.shadowsEnabled && (Config.isNotch ? Config.shadowNotch : Config.shadowIsland)) ? Config.shadowOpacity : 0)
      cornerRadius: captureIslandHud.activeRadius + glowRadius
      visible: Config.shadowsEnabled && (Config.isNotch ? Config.shadowNotch : Config.shadowIsland)
      z: -1
    }

    // Surface 1: Notch Bézier Drape Silhouette (Used when form_factor is "notch")
    Shape {
      id: notchShape
      anchors.fill: parent
      anchors.leftMargin: -captureIslandHud.notchEarW
      anchors.rightMargin: -captureIslandHud.notchEarW
      visible: Config.isNotch

      layer.enabled: true
      layer.samples: 4
      layer.smooth: true

      ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: captureIslandHud.surfaceColor
        startX: 0
        startY: 0

        // Left Tall Slope: Smooth Cubic Bezier drape
        PathCubic {
          control1X: captureIslandHud.notchEarW * 0.35
          control1Y: 0
          control2X: captureIslandHud.notchEarW
          control2Y: captureIslandHud.notchEarH * 0.65
          x: captureIslandHud.notchEarW
          y: captureIslandHud.notchEarH
        }

        // Left Vertical Wall
        PathLine {
          x: captureIslandHud.notchEarW
          y: captureIslandHud.height - captureIslandHud.activeRadius
        }

        // Bottom-Left Corner Arc
        PathArc {
          x: captureIslandHud.notchEarW + captureIslandHud.activeRadius
          y: captureIslandHud.height
          radiusX: captureIslandHud.activeRadius
          radiusY: captureIslandHud.activeRadius
          direction: PathArc.Counterclockwise
        }

        // Bottom Edge
        PathLine {
          x: captureIslandHud.notchEarW + captureIslandHud.width - captureIslandHud.activeRadius
          y: captureIslandHud.height
        }

        // Bottom-Right Corner Arc
        PathArc {
          x: captureIslandHud.notchEarW + captureIslandHud.width
          y: captureIslandHud.height - captureIslandHud.activeRadius
          radiusX: captureIslandHud.activeRadius
          radiusY: captureIslandHud.activeRadius
          direction: PathArc.Counterclockwise
        }

        // Right Vertical Wall
        PathLine {
          x: captureIslandHud.notchEarW + captureIslandHud.width
          y: captureIslandHud.notchEarH
        }

        // Right Tall Slope
        PathCubic {
          control1X: captureIslandHud.notchEarW + captureIslandHud.width
          control1Y: captureIslandHud.notchEarH * 0.65
          control2X: captureIslandHud.notchEarW + captureIslandHud.width + captureIslandHud.notchEarW * 0.65
          control2Y: 0
          x: captureIslandHud.notchEarW * 2 + captureIslandHud.width
          y: 0
        }

        // Top Ceiling Line
        PathLine {
          x: 0
          y: 0
        }
      }
    }

    // Surface 2: Floating Pill Squircle (Used when form_factor is "island")
    Rectangle {
      id: islandShape
      anchors.fill: parent
      visible: !Config.isNotch
      radius: captureIslandHud.activeRadius
      color: captureIslandHud.surfaceColor
      border.width: 1
      border.color: Style.borderSubtle
      antialiasing: true
      smooth: true
    }

    // Content: Centered Interactive Capture Bar
    Column {
      id: contentCol
      anchors.centerIn: parent
      spacing: 2

      RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        // 1. SS (Bölge Seçim / Snip)
        Rectangle {
          Layout.preferredHeight: 30
          Layout.preferredWidth: ssRow.implicitWidth + 20
          radius: 15
          color: SnippingService.mode === "SS" ? Style.accent : (ssMouse.containsMouse ? Style.surfaceHover : "transparent")

          Row {
            id: ssRow
            anchors.centerIn: parent
            spacing: 5
            Text {
              text: "📸"
              font.pixelSize: 13
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "Bölge"
              color: SnippingService.mode === "SS" ? Style.bgPrimary : Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.DemiBold
              font.family: Style.fontText
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: ssMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SnippingService.setMode("SS")
          }
        }

        // 2. OCR (Metin Tanıma)
        Rectangle {
          Layout.preferredHeight: 30
          Layout.preferredWidth: ocrRow.implicitWidth + 20
          radius: 15
          color: SnippingService.mode === "OCR" ? Style.accent : (ocrMouse.containsMouse ? Style.surfaceHover : "transparent")

          Row {
            id: ocrRow
            anchors.centerIn: parent
            spacing: 5
            Text {
              text: "🔍"
              font.pixelSize: 13
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "OCR"
              color: SnippingService.mode === "OCR" ? Style.bgPrimary : Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.DemiBold
              font.family: Style.fontText
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: ocrMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SnippingService.setMode("OCR")
          }
        }

        // 3. Kayıt (Video)
        Rectangle {
          Layout.preferredHeight: 30
          Layout.preferredWidth: recRow.implicitWidth + 20
          radius: 15
          color: SnippingService.mode === "RECORD" ? "#ed4245" : (recMouse.containsMouse ? Style.surfaceHover : "transparent")

          Row {
            id: recRow
            anchors.centerIn: parent
            spacing: 5
            Text {
              text: "🎥"
              font.pixelSize: 13
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "Kayıt"
              color: SnippingService.mode === "RECORD" ? "#ffffff" : Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.DemiBold
              font.family: Style.fontText
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: recMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SnippingService.setMode("RECORD")
          }
        }

        // Hairline Divider
        Rectangle {
          Layout.preferredWidth: 1
          Layout.preferredHeight: 18
          Layout.leftMargin: 2
          Layout.rightMargin: 2
          color: Style.borderSubtle
        }

        // 4. Tam Ekran (1-Tık Full Screenshot)
        Rectangle {
          Layout.preferredHeight: 30
          Layout.preferredWidth: fullRow.implicitWidth + 18
          radius: 15
          color: fullMouse.containsMouse ? Style.surfaceHover : "transparent"

          Row {
            id: fullRow
            anchors.centerIn: parent
            spacing: 5
            Text {
              text: "🖥️"
              font.pixelSize: 13
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "Tam Ekran"
              color: Style.textPrimary
              font.pixelSize: 12
              font.weight: Font.DemiBold
              font.family: Style.fontText
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: fullMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.dispatchAction({
                geometry: "",
                monitor: root.monitorName,
                local_x: 0,
                local_y: 0,
                width: Math.round(root.width),
                height: Math.round(root.height)
              });
              SnippingService.close();
            }
          }
        }

        // 5. İptal / Kapat (✕)
        Rectangle {
          Layout.preferredHeight: 28
          Layout.preferredWidth: 28
          radius: 14
          color: closeMouse.containsMouse ? Qt.rgba(255,255,255,0.15) : "transparent"

          Text {
            anchors.centerIn: parent
            text: "✕"
            color: Style.textMuted
            font.pixelSize: 12
            font.bold: true
          }

          MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SnippingService.close()
          }
        }
      }

      // Keyboard & Mouse Helper Hints
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Sürükle: Seçim  •  Sağ Tık: İptal  •  Ctrl: Pencereye Yapış  •  esc: Kapat"
        color: Style.textMuted
        font.pixelSize: 10
        font.family: Style.fontText
      }
    }
  }

  // 7. Keyboard Navigation & Shortcuts
  Item {
    id: keyHandler
    focus: true

    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        SnippingService.close();
        event.accepted = true;
      } else if (event.key === Qt.Key_Control) {
        root.ctrlPressed = true;
        root.updateSnappedWindow(root.mouseX, root.mouseY);
        event.accepted = true;
      }
    }

    Keys.onReleased: event => {
      if (event.key === Qt.Key_Control) {
        root.ctrlPressed = false;
        root.snappedWindow = null;
        event.accepted = true;
      }
    }
  }

  // 8. Window Snapping Logic
  function updateSnappedWindow(localX, localY) {
    let globalX = Math.round(root.monitorGlobalX + localX);
    let globalY = Math.round(root.monitorGlobalY + localY);

    let toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
    let found = null;

    for (let i = toplevels.length - 1; i >= 0; i--) {
      let win = toplevels[i];
      if (!win) continue;
      if (win.hidden === true || (win.lastIpcObject && win.lastIpcObject.hidden === true)) continue;

      let at = (win.lastIpcObject && win.lastIpcObject.at) ? win.lastIpcObject.at : (win.at || [win.x, win.y]);
      let size = (win.lastIpcObject && win.lastIpcObject.size) ? win.lastIpcObject.size : (win.size || [win.width, win.height]);
      if (!at || !size) continue;

      let wx = at[0];
      let wy = at[1];
      let ww = size[0];
      let wh = size[1];

      if (globalX >= wx && globalX <= wx + ww && globalY >= wy && globalY <= wy + wh) {
        found = {
          globalX: wx,
          globalY: wy,
          width: ww,
          height: wh,
          localX: wx - root.monitorGlobalX,
          localY: wy - root.monitorGlobalY,
          title: win.title || "",
          className: win.initialClass || win.class || ""
        };
        break;
      }
    }
    root.snappedWindow = found;
  }

  // 9. Dispatch Action to Backend
  function dispatchAction(param) {
    if (!ipc) return;
    let geomStr = (typeof param === "object" && param.geometry) ? param.geometry : param;
    if (SnippingService.mode === "SS") {
      ipc.captureScreenshot(param);
    } else if (SnippingService.mode === "OCR") {
      ipc.captureOCR(param);
    } else if (SnippingService.mode === "RECORD") {
      ipc.startRecording(geomStr);
    }
  }
}
