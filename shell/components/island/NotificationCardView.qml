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

  // Capture & Media Extensions
  property string notificationType: "normal" // "normal" | "screenshot" | "ocr" | "recording"
  property string thumbnail: ""
  property string filePath: ""
  property var openAction: null

  readonly property bool isCritical: urgency === "critical"
  readonly property bool hasThumbnail: thumbnail !== "" && thumbnail.length > 0

  RowLayout {
    anchors.fill: parent
    spacing: 12

    // Leading: Thumbnail, Icon or Urgency Indicator Dot
    Rectangle {
      Layout.preferredWidth: root.hasThumbnail ? 40 : 36
      Layout.preferredHeight: root.hasThumbnail ? 40 : 36
      Layout.alignment: Qt.AlignVCenter
      radius: root.hasThumbnail ? 8 : 18
      clip: true
      color: root.isCritical ? "#3d1f28" : (root.hasThumbnail ? "#11111b" : Style.surface)
      border.color: root.hasThumbnail ? (Style.accent || "#89b4fa") : (root.isCritical ? "#ed8796" : Style.border)
      border.width: root.isCritical ? 1.5 : 1

      // High-resolution rounded Thumbnail for Screenshot
      Image {
        visible: root.hasThumbnail
        anchors.fill: parent
        anchors.margins: 1
        source: root.thumbnail
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
      }

      // OCR Magnifier Icon
      Text {
        visible: !root.hasThumbnail && root.notificationType === "ocr"
        anchors.centerIn: parent
        text: "🔍"
        font.pixelSize: 16
      }

      // Recording Camera Icon
      Text {
        visible: !root.hasThumbnail && root.notificationType === "recording"
        anchors.centerIn: parent
        text: "🎥"
        font.pixelSize: 16
      }

      // Default animated pulsing dot for standard system notifications
      Rectangle {
        visible: !root.hasThumbnail && root.notificationType !== "ocr" && root.notificationType !== "recording"
        anchors.centerIn: parent
        width: 12
        height: 12
        radius: 6
        color: root.isCritical ? "#ed8796" : Style.accent

        SequentialAnimation on scale {
          loops: Animation.Infinite
          running: root.visible && (!root.hasThumbnail)
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

    // Content: Title & Body Message
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        Layout.fillWidth: true
        text: {
          let app = root.appName || ""
          let sum = root.summary || "Notification"
          if (root.notificationType === "screenshot" || root.notificationType === "ocr" || root.notificationType === "recording") {
            return sum
          }
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
        color: root.isCritical ? "#f5bde6" : (root.notificationType === "ocr" ? (Style.accent || "#89b4fa") : Style.textMuted)
        font.family: Style.fontText
        font.pixelSize: Config.notificationBodySize
        font.italic: root.notificationType === "ocr"
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

    // Trailing Action: Edit Pencil Icon (For screenshots / Gradia open action)
    Rectangle {
      id: editButton
      visible: (root.notificationType === "screenshot" || (root.filePath && root.filePath.length > 0)) && root.remainingStackCount === 0
      Layout.preferredWidth: 30
      Layout.preferredHeight: 30
      Layout.alignment: Qt.AlignVCenter
      radius: 15
      color: editMouse.containsMouse ? Qt.rgba(137/255, 180/255, 250/255, 0.3) : Qt.rgba(255, 255, 255, 0.08)
      border.color: Qt.rgba(137/255, 180/255, 250/255, 0.4)
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: "✏️"
        font.pixelSize: 13
      }

      MouseArea {
        id: editMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.openAction && typeof root.openAction === "function") {
            root.openAction();
          }
        }
      }
    }
  }
}
