import QtQuick
import QtQuick.Layouts
import "../.."

Item {
  id: root

  property string summary: ""
  property string body: ""
  property string appName: "System"
  property string urgency: "normal"
  property string icon: ""
  property int remainingStackCount: 0
  property bool isTransitioning: false

  readonly property bool isCritical: urgency === "critical"

  RowLayout {
    anchors.fill: parent
    spacing: 12

    // Leading: Urgency Indicator Dot / Badge
    Rectangle {
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      Layout.alignment: Qt.AlignVCenter
      radius: 18
      color: root.isCritical ? "#3d1f28" : Style.surface
      border.color: root.isCritical ? "#ed8796" : Style.border
      border.width: root.isCritical ? 1.5 : 1

      Rectangle {
        anchors.centerIn: parent
        width: 12
        height: 12
        radius: 6
        color: root.isCritical ? "#ed8796" : Style.accent

        SequentialAnimation on scale {
          loops: Animation.Infinite
          running: root.visible
          PropertyAnimation {
            from: 0.85
            to: 1.25
            duration: root.isCritical ? 500 : 900
            easing.type: Easing.InOutSine
          }
          PropertyAnimation {
            from: 1.25
            to: 0.85
            duration: root.isCritical ? 500 : 900
            easing.type: Easing.InOutSine
          }
        }
      }
    }

    // Content: Title (with App Prefix if distinct) & Body Message
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        Layout.fillWidth: true
        text: {
          let app = root.appName || ""
          let sum = root.summary || "Notification"
          if (app.length > 0 && app !== "System" && !sum.startsWith(app)) {
            return app + " • " + sum
          }
          return sum
        }
        color: root.isCritical ? "#ed8796" : Style.textPrimary
        font.family: Style.fontDisplay
        font.pixelSize: Config.notificationTitleSize
        font.weight: Style.fontWeightDisplay
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        text: (root.body && root.body.length > 0) ? root.body : (root.appName || "")
        color: root.isCritical ? "#f5bde6" : Style.textMuted
        font.family: Style.fontText
        font.pixelSize: Config.notificationBodySize
        elide: Text.ElideRight
      }
    }

    // Trailing: 3D Layered Deck Indicator Badge [+X Deste]
    Rectangle {
      id: stackBadge
      Layout.preferredHeight: 24
      Layout.preferredWidth: badgeRow.implicitWidth + 16
      Layout.alignment: Qt.AlignVCenter
      radius: 12
      visible: root.remainingStackCount > 0
      color: root.isCritical ? Qt.rgba(0.93, 0.53, 0.59, 0.2) : Qt.rgba(0.78, 0.63, 0.96, 0.15)
      border.color: root.isCritical ? "#ed8796" : "#c6a0f6"
      border.width: 1.2

      Row {
        id: badgeRow
        anchors.centerIn: parent
        spacing: 5

        Rectangle {
          width: 5
          height: 5
          radius: 2.5
          color: root.isCritical ? "#ed8796" : "#c6a0f6"
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: "+" + root.remainingStackCount + " Deste"
          color: root.isCritical ? "#ed8796" : "#c6a0f6"
          font.family: Style.fontText
          font.pixelSize: 11
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
}
