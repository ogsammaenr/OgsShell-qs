import QtQuick
import QtQuick.Layouts
import "../../../.."

Rectangle {
  id: sliderRoot

  property int volume: 50
  property bool muted: false
  property bool dragging: false

  signal dragStarted()
  signal dragFinished()
  signal volumeEdited(int newVolume)
  signal wheelStepped(int newVolume)

  Layout.fillWidth: true
  Layout.preferredHeight: 18
  radius: 9
  color: Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.07)
  clip: true

  Component.onDestruction: {
    if (sliderRoot.dragging) {
      sliderRoot.dragging = false
      sliderRoot.dragFinished()
    }
  }

  // Active Fill Bar
  Rectangle {
    height: parent.height
    width: sliderRoot.muted ? 0 : Math.max(0, Math.min(parent.width, parent.width * (sliderRoot.volume / Config.audioMaxVolume)))
    radius: 9
    color: (!sliderRoot.muted && sliderRoot.volume >= 135)
      ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.45)
      : ((!sliderRoot.muted && sliderRoot.volume > 100)
        ? Qt.rgba(Style.accentOrange.r, Style.accentOrange.g, Style.accentOrange.b, 0.42)
        : Qt.rgba(Style.textPrimary.r, Style.textPrimary.g, Style.textPrimary.b, 0.22))

    Behavior on width {
      enabled: !sliderRoot.dragging
      NumberAnimation { duration: 100 }
    }
  }

  // 100% Threshold Marker (Over-Amplification)
  Rectangle {
    visible: Config.audioOverAmplification
    x: Math.round(parent.width * (100.0 / Config.audioMaxVolume))
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 3
    anchors.bottomMargin: 3
    width: 1.5
    radius: 1
    color: Style.textMuted
    opacity: 0.50
  }

  // Percentage Text
  Text {
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    text: sliderRoot.muted ? "Sessiz" : `%${sliderRoot.volume}`
    font.family: Style.fontDisplay
    font.pixelSize: 9
    font.weight: Font.DemiBold
    color: sliderRoot.muted ? Style.accentRed : (sliderRoot.volume >= 135 ? Style.accentRed : (sliderRoot.volume > 100 ? Style.accentOrange : Style.textSecondary))
  }

  // Slider Mouse & Wheel Handler (no redundant onClicked after onReleased)
  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    preventStealing: true
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    function computePct(mouseX) {
      if (width <= 0) return sliderRoot.volume
      return Math.max(0, Math.min(Config.audioMaxVolume, Math.round((mouseX / width) * Config.audioMaxVolume)))
    }

    onPressed: mouse => {
      if (mouse.button !== Qt.LeftButton) return
      sliderRoot.dragging = true
      sliderRoot.dragStarted()
      sliderRoot.volumeEdited(computePct(mouse.x))
    }

    onPositionChanged: mouse => {
      if (pressed && (mouse.buttons & Qt.LeftButton)) {
        sliderRoot.volumeEdited(computePct(mouse.x))
      }
    }

    onReleased: mouse => {
      if (mouse.button !== Qt.LeftButton) return
      let pct = computePct(mouse.x)
      if (pct !== sliderRoot.volume) {
        sliderRoot.volumeEdited(pct)
      }
      sliderRoot.dragging = false
      sliderRoot.dragFinished()
    }

    onCanceled: {
      if (sliderRoot.dragging) {
        sliderRoot.dragging = false
        sliderRoot.dragFinished()
      }
    }

    onWheel: wheel => {
      if (wheel.angleDelta.y === 0) {
        wheel.accepted = false
        return
      }
      let delta = wheel.angleDelta.y > 0 ? 5 : -5
      let pct = Math.max(0, Math.min(Config.audioMaxVolume, sliderRoot.volume + delta))
      sliderRoot.wheelStepped(pct)
    }
  }
}
