import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import "../.."
import "../widgets"
import "../widgets/clock"
import "../widgets/calendar"
import "../widgets/controlcenter"
import "../widgets/launcher"
import "../widgets/media"

Item {
  id: root

  // IPC Service Reference
  required property var ipc

  // State Machine: "IDLE" | "HOVER" | "EXPANDED" | "TRANSIENT"
  property string stateMode: "IDLE"
  property string previousState: "IDLE"
  property string expandedActiveTab: "CLOCK" // "CLOCK" | "CALENDAR" | "CONTROL_CENTER" | "LAUNCHER" | "MEDIA"
  property string clockAppActiveTab: "WORLD" // "WORLD" | "POMODORO" | "STOPWATCH" | "ALARMS"
  readonly property bool isIslandHovered: islandHoverHandler.hovered

  // Transient notification metadata
  property string transientSummary: "Notification"
  property string transientBody: ""
  property string transientAppName: "System"
  property int transientTimeout: 3500

  // Pomodoro completion alert listener
  Connections {
    target: ClockManager
    function onPomodoroCompleted(phaseName) {
      let title = ""
      let body = ""
      if (phaseName === "target_reached") {
        title = "🎉 Tebrikler! Hedefe Ulaştın!"
        body = "Bugünkü " + ClockManager.pomodoroTargetSessions + " seanslık Pomodoro hedefini başarıyla tamamladın."
      } else if (phaseName === "work") {
        title = "🍅 Çalışma Seansı Tamamlandı (" + ClockManager.pomodoroCompletedSessions + "/" + ClockManager.pomodoroTargetSessions + ")"
        body = "Harika odaklandın! Şimdi " + ClockManager.pomodoroBreakMinutes + " dakikalık mola vakti."
      } else {
        title = "☕ Mola Süresi Bitti!"
        body = "Mola bitti, yeni çalışma seansına hazır mısın?"
      }
      root.triggerNotification(title, body, "Pomodoro", 8000)
    }
  }

  property bool isScreenFocused: true

  // IPC Signal Listeners for Real-Time Island Morphing
  Connections {
    target: root.ipc || null

    function onAlarmTriggered(payload) {
      root.triggerNotification("⏰ Alarm: " + (payload.label || "Alarm"), payload.time || "", "ogsShell Alarm", 10000);
    }

    function onCalendarReminderTriggered(payload) {
      root.triggerNotification("📅 " + payload.title, (payload.date || "") + " " + (payload.time || ""), "ogsShell Takvim", 8000);
    }

    function onNotificationReceived(payload) {
      if (payload && payload.should_popup) {
        let n = payload.notification || {};
        root.triggerNotification(n.summary || "Notification", n.body || "", n.app_name || "System", 3500);
      }
    }

    function onLauncherToggled() {
      if (root.stateMode === "EXPANDED" && root.expandedActiveTab === "LAUNCHER") {
        root.collapse();
      } else if (root.isScreenFocused) {
        root.expandedActiveTab = "LAUNCHER";
        root.stateMode = "EXPANDED";
      }
    }

    function onLauncherOpened() {
      if (root.isScreenFocused) {
        root.expandedActiveTab = "LAUNCHER";
        root.stateMode = "EXPANDED";
      }
    }

    function onLauncherClosed() {
      if (root.expandedActiveTab === "LAUNCHER") {
        root.collapse();
      }
    }
  }

  // State change lifecycle handler
  onStateModeChanged: {
    if (stateMode === "EXPANDED") {
      if (!islandHoverHandler.hovered) {
        expandedUnhoverTimer.restart()
      } else {
        expandedUnhoverTimer.stop()
      }
    } else {
      expandedUnhoverTimer.stop()
    }
  }

  // Collapse / Dismiss helper method
  function collapse() {
    if (stateMode === "TRANSIENT") {
      transientTimer.stop()
    }
    expandedUnhoverTimer.stop()
    if (controlCenterLoader.item) {
      controlCenterLoader.item.resetToMain()
    }
    stateMode = "IDLE"
  }

  // Reset inactivity countdown when user interacts with expanded widgets
  function resetInactivityTimer() {
    if (stateMode === "EXPANDED") {
      expandedUnhoverTimer.restart()
    }
  }

  // Trigger transient notification display
  function triggerNotification(summary, body, appName, timeoutMs) {
    transientSummary = summary && summary.length > 0 ? summary : "Notification"
    transientBody = body || ""
    transientAppName = appName || "System"
    transientTimeout = timeoutMs && timeoutMs > 0 ? timeoutMs : (Config.notifications.default_timeout_ms || 3500)

    if (stateMode !== "EXPANDED") {
      if (stateMode !== "TRANSIENT") {
        previousState = stateMode
      }
      stateMode = "TRANSIENT"
    }

    transientTimer.interval = transientTimeout
    transientTimer.restart()
  }

  // Dynamic geometry derived from active form-factor (Island vs Notch)
  implicitWidth: {
    let geo = Config.activeGeometry
    switch (stateMode) {
      case "HOVER":     return geo.hover_width
      case "TRANSIENT": return geo.transient_width
      case "EXPANDED":
        if (expandedActiveTab === "CONTROL_CENTER") {
          return (controlCenterLoader.item && controlCenterLoader.item.preferredIslandWidth) ? controlCenterLoader.item.preferredIslandWidth : 440
        }
        if (expandedActiveTab === "LAUNCHER") {
          return 520
        }
        if (expandedActiveTab === "MEDIA") {
          return 390
        }
        return geo.expanded_width
      default:          return geo.idle_width
    }
  }

  implicitHeight: {
    let geo = Config.activeGeometry
    switch (stateMode) {
      case "HOVER":     return geo.hover_height
      case "TRANSIENT": return geo.transient_height
      case "EXPANDED":
        if (expandedActiveTab === "CONTROL_CENTER") {
          return (controlCenterLoader.item && controlCenterLoader.item.preferredIslandHeight) ? controlCenterLoader.item.preferredIslandHeight : 310
        }
        if (expandedActiveTab === "LAUNCHER") {
          return 440
        }
        if (expandedActiveTab === "MEDIA") {
          return 170
        }
        return geo.expanded_height
      default:          return geo.idle_height
    }
  }

  width: implicitWidth
  height: implicitHeight

  // Active parameters
  readonly property real activeRadius: {
    if (Config.isNotch) {
      let rawR = root.stateMode === "EXPANDED" ? Config.notch.bottom_radius_expanded : Config.notch.bottom_radius
      return Math.min(rawR, root.height * 0.48)
    } else {
      return root.stateMode === "EXPANDED" ? Config.island.radius_expanded : (root.stateMode === "TRANSIENT" ? (Config.island.radius_full + 4) : Config.island.radius_full)
    }
  }

  // Proportional tall-slope notch parameters (Tight horizontal spread, generous vertical drape)
  readonly property real notchEarW: 5
  readonly property real notchEarH: Math.min(16, root.height * 0.45)

  readonly property color surfaceColor: (root.stateMode === "EXPANDED" || root.stateMode === "TRANSIENT") ? Style.bgSecondary : Style.bgPrimary

  // ==========================================
  // High-Performance GPU-Accelerated Animations
  // ==========================================
  Behavior on width {
    NumberAnimation {
      duration: root.stateMode === "EXPANDED" ? Config.animation.duration_expanded : (root.stateMode === "TRANSIENT" ? Config.animation.duration_transient : Config.animation.duration_compact)
      easing.type: root.stateMode === "EXPANDED" ? Easing.OutBack : Easing.OutCubic
      easing.overshoot: Config.animation.overshoot_factor
    }
  }

  Behavior on height {
    NumberAnimation {
      duration: root.stateMode === "EXPANDED" ? Config.animation.duration_expanded : (root.stateMode === "TRANSIENT" ? Config.animation.duration_transient : Config.animation.duration_compact)
      easing.type: root.stateMode === "EXPANDED" ? Easing.OutBack : Easing.OutCubic
      easing.overshoot: Config.animation.overshoot_factor
    }
  }

  // =========================================================================
  // SURFACE 1: Unified Vector Shape (Used for "notch" mode)
  // Borderless, pure black OLED silhouette with 8x MSAA anti-aliasing
  // =========================================================================
  Shape {
    id: notchVectorShape
    anchors.fill: parent
    anchors.leftMargin: -root.notchEarW
    anchors.rightMargin: -root.notchEarW
    visible: Config.isNotch

    // 8x Hardware Multi-Sample Anti-Aliasing for razor-sharp Retina/4K lines
    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    // Pure Solid Fill Path (Zero outer border)
    ShapePath {
      strokeWidth: 0
      strokeColor: "transparent"
      fillColor: root.surfaceColor
      startX: 0
      startY: 0

      // Left Tall Slope: Smooth Cubic Bezier drape
      PathCubic {
        control1X: root.notchEarW * 0.35
        control1Y: 0
        control2X: root.notchEarW
        control2Y: root.notchEarH * 0.65
        x: root.notchEarW
        y: root.notchEarH
      }

      // Left Vertical Wall
      PathLine {
        x: root.notchEarW
        y: root.height - root.activeRadius
      }

      // Bottom-Left Corner Arc (Convex)
      PathArc {
        x: root.notchEarW + root.activeRadius
        y: root.height
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Counterclockwise
      }

      // Bottom Edge
      PathLine {
        x: root.notchEarW + root.width - root.activeRadius
        y: root.height
      }

      // Bottom-Right Corner Arc (Convex)
      PathArc {
        x: root.notchEarW + root.width
        y: root.height - root.activeRadius
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Counterclockwise
      }

      // Right Vertical Wall
      PathLine {
        x: root.notchEarW + root.width
        y: root.notchEarH
      }

      // Right Tall Slope: Smooth Cubic Bezier drape
      PathCubic {
        control1X: root.notchEarW + root.width
        control1Y: root.notchEarH * 0.65
        control2X: root.notchEarW + root.width + root.notchEarW * 0.65
        control2Y: 0
        x: root.notchEarW * 2 + root.width
        y: 0
      }

      // Top Ceiling Line (Closes solid fill flush against screen bezel)
      PathLine {
        x: 0
        y: 0
      }
    }
  }

  // =========================================================================
  // SURFACE 2: Floating Pill Squircle (Used for "island" mode)
  // Borderless, pure black OLED squircle
  // =========================================================================
  Rectangle {
    id: islandSquircleShape
    anchors.fill: parent
    visible: !Config.isNotch
    radius: root.activeRadius
    color: root.surfaceColor
    border.width: 0
    border.color: "transparent"
    antialiasing: true
    smooth: true

    Behavior on radius {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color { ColorAnimation { duration: 200 } }
  }

  // ==========================================
  // Interaction: Pointer Handlers (Qt Quick)
  // HoverHandler tracks hover continuously across all child items without flickering.
  // TapHandler allows dismissing active transient alerts.
  // ==========================================
  HoverHandler {
    id: islandHoverHandler
    onHoveredChanged: {
      if (hovered) {
        if (root.stateMode === "IDLE") {
          root.stateMode = "HOVER"
        }
        if (root.stateMode === "EXPANDED") {
          expandedUnhoverTimer.stop()
        }
      } else {
        if (root.stateMode === "HOVER") {
          root.stateMode = "IDLE"
        }
        if (root.stateMode === "EXPANDED") {
          expandedUnhoverTimer.restart()
        }
      }
    }
  }

  TapHandler {
    onTapped: {
      if (root.stateMode === "TRANSIENT") {
        root.collapse()
      }
    }
  }

  // Right-Click Gesture: Opens Control Center directly when hovering over the island
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: {
      if (root.stateMode === "HOVER" || root.stateMode === "IDLE") {
        if (controlCenterLoader.item) {
          controlCenterLoader.item.resetToMain()
        }
        root.expandedActiveTab = "CONTROL_CENTER"
        root.stateMode = "EXPANDED"
      }
    }
  }

  // =========================================================================
  // Content Layers (Centered & Clamped to Island / Notch Frame)
  // =========================================================================
  Item {
    id: contentArea
    anchors.fill: parent

    // ==========================================
    // Layer 1: Unified Main Status Bar (IDLE & HOVER)
    // Single persistent ClockWidget with morphing coordinates and sliding side widgets
    // ==========================================
    Item {
      id: mainBarLayer
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.topMargin: 4
      anchors.bottomMargin: 4
      opacity: (root.stateMode === "IDLE" || root.stateMode === "HOVER") ? 1.0 : 0.0
      visible: opacity > 0.0

      Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
      }

      // Left Slot: MPRIS Media Status (Fades & Scales smoothly on hover)
      MediaWidget {
        id: mediaWidget
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(130, Math.floor(parent.width * 0.32))
        height: 28
        opacity: root.stateMode === "HOVER" ? 1.0 : 0.0
        scale: root.stateMode === "HOVER" ? 1.0 : 0.82
        visible: opacity > 0.0
        onMediaRightClicked: {
          root.expandedActiveTab = "MEDIA"
          root.stateMode = "EXPANDED"
        }

        Behavior on opacity {
          NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
          NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutCubic }
        }
      }

      // Center Slot: Single Continuous Clock & Date Widget (Morphs smoothly)
      ClockWidget {
        id: clockWidget
        hoverMode: root.stateMode === "HOVER"
        anchors.centerIn: parent
        onTimeClicked: targetTab => {
          root.clockAppActiveTab = targetTab || "WORLD"
          root.expandedActiveTab = "CLOCK"
          root.stateMode = "EXPANDED"
        }
        onDateClicked: {
          root.expandedActiveTab = "CALENDAR"
          root.stateMode = "EXPANDED"
        }
      }

      // Right Slot: Wi-Fi & Bluetooth Status Button (Fades & Scales smoothly on hover)
      ConnectivityStatusWidget {
        id: connectivityWidget
        ipc: root.ipc
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: implicitWidth
        height: 28
        opacity: root.stateMode === "HOVER" ? 1.0 : 0.0
        scale: root.stateMode === "HOVER" ? 1.0 : 0.82
        visible: opacity > 0.0

        onClicked: {
          if (controlCenterLoader.item) {
            controlCenterLoader.item.resetToMain()
          }
          root.expandedActiveTab = "CONTROL_CENTER"
          root.stateMode = "EXPANDED"
        }

        Behavior on opacity {
          NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
          NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutCubic }
        }
      }
    }

    // ==========================================
    // Layer 2: Transient Notification View
    // ==========================================
    Item {
      id: transientLayer
      anchors.fill: parent
      anchors.margins: 10
      opacity: root.stateMode === "TRANSIENT" ? 1.0 : 0.0
      visible: opacity > 0.0

      Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
      }

      Row {
        anchors.fill: parent
        spacing: 12

        // Leading: Notification Icon Badge
        Rectangle {
          width: 36
          height: 36
          radius: 18
          color: Style.surface
          border.color: Style.border
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: 6
            color: Style.accent

            SequentialAnimation on scale {
              loops: Animation.Infinite
              running: root.stateMode === "TRANSIENT"
              PropertyAnimation { from: 0.85; to: 1.15; duration: 900; easing.type: Easing.InOutSine }
              PropertyAnimation { from: 1.15; to: 0.85; duration: 900; easing.type: Easing.InOutSine }
            }
          }
        }

        // Content Stack: Title & Message
        Column {
          width: parent.width - 48
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: root.transientSummary
            color: Style.textPrimary
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.transientBody.length > 0 ? root.transientBody : root.transientAppName
            color: Style.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
          }
        }
      }
    }

    // ==========================================
    // Layer 3: Expanded Active App View (EXPANDED)
    // Dedicated host for the currently opened application
    // ==========================================
    Item {
      id: expandedLayer
      anchors.fill: parent
      anchors.margins: 14
      opacity: root.stateMode === "EXPANDED" ? 1.0 : 0.0
      visible: opacity > 0.0

      Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
      }

      // Focused App 1: Clock App Suite (Lazy Loaded)
      Loader {
        id: clockSuiteLoader
        anchors.fill: parent
        active: root.stateMode === "EXPANDED" && root.expandedActiveTab === "CLOCK"
        visible: active
        sourceComponent: ClockSuiteView {
          ipc: root.ipc
          activeTab: root.clockAppActiveTab
        }
      }

      // Focused App 2: Calendar & Events App (Lazy Loaded)
      Loader {
        id: calendarLoader
        anchors.fill: parent
        active: root.stateMode === "EXPANDED" && root.expandedActiveTab === "CALENDAR"
        visible: active
        sourceComponent: CalendarWidget {
          ipc: root.ipc
        }
      }

      // Focused App 3: Control Center Suite (Lazy Loaded)
      Loader {
        id: controlCenterLoader
        anchors.fill: parent
        active: root.stateMode === "EXPANDED" && root.expandedActiveTab === "CONTROL_CENTER"
        visible: active
        sourceComponent: ControlCenterView {
          ipc: root.ipc
        }
      }

      // Focused App 4: App Launcher Suite (Lazy Loaded)
      Loader {
        id: launcherLoader
        anchors.fill: parent
        active: root.stateMode === "EXPANDED" && root.expandedActiveTab === "LAUNCHER"
        visible: active
        sourceComponent: AppLauncherWidget {
          ipc: root.ipc
          onLaunchRequested: root.collapse()
          onCloseRequested: root.collapse()
          onUserActivity: root.resetInactivityTimer()
        }
      }

      // Focused App 5: Media Player App (Lazy Loaded)
      Loader {
        id: mediaPlayerLoader
        anchors.fill: parent
        active: root.stateMode === "EXPANDED" && root.expandedActiveTab === "MEDIA"
        visible: active
        sourceComponent: MediaPlayerView {
          onCloseRequested: root.collapse()
          onUserActivity: root.resetInactivityTimer()
        }
      }
    }
  }

  // ==========================================
  // Transient Auto-Dismiss Timer
  // ==========================================
  Timer {
    id: transientTimer
    repeat: false
    onTriggered: {
      if (root.stateMode === "TRANSIENT") {
        root.stateMode = root.previousState || "IDLE"
      }
    }
  }

  // ==========================================
  // Expanded State Inactivity / Unfocus Auto-Close Timer (5 seconds)
  // When the mouse leaves the expanded island for 5 continuous seconds, collapse to IDLE.
  // Re-entering the island resets/cancels the countdown.
  // ==========================================
  Timer {
    id: expandedUnhoverTimer
    interval: 5000
    repeat: false
    onTriggered: {
      if (root.stateMode === "EXPANDED" && !islandHoverHandler.hovered) {
        root.collapse()
      }
    }
  }
}
