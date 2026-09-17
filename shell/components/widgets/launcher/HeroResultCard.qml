import QtQuick
import QtQuick.Layouts
import "../../.."

Rectangle {
  id: root

  property var result: null
  property bool isSelected: false
  property bool isCopied: false

  signal copyTriggered()

  visible: result !== null
  height: visible ? 58 : 0
  radius: 12

  color: {
    if (isCopied) return Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.22)
    if (isSelected) return Style.surfaceActive
    if (mouseArea.containsMouse) return Style.surfaceHover
    return Style.surfaceVariant
  }

  border.color: {
    if (isCopied) return Style.accentGreen
    if (isSelected) return Style.accent
    return Style.border
  }
  border.width: isSelected || isCopied ? 1.5 : 1

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }

  readonly property bool isMath: result && result.type === "math"
  readonly property bool isCurrency: result && result.type === "currency"

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 12

    // 1. Left Icon Badge
    Rectangle {
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: 10
      Layout.alignment: Qt.AlignVCenter
      color: {
        if (root.isCopied) return Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.25)
        if (root.isCurrency) return Qt.rgba(Style.accentCyan.r, Style.accentCyan.g, Style.accentCyan.b, 0.20)
        return Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.20)
      }

      Text {
        anchors.centerIn: parent
        text: {
          if (root.isCopied) return "✓"
          if (root.isCurrency) return "󱁉"
          return "󰃬"
        }
        font.family: "JetBrainsMono Nerd Font, Symbols Nerd Font, sans-serif"
        font.pixelSize: 18
        color: {
          if (root.isCopied) return Style.accentGreen
          if (root.isCurrency) return Style.accentCyan
          return Style.accent
        }
      }
    }

    // 2. Result Information Column
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      // Main Large Result Text
      Text {
        text: root.result ? (root.result.display || "") : ""
        font.pixelSize: 17
        font.weight: Font.DemiBold
        font.family: "Inter, -apple-system, Roboto, sans-serif"
        color: root.isCopied ? Style.accentGreen : Style.textPrimary
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      // Contextual Subtitle (parity or math expression)
      Text {
        text: root.result ? (root.result.subtitle || root.result.expression || "") : ""
        font.pixelSize: 11
        font.weight: Font.Normal
        font.family: "Inter, -apple-system, Roboto, sans-serif"
        color: Style.textMuted
        elide: Text.ElideRight
        Layout.fillWidth: true
        visible: text.length > 0
      }
    }

    // 3. Right Action Hint Pill
    Rectangle {
      Layout.preferredHeight: 24
      Layout.preferredWidth: actionLabel.implicitWidth + 16
      radius: 8
      Layout.alignment: Qt.AlignVCenter
      color: {
        if (root.isCopied) return Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.30)
        if (root.isSelected) return Style.surfaceActive
        return Style.surface
      }
      border.color: {
        if (root.isCopied) return Style.accentGreen
        if (root.isSelected) return Style.accent
        return Style.border
      }
      border.width: 1

      Text {
        id: actionLabel
        anchors.centerIn: parent
        text: root.isCopied ? "✓ Kopyalandı!" : "↵ Kopyala"
        font.pixelSize: 11
        font.weight: root.isCopied || root.isSelected ? Font.DemiBold : Font.Normal
        color: {
          if (root.isCopied) return Style.accentGreen
          if (root.isSelected) return Style.accent
          return Style.textSecondary
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.copyTriggered()
  }
}
