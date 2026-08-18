import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../.."

Item {
  id: root

  signal mediaRightClicked()

  // Query active player from Mpris service
  readonly property var activePlayer: {
    if (!Mpris || !Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null
    // Prefer playing player
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
  readonly property string title: activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0 ? activePlayer.trackTitle : (hasMedia ? "Bilinmeyen Parça" : "Medya Yok")
  readonly property string artist: activePlayer && activePlayer.trackArtist && activePlayer.trackArtist.length > 0 ? activePlayer.trackArtist : (activePlayer && activePlayer.identity ? activePlayer.identity : "Çalınmıyor")
  readonly property bool canAnimate: root.isPlaying && root.visible && (root.opacity > 0.0)

  implicitWidth: contentRow.implicitWidth
  implicitHeight: contentRow.implicitHeight

  Rectangle {
    id: container
    anchors.fill: parent
    radius: 10
    color: mediaHoverHandler.hovered ? Style.surfaceVariant : "transparent"
    border.color: mediaHoverHandler.hovered ? Style.border : "transparent"
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler {
      id: mediaHoverHandler
      cursorShape: root.hasMedia ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
      acceptedButtons: Qt.LeftButton
      onTapped: {
        if (root.activePlayer) {
          root.activePlayer.togglePlaying()
        }
      }
    }

    TapHandler {
      acceptedButtons: Qt.RightButton
      onTapped: {
        root.mediaRightClicked()
      }
    }

    RowLayout {
      id: contentRow
      anchors.fill: parent
      anchors.leftMargin: 6
      anchors.rightMargin: 8
      spacing: 7

      // ==========================================
      // Animated Equalizer / Music Icon Badge
      // ==========================================
      Rectangle {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        Layout.alignment: Qt.AlignVCenter
        radius: 12
        color: root.hasMedia ? Style.surface : "transparent"

        // Animated 3-bar equalizer when playing (only animates when visible)
        Row {
          anchors.centerIn: parent
          spacing: 2
          visible: root.isPlaying

          Rectangle {
            width: 2
            height: 10
            radius: 1
            color: Style.accent
            anchors.bottom: parent.bottom

            SequentialAnimation on height {
              loops: Animation.Infinite
              running: root.canAnimate
              PropertyAnimation { from: 3; to: 10; duration: 420; easing.type: Easing.InOutSine }
              PropertyAnimation { from: 10; to: 3; duration: 420; easing.type: Easing.InOutSine }
            }
          }

          Rectangle {
            width: 2
            height: 12
            radius: 1
            color: Style.accent
            anchors.bottom: parent.bottom

            SequentialAnimation on height {
              loops: Animation.Infinite
              running: root.canAnimate
              PropertyAnimation { from: 12; to: 4; duration: 320; easing.type: Easing.InOutSine }
              PropertyAnimation { from: 4; to: 12; duration: 320; easing.type: Easing.InOutSine }
            }
          }

          Rectangle {
            width: 2
            height: 7
            radius: 1
            color: Style.accent
            anchors.bottom: parent.bottom

            SequentialAnimation on height {
              loops: Animation.Infinite
              running: root.canAnimate
              PropertyAnimation { from: 5; to: 11; duration: 500; easing.type: Easing.InOutSine }
              PropertyAnimation { from: 11; to: 5; duration: 500; easing.type: Easing.InOutSine }
            }
          }
        }

        // Static / Paused / Idle Music Icon
        Text {
          anchors.centerIn: parent
          visible: !root.isPlaying
          text: root.hasMedia ? "⏸" : "󰎆"
          color: root.hasMedia ? Style.textPrimary : Style.textMuted
          font.pixelSize: root.hasMedia ? 9 : 12
        }
      }

      // ==========================================
      // Track Title & Artist Info
      // ==========================================
      Column {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        Text {
          width: parent.width
          text: root.title
          color: root.hasMedia ? Style.textPrimary : Style.textMuted
          font.pixelSize: 10
          font.weight: Font.DemiBold
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: root.artist
          color: Style.textMuted
          font.pixelSize: 9
          font.weight: Font.Normal
          elide: Text.ElideRight
        }
      }
    }
  }
}
