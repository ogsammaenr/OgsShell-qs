import QtQuick
import "../theme"

Text {
  id: root

  property string titleText: ""
  property alias title: root.titleText
  text: titleText.toUpperCase()

  font.family: Style.fontText
  font.pixelSize: 11
  font.weight: Font.DemiBold
  font.letterSpacing: 0.7
  color: Style.textMuted
  leftPadding: 2
  bottomPadding: 2
}
