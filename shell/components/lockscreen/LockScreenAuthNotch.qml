import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../.."

Item {
  id: root

  required property var ipc

  // Reactive Morph State: IDLE (only lock icon) -> TYPING (sleek single-line password notch)
  readonly property bool isExpanded: LockScreenService.inputExpanded || LockScreenService.authenticating || LockScreenService.passwordText.length > 0 || LockScreenService.errorMessage.length > 0
  readonly property bool hasError: LockScreenService.errorMessage.length > 0
  property real shakeOffset: 0

  // Sleek, Notch-Native Dimensions (Matches DynamicIsland idle height & proportions)
  readonly property int idleW: 96
  readonly property int idleH: Config.isNotch ? Math.max(28, Config.notchIdleHeight) : Math.max(32, Config.islandIdleHeight)
  readonly property int expandedW: 284
  readonly property int expandedH: Config.isNotch ? 44 : 46

  // Smooth Border & Corner Radius Matching DynamicIsland.qml
  readonly property real targetRadius: {
    if (Config.isNotch) {
      let rawR = isExpanded ? Math.min(20, Config.notchBottomRadius) : Math.min(14, Config.notchBottomRadius)
      return Math.min(rawR, height * 0.48)
    }
    return height * 0.5
  }

  readonly property real notchEarW: 5
  readonly property real notchEarH: Math.min(16, height * 0.45)

  width: isExpanded ? expandedW : idleW
  height: isExpanded ? expandedH : idleH

  // Silky-Smooth Easing (No harsh spring slam or mechanical bounce)
  Behavior on width {
    NumberAnimation {
      duration: root.isExpanded ? 360 : 300
      easing.type: Easing.OutQuart
    }
  }
  Behavior on height {
    NumberAnimation {
      duration: root.isExpanded ? 360 : 300
      easing.type: Easing.OutQuart
    }
  }

  // Gentle, understated horizontal shake on wrong password
  SequentialAnimation {
    id: shakeAnim
    NumberAnimation { target: root; property: "shakeOffset"; to: -7; duration: 55; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: 7; duration: 65; easing.type: Easing.InOutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: -4; duration: 55; easing.type: Easing.InOutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: 4; duration: 50; easing.type: Easing.InOutCubic }
    NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 55; easing.type: Easing.OutCubic }
  }

  // Auto-collapse smoothly back to lock-icon-only state when input is cleared
  Timer {
    id: idleCollapseTimer
    interval: 1100
    repeat: false
    onTriggered: {
      if (LockScreenService.passwordText.length === 0 && !LockScreenService.authenticating && LockScreenService.errorMessage.length === 0) {
        LockScreenService.inputExpanded = false
      }
    }
  }

  // Softly clear transient error tint if user pauses without typing
  Timer {
    id: errorResetTimer
    interval: 1800
    repeat: false
    onTriggered: {
      if (LockScreenService.passwordText.length === 0 && !LockScreenService.authenticating) {
        LockScreenService.errorMessage = ""
        idleCollapseTimer.restart()
      }
    }
  }

  // Multi-stage focus guarantee for Wayland WlSessionLockSurface keyboard grab
  Timer {
    id: focusRetryTimer
    interval: 35
    repeat: true
    running: false
    property int attempts: 0
    onTriggered: {
      attempts++
      passwordInput.forceActiveFocus()
      if (passwordInput.activeFocus || attempts >= 20) {
        stop()
      }
    }
  }

  function grabPasswordFocus() {
    focusRetryTimer.attempts = 0
    passwordInput.forceActiveFocus()
    focusRetryTimer.restart()
  }

  Component.onCompleted: {
    grabPasswordFocus()
  }

  Connections {
    target: LockScreenService

    function onAuthFailedCountChanged() {
      if (LockScreenService.authFailedCount > 0) {
        shakeAnim.restart()
        errorResetTimer.restart()
        grabPasswordFocus()
      }
    }

    function onPasswordTextChanged() {
      if (passwordInput.text !== LockScreenService.passwordText) {
        passwordInput.text = LockScreenService.passwordText
        passwordInput.cursorPosition = passwordInput.text.length
      }
      if (LockScreenService.passwordText.length > 0) {
        idleCollapseTimer.stop()
        errorResetTimer.stop()
      } else if (LockScreenService.inputExpanded && !LockScreenService.authenticating && LockScreenService.errorMessage.length === 0) {
        idleCollapseTimer.restart()
      }
    }

    function onLockedChanged() {
      if (LockScreenService.locked) {
        passwordInput.text = ""
        grabPasswordFocus()
      }
    }
  }

  // =========================================================================
  // PURE OLED BLACK SILHOUETTE (Exact DynamicIsland / DynamicNotch DNA)
  // =========================================================================
  Item {
    id: notchBody
    anchors.fill: parent
    transform: Translate { x: root.shakeOffset }

    // -----------------------------------------------------------------------
    // SURFACE 1: Dynamic Notch Mode (Borderless G2 Bezier Top-Bezel Shape)
    // -----------------------------------------------------------------------
    RectangularGlow {
      anchors.fill: parent
      anchors.topMargin: Config.shadowsEnabled ? Config.shadowVerticalOffset : 0
      anchors.bottomMargin: Config.shadowsEnabled ? -Config.shadowVerticalOffset : 0
      glowRadius: Config.shadowsEnabled ? (root.isExpanded ? 26 : Config.shadowBlurRadius) : 0
      spread: Config.shadowSpread
      color: Qt.rgba(0, 0, 0, Config.shadowsEnabled ? Config.shadowOpacity : 0)
      cornerRadius: root.targetRadius + glowRadius
      visible: Config.isNotch && Config.shadowsEnabled && Config.shadowNotch
      z: -1

      Behavior on glowRadius {
        NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
      }
    }

    Shape {
      id: notchVectorShape
      anchors.fill: parent
      anchors.leftMargin: -root.notchEarW
      anchors.rightMargin: -root.notchEarW
      visible: Config.isNotch
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: Style.bgPrimary
        startX: 0
        startY: 0

        PathCubic {
          control1X: root.notchEarW * 0.35
          control1Y: 0
          control2X: root.notchEarW
          control2Y: root.notchEarH * 0.65
          x: root.notchEarW
          y: root.notchEarH
        }
        PathLine {
          x: root.notchEarW
          y: root.height - root.targetRadius
        }
        PathArc {
          x: root.notchEarW + root.targetRadius
          y: root.height
          radiusX: root.targetRadius
          radiusY: root.targetRadius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: root.notchEarW + root.width - root.targetRadius
          y: root.height
        }
        PathArc {
          x: root.notchEarW + root.width
          y: root.height - root.targetRadius
          radiusX: root.targetRadius
          radiusY: root.targetRadius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: root.notchEarW + root.width
          y: root.notchEarH
        }
        PathCubic {
          control1X: root.notchEarW + root.width
          control1Y: root.notchEarH * 0.65
          control2X: root.notchEarW + root.width + root.notchEarW * 0.65
          control2Y: 0
          x: root.notchEarW * 2 + root.width
          y: 0
        }
        PathLine {
          x: 0
          y: 0
        }
      }
    }

    // -----------------------------------------------------------------------
    // SURFACE 2: Dynamic Island Mode (Borderless Pure OLED Black Pill)
    // -----------------------------------------------------------------------
    RectangularGlow {
      anchors.fill: islandSquircle
      anchors.topMargin: Config.shadowsEnabled ? Config.shadowVerticalOffset : 0
      anchors.bottomMargin: Config.shadowsEnabled ? -Config.shadowVerticalOffset : 0
      glowRadius: Config.shadowsEnabled ? (root.isExpanded ? 26 : Config.shadowBlurRadius) : 0
      spread: Config.shadowSpread
      color: Qt.rgba(0, 0, 0, Config.shadowsEnabled ? Config.shadowOpacity : 0)
      cornerRadius: root.targetRadius + glowRadius
      visible: !Config.isNotch && Config.shadowsEnabled && Config.shadowIsland
      z: -1

      Behavior on glowRadius {
        NumberAnimation { duration: 340; easing.type: Easing.OutCubic }
      }
    }

    Rectangle {
      id: islandSquircle
      anchors.fill: parent
      visible: !Config.isNotch
      radius: root.targetRadius
      color: Style.bgPrimary
    }

    // =======================================================================
    // CLICK TO EXPAND WHEN IDLE
    // =======================================================================
    MouseArea {
      anchors.fill: parent
      enabled: !root.isExpanded
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        LockScreenService.expandInput()
        root.grabPasswordFocus()
      }
    }

    // =======================================================================
    // LAYER A: IDLE STATE — Pure Minimal Centered Lock Icon Only
    // =======================================================================
    Item {
      id: idleLockLayer
      anchors.fill: parent
      opacity: root.isExpanded ? 0.0 : 1.0
      scale: root.isExpanded ? 0.85 : 1.0
      visible: opacity > 0.01

      Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
      }

      Text {
        anchors.centerIn: parent
        text: "󰌾"
        font.pixelSize: 14
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.86)
      }
    }

    // =======================================================================
    // LAYER B: TYPING STATE — Single Continuous Pure-Black Input Row
    // Always mounted & visible:true (clipped + opacity) for zero-drop typing
    // =======================================================================
    Item {
      id: expandedInputLayer
      anchors.fill: parent
      clip: true
      opacity: root.isExpanded ? 1.0 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 10
        spacing: 10

        // Minimal Status / Lock Icon (subtly turns red on error, spins on PAM verify)
        Text {
          Layout.alignment: Qt.AlignVCenter
          text: LockScreenService.authenticating ? "󰔟" : (root.hasError ? "󰌿" : "󰌾")
          font.pixelSize: 15
          color: {
            if (root.hasError) return Style.accentRed
            if (LockScreenService.authenticating) return Style.accent
            return Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.72)
          }

          Behavior on color { ColorAnimation { duration: 180 } }

          RotationAnimation on rotation {
            running: LockScreenService.authenticating
            from: 0
            to: 360
            duration: 950
            loops: Animation.Infinite
          }
        }

        // Direct Borderless Password Input (** characters, single continuous canvas)
        TextInput {
          id: passwordInput
          Layout.fillWidth: true
          Layout.fillHeight: true
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignLeft
          focus: true
          enabled: !LockScreenService.authenticating
          echoMode: TextInput.Password
          passwordCharacter: "*"
          color: root.hasError ? Style.accentRed : Style.textPrimary
          selectionColor: Style.surfaceActive
          selectedTextColor: Style.textPrimary
          font.family: Style.fontDisplay
          font.pixelSize: 18
          font.weight: Font.DemiBold
          font.letterSpacing: 3.5
          cursorVisible: root.isExpanded && activeFocus && !LockScreenService.authenticating
          clip: true

          onTextEdited: {
            LockScreenService.setPasswordText(text)
          }

          Keys.onReturnPressed: {
            LockScreenService.submitPassword()
          }
          Keys.onEnterPressed: {
            LockScreenService.submitPassword()
          }
          Keys.onEscapePressed: {
            LockScreenService.resetInput()
          }
          Keys.onPressed: event => {
            if (event.key === Qt.Key_CapsLock) {
              LockScreenService.capsLockOn = !LockScreenService.capsLockOn
            }
          }

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: root.hasError ? "Hatalı parola" : (LockScreenService.capsLockOn ? "Caps Lock açık" : "Parola")
            font.family: Style.fontText
            font.pixelSize: 12
            font.letterSpacing: 0.3
            color: root.hasError
              ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.85)
              : (LockScreenService.capsLockOn ? Style.accentYellow : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.34))
            visible: passwordInput.text.length === 0 && !passwordInput.inputMethodComposing
          }
        }

        // Minimal Circular Submit Control (Softly appears once typing starts)
        Rectangle {
          Layout.preferredWidth: 26
          Layout.preferredHeight: 26
          Layout.alignment: Qt.AlignVCenter
          radius: 13
          opacity: (LockScreenService.passwordText.length > 0 && !LockScreenService.authenticating) ? 1.0 : 0.0
          scale: submitMouse.pressed ? 0.90 : ((LockScreenService.passwordText.length > 0 && !LockScreenService.authenticating) ? 1.0 : 0.78)
          color: submitMouse.containsMouse
            ? Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.24)
            : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.14)

          Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 140 } }

          Text {
            anchors.centerIn: parent
            text: "󰁔"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }

          MouseArea {
            id: submitMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: LockScreenService.passwordText.length > 0 && !LockScreenService.authenticating
            cursorShape: Qt.PointingHandCursor
            onClicked: LockScreenService.submitPassword()
          }
        }
      }
    }
  }
}
