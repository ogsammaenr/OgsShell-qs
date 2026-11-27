import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.UPower
import "../.."

Item {
  id: root

  required property var ipc

  // Reactive Morph State: IDLE (only lock icon) -> EXPANDED (typing / auth / error)
  readonly property bool isExpanded: LockScreenService.inputExpanded || LockScreenService.authenticating || LockScreenService.passwordText.length > 0 || LockScreenService.errorMessage.length > 0
  readonly property bool hasError: LockScreenService.errorMessage.length > 0
  property bool showPassword: false
  property real shakeOffset: 0

  // Geometry Targets (Reactive to Config.formFactor)
  readonly property int idleW: 112
  readonly property int idleH: Config.isNotch ? 34 : 38
  readonly property int expandedW: Config.isNotch ? Math.max(460, Config.notchExpandedWidth) : Math.max(460, Config.islandExpandedWidth)
  readonly property int expandedH: 142

  property real activeRadius: {
    if (Config.isNotch) {
      let rawR = isExpanded ? Math.max(24, Config.notchBottomRadiusExpanded) : Math.min(18, Config.notchBottomRadius)
      return Math.min(rawR, height * 0.48)
    }
    return isExpanded ? Math.max(26, Config.islandRadiusExpanded) : 19
  }

  readonly property real notchEarW: isExpanded ? 10 : 5
  readonly property real notchEarH: Math.min(isExpanded ? 24 : 16, height * 0.45)

  // Live Telemetry Bindings
  readonly property string keyboardShortCode: (ipc && ipc.keyboardLayout && ipc.keyboardLayout.current_short_code) ? ipc.keyboardLayout.current_short_code.toUpperCase() : "TR"
  readonly property bool wifiConnected: !!(ipc && ipc.wifi && ipc.wifi.connected)
  readonly property bool btPowered: !!(ipc && ipc.bluetooth && ipc.bluetooth.adapter_powered)
  readonly property var batteryDev: (UPower && UPower.displayDevice) ? UPower.displayDevice : null
  readonly property bool hasBattery: !!(batteryDev && batteryDev.ready && batteryDev.isLaptopBattery)
  readonly property int batteryPercent: hasBattery ? Math.round((batteryDev.percentage || 0) * 100) : 0
  readonly property bool batteryCharging: hasBattery && (batteryDev.state === UPowerDeviceState.Charging || batteryDev.state === UPowerDeviceState.PendingCharge)

  width: isExpanded ? expandedW : idleW
  height: isExpanded ? expandedH : idleH

  // Mandatory SpringAnimation Physics per AGENTS.md
  Behavior on width {
    SpringAnimation {
      spring: 28.0
      damping: 0.78
      epsilon: 0.01
    }
  }
  Behavior on height {
    SpringAnimation {
      spring: 28.0
      damping: 0.78
      epsilon: 0.01
    }
  }
  Behavior on activeRadius {
    SpringAnimation {
      spring: 28.0
      damping: 0.78
      epsilon: 0.01
    }
  }

  // Horizontal Shake on Failed PAM Auth
  SequentialAnimation {
    id: shakeAnim
    NumberAnimation { target: root; property: "shakeOffset"; to: -12; duration: 48; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: 12; duration: 56; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: 52; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 48; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: -4; duration: 42; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 42; easing.type: Easing.OutQuad }
  }

  // Auto-collapse back to compact lock-icon-only state when password is erased
  Timer {
    id: idleCollapseTimer
    interval: 1200
    repeat: false
    onTriggered: {
      if (LockScreenService.passwordText.length === 0 && !LockScreenService.authenticating && LockScreenService.errorMessage.length === 0) {
        LockScreenService.inputExpanded = false
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

  // Synchronize shared service password state & shake triggers across monitors
  Connections {
    target: LockScreenService

    function onAuthFailedCountChanged() {
      if (LockScreenService.authFailedCount > 0) {
        shakeAnim.restart()
        grabPasswordFocus()
      }
    }

    function onPasswordTextChanged() {
      if (passwordInput.text !== LockScreenService.passwordText) {
        passwordInput.text = LockScreenService.passwordText
        passwordInput.cursorPosition = passwordInput.text.length
      }
      if (LockScreenService.passwordText.length === 0 && LockScreenService.inputExpanded && !LockScreenService.authenticating && LockScreenService.errorMessage.length === 0) {
        idleCollapseTimer.restart()
      } else {
        idleCollapseTimer.stop()
      }
    }

    function onLockedChanged() {
      if (LockScreenService.locked) {
        root.showPassword = false
        passwordInput.text = ""
        grabPasswordFocus()
      }
    }
  }

  // =========================================================================
  // SURFACE CONTAINER (Translated horizontally by shakeOffset)
  // =========================================================================
  Item {
    id: notchBody
    anchors.fill: parent
    transform: Translate { x: root.shakeOffset }

    // -----------------------------------------------------------------------
    // SURFACE 1: Dynamic Notch Mode (G2 Cubic Bezier Top-Bezel Attachment)
    // -----------------------------------------------------------------------
    RectangularGlow {
      anchors.fill: notchVectorShape
      anchors.leftMargin: root.notchEarW
      anchors.rightMargin: root.notchEarW
      anchors.topMargin: Config.shadowsEnabled ? (root.isExpanded ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
      anchors.bottomMargin: Config.shadowsEnabled ? -(root.isExpanded ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
      glowRadius: Config.shadowsEnabled ? (root.isExpanded ? Config.shadowExpandedBlurRadius : Config.shadowBlurRadius) : 0
      spread: Config.shadowSpread
      color: Qt.rgba(0, 0, 0, Config.shadowsEnabled ? (root.isExpanded ? Config.shadowExpandedOpacity : Config.shadowOpacity) : 0)
      cornerRadius: root.activeRadius + glowRadius
      visible: Config.isNotch && Config.shadowsEnabled && Config.shadowNotch
      z: -1
    }

    Shape {
      id: notchVectorShape
      anchors.fill: parent
      anchors.leftMargin: -root.notchEarW
      anchors.rightMargin: -root.notchEarW
      visible: Config.isNotch
      preferredRendererType: Shape.CurveRenderer

      // Pure OLED Black Solid Fill
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
          y: root.height - root.activeRadius
        }
        PathArc {
          x: root.notchEarW + root.activeRadius
          y: root.height
          radiusX: root.activeRadius
          radiusY: root.activeRadius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: root.notchEarW + root.width - root.activeRadius
          y: root.height
        }
        PathArc {
          x: root.notchEarW + root.width
          y: root.height - root.activeRadius
          radiusX: root.activeRadius
          radiusY: root.activeRadius
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

      // Subtle Bottom Specular Rim Hairline
      ShapePath {
        strokeWidth: 1
        strokeColor: root.hasError
          ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.45)
          : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, root.isExpanded ? 0.13 : 0.08)
        fillColor: "transparent"
        startX: root.notchEarW + 0.5
        startY: root.height - root.activeRadius

        PathArc {
          x: root.notchEarW + root.activeRadius
          y: root.height - 0.5
          radiusX: Math.max(1, root.activeRadius - 0.5)
          radiusY: Math.max(1, root.activeRadius - 0.5)
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: root.notchEarW + root.width - root.activeRadius
          y: root.height - 0.5
        }
        PathArc {
          x: root.notchEarW + root.width - 0.5
          y: root.height - root.activeRadius
          radiusX: Math.max(1, root.activeRadius - 0.5)
          radiusY: Math.max(1, root.activeRadius - 0.5)
          direction: PathArc.Counterclockwise
        }
      }
    }

    // -----------------------------------------------------------------------
    // SURFACE 2: Dynamic Island Mode (Floating Pure OLED Black Capsule)
    // -----------------------------------------------------------------------
    RectangularGlow {
      anchors.fill: islandSquircle
      anchors.topMargin: Config.shadowsEnabled ? (root.isExpanded ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
      anchors.bottomMargin: Config.shadowsEnabled ? -(root.isExpanded ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
      glowRadius: Config.shadowsEnabled ? (root.isExpanded ? Config.shadowExpandedBlurRadius : Config.shadowBlurRadius) : 0
      spread: Config.shadowSpread
      color: Qt.rgba(0, 0, 0, Config.shadowsEnabled ? (root.isExpanded ? Config.shadowExpandedOpacity : Config.shadowOpacity) : 0)
      cornerRadius: root.activeRadius + glowRadius
      visible: !Config.isNotch && Config.shadowsEnabled && Config.shadowIsland
      z: -1
    }

    Rectangle {
      id: islandSquircle
      anchors.fill: parent
      visible: !Config.isNotch
      radius: root.activeRadius
      color: Style.bgPrimary
      border.width: 1
      border.color: root.hasError
        ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.45)
        : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, root.isExpanded ? 0.14 : 0.10)
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
    // LAYER A: IDLE STATE — Pure Minimal Lock Icon Only
    // =======================================================================
    Item {
      id: idleLockLayer
      anchors.fill: parent
      opacity: root.isExpanded ? 0.0 : 1.0
      visible: opacity > 0.01

      Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      Text {
        anchors.centerIn: parent
        text: "󰌾"
        font.pixelSize: 16
        color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.90)
      }
    }

    // =======================================================================
    // LAYER B: EXPANDED AUTH STATE — Design #6 Password & Status Hub
    // NOTE: Always kept visible:true (clipped & opacity-animated) so passwordInput
    // captures the VERY FIRST keystroke seamlessly without losing a character!
    // =======================================================================
    Item {
      id: expandedAuthLayer
      anchors.fill: parent
      clip: true
      opacity: root.isExpanded ? 1.0 : 0.0

      Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 15
        anchors.bottomMargin: 13
        spacing: 12

        // -------------------------------------------------------------------
        // Row 1: User Identity + Status | Keyboard Layout + Wi-Fi + BT + Bat
        // -------------------------------------------------------------------
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: LockScreenService.authenticating ? "󰦖" : (root.hasError ? "󰌿" : "󰌾")
            font.pixelSize: 14
            color: root.hasError ? Style.accentRed : Style.textPrimary
          }

          Text {
            text: LockScreenService.currentUser
            font.family: Style.fontDisplay
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }

          Rectangle {
            width: 3.5
            height: 3.5
            radius: 2
            color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.34)
          }

          Text {
            text: {
              if (LockScreenService.authenticating) return "Doğrulanıyor..."
              if (root.hasError) return LockScreenService.errorMessage
              return "Oturum Kilitli"
            }
            font.family: Style.fontText
            font.pixelSize: 12
            color: root.hasError ? Style.accentRed : Style.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          // Right Connectivity & Layout Cluster
          RowLayout {
            spacing: 10

            // Clickable Keyboard Layout Badge (TR / US)
            Rectangle {
              implicitWidth: Math.max(26, kbText.implicitWidth + 10)
              implicitHeight: 19
              radius: 6
              color: kbMouse.containsMouse
                ? Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.18)
                : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.10)

              Text {
                id: kbText
                anchors.centerIn: parent
                text: root.keyboardShortCode
                font.family: Style.fontDisplay
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Style.textPrimary
              }

              MouseArea {
                id: kbMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.ipc && root.ipc.switchKeyboardLayout) {
                    root.ipc.switchKeyboardLayout("next")
                  }
                  root.grabPasswordFocus()
                }
              }
            }

            // Wi-Fi Status Glyph
            Text {
              text: root.wifiConnected ? "󰤨" : "󰤭"
              font.pixelSize: 14
              color: root.wifiConnected
                ? Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.88)
                : Style.textMuted
            }

            // Bluetooth Status Glyph
            Text {
              text: root.btPowered ? "󰂯" : "󰂲"
              font.pixelSize: 14
              color: root.btPowered
                ? Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.80)
                : Style.textMuted
            }

            // Battery Status (Hidden gracefully on battery-less desktop PCs)
            RowLayout {
              visible: root.hasBattery
              spacing: 4

              Text {
                text: {
                  if (root.batteryCharging) return "󰂄"
                  if (root.batteryPercent >= 80) return "󰁹"
                  if (root.batteryPercent >= 50) return "󰁿"
                  if (root.batteryPercent >= 25) return "󰁼"
                  return "󰁺"
                }
                font.pixelSize: 14
                color: (!root.batteryCharging && root.batteryPercent <= 15)
                  ? Style.accentRed
                  : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.88)
              }

              Text {
                text: root.batteryPercent + "%"
                font.family: Style.fontDisplay
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.88)
              }
            }
          }
        }

        // -------------------------------------------------------------------
        // Row 2: Frosted Glass Password Input Capsule (** masked characters)
        // -------------------------------------------------------------------
        Rectangle {
          id: inputCapsule
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          radius: 24
          color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.085)
          border.width: 1
          border.color: {
            if (root.hasError) return Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.65)
            if (LockScreenService.authenticating) return Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.55)
            return Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.24)
          }

          Behavior on border.color { ColorAnimation { duration: 160 } }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.LeftButton
            onPressed: mouse => {
              passwordInput.forceActiveFocus()
              mouse.accepted = false
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 6
            spacing: 10

            // Native Password TextInput (Always mounted for instant zero-click typing)
            TextInput {
              id: passwordInput
              Layout.fillWidth: true
              Layout.fillHeight: true
              verticalAlignment: TextInput.AlignVCenter
              focus: true
              enabled: !LockScreenService.authenticating
              echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
              passwordCharacter: "*"
              color: Style.textPrimary
              selectionColor: Style.surfaceActive
              selectedTextColor: Style.textPrimary
              font.family: Style.fontDisplay
              font.pixelSize: root.showPassword ? 14 : 20
              font.weight: root.showPassword ? Font.Medium : Font.Bold
              font.letterSpacing: root.showPassword ? 0.3 : 4.5
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
                text: "Parola..."
                font.family: Style.fontText
                font.pixelSize: 13
                font.letterSpacing: 0.2
                color: Style.textMuted
                visible: passwordInput.text.length === 0 && !passwordInput.inputMethodComposing
              }
            }

            // Show / Hide Password Toggle
            Item {
              Layout.preferredWidth: 30
              Layout.preferredHeight: 30

              Text {
                anchors.centerIn: parent
                text: root.showPassword ? "󰈉" : "󰈈"
                font.pixelSize: 16
                color: eyeMouse.containsMouse ? Style.textPrimary : Style.textMuted
                Behavior on color { ColorAnimation { duration: 120 } }
              }

              MouseArea {
                id: eyeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.showPassword = !root.showPassword
                  root.grabPasswordFocus()
                }
              }
            }

            // Circular High-Contrast Submit Button
            Rectangle {
              Layout.preferredWidth: 36
              Layout.preferredHeight: 36
              radius: 18
              color: LockScreenService.authenticating
                ? Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.24)
                : (submitMouse.containsMouse ? "#ffffff" : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.92))
              scale: submitMouse.pressed ? 0.92 : 1.0

              Behavior on scale { NumberAnimation { duration: 100 } }
              Behavior on color { ColorAnimation { duration: 120 } }

              Text {
                anchors.centerIn: parent
                text: LockScreenService.authenticating ? "󰔟" : "󰁔"
                font.pixelSize: 17
                font.weight: Font.Bold
                color: LockScreenService.authenticating ? Style.textPrimary : "#000000"

                RotationAnimation on rotation {
                  running: LockScreenService.authenticating
                  from: 0
                  to: 360
                  duration: 900
                  loops: Animation.Infinite
                }
              }

              MouseArea {
                id: submitMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !LockScreenService.authenticating
                cursorShape: Qt.PointingHandCursor
                onClicked: LockScreenService.submitPassword()
              }
            }
          }
        }

        // -------------------------------------------------------------------
        // Row 3: Subtle Micro-Hint / Caps Lock Indicator
        // -------------------------------------------------------------------
        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: {
            if (LockScreenService.capsLockOn) return "Caps Lock Açık · Enter ile doğrulayın"
            if (LockScreenService.authenticating) return "Kimlik doğrulanıyor..."
            if (root.hasError) return "Tekrar deneyin · Vazgeçmek için ESC"
            return "Parolanızı girip Enter'a basın"
          }
          font.family: Style.fontText
          font.pixelSize: 11
          color: LockScreenService.capsLockOn
            ? Style.accentYellow
            : (root.hasError ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.85) : Style.textMuted)
        }
      }
    }
  }
}
