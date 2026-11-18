import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

Rectangle {
  id: root

  property var ipc: null
  property real x1: 0.25
  property real y1: 0.10
  property real x2: 0.25
  property real y2: 1.00
  property string curveName: "custom_curve"
  property int testDuration: 650

  readonly property string cssString: "cubic-bezier(" + x1.toFixed(2) + ", " + y1.toFixed(2) + ", " + x2.toFixed(2) + ", " + y2.toFixed(2) + ")"
  readonly property string hyprString: "hl.curve(\"" + (curveName.trim() !== "" ? curveName.trim() : "custom_curve") + "\", { type = \"bezier\", points = { { " + x1.toFixed(3) + ", " + y1.toFixed(3) + " }, { " + x2.toFixed(3) + ", " + y2.toFixed(3) + " } } })"

  signal curveChanged(real x1, real y1, real x2, real y2)
  signal curveSaved(string name, real x1, real y1, real x2, real y2)

  Layout.fillWidth: true
  implicitHeight: mainLayout.implicitHeight + 28
  color: Style.appCard
  border.color: Style.appBorder
  border.width: 1
  radius: 10
  clip: true

  // Helper coordinate functions
  // Normalized: U in [0.0, 1.0], V in [-0.5, 1.5]
  readonly property real padX: 32
  readonly property real padY: 42
  readonly property real yMin: -0.5
  readonly property real yMax: 1.5
  readonly property real boxW: canvasArea.width - (padX * 2)
  readonly property real boxH: canvasArea.height - (padY * 2)
  readonly property real unitH: boxH / (yMax - yMin)

  function toScreenX(u) {
    return padX + u * boxW;
  }

  function toScreenY(v) {
    return padY + (yMax - v) * unitH;
  }

  function toNormX(px) {
    return Math.max(0.0, Math.min(1.0, (px - padX) / boxW));
  }

  function toNormY(py) {
    return Math.max(yMin, Math.min(yMax, yMax - ((py - padY) / unitH)));
  }

  function setCoordinates(nx1, ny1, nx2, ny2) {
    root.x1 = Math.max(0.0, Math.min(1.0, nx1));
    root.y1 = Math.max(yMin, Math.min(yMax, ny1));
    root.x2 = Math.max(0.0, Math.min(1.0, nx2));
    root.y2 = Math.max(yMin, Math.min(yMax, ny2));
    canvas.requestPaint();
    root.curveChanged(root.x1, root.y1, root.x2, root.y2);
  }

  onX1Changed: canvas.requestPaint()
  onY1Changed: canvas.requestPaint()
  onX2Changed: canvas.requestPaint()
  onY2Changed: canvas.requestPaint()

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: 14
    spacing: 16

    // =========================================================================
    // SECTION HEADER & TITLE
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Cubic Bézier Eğri Editörü"
        font.family: Style.fontText
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Style.textPrimary
      }

      Item { Layout.fillWidth: true }

      Rectangle {
        height: 24
        implicitWidth: cssLabel.implicitWidth + 14
        radius: 6
        color: Style.appBackground
        border.color: Style.appBorder
        border.width: 1

        Text {
          id: cssLabel
          anchors.centerIn: parent
          text: root.cssString
          font.family: "Monospace"
          font.pixelSize: 11
          color: Style.textSecondary
        }
      }
    }

    // =========================================================================
    // MAIN INTERACTIVE AREA: LEFT CANVAS + RIGHT CONTROLS
    // =========================================================================
    RowLayout {
      Layout.fillWidth: true
      spacing: 18

      // -----------------------------------------------------------------------
      // LEFT: INTERACTIVE 2D BEZIER CANVAS (260x260)
      // -----------------------------------------------------------------------
      Rectangle {
        id: canvasArea
        Layout.preferredWidth: 260
        Layout.preferredHeight: 260
        radius: 10
        color: Style.appBackground
        border.color: Style.appBorder
        border.width: 1
        clip: true

        // Canvas Drawing Layer
        Canvas {
          id: canvas
          anchors.fill: parent

          onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            let sX0 = root.toScreenX(0.0);
            let sY0 = root.toScreenY(0.0);
            let sX1 = root.toScreenX(1.0);
            let sY1 = root.toScreenY(1.0);
            let sYMax = root.toScreenY(1.5);
            let sYMin = root.toScreenY(-0.5);

            // 1. Shaded Overshoot & Dip Regions
            ctx.fillStyle = Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.04);
            ctx.fillRect(sX0, sYMax, root.boxW, sY1 - sYMax);

            ctx.fillStyle = Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.04);
            ctx.fillRect(sX0, sY0, root.boxW, sYMin - sY0);

            // 2. Unit Box Grid & Boundary lines
            ctx.lineWidth = 1;
            ctx.strokeStyle = Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.12);
            ctx.strokeRect(sX0, sY1, root.boxW, sY0 - sY1);

            // 3. Horizontal Guide Lines (0.25, 0.5, 0.75, 1.0)
            ctx.strokeStyle = Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.06);
            for (let v = 0.25; v < 1.0; v += 0.25) {
              let gy = root.toScreenY(v);
              ctx.beginPath();
              ctx.moveTo(sX0, gy);
              ctx.lineTo(sX1, gy);
              ctx.stroke();
            }

            // Target 100% (y = 1.0) Dash Guideline
            ctx.strokeStyle = Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.35);
            ctx.beginPath();
            ctx.setLineDash([4, 4]);
            ctx.moveTo(sX0 - 15, sY1);
            ctx.lineTo(sX1 + 15, sY1);
            ctx.stroke();

            // Start 0% (y = 0.0) Dash Guideline
            ctx.strokeStyle = Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.25);
            ctx.beginPath();
            ctx.moveTo(sX0 - 15, sY0);
            ctx.lineTo(sX1 + 15, sY0);
            ctx.stroke();
            ctx.setLineDash([]); // Reset dash

            // 4. Tangent Arms (P0 -> P1, P3 -> P2)
            let p1Sx = root.toScreenX(root.x1);
            let p1Sy = root.toScreenY(root.y1);
            let p2Sx = root.toScreenX(root.x2);
            let p2Sy = root.toScreenY(root.y2);

            // Arm 1 (Cyan)
            ctx.lineWidth = 1.8;
            ctx.strokeStyle = Style.accentCyan;
            ctx.beginPath();
            ctx.moveTo(sX0, sY0);
            ctx.lineTo(p1Sx, p1Sy);
            ctx.stroke();

            // Arm 2 (Orange)
            ctx.strokeStyle = Style.accentOrange;
            ctx.beginPath();
            ctx.moveTo(sX1, sY1);
            ctx.lineTo(p2Sx, p2Sy);
            ctx.stroke();

            // 5. Cubic Bézier Curve (Accent Tint)
            ctx.lineWidth = 3.2;
            ctx.strokeStyle = Style.accent;
            ctx.beginPath();
            ctx.moveTo(sX0, sY0);
            ctx.bezierCurveTo(p1Sx, p1Sy, p2Sx, p2Sy, sX1, sY1);
            ctx.stroke();

            // 6. Fixed Base Points (P0 and P3)
            ctx.fillStyle = Style.textMuted;
            ctx.beginPath();
            ctx.arc(sX0, sY0, 4, 0, 2 * Math.PI);
            ctx.fill();

            ctx.beginPath();
            ctx.arc(sX1, sY1, 4, 0, 2 * Math.PI);
            ctx.fill();
          }
        }

        // ---------------------------------------------------------------------
        // CANVAS DRAG AREA: Click or drag anywhere on canvas to move nearest point
        // ---------------------------------------------------------------------
        MouseArea {
          id: canvasDragArea
          anchors.fill: parent
          preventStealing: true
          cursorShape: Qt.CrossCursor

          property int activePoint: 0

          function updateCoord(mx, my) {
            if (activePoint === 1) {
              root.x1 = root.toNormX(mx);
              root.y1 = root.toNormY(my);
            } else if (activePoint === 2) {
              root.x2 = root.toNormX(mx);
              root.y2 = root.toNormY(my);
            }
            canvas.requestPaint();
            root.curveChanged(root.x1, root.y1, root.x2, root.y2);
          }

          onPressed: mouse => {
            let p1Sx = root.toScreenX(root.x1);
            let p1Sy = root.toScreenY(root.y1);
            let p2Sx = root.toScreenX(root.x2);
            let p2Sy = root.toScreenY(root.y2);

            let d1 = Math.hypot(mouse.x - p1Sx, mouse.y - p1Sy);
            let d2 = Math.hypot(mouse.x - p2Sx, mouse.y - p2Sy);

            activePoint = (d1 <= d2) ? 1 : 2;
            updateCoord(mouse.x, mouse.y);
          }

          onPositionChanged: mouse => {
            if (pressed && activePoint > 0) {
              updateCoord(mouse.x, mouse.y);
            }
          }

          onReleased: {
            activePoint = 0;
          }
        }

        // ---------------------------------------------------------------------
        // DRAGGABLE HANDLE 1: P1 (Start Tangent Point - Cyan)
        // ---------------------------------------------------------------------
        Rectangle {
          id: handle1
          z: 2
          x: root.toScreenX(root.x1) - (width / 2)
          y: root.toScreenY(root.y1) - (height / 2)
          width: 18
          height: 18
          radius: 9
          color: Style.appBackground
          border.color: Style.accentCyan
          border.width: 2.5

          Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: Style.accentCyan
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -12
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: mouse => {
              let mapped = mapToItem(canvasArea, mouse.x, mouse.y);
              root.x1 = root.toNormX(mapped.x);
              root.y1 = root.toNormY(mapped.y);
              canvas.requestPaint();
              root.curveChanged(root.x1, root.y1, root.x2, root.y2);
            }

            onPositionChanged: mouse => {
              if (pressed) {
                let mapped = mapToItem(canvasArea, mouse.x, mouse.y);
                root.x1 = root.toNormX(mapped.x);
                root.y1 = root.toNormY(mapped.y);
                canvas.requestPaint();
                root.curveChanged(root.x1, root.y1, root.x2, root.y2);
              }
            }
          }
        }

        // ---------------------------------------------------------------------
        // DRAGGABLE HANDLE 2: P2 (End Tangent Point - Orange)
        // ---------------------------------------------------------------------
        Rectangle {
          id: handle2
          z: 2
          x: root.toScreenX(root.x2) - (width / 2)
          y: root.toScreenY(root.y2) - (height / 2)
          width: 18
          height: 18
          radius: 9
          color: Style.appBackground
          border.color: Style.accentOrange
          border.width: 2.5

          Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: Style.accentOrange
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -12
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            preventStealing: true

            onPressed: mouse => {
              let mapped = mapToItem(canvasArea, mouse.x, mouse.y);
              root.x2 = root.toNormX(mapped.x);
              root.y2 = root.toNormY(mapped.y);
              canvas.requestPaint();
              root.curveChanged(root.x1, root.y1, root.x2, root.y2);
            }

            onPositionChanged: mouse => {
              if (pressed) {
                let mapped = mapToItem(canvasArea, mouse.x, mouse.y);
                root.x2 = root.toNormX(mapped.x);
                root.y2 = root.toNormY(mapped.y);
                canvas.requestPaint();
                root.curveChanged(root.x1, root.y1, root.x2, root.y2);
              }
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // RIGHT: FINE-TUNING CONTROLS, PRESETS & SANDBOX PREVIEW
      // -----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        // PRESET CHIPS GRID
        Text {
          text: "Hazır Şablonlar"
          font.family: Style.fontText
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Style.textMuted
        }

        Flow {
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: [
              { "name": "Ease",        "pts": [0.25, 0.10, 0.25, 1.00] },
              { "name": "Linear",      "pts": [0.00, 0.00, 1.00, 1.00] },
              { "name": "Ease Out",    "pts": [0.00, 0.00, 0.58, 1.00] },
              { "name": "Ease In Out", "pts": [0.42, 0.00, 0.58, 1.00] },
              { "name": "Snappy",      "pts": [0.15, 0.00, 0.05, 1.00] },
              { "name": "macOS",       "pts": [0.23, 1.00, 0.32, 1.00] },
              { "name": "Overshoot",   "pts": [0.05, 0.90, 0.10, 1.10] },
              { "name": "Bouncy Pop",  "pts": [0.34, 1.56, 0.64, 1.00] }
            ]

            delegate: Rectangle {
              height: 24
              implicitWidth: chipText.implicitWidth + 14
              radius: 6
              color: chipMouse.containsMouse ? Style.surfaceHover : Style.surfaceVariant
              border.color: chipMouse.containsMouse ? Style.borderHover : Style.appBorder
              border.width: 1

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on border.color { ColorAnimation { duration: 120 } }

              Text {
                id: chipText
                anchors.centerIn: parent
                text: modelData.name
                font.family: Style.fontText
                font.pixelSize: 10
                font.weight: Font.Medium
                color: chipMouse.containsMouse ? Style.accent : Style.textPrimary
              }

              MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.setCoordinates(modelData.pts[0], modelData.pts[1], modelData.pts[2], modelData.pts[3]);
                }
              }
            }
          }
        }

        // P1 & P2 Coordinate Readout
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 7
            color: Style.appBackground

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 6

              Text {
                text: "P1"
                font.family: Style.fontText
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Style.accentCyan
              }

              Text {
                text: root.x1.toFixed(2) + ", " + root.y1.toFixed(2)
                font.family: "Monospace"
                font.pixelSize: 11
                color: Style.textPrimary
                Layout.fillWidth: true
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 7
            color: Style.appBackground

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 6

              Text {
                text: "P2"
                font.family: Style.fontText
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Style.accentOrange
              }

              Text {
                text: root.x2.toFixed(2) + ", " + root.y2.toFixed(2)
                font.family: "Monospace"
                font.pixelSize: 11
                color: Style.textPrimary
                Layout.fillWidth: true
              }
            }
          }
        }

        // Live Animation Sandbox
        Rectangle {
          Layout.fillWidth: true
          height: 48
          radius: 8
          color: Style.appBackground
          border.color: Style.appBorder
          border.width: 1
          clip: true

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            Item {
              id: testTrack
              Layout.fillWidth: true
              height: 24

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                radius: 1
                color: Style.surfaceVariant
              }

              Rectangle {
                id: testRunner
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 5
                color: Style.accent

                NumberAnimation {
                  id: runnerAnim
                  target: testRunner
                  property: "x"
                  from: 0
                  to: testTrack.width - testRunner.width
                  duration: root.testDuration
                  easing.type: Easing.BezierSpline
                  easing.bezierCurve: [root.x1, root.y1, root.x2, root.y2, 1.0, 1.0]
                }
              }
            }

            SettingsButton {
              text: "Test"
              iconText: "󰐊"
              onClicked: {
                testRunner.x = 0;
                runnerAnim.restart();

                if (root.ipc) {
                  let previewLua = "hl.curve(\"__preview__\", { type = \"bezier\", points = { { " + root.x1.toFixed(3) + ", " + root.y1.toFixed(3) + " }, { " + root.x2.toFixed(3) + ", " + root.y2.toFixed(3) + " } } }); hl.animation({ leaf = \"windows\", bezier = \"__preview__\" })";
                  root.ipc.previewHyprEval(previewLua);
                }
              }
            }
          }
        }

        // Save Custom Curve
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: Style.appBackground
            border.color: nameInput.activeFocus ? Style.accent : Style.appBorder
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 6

              Text {
                text: "󰓹"
                font.pixelSize: 12
                color: Style.textMuted
              }

              TextInput {
                id: nameInput
                Layout.fillWidth: true
                text: root.curveName
                font.family: Style.fontText
                font.pixelSize: 12
                color: Style.textPrimary
                clip: true
                selectByMouse: true
                onTextChanged: root.curveName = text
              }
            }
          }

          SettingsButton {
            text: saveFeedbackTimer.running ? "Kaydedildi" : "Kaydet"
            iconText: saveFeedbackTimer.running ? "󰄬" : "󰆓"
            isAccent: true
            onClicked: {
              let name = root.curveName.trim() || "custom_curve";
              let pts = [
                [root.x1, root.y1],
                [root.x2, root.y2]
              ];

              if (root.ipc) {
                root.ipc.saveCustomCurve(name, pts);
              }
              saveFeedbackTimer.restart();
              root.curveSaved(name, root.x1, root.y1, root.x2, root.y2);
            }
          }

          Timer {
            id: saveFeedbackTimer
            interval: 2200
          }
        }
      }
    }
  }

  Component.onCompleted: {
    canvas.requestPaint();
  }
}
