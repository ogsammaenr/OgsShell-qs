import Quickshell
import QtQuick
import "."

Rectangle {
  id: islandContainer
  required property var group

  readonly property bool showPomodoro: timeService.pomodoroRunning
  readonly property bool showStopwatch: !showPomodoro && (timeService.stopwatchRunning || timeService.stopwatchTime > 0)
  readonly property bool isCustomActive: showPomodoro || showStopwatch
  readonly property bool isHudActive: group.activeIslandHud !== ""

  readonly property real hudWidth: 250
  readonly property real hudHeight: 34
  readonly property real idleWidth: isCustomActive ? 140 : 115
  readonly property real hoveredWidth: isCustomActive ? 410 : 420
  readonly property real idleHeight: isCustomActive ? 34 : 30
  readonly property real hoveredHeight: 44
  
  width: isHudActive ? hudWidth : (hoverArea.containsMouse ? hoveredWidth : idleWidth)
  height: isHudActive ? hudHeight : (hoverArea.containsMouse ? hoveredHeight : idleHeight)
  radius: height / 2
  clip: true
  color: group.theme.bg
  border.color: group.theme.border
  border.width: 1
  opacity: (group.isControlCenterOpen || group.isTimeManagerOpen || group.isCalendarOpen || group.isAppLauncherOpen) ? 0.0 : 1.0
  scale: (group.isControlCenterOpen || group.isTimeManagerOpen || group.isCalendarOpen || group.isAppLauncherOpen) ? 0.85 : 1.0
  
  Behavior on opacity {
    NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
  }
  Behavior on scale {
    NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
  }

  Behavior on width {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }
  Behavior on height {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
  }

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: hoverArea.containsMouse ? 18 : 0
    visible: !islandContainer.isHudActive
    
    Behavior on spacing {
      NumberAnimation { duration: 150 }
    }

    VolumeBrightnessMinimal {
      screenContext: systemStatsService
      isHovered: hoverArea.containsMouse
      theme: group.theme
      onVolumeClickRequested: group.triggerIslandHud("volume")
      onVolumeScrollRequested: group.triggerIslandHud("volume")
      onBrightnessClickRequested: group.triggerIslandHud("brightness")
      onBrightnessScrollRequested: group.triggerIslandHud("brightness")
    }

    // 1. Normal Clock & Date Wrapper (visible when no custom tracker is active)
    Item {
      id: clockDateWrapper
      visible: !islandContainer.isCustomActive
      width: visible ? clockDateIndicator.width : 0
      height: clockDateIndicator.height
      anchors.verticalCenter: parent.verticalCenter

      ClockDateMinimal {
        id: clockDateIndicator
        sysClock: clock
        isHovered: hoverArea.containsMouse
        theme: group.theme
        onClockClicked: {
          group.isCalendarOpen = false;
          group.isTimeManagerOpen = !group.isTimeManagerOpen;
        }
        onDateClicked: {
          group.isTimeManagerOpen = false;
          group.isCalendarOpen = !group.isCalendarOpen;
        }
      }
    }

    // 2. Pomodoro Timer Wrapper (visible when Pomodoro is active)
    Item {
      id: pomodoroWrapper
      visible: islandContainer.showPomodoro
      width: visible ? pomodoroText.implicitWidth : 0
      height: 24
      anchors.verticalCenter: parent.verticalCenter

      function formatPomodoro(s) {
        var min = Math.floor(s / 60);
        var sec = s % 60;
        return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
      }

      Text {
        id: pomodoroText
        text: pomodoroWrapper.formatPomodoro(timeService.pomodoroTime)
        color: timeService.pomodoroState === "Work" ? group.theme.accent : "#22c55e"
        font {
          family: "JetBrains Mono"
          pixelSize: hoverArea.containsMouse ? 18 : 14
          weight: Font.ExtraBold
        }
        anchors.centerIn: parent
        
        Behavior on font.pixelSize {
          NumberAnimation { duration: 150 }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          group.isTimeManagerOpen = !group.isTimeManagerOpen;
        }
      }
    }

    // 3. Stopwatch Timer Wrapper (visible when Stopwatch is active)
    Item {
      id: stopwatchWrapper
      visible: islandContainer.showStopwatch
      width: visible ? stopwatchText.implicitWidth : 0
      height: 24
      anchors.verticalCenter: parent.verticalCenter

      function formatStopwatch(ms) {
        var min = Math.floor(ms / 60000);
        var sec = Math.floor((ms % 60000) / 1000);
        var cent = Math.floor((ms % 1000) / 10);
        return (min < 10 ? "0" : "") + min + ":" +
               (sec < 10 ? "0" : "") + sec + "." +
               (cent < 10 ? "0" : "") + cent;
      }

      Text {
        id: stopwatchText
        text: stopwatchWrapper.formatStopwatch(timeService.stopwatchTime)
        color: group.theme.accent
        font {
          family: "JetBrains Mono"
          pixelSize: hoverArea.containsMouse ? 17 : 13
          weight: Font.ExtraBold
        }
        anchors.centerIn: parent

        Behavior on font.pixelSize {
          NumberAnimation { duration: 150 }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          group.isTimeManagerOpen = !group.isTimeManagerOpen;
        }
      }
    }

    Item {
      width: statusIndicator.width
      height: statusIndicator.height
      anchors.verticalCenter: parent.verticalCenter
      
      StatusMinimal {
        id: statusIndicator
        screenContext: systemStatsService
        isHovered: hoverArea.containsMouse
        theme: group.theme
      }
      
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          group.isControlCenterOpen = !group.isControlCenterOpen;
        }
      }
    }
  }

  // 4. HUD Slider Wrapper (visible when volume/brightness HUD is active)
  Item {
    id: hudSliderWrapper
    visible: islandContainer.isHudActive
    anchors.fill: parent

    // Progress Bar
    Rectangle {
      id: hudProgress
      height: parent.height
      width: parent.width * (
        group.activeIslandHud === "volume" 
          ? (systemStatsService.volume / 100.0) 
          : (systemStatsService.brightness / 100.0)
      )
      color: group.theme.accent
      opacity: 0.85
      radius: parent.height / 2
    }

    // Text & Icon Overlay
    Row {
      anchors.centerIn: parent
      spacing: 8
      
      Text {
        text: group.activeIslandHud === "volume"
          ? (systemStatsService.audioMuted ? "\uf026" : (systemStatsService.volume > 50 ? "\uf028" : (systemStatsService.volume > 0 ? "\uf027" : "\uf026")))
          : "\uf185"
        color: "#ffffff"
        font { family: "FiraCode Nerd Font"; pixelSize: 11 }
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: group.activeIslandHud === "volume"
          ? (systemStatsService.audioMuted ? "Sessiz" : systemStatsService.volume + "%")
          : systemStatsService.brightness + "%"
        color: "#ffffff"
        font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.Bold }
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // MouseArea to click/drag to adjust the value, and SCROLL to adjust!
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      
      function handleAdjust(mouse) {
        group.restartIslandHudTimer();
        var pct = Math.max(0, Math.min(100, Math.round(mouse.x / width * 100)));
        if (group.activeIslandHud === "volume") {
          systemStatsService.volume = pct;
          Quickshell.execDetached(["amixer", "sset", "Master", pct + "%"]);
        } else if (group.activeIslandHud === "brightness") {
          systemStatsService.setBrightness(pct);
        }
      }

      onPositionChanged: (mouse) => { if (pressed) handleAdjust(mouse) }
      onPressed: (mouse) => handleAdjust(mouse)
      onReleased: {
        group.restartIslandHudTimer();
      }

      // Scroll on the expanded slider bar to continue adjusting!
      onWheel: (wheel) => {
        group.restartIslandHudTimer();
        if (group.activeIslandHud === "volume") {
          var newVol = Math.max(0, Math.min(100, systemStatsService.volume + (wheel.angleDelta.y > 0 ? 2 : -2)));
          systemStatsService.volume = newVol;
          Quickshell.execDetached(["amixer", "sset", "Master", newVol + "%"]);
        } else if (group.activeIslandHud === "brightness") {
          var newBright = Math.max(0, Math.min(100, systemStatsService.brightness + (wheel.angleDelta.y > 0 ? 5 : -5)));
          systemStatsService.setBrightness(newBright);
        }
      }
    }
  }

  // Right-click anywhere on the island to toggle the control center
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        group.isControlCenterOpen = !group.isControlCenterOpen;
      }
    }
  }
}
