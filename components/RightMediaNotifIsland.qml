import Quickshell
import QtQuick
import "."

Item {
  id: rootItem
  required property var group

  width: rightContainer.width

  property alias container: rightContainer
  property alias subNotificationsList: rightSubNotificationsList

  Timer {
    id: mediaManagerCollapseTimer
    interval: 3000 // 3 seconds timeout
    running: false
    repeat: false
    onTriggered: {
      group.isMediaManagerOpen = false;
    }
  }

  Connections {
    target: group
    function onIsMediaManagerOpenChanged() {
      if (group.isMediaManagerOpen) {
        if (!rightContainerHover.hovered) {
          mediaManagerCollapseTimer.restart();
        }
      } else {
        mediaManagerCollapseTimer.stop();
      }
    }
  }

  // C. Right Wall Media & Notification Island (Dynamic Meniscus Menü)
  Rectangle {
    id: rightContainer
    
    color: group.theme.bg
    border.color: group.theme.border
    border.width: 1
    clip: true

    state: group.isMediaManagerOpen ? "media" : (workspaceService.isShowingNotification ? "notification" : "idle")

    anchors.top: parent.top
    anchors.right: parent.right

    states: [
      State {
        name: "idle"
        PropertyChanges {
          target: rightContainer
          width: 260
          height: 30
          anchors.topMargin: 2
          anchors.rightMargin: -12
          radius: 15
        }
      },
      State {
        name: "notification"
        PropertyChanges {
          target: rightContainer
          width: 450
          height: 70
          anchors.topMargin: 2
          anchors.rightMargin: 12
          radius: 35
        }
      },
      State {
        name: "media"
        PropertyChanges {
          target: rightContainer
          width: 340
          height: 120
          anchors.topMargin: 8
          anchors.rightMargin: 12
          radius: 20
        }
      }
    ]

    transitions: [
      Transition {
        from: "*"; to: "*"
        NumberAnimation {
          properties: "width,height,anchors.topMargin,anchors.rightMargin,radius"
          duration: 180
          easing.type: Easing.OutQuad
        }
      }
    ]

    HoverHandler {
      id: rightContainerHover
      onHoveredChanged: {
        if (group.isMediaManagerOpen) {
          if (hovered) {
            mediaManagerCollapseTimer.stop();
          } else {
            mediaManagerCollapseTimer.restart();
          }
        }
      }
    }

    // Content 1: Media Info (visible when NOT showing notification)
    Item {
      id: rightMediaRow
      anchors.fill: parent
      visible: !group.isMediaManagerOpen && !workspaceService.isShowingNotification
      opacity: visible ? 1.0 : 0.0

      Behavior on opacity { NumberAnimation { duration: 120 } }

      Row {
        anchors.fill: parent
        anchors.rightMargin: 24
        anchors.leftMargin: 16
        spacing: 10

        Text {
          text: (systemStatsService.mediaStatus === "Playing") ? "\uf144" : "\uf001"
          color: (systemStatsService.mediaStatus === "Playing") ? group.theme.accent : group.theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 13 }
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          id: scrollContainer
          width: 185
          height: parent.height
          clip: true
          anchors.verticalCenter: parent.verticalCenter

          readonly property string mediaTextValue: {
            if (systemStatsService.mediaTitle !== "") {
              if (systemStatsService.mediaArtist !== "") {
                return systemStatsService.mediaArtist + " - " + systemStatsService.mediaTitle
              }
              return systemStatsService.mediaTitle
            }
            return "Medya Çalmıyor"
          }

          property real textWidth: mediaText1.implicitWidth
          property real containerWidth: width
          property bool needsScroll: textWidth > containerWidth && systemStatsService.mediaStatus === "Playing"

          Row {
            id: textRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 40
            x: 0

            Text {
              id: mediaText1
              text: scrollContainer.mediaTextValue
              color: group.theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 12; weight: Font.Bold }
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: mediaText2
              text: scrollContainer.mediaTextValue
              color: group.theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 12; weight: Font.Bold }
              anchors.verticalCenter: parent.verticalCenter
              visible: scrollContainer.needsScroll
            }
          }

          NumberAnimation {
            id: marqueeAnim
            target: textRow
            property: "x"
            from: 0
            to: -(scrollContainer.textWidth + 40)
            duration: (scrollContainer.textWidth + 40) * 35
            loops: Animation.Infinite
            running: scrollContainer.needsScroll
          }

          onNeedsScrollChanged: {
            if (!needsScroll) {
              marqueeAnim.stop();
              textRow.x = 0;
            }
          }

          onMediaTextValueChanged: {
            textRow.x = 0;
            if (needsScroll) {
              marqueeAnim.restart();
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
          if (mouse.button === Qt.RightButton) {
            group.isMediaManagerOpen = true;
          } else {
            Quickshell.execDetached(["playerctl", "play-pause"]);
            systemStatsService.mediaStatus = (systemStatsService.mediaStatus === "Playing") ? "Paused" : "Playing";
          }
        }
      }
    }

    // Content 2: Notification Display (visible when showing notification)
    Item {
      id: rightNotificationRow
      anchors.fill: parent
      visible: !group.isMediaManagerOpen && workspaceService.isShowingNotification
      opacity: visible ? 1.0 : 0.0

      Behavior on opacity { NumberAnimation { duration: 120 } }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          workspaceService.dismissNotification(0);
        }
      }

      Row {
        anchors.fill: parent
        anchors.rightMargin: 24
        anchors.leftMargin: 20
        spacing: 14

        Text {
          id: notificationBellIcon
          text: "\uf0f3"
          color: "#fbbf24"
          font { family: "FiraCode Nerd Font"; pixelSize: 22 }
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          width: parent.width - parent.spacing - notificationBellIcon.width
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Text {
            text: (workspaceService.activeNotifications && workspaceService.activeNotifications.length > 0) ? workspaceService.activeNotifications[0].title : ""
            color: group.theme.textPrimary
            font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Bold }
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: (workspaceService.activeNotifications && workspaceService.activeNotifications.length > 0) ? workspaceService.activeNotifications[0].body : ""
            color: group.theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 12 }
            elide: Text.ElideRight
            width: parent.width
          }
        }
      }
    }

    // Content 3: Full Media Manager Card (visible when right-clicked to expand)
    Item {
      id: rightMediaManagerCard
      anchors.fill: parent
      visible: group.isMediaManagerOpen
      opacity: visible ? 1.0 : 0.0

      Behavior on opacity { NumberAnimation { duration: 150 } }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
          group.isMediaManagerOpen = false;
        }
      }

      Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
          width: 96
          height: 96
          radius: 12
          color: "#1e1e2e"
          border.color: group.theme.border
          border.width: 1
          clip: true
          anchors.verticalCenter: parent.verticalCenter

          Image {
            id: coverArt
            anchors.fill: parent
            source: (systemStatsService.mediaArtUrl) ? systemStatsService.mediaArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            visible: source != ""
          }

          Text {
            anchors.centerIn: parent
            text: "\uf001"
            font { family: "FiraCode Nerd Font"; pixelSize: 28 }
            color: group.theme.accent
            visible: !coverArt.visible
          }
        }

        Column {
          width: parent.width - 96 - 12
          height: 96
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter

          Item {
            id: titleScrollContainer
            width: parent.width
            height: 20
            clip: true

            readonly property string mediaTextValue: (systemStatsService.mediaTitle !== "") ? systemStatsService.mediaTitle : "Medya Çalmıyor"
            property real textWidth: titleText1.implicitWidth
            property real containerWidth: width
            property bool needsScroll: textWidth > containerWidth && systemStatsService.mediaStatus === "Playing"

            Row {
              id: titleTextRow
              anchors.verticalCenter: parent.verticalCenter
              spacing: 40
              x: 0

              Text {
                id: titleText1
                text: titleScrollContainer.mediaTextValue
                color: group.theme.textPrimary
                font { family: "JetBrains Mono"; pixelSize: 13; weight: Font.Bold }
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                id: titleText2
                text: titleScrollContainer.mediaTextValue
                color: group.theme.textPrimary
                font { family: "JetBrains Mono"; pixelSize: 13; weight: Font.Bold }
                anchors.verticalCenter: parent.verticalCenter
                visible: titleScrollContainer.needsScroll
              }
            }

            NumberAnimation {
              id: titleMarqueeAnim
              target: titleTextRow
              property: "x"
              from: 0
              to: -(titleScrollContainer.textWidth + 40)
              duration: (titleScrollContainer.textWidth + 40) * 35
              loops: Animation.Infinite
              running: titleScrollContainer.needsScroll
            }

            onNeedsScrollChanged: {
              if (!needsScroll) {
                titleMarqueeAnim.stop();
                titleTextRow.x = 0;
              }
            }

            onMediaTextValueChanged: {
              titleTextRow.x = 0;
              if (needsScroll) {
                titleMarqueeAnim.restart();
              }
            }
          }

          Text {
            width: parent.width
            text: (systemStatsService.mediaArtist !== "") ? systemStatsService.mediaArtist : "Bilinmeyen Sanatçı"
            color: group.theme.textSecondary
            font { family: "JetBrains Mono"; pixelSize: 11 }
            elide: Text.ElideRight
          }

          Row {
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 4

            Text {
              text: "\uf048"
              color: prevMouse.containsMouse ? group.theme.accent : group.theme.textPrimary
              font { family: "FiraCode Nerd Font"; pixelSize: 16 }
              anchors.verticalCenter: parent.verticalCenter
              
              MouseArea {
                id: prevMouse
                anchors.fill: parent
                anchors.margins: -10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["playerctl", "previous"]);
                }
              }
            }

            Text {
              text: (systemStatsService.mediaStatus === "Playing") ? "\uf04c" : "\uf04b"
              color: group.theme.accent
              font { family: "FiraCode Nerd Font"; pixelSize: 22 }
              anchors.verticalCenter: parent.verticalCenter
              
              MouseArea {
                id: playMouse
                anchors.fill: parent
                anchors.margins: -10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["playerctl", "play-pause"]);
                  systemStatsService.mediaStatus = (systemStatsService.mediaStatus === "Playing") ? "Paused" : "Playing";
                }
              }
            }

            Text {
              text: "\uf051"
              color: nextMouse.containsMouse ? group.theme.accent : group.theme.textPrimary
              font { family: "FiraCode Nerd Font"; pixelSize: 16 }
              anchors.verticalCenter: parent.verticalCenter
              
              MouseArea {
                id: nextMouse
                anchors.fill: parent
                anchors.margins: -10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["playerctl", "next"]);
                }
              }
            }
          }
        }
      }
    }
  }

  // D. Right Wall Secondary/Older Notifications List
  ListView {
    id: rightSubNotificationsList
    anchors.top: rightContainer.bottom
    anchors.topMargin: 8
    anchors.right: parent.right
    anchors.rightMargin: 12
    width: 380
    height: (workspaceService.activeNotifications && workspaceService.activeNotifications.length > 1) ? (workspaceService.activeNotifications.length - 1) * 58 - 8 : 0
    spacing: 8
    interactive: false

    visible: !group.isMediaManagerOpen && workspaceService.isShowingNotification && workspaceService.activeNotifications.length > 1

    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    model: workspaceService.activeNotifications ? workspaceService.activeNotifications.slice(1) : []
    
    delegate: Rectangle {
      width: 380
      height: 50
      radius: height / 2
      color: group.theme.bg
      border.color: group.theme.border
      border.width: 1
      clip: true

      Text {
        id: subBellIcon
        text: "\uf0f3"
        color: "#94a3b8"
        font { family: "FiraCode Nerd Font"; pixelSize: 15 }
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        anchors.left: subBellIcon.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          text: modelData ? modelData.title : ""
          color: group.theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 11; weight: Font.Bold }
          elide: Text.ElideRight
          width: parent.width
        }

        Text {
          text: modelData ? modelData.body : ""
          color: group.theme.textSecondary
          font { family: "JetBrains Mono"; pixelSize: 9 }
          elide: Text.ElideRight
          width: parent.width
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          workspaceService.dismissNotification(index + 1);
        }
      }
    }

    add: Transition {
      NumberAnimation { properties: "opacity,scale"; from: 0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
      NumberAnimation { property: "y"; from: -50; duration: 200; easing.type: Easing.OutQuad }
    }
    displaced: Transition {
      NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad }
    }
  }
}
