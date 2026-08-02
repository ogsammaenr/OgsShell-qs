import QtQuick
import Quickshell

Column {
  id: audioMixerContent
  width: 332
  height: 362
  spacing: 10

  required property var theme
  required property var screenContext
  signal backClicked()

  property string activeTab: "devices" // "devices" or "apps"

  Component.onCompleted: {
    if (typeof audioMixerService !== "undefined") {
      audioMixerService.refresh();
    }
  }

  onVisibleChanged: {
    if (visible && typeof audioMixerService !== "undefined") {
      audioMixerService.refresh();
    }
  }

  // 1. Header (Back Button + Title + Refresh Button)
  Item {
    width: parent.width
    height: 24

    Text {
      id: backBtn
      text: "\uf060" // Back arrow
      color: theme.textPrimary
      font { family: "FiraCode Nerd Font"; pixelSize: 14 }
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: audioMixerContent.backClicked()
      }
    }

    Text {
      text: "Ses Karıştırıcısı"
      color: theme.textPrimary
      font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Bold }
      anchors.left: backBtn.right
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
    }

    // Refresh Button
    Text {
      id: refreshBtn
      text: "\uf021" // Refresh icon
      color: (typeof audioMixerService !== "undefined" && audioMixerService.isLoading) ? theme.accent : theme.textSecondary
      font { family: "FiraCode Nerd Font"; pixelSize: 13 }
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
        running: (typeof audioMixerService !== "undefined" && audioMixerService.isLoading)
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (typeof audioMixerService !== "undefined") {
            audioMixerService.refresh();
          }
        }
      }
    }
  }

  // 2. Tab Bar Selector (Aygıtlar / Uygulamalar)
  Row {
    width: parent.width
    height: 28
    spacing: 8

    // Tab 1: Ses Aygıtları
    Rectangle {
      width: (parent.width - 8) / 2
      height: parent.height
      radius: 8
      color: activeTab === "devices" ? theme.accent : theme.buttonBg
      opacity: activeTab === "devices" ? 0.9 : 0.6

      Behavior on color { ColorAnimation { duration: 120 } }

      Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: "\uf028"
          color: activeTab === "devices" ? theme.textOnAccent : theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 11 }
        }

        Text {
          text: "Aygıtlar"
          color: activeTab === "devices" ? theme.textOnAccent : theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: activeTab = "devices"
      }
    }

    // Tab 2: Uygulamalar
    Rectangle {
      width: (parent.width - 8) / 2
      height: parent.height
      radius: 8
      color: activeTab === "apps" ? theme.accent : theme.buttonBg
      opacity: activeTab === "apps" ? 0.9 : 0.6

      Behavior on color { ColorAnimation { duration: 120 } }

      Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: "\uf001"
          color: activeTab === "apps" ? theme.textOnAccent : theme.textPrimary
          font { family: "FiraCode Nerd Font"; pixelSize: 11 }
        }

        Text {
          text: "Uygulamalar"
          color: activeTab === "apps" ? theme.textOnAccent : theme.textPrimary
          font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: activeTab = "apps"
      }
    }
  }

  // 3. Main Content View
  Item {
    width: parent.width
    height: parent.height - 24 - 28 - 20
    clip: true

    // --- Tab 1: Sound Output Devices View ---
    ListView {
      id: devicesList
      anchors.fill: parent
      visible: activeTab === "devices"
      spacing: 8
      clip: true

      model: (typeof audioMixerService !== "undefined") ? audioMixerService.sinkList : []

      delegate: Rectangle {
        width: devicesList.width
        height: 66
        radius: 10
        color: modelData.is_default ? Qt.rgba(1, 1, 1, 0.08) : theme.buttonBg
        border.color: modelData.is_default ? theme.accent : theme.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }

        Column {
          anchors.fill: parent
          anchors.margins: 8
          spacing: 6

          // Header Row: Default Checkmark + Device Description + Mute Button
          Row {
            width: parent.width
            height: 20
            spacing: 8

            // Active Device Selection Radio/Check
            Rectangle {
              width: 16
              height: 16
              radius: 8
              color: modelData.is_default ? theme.accent : "transparent"
              border.color: modelData.is_default ? theme.accent : theme.textSecondary
              border.width: 1.5
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: "\uf00c"
                color: theme.textOnAccent
                font { family: "FiraCode Nerd Font"; pixelSize: 10; weight: Font.Bold }
                anchors.centerIn: parent
                visible: modelData.is_default
              }

              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (typeof audioMixerService !== "undefined") {
                    audioMixerService.setDefaultSink(modelData.name);
                  }
                }
              }
            }

            // Device Name
            Text {
              width: parent.width - 16 - 8 - 24 - 8
              text: modelData.description ? modelData.description : modelData.name
              color: theme.textPrimary
              font { family: "JetBrains Mono"; pixelSize: 10; weight: modelData.is_default ? Font.Bold : Font.Normal }
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (typeof audioMixerService !== "undefined") {
                    audioMixerService.setDefaultSink(modelData.name);
                  }
                }
              }
            }

            // Mute Button
            Text {
              text: modelData.mute ? "\uf026" : "\uf028"
              color: modelData.mute ? "#ef4444" : theme.textSecondary
              font { family: "FiraCode Nerd Font"; pixelSize: 12 }
              anchors.verticalCenter: parent.verticalCenter

              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (typeof audioMixerService !== "undefined") {
                    audioMixerService.setSinkMute(modelData.name);
                  }
                }
              }
            }
          }

          // Volume Slider Pill
          Rectangle {
            id: devSliderPill
            width: parent.width
            height: 20
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.2)
            border.color: theme.border
            border.width: 1
            clip: true

            property bool isDragging: false
            property int localVol: modelData.volume

            // Progress Fill
            Rectangle {
              height: parent.height
              width: parent.width * ((devSliderPill.isDragging ? devSliderPill.localVol : modelData.volume) / 100.0)
              radius: parent.radius
              color: modelData.mute ? "#64748b" : theme.accent
              opacity: 0.85
            }

            // Percentage Text
            Text {
              text: modelData.mute ? "Sessiz" : (devSliderPill.isDragging ? devSliderPill.localVol : modelData.volume) + "%"
              color: "#ffffff"
              font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
              anchors.right: parent.right
              anchors.rightMargin: 8
              anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
              id: devVolMouse
              anchors.fill: parent
              preventStealing: true
              cursorShape: Qt.PointingHandCursor

              function updateVol(mouse) {
                var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
                devSliderPill.localVol = pct;
                if (typeof audioMixerService !== "undefined") {
                  audioMixerService.setSinkVolume(modelData.name, pct);
                }
              }

              onPressed: (mouse) => {
                if (typeof audioMixerService !== "undefined") audioMixerService.isUserDragging = true;
                devSliderPill.isDragging = true;
                updateVol(mouse);
              }

              onPositionChanged: (mouse) => {
                if (pressed) {
                  updateVol(mouse);
                }
              }

              onReleased: {
                if (typeof audioMixerService !== "undefined") audioMixerService.isUserDragging = false;
                devSliderPill.isDragging = false;
                devSliderPill.localVol = Qt.binding(function() { return modelData.volume; });
              }

              onCanceled: {
                if (typeof audioMixerService !== "undefined") audioMixerService.isUserDragging = false;
                devSliderPill.isDragging = false;
                devSliderPill.localVol = Qt.binding(function() { return modelData.volume; });
              }

              onWheel: (wheel) => {
                var newVol = Math.max(0, Math.min(100, modelData.volume + (wheel.angleDelta.y > 0 ? 2 : -2)));
                devSliderPill.localVol = newVol;
                if (typeof audioMixerService !== "undefined") {
                  audioMixerService.setSinkVolume(modelData.name, newVol);
                }
              }
            }
          }
        }
      }
    }

    // --- Tab 2: Application Audio Streams View ---
    Item {
      anchors.fill: parent
      visible: activeTab === "apps"

      // Empty State Notice
      Column {
        anchors.centerIn: parent
        spacing: 8
        visible: (typeof audioMixerService === "undefined" || !audioMixerService.appList || audioMixerService.appList.length === 0)

        Text {
          text: "\uf025" // Headphones / Mute icon
          color: theme.textSecondary
          font { family: "FiraCode Nerd Font"; pixelSize: 28 }
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          text: "Aktif ses çalan uygulama yok"
          color: theme.textSecondary
          font { family: "JetBrains Mono"; pixelSize: 11 }
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }

      ListView {
        id: appsList
        anchors.fill: parent
        visible: (typeof audioMixerService !== "undefined" && audioMixerService.appList && audioMixerService.appList.length > 0)
        spacing: 8
        clip: true

        model: (typeof audioMixerService !== "undefined") ? audioMixerService.appList : []

        delegate: Rectangle {
          width: appsList.width
          height: 64
          radius: 10
          color: theme.buttonBg
          border.color: theme.border
          border.width: 1

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Header Row: App Name + Mute Button
            Row {
              width: parent.width
              height: 18
              spacing: 8

              Text {
                text: "\uf001"
                color: theme.accent
                font { family: "FiraCode Nerd Font"; pixelSize: 11 }
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                width: parent.width - 11 - 8 - 24 - 8
                text: modelData.name + (modelData.media_name ? (" (" + modelData.media_name + ")") : "")
                color: theme.textPrimary
                font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
              }

              // Mute Button
              Text {
                text: modelData.mute ? "\uf026" : "\uf028"
                color: modelData.mute ? "#ef4444" : theme.textSecondary
                font { family: "FiraCode Nerd Font"; pixelSize: 12 }
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -4
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (typeof audioMixerService !== "undefined") {
                      audioMixerService.setAppMute(modelData.index);
                    }
                  }
                }
              }
            }

            // Volume Slider Pill
            Rectangle {
              id: appSliderPill
              width: parent.width
              height: 20
              radius: 10
              color: Qt.rgba(0, 0, 0, 0.2)
              border.color: theme.border
              border.width: 1
              clip: true

              property bool isDragging: false
              property int localVol: modelData.volume

              // Progress Fill
              Rectangle {
                height: parent.height
                width: parent.width * ((appSliderPill.isDragging ? appSliderPill.localVol : modelData.volume) / 100.0)
                radius: parent.radius
                color: modelData.mute ? "#64748b" : theme.accent
                opacity: 0.85
              }

              // Percentage Text
              Text {
                text: modelData.mute ? "Sessiz" : (appSliderPill.isDragging ? appSliderPill.localVol : modelData.volume) + "%"
                color: "#ffffff"
                font { family: "JetBrains Mono"; pixelSize: 8; weight: Font.Bold }
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
              }

              MouseArea {
                id: appVolMouse
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                function updateAppVol(mouse) {
                  var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
                  appSliderPill.localVol = pct;
                  if (typeof audioMixerService !== "undefined") {
                    audioMixerService.setAppVolume(modelData.index, pct);
                  }
                }

                onPressed: (mouse) => {
                  if (typeof audioMixerService !== "undefined") audioMixerService.isUserDragging = true;
                  appSliderPill.isDragging = true;
                  updateAppVol(mouse);
                }

                onPositionChanged: (mouse) => {
                  if (pressed) {
                    updateAppVol(mouse);
                  }
                }

                onReleased: {
                  if (typeof audioMixerService !== "undefined") audioMixerService.isUserDragging = false;
                  appSliderPill.isDragging = false;
                  appSliderPill.localVol = Qt.binding(function() { return modelData.volume; });
                }

                onCanceled: {
                  if (typeof audioMixerService !== "undefined") audioMixerService.isUserDragging = false;
                  appSliderPill.isDragging = false;
                  appSliderPill.localVol = Qt.binding(function() { return modelData.volume; });
                }

                onWheel: (wheel) => {
                  var newVol = Math.max(0, Math.min(100, modelData.volume + (wheel.angleDelta.y > 0 ? 2 : -2)));
                  appSliderPill.localVol = newVol;
                  if (typeof audioMixerService !== "undefined") {
                    audioMixerService.setAppVolume(modelData.index, newVol);
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
