import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../.."
import "../corners"

FocusScope {
  id: root

  required property var screen
  required property var ipc

  focus: true

  // Silky Entrance Reveal State (animates smoothly from 0 -> 1 upon lock)
  property real revealProgress: 0.0

  // Live Clock & Turkish Date State
  property string timeText: ""
  property string dateText: ""

  readonly property var turkishMonths: [
    "OCAK", "ŞUBAT", "MART", "NİSAN", "MAYIS", "HAZİRAN",
    "TEMMUZ", "AĞUSTOS", "EYLÜL", "EKİM", "KASIM", "ARALIK"
  ]
  readonly property var turkishDays: [
    "PAZAR", "PAZARTESİ", "SALI", "ÇARŞAMBA", "PERŞEMBE", "CUMA", "CUMARTESİ"
  ]

  function updateClock() {
    let now = new Date()
    let hh = String(now.getHours()).padStart(2, "0")
    let mm = String(now.getMinutes()).padStart(2, "0")
    root.timeText = hh + ":" + mm
    root.dateText = now.getDate() + " " + turkishMonths[now.getMonth()] + " " + turkishDays[now.getDay()] + " · " + now.getFullYear()
  }

  Timer {
    interval: 1000
    running: LockScreenService.locked
    repeat: true
    triggeredOnStart: true
    onTriggered: root.updateClock()
  }

  Component.onCompleted: {
    updateClock()
    revealProgress = 1.0
    authNotch.grabPasswordFocus()
  }

  Behavior on revealProgress {
    NumberAnimation {
      duration: 420
      easing.type: Easing.OutCubic
    }
  }

  // Active Media Player (MPRIS)
  readonly property var activePlayer: {
    if (!Mpris || !Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null
    for (let i = 0; i < Mpris.players.values.length; i++) {
      let p = Mpris.players.values[i]
      if (p && (p.playbackState === MprisPlaybackState.Playing || p.isPlaying)) {
        return p
      }
    }
    return Mpris.players.values[0]
  }
  readonly property bool hasMedia: activePlayer !== null && ((activePlayer.trackTitle && activePlayer.trackTitle.length > 0) || activePlayer.isPlaying)
  readonly property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing || activePlayer.isPlaying) : false
  readonly property string mediaTitle: (activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0) ? activePlayer.trackTitle : "Medya"
  readonly property string mediaArtist: (activePlayer && activePlayer.trackArtist && activePlayer.trackArtist.length > 0) ? activePlayer.trackArtist : (activePlayer && activePlayer.identity ? activePlayer.identity : "")

  // Session Action Runner
  Process {
    id: powerProc
    running: false
  }

  function runPowerCommand(cmd) {
    if (!cmd || cmd.length === 0) return
    powerProc.running = false
    powerProc.command = cmd
    powerProc.running = true
  }

  // =========================================================================
  // 1. LIVE BLURRED SCREENSHOT BACKGROUND (Captured right before lock)
  // =========================================================================
  Rectangle {
    id: fallbackBackdrop
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#0d0e12" }
      GradientStop { position: 0.5; color: "#171920" }
      GradientStop { position: 1.0; color: "#090a0d" }
    }
  }

  Image {
    id: capturedWallpaper
    anchors.fill: parent
    source: {
      let _rev = LockScreenService.captureRevision
      let p = root.screen ? LockScreenService.screenshotPathFor(root.screen.name) : ""
      return p.length > 0 ? ("file://" + p) : ""
    }
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
    cache: false
    smooth: true
    visible: false
  }

  FastBlur {
    id: blurredBackdrop
    anchors.fill: parent
    source: capturedWallpaper
    radius: Math.round(Math.max(0, Math.min(128, Config.lockscreenBlurRadius)) * root.revealProgress)
    transparentBorder: false
    visible: capturedWallpaper.status === Image.Ready
  }

  // Atmospheric Dark Dimming & Vignette Overlay for High-Contrast Typography
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(6 / 255, 7 / 255, 10 / 255, Math.max(0.15, Math.min(0.85, Config.lockscreenDimOpacity)) * root.revealProgress)
  }

  // Subtle Top & Bottom Radial/Linear Vignette
  Rectangle {
    anchors.fill: parent
    opacity: root.revealProgress
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.34) }
      GradientStop { position: 0.30; color: Qt.rgba(0, 0, 0, 0.0) }
      GradientStop { position: 0.72; color: Qt.rgba(0, 0, 0, 0.0) }
      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.42) }
    }
  }

  // Click anywhere on backdrop to ensure keyboard focus stays on passwordInput
  MouseArea {
    anchors.fill: parent
    onClicked: {
      authNotch.grabPasswordFocus()
    }
  }

  // =========================================================================
  // 2. TOP DYNAMIC NOTCH / ISLAND AUTHENTICATION HUB
  // =========================================================================
  LockScreenAuthNotch {
    id: authNotch
    ipc: root.ipc
    anchors.top: parent.top
    anchors.topMargin: Config.isNotch ? 0 : Config.islandTopMargin
    anchors.horizontalCenter: parent.horizontalCenter
    opacity: root.revealProgress
    z: 20
  }

  // =========================================================================
  // 3. CENTERPIECE: MONUMENTAL CLOCK + SMALL DATE INDICATOR DIRECTLY BENEATH
  // =========================================================================
  Column {
    id: heroClockGroup
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 10 + (1.0 - root.revealProgress) * 14
    spacing: 14
    opacity: root.revealProgress
    z: 10

    Text {
      id: clockLabel
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.timeText
      font.family: Config.lockscreenClockFont
      font.pixelSize: Config.lockscreenClockSize
      font.weight: Config.lockscreenClockWeightInt
      font.letterSpacing: -4
      color: "#f4f5f8"
      layer.enabled: true
      layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 8
        radius: 26
        samples: 32
        color: Qt.rgba(0, 0, 0, 0.48)
      }
    }

    Text {
      id: dateLabel
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.dateText
      font.family: Config.lockscreenDateFont
      font.pixelSize: Config.lockscreenDateSize
      font.weight: Font.Medium
      font.letterSpacing: 3.0
      color: Qt.rgba(244 / 255, 245 / 255, 248 / 255, 0.68)
      layer.enabled: true
      layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 4
        radius: 14
        samples: 20
        color: Qt.rgba(0, 0, 0, 0.45)
      }
    }
  }

  // =========================================================================
  // 4. BOTTOM-LEFT COMPACT SINGLE-LINE MEDIA PILL (MPRIS)
  // =========================================================================
  Rectangle {
    id: mediaPill
    visible: Config.lockscreenShowMedia && root.hasMedia
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 42
    anchors.bottomMargin: 40
    height: 48
    width: Math.min(340, mediaRow.implicitWidth + 30)
    radius: 24
    color: Qt.rgba(0, 0, 0, 0.78)
    border.width: 1
    border.color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.12)
    z: 15

    RowLayout {
      id: mediaRow
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 14
      spacing: 10

      // Animated 3-Bar Equalizer
      Row {
        Layout.alignment: Qt.AlignVCenter
        spacing: 2.5

        Rectangle {
          width: 2.4
          height: root.isPlaying ? 10 : 5
          radius: 1.2
          color: Style.textPrimary
          anchors.bottom: parent.bottom
          SequentialAnimation on height {
            running: root.isPlaying && mediaPill.visible
            loops: Animation.Infinite
            NumberAnimation { from: 4; to: 12; duration: 420; easing.type: Easing.InOutSine }
            NumberAnimation { from: 12; to: 4; duration: 420; easing.type: Easing.InOutSine }
          }
        }
        Rectangle {
          width: 2.4
          height: root.isPlaying ? 13 : 8
          radius: 1.2
          color: Style.textPrimary
          anchors.bottom: parent.bottom
          SequentialAnimation on height {
            running: root.isPlaying && mediaPill.visible
            loops: Animation.Infinite
            NumberAnimation { from: 13; to: 5; duration: 320; easing.type: Easing.InOutSine }
            NumberAnimation { from: 5; to: 13; duration: 320; easing.type: Easing.InOutSine }
          }
        }
        Rectangle {
          width: 2.4
          height: root.isPlaying ? 9 : 6
          radius: 1.2
          color: Style.textPrimary
          anchors.bottom: parent.bottom
          SequentialAnimation on height {
            running: root.isPlaying && mediaPill.visible
            loops: Animation.Infinite
            NumberAnimation { from: 5; to: 11; duration: 380; easing.type: Easing.InOutSine }
            NumberAnimation { from: 11; to: 5; duration: 380; easing.type: Easing.InOutSine }
          }
        }
      }

      Text {
        text: root.mediaTitle
        font.family: Style.fontDisplay
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: Style.textPrimary
        elide: Text.ElideRight
        Layout.maximumWidth: 130
      }

      Text {
        visible: root.mediaArtist.length > 0
        text: "· " + root.mediaArtist
        font.family: Style.fontText
        font.pixelSize: 12
        color: Style.textMuted
        elide: Text.ElideRight
        Layout.maximumWidth: 85
      }

      // Play / Pause Button
      Item {
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26

        Text {
          anchors.centerIn: parent
          text: root.isPlaying ? "󰏤" : "󰐊"
          font.pixelSize: 15
          color: playMouse.containsMouse ? "#ffffff" : Style.textSecondary
        }

        MouseArea {
          id: playMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.activePlayer) root.activePlayer.togglePlaying()
            authNotch.grabPasswordFocus()
          }
        }
      }

      // Next Track Button
      Item {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 26

        Text {
          anchors.centerIn: parent
          text: "󰒭"
          font.pixelSize: 15
          color: nextMouse.containsMouse ? "#ffffff" : Style.textMuted
        }

        MouseArea {
          id: nextMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
            authNotch.grabPasswordFocus()
          }
        }
      }
    }
  }

  // =========================================================================
  // 5. BOTTOM-RIGHT CIRCULAR SESSION CONTROLS (PowerOverlay DNA)
  // =========================================================================
  Row {
    id: powerRow
    visible: Config.lockscreenShowPower
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 42
    anchors.bottomMargin: 40
    spacing: 12
    z: 15

    // Suspend
    Rectangle {
      width: 48
      height: 48
      radius: 24
      color: slpHover.containsMouse
        ? Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.20)
        : Qt.rgba(0, 0, 0, 0.68)
      border.width: 1
      border.color: slpHover.containsMouse
        ? Style.accentCyan
        : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.12)
      scale: slpHover.pressed ? 0.94 : (slpHover.containsMouse ? 1.08 : 1.0)

      Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 140 } }
      Behavior on border.color { ColorAnimation { duration: 140 } }

      Text {
        anchors.centerIn: parent
        text: "󰤄"
        font.pixelSize: 18
        color: slpHover.containsMouse ? Style.accentCyan : Style.textPrimary
      }

      MouseArea {
        id: slpHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.runPowerCommand(["systemctl", "suspend"])
      }
    }

    // Reboot
    Rectangle {
      width: 48
      height: 48
      radius: 24
      color: rbtHover.containsMouse
        ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.20)
        : Qt.rgba(0, 0, 0, 0.68)
      border.width: 1
      border.color: rbtHover.containsMouse
        ? Style.accentOrange
        : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.12)
      scale: rbtHover.pressed ? 0.94 : (rbtHover.containsMouse ? 1.08 : 1.0)

      Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 140 } }
      Behavior on border.color { ColorAnimation { duration: 140 } }

      Text {
        anchors.centerIn: parent
        text: "󰜉"
        font.pixelSize: 18
        color: rbtHover.containsMouse ? Style.accentOrange : Style.textPrimary
      }

      MouseArea {
        id: rbtHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.runPowerCommand(["systemctl", "reboot"])
      }
    }

    // Poweroff
    Rectangle {
      width: 48
      height: 48
      radius: 24
      color: pwrHover.containsMouse
        ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.24)
        : Qt.rgba(0, 0, 0, 0.68)
      border.width: 1
      border.color: pwrHover.containsMouse
        ? Style.accentRed
        : Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.30)
      scale: pwrHover.pressed ? 0.94 : (pwrHover.containsMouse ? 1.08 : 1.0)

      Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 140 } }
      Behavior on border.color { ColorAnimation { duration: 140 } }

      Text {
        anchors.centerIn: parent
        text: "󰐥"
        font.pixelSize: 18
        color: Style.accentRed
      }

      MouseArea {
        id: pwrHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.runPowerCommand(["systemctl", "poweroff"])
      }
    }
  }

  // =========================================================================
  // 6. ROUNDED SCREEN CORNERS (14px Pure Black Hardware Cutouts)
  // =========================================================================
  ScreenCorners {
    anchors.top: parent.top
    anchors.left: parent.left
    width: Config.screenCornersRadius
    height: Config.screenCornersRadius
    visible: Config.screenCornersEnabled && Config.screenCornerTopLeft
    radius: Config.screenCornersRadius
    cornerColor: Config.screenCornersColor
    cornerMode: "TOP_LEFT"
    z: 30
  }

  ScreenCorners {
    anchors.top: parent.top
    anchors.right: parent.right
    width: Config.screenCornersRadius
    height: Config.screenCornersRadius
    visible: Config.screenCornersEnabled && Config.screenCornerTopRight
    radius: Config.screenCornersRadius
    cornerColor: Config.screenCornersColor
    cornerMode: "TOP_RIGHT"
    z: 30
  }

  ScreenCorners {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: Config.screenCornersRadius
    height: Config.screenCornersRadius
    visible: Config.screenCornersEnabled && Config.screenCornerBottomLeft
    radius: Config.screenCornersRadius
    cornerColor: Config.screenCornersColor
    cornerMode: "BOTTOM_LEFT"
    z: 30
  }

  ScreenCorners {
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: Config.screenCornersRadius
    height: Config.screenCornersRadius
    visible: Config.screenCornersEnabled && Config.screenCornerBottomRight
    radius: Config.screenCornersRadius
    cornerColor: Config.screenCornersColor
    cornerMode: "BOTTOM_RIGHT"
    z: 30
  }
}
