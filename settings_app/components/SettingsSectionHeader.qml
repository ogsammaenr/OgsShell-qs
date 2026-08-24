import QtQuick
import "../theme"

Text {
  id: root

  property string titleText: ""
  text: titleText.toUpperCase()

  font.pixelSize: 11
  font.weight: Font.DemiBold
  font.letterSpacing: 0.6
  color: Style.textMuted
  leftPadding: 4
  bottomPadding: 2
}
