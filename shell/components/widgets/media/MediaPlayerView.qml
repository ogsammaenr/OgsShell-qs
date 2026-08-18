import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../.."

Item {
  id: root

  signal closeRequested()
  signal userActivity()

  // Query active player from Mpris service
  readonly property var activePlayer: {
    if (!Mpris || !Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null
    // 1. Prefer currently playing player
    for (let i = 0; i < Mpris.players.values.length; i++) {
      let p = Mpris.players.values[i]
      if (p && (p.playbackState === MprisPlaybackState.Playing || p.isPlaying)) {
        return p
      }
    }
    // 2. Otherwise fallback to first available player
    return Mpris.players.values[0]
  }

  readonly property bool hasMedia: activePlayer !== null && ((activePlayer.trackTitle && activePlayer.trackTitle.length > 0) || activePlayer.isPlaying)
  readonly property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing || activePlayer.isPlaying) : false
  readonly property string title: activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0 ? activePlayer.trackTitle : (hasMedia ? "Bilinmeyen Parça" : "Medya Çalınmıyor")
  readonly property string artist: activePlayer && activePlayer.trackArtist && activePlayer.trackArtist.length > 0 ? activePlayer.trackArtist : (activePlayer && activePlayer.identity ? activePlayer.identity : "Çalınmıyor")
  readonly property string album: activePlayer && activePlayer.trackAlbum ? activePlayer.trackAlbum : ""
  readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || activePlayer.artUrl || "") : ""
  readonly property real position: (activePlayer && activePlayer.position !== undefined) ? activePlayer.position : 0
  readonly property real length: (activePlayer && (activePlayer.trackLength || activePlayer.length)) ? (activePlayer.trackLength || activePlayer.length) : 0
  readonly property real progressPercent: (length > 0) ? Math.min(1.0, Math.max(0.0, position / length)) : 0

  function formatTime(seconds) {
    if (!seconds || seconds <= 0 || isNaN(seconds)) return "0:00"
    let m = Math.floor(seconds / 60)
    let s = Math.floor(seconds % 60)
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  // =========================================================================
  // 1. Empty State (When no media is playing or available)
  // =========================================================================
  ColumnLayout {
    anchors.centerIn: parent
    visible: !root.hasMedia
    spacing: 10

    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      width: 48
      height: 48
      radius: 24
      color: Style.surfaceVariant
      border.color: Style.border
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: "󰎆"
        font.pixelSize: 22
        color: Style.textMuted
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: "Medya Çalınmıyor"
      font.pixelSize: 13
      font.weight: Font.DemiBold
      color: Style.textPrimary
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: "Bir müzik veya video başlatın"
      font.pixelSize: 10
      color: Style.textMuted
    }
  }

  // =========================================================================
  // 2. Rich Media Player Layout (Cover Art + Info + Progress + Controls)
  // =========================================================================
  RowLayout {
    anchors.fill: parent
    visible: root.hasMedia
    spacing: 16

    // -----------------------------------------------------------------------
    // Left: Album Cover Art Card
    // -----------------------------------------------------------------------
    Item {
      Layout.preferredWidth: 84
      Layout.preferredHeight: 84
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        anchors.fill: parent
        radius: 14
        color: Style.surface
        border.color: Style.border
        border.width: 1
        clip: true

        // Fallback gradient & icon
        Rectangle {
          anchors.fill: parent
          color: Style.surfaceVariant
          visible: !albumArt.visible || albumArt.status !== Image.Ready

          Text {
            anchors.centerIn: parent
            text: "󰝚"
            font.pixelSize: 34
            color: Style.accent
          }
        }

        // Cover Art Image
        Image {
          id: albumArt
          anchors.fill: parent
          source: root.artUrl
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: status === Image.Ready && source !== ""
        }

        // Sleek Inner Glass Border
        Rectangle {
          anchors.fill: parent
          radius: 14
          color: "transparent"
          border.color: Qt.rgba(255, 255, 255, 0.08)
          border.width: 1
        }
      }
    }

    // -----------------------------------------------------------------------
    // Right: Track Title, Artist, Progress Bar & Playback Controls
    // -----------------------------------------------------------------------
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 6

      // Title & Artist Block
      Column {
        Layout.fillWidth: true
        spacing: 2

        // Marquee Scrollable Title
        Item {
          id: marqueeContainer
          width: parent.width
          height: 20
          clip: true

          Text {
            id: titleText
            text: root.title
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Style.textPrimary
            verticalAlignment: Text.AlignVCenter

            readonly property bool isOverflowing: implicitWidth > marqueeContainer.width

            SequentialAnimation on x {
              id: marqueeAnim
              running: titleText.isOverflowing && root.isPlaying
              loops: Animation.Infinite

              PauseAnimation { duration: 1800 }
              NumberAnimation {
                to: -(titleText.implicitWidth - marqueeContainer.width + 14)
                duration: Math.max(2500, (titleText.implicitWidth - marqueeContainer.width) * 35)
                easing.type: Easing.Linear
              }
              PauseAnimation { duration: 1800 }
              NumberAnimation {
                to: 0
                duration: 450
                easing.type: Easing.InOutQuad
              }
              PauseAnimation { duration: 800 }
            }

            onTextChanged: {
              x = 0
            }
          }
        }

        // Artist & Identity Tag
        RowLayout {
          width: parent.width
          spacing: 6

          Text {
            Layout.fillWidth: true
            text: root.artist
            font.pixelSize: 11
            color: Style.textMuted
            elide: Text.ElideRight
          }

          // Player Source Tag
          Rectangle {
            visible: root.activePlayer && root.activePlayer.identity && root.activePlayer.identity.length > 0
            Layout.preferredHeight: 16
            Layout.preferredWidth: identityTxt.implicitWidth + 10
            radius: 8
            color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.16)

            Text {
              id: identityTxt
              anchors.centerIn: parent
              text: root.activePlayer ? root.activePlayer.identity : ""
              font.pixelSize: 9
              font.weight: Font.DemiBold
              color: Style.accent
            }
          }
        }
      }

      // Progress Bar & Timestamp Labels
      Column {
        Layout.fillWidth: true
        spacing: 3
        visible: root.length > 0

        // Track line
        Rectangle {
          id: progressBarTrack
          width: parent.width
          height: 4
          radius: 2
          color: Style.surfaceVariant

          Rectangle {
            width: parent.width * root.progressPercent
            height: parent.height
            radius: 2
            color: Style.accent

            Behavior on width {
              NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (root.activePlayer && root.length > 0) {
                let pct = Math.max(0.0, Math.min(1.0, mouse.x / width))
                let targetPos = pct * root.length
                if (root.activePlayer.setPosition) {
                  root.activePlayer.setPosition(targetPos)
                }
                root.userActivity()
              }
            }
          }
        }

        // Elapsed / Total Time Labels
        RowLayout {
          width: parent.width

          Text {
            text: root.formatTime(root.position)
            font.pixelSize: 9
            color: Style.textMuted
          }

          Item { Layout.fillWidth: true }

          Text {
            text: root.formatTime(root.length)
            font.pixelSize: 9
            color: Style.textMuted
          }
        }
      }

      // Playback Controls (Previous, Play/Pause, Next)
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 18

        // Previous Button
        Rectangle {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: 16
          color: prevMouse.containsMouse ? Style.surfaceVariant : "transparent"

          Behavior on color { ColorAnimation { duration: 120 } }
          scale: prevMouse.pressed ? 0.90 : (prevMouse.containsMouse ? 1.08 : 1.0)
          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

          Text {
            anchors.centerIn: parent
            text: "󰒮"
            font.pixelSize: 18
            color: prevMouse.containsMouse ? Style.textPrimary : Style.textSecondary
          }

          MouseArea {
            id: prevMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activePlayer) root.activePlayer.previous()
              root.userActivity()
            }
          }
        }

        // Play / Pause Button
        Rectangle {
          Layout.preferredWidth: 38
          Layout.preferredHeight: 38
          radius: 19
          color: playMouse.containsMouse ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.35) : Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.22)
          border.color: Style.accent
          border.width: 1

          Behavior on color { ColorAnimation { duration: 120 } }
          scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.08 : 1.0)
          Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

          Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.isPlaying ? 0 : 1
            text: root.isPlaying ? "󰏤" : "󰐊"
            font.pixelSize: 20
            color: Style.accent
          }

          MouseArea {
            id: playMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activePlayer) root.activePlayer.togglePlaying()
              root.userActivity()
            }
          }
        }

        // Next Button
        Rectangle {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: 16
          color: nextMouse.containsMouse ? Style.surfaceVariant : "transparent"

          Behavior on color { ColorAnimation { duration: 120 } }
          scale: nextMouse.pressed ? 0.90 : (nextMouse.containsMouse ? 1.08 : 1.0)
          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

          Text {
            anchors.centerIn: parent
            text: "󰒭"
            font.pixelSize: 18
            color: nextMouse.containsMouse ? Style.textPrimary : Style.textSecondary
          }

          MouseArea {
            id: nextMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activePlayer) root.activePlayer.next()
              root.userActivity()
            }
          }
        }
      }
    }
  }
}
