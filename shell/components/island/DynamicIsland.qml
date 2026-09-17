import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
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
  property var audioFeedback: null

  // State Machine: "IDLE" | "HOVER" | "EXPANDED" | "TRANSIENT"
  property string stateMode: "IDLE"
  property string previousState: "IDLE"
  property string expandedActiveTab: "CLOCK" // "CLOCK" | "CALENDAR" | "CONTROL_CENTER" | "LAUNCHER" | "MEDIA"
  property string clockAppActiveTab: "WORLD" // "WORLD" | "POMODORO" | "STOPWATCH" | "ALARMS"
  readonly property bool isIslandHovered: islandHoverHandler.hovered

  // Notification Stack & 3D Layered Cards Deck
  property var notificationStack: []
  readonly property int notificationCount: notificationStack.length
  readonly property var activeNotification: notificationCount > 0 ? notificationStack[0] : null
  readonly property var secondNotification: notificationCount > 1 ? notificationStack[1] : null
  readonly property var thirdNotification: notificationCount > 2 ? notificationStack[2] : null
  readonly property int extraStackHeight: {
    if (stateMode !== "TRANSIENT") return 0
    if (notificationCount >= 3) return 18
    if (notificationCount >= 2) return 10
    return 0
  }

  // Active notification convenience bindings (with fallbacks)
  property string transientSummary: activeNotification ? (activeNotification.summary || "Notification") : "Notification"
  property string transientBody: activeNotification ? (activeNotification.body || "") : ""
  property string transientAppName: activeNotification ? (activeNotification.appName || "System") : "System"
  property string transientUrgency: activeNotification ? (activeNotification.urgency || "normal") : "normal"
  property string transientIcon: activeNotification ? (activeNotification.icon || "") : ""
  property int transientTimeout: activeNotification ? (activeNotification.timeoutMs || 3500) : 3500
  property string transientType: activeNotification ? (activeNotification.type || "normal") : "normal"
  property string transientThumbnail: activeNotification ? (activeNotification.thumbnail || "") : ""
  property string transientFilePath: activeNotification ? (activeNotification.filePath || "") : ""
  property var transientAction: activeNotification ? (activeNotification.action || null) : null

  // Dismiss & Slide Transition States
  property bool isDismissing: false
  property bool isTransitioning: false
  property var incomingNotification: null
  property real deckShiftProgress: 0.0

  // Primary (front) card animation coordinates
  property real currentCardOffsetY: 0
  property real currentCardOpacity: 1.0
  property real currentCardScale: 1.0

  // Incoming (next) card animation coordinates
  property real incomingCardOffsetY: 36
  property real incomingCardOpacity: 0.0
  property real incomingCardScale: 1.0

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
      root.triggerNotification(title, body, "Pomodoro", 8000, "normal", "pomodoro_" + Date.now(), "", "")
    }
  }

  property bool isScreenFocused: true

  // IPC Signal Listeners for Real-Time Island Morphing
  Connections {
    target: root.ipc || null

    function onAlarmTriggered(payload) {
      root.triggerNotification("⏰ Alarm: " + (payload.label || "Alarm"), payload.time || "", "ogsShell Alarm", 10000, "critical", "alarm_" + Date.now(), "", "");
    }

    function onCalendarReminderTriggered(payload) {
      root.triggerNotification("📅 " + payload.title, (payload.date || "") + " " + (payload.time || ""), "ogsShell Takvim", 8000, "normal", "calendar_" + Date.now(), "", "");
    }

    function onNotificationReceived(payload) {
      if (payload && payload.should_popup) {
        let n = payload.notification || {};
        let t = (n.timeout_ms && n.timeout_ms > 0) ? n.timeout_ms : (Config.notificationTimeoutMs || 3500);
        root.enqueueNotification({
          id: n.id || ("notif_" + Date.now() + "_" + Math.floor(Math.random() * 1000)),
          summary: n.summary || "Notification",
          body: n.body || "",
          appName: n.app_name || "System",
          urgency: n.urgency || "normal",
          icon: n.icon || "",
          timeoutMs: t,
          desktopEntry: n.desktop_entry || ""
        });
      }
    }

    function onLauncherToggled() {
      root.toggleApp("LAUNCHER", "");
    }

    function onLauncherOpened() {
      root.openApp("LAUNCHER", "");
    }

    function onLauncherClosed() {
      if (root.expandedActiveTab === "LAUNCHER") {
        root.collapse();
      }
    }

    function onAppToggleRequested(payload) {
      if (payload && payload.app) {
        root.toggleApp(payload.app, payload.subview || "");
      }
    }

    function onAppOpenRequested(payload) {
      if (payload && payload.app) {
        root.openApp(payload.app, payload.subview || "");
      }
    }

    function onAppCloseRequested(payload) {
      root.collapse();
    }

    function onScreenshotCaptured(payload) {
      // Play camera shutter sound
      if (root.audioFeedback && root.audioFeedback.playShutterSound) {
        root.audioFeedback.playShutterSound();
      }
      let path = (payload && payload.file_path) ? payload.file_path : "";
      let thumbSrc = path.length > 0 ? ("file://" + path) : "";
      root.enqueueNotification({
        id: "screenshot_" + Date.now(),
        summary: "📸 Ekran Görüntüsü Alındı",
        body: path.length > 0 ? path.split("/").pop() : "Panoya kopyalandı",
        appName: "ogsShell Capture",
        urgency: "normal",
        icon: "",
        timeoutMs: 5000,
        desktopEntry: "",
        type: "screenshot",
        thumbnail: thumbSrc,
        filePath: path,
        action: function() {
          if (root.ipc && root.ipc.openAnnotator && path.length > 0) {
            root.ipc.openAnnotator(path);
          }
        }
      });
    }

    function onOcrCompleted(payload) {
      let text = (payload && payload.text) ? payload.text : "";
      let snippet = text.length > 60 ? text.substring(0, 60) + "…" : text;
      root.enqueueNotification({
        id: "ocr_" + Date.now(),
        summary: "🔍 OCR Metin Tanıma",
        body: snippet.length > 0 ? ("\"" + snippet + "\"") : "Metin bulunamadı",
        appName: "ogsShell Capture",
        urgency: "normal",
        icon: "",
        timeoutMs: 5000,
        desktopEntry: "",
        type: "ocr",
        thumbnail: "",
        filePath: "",
        action: null
      });
    }

    function onRecordingFinished(payload) {
      let path = (payload && payload.file_path) ? payload.file_path : "";
      root.enqueueNotification({
        id: "recording_" + Date.now(),
        summary: "🎥 Ekran Kaydı Tamamlandı",
        body: path.length > 0 ? path.split("/").pop() : "Kayıt tamamlandı",
        appName: "ogsShell Capture",
        urgency: "normal",
        icon: "",
        timeoutMs: 5000,
        desktopEntry: "",
        type: "recording",
        thumbnail: "",
        filePath: path,
        action: null
      });
    }
  }

  // App routing and toggle methods
  function toggleApp(appName, subview) {
    if (!root.isScreenFocused) return;
    let target = (appName || "").toUpperCase();

    if (target === "POWER" || target === "POWER_MENU" || target === "SESSION") {
      PowerService.toggle();
      return;
    }

    if (target === "LAUNCHER") {
      if (root.stateMode === "EXPANDED" && root.expandedActiveTab === "LAUNCHER") {
        root.collapse();
      } else {
        root.expandedActiveTab = "LAUNCHER";
        root.stateMode = "EXPANDED";
      }
      return;
    }

    if (target === "MEDIA" || target === "MEDIA_PLAYER") {
      if (root.stateMode === "EXPANDED" && root.expandedActiveTab === "MEDIA") {
        root.collapse();
      } else {
        root.expandedActiveTab = "MEDIA";
        root.stateMode = "EXPANDED";
      }
      return;
    }

    if (target === "CALENDAR") {
      if (root.stateMode === "EXPANDED" && root.expandedActiveTab === "CALENDAR") {
        root.collapse();
      } else {
        root.expandedActiveTab = "CALENDAR";
        root.stateMode = "EXPANDED";
      }
      return;
    }

    if (target === "CLOCK" || target === "STOPWATCH" || target === "POMODORO" || target === "ALARMS" || target === "WORLD") {
      let clockTab = (target === "CLOCK") ? (subview ? subview.toUpperCase() : "WORLD") : target;
      if (root.stateMode === "EXPANDED" && root.expandedActiveTab === "CLOCK" && root.clockAppActiveTab === clockTab) {
        root.collapse();
      } else {
        root.clockAppActiveTab = clockTab;
        root.expandedActiveTab = "CLOCK";
        root.stateMode = "EXPANDED";
      }
      return;
    }

    if (target === "CONTROL_CENTER" || target === "THEMES" || target === "THEME" || target === "NOTIFICATIONS" || target === "NOTIFICATION" || target === "CLIPBOARD" || target === "WIFI" || target === "BLUETOOTH" || target === "KEYBOARD" || target === "AUDIO" || target === "MIXER" || target === "AUDIO_MIXER") {
      let sub = "MAIN";
      if (target === "THEMES" || target === "THEME") sub = "THEMES";
      else if (target === "NOTIFICATIONS" || target === "NOTIFICATION") sub = "NOTIFICATIONS";
      else if (target === "CLIPBOARD") sub = "CLIPBOARD";
      else if (target === "WIFI") sub = "WIFI";
      else if (target === "BLUETOOTH") sub = "BLUETOOTH";
      else if (target === "KEYBOARD") sub = "KEYBOARD";
      else if (target === "AUDIO" || target === "MIXER" || target === "AUDIO_MIXER") sub = "AUDIO_MIXER";
      else if (subview && subview.length > 0) sub = subview.toUpperCase();

      if (root.stateMode === "EXPANDED" && root.expandedActiveTab === "CONTROL_CENTER" && controlCenterLoader.item && controlCenterLoader.item.currentView === sub) {
        root.collapse();
      } else {
        root.expandedActiveTab = "CONTROL_CENTER";
        root.stateMode = "EXPANDED";
        if (controlCenterLoader.item) {
          controlCenterLoader.item.setView(sub);
        }
      }
      return;
    }
  }

  function openApp(appName, subview) {
    if (!root.isScreenFocused) return;
    let target = (appName || "").toUpperCase();

    if (target === "POWER" || target === "POWER_MENU" || target === "SESSION") {
      PowerService.open();
      return;
    }

    if (target === "LAUNCHER") {
      root.expandedActiveTab = "LAUNCHER";
      root.stateMode = "EXPANDED";
      return;
    }

    if (target === "MEDIA" || target === "MEDIA_PLAYER") {
      root.expandedActiveTab = "MEDIA";
      root.stateMode = "EXPANDED";
      return;
    }

    if (target === "CALENDAR") {
      root.expandedActiveTab = "CALENDAR";
      root.stateMode = "EXPANDED";
      return;
    }

    if (target === "CLOCK" || target === "STOPWATCH" || target === "POMODORO" || target === "ALARMS" || target === "WORLD") {
      root.clockAppActiveTab = (target === "CLOCK") ? (subview ? subview.toUpperCase() : "WORLD") : target;
      root.expandedActiveTab = "CLOCK";
      root.stateMode = "EXPANDED";
      return;
    }

    if (target === "CONTROL_CENTER" || target === "THEMES" || target === "THEME" || target === "NOTIFICATIONS" || target === "NOTIFICATION" || target === "CLIPBOARD" || target === "WIFI" || target === "BLUETOOTH" || target === "KEYBOARD" || target === "AUDIO" || target === "MIXER" || target === "AUDIO_MIXER") {
      let sub = "MAIN";
      if (target === "THEMES" || target === "THEME") sub = "THEMES";
      else if (target === "NOTIFICATIONS" || target === "NOTIFICATION") sub = "NOTIFICATIONS";
      else if (target === "CLIPBOARD") sub = "CLIPBOARD";
      else if (target === "WIFI") sub = "WIFI";
      else if (target === "BLUETOOTH") sub = "BLUETOOTH";
      else if (target === "KEYBOARD") sub = "KEYBOARD";
      else if (target === "AUDIO" || target === "MIXER" || target === "AUDIO_MIXER") sub = "AUDIO_MIXER";
      else if (subview && subview.length > 0) sub = subview.toUpperCase();

      root.expandedActiveTab = "CONTROL_CENTER";
      root.stateMode = "EXPANDED";
      if (controlCenterLoader.item) {
        controlCenterLoader.item.setView(sub);
      }
      return;
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
      root.notificationStack = []
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

  // Add notification to stack with criticality preemption
  function enqueueNotification(notif) {
    if (!notif) return;
    let isCrit = (notif.urgency === "critical");
    let newStack = [];
    if (isCrit) {
      // Critical urgency bypasses queue and jumps directly to front (unshift)
      newStack = [notif, ...root.notificationStack];
    } else {
      // Normal / low urgency appends to end of deck
      newStack = [...root.notificationStack, notif];
    }
    // Reassignment guarantees QML reactivity
    root.notificationStack = newStack;

    if (root.stateMode !== "EXPANDED") {
      if (root.stateMode !== "TRANSIENT") {
        root.previousState = root.stateMode;
      }
      root.stateMode = "TRANSIENT";
    }

    // If critical or first item, immediately reset timer for active item
    if (isCrit || root.notificationStack.length === 1) {
      startNotificationTimer(notif.timeoutMs);
    }
  }

  // ==========================================
  // Dual-Card Slide Transition & Dismiss Animations
  // Outgoing card slides UP and out, while incoming card simultaneously slides UP into place.
  // ==========================================
  ParallelAnimation {
    id: transitionToNextSequence

    // Outgoing card slides up and fades out
    NumberAnimation {
      target: root
      property: "currentCardOffsetY"
      to: -36
      duration: 300
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "currentCardOpacity"
      to: 0.0
      duration: 260
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "currentCardScale"
      to: 0.96
      duration: 300
      easing.type: Easing.OutCubic
    }

    // Incoming card slides up from below into place
    NumberAnimation {
      target: root
      property: "incomingCardOffsetY"
      to: 0
      duration: 300
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "incomingCardOpacity"
      to: 1.0
      duration: 260
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "incomingCardScale"
      to: 1.0
      duration: 300
      easing.type: Easing.OutCubic
    }

    // Stacked physical deck ascends into notch bottom
    NumberAnimation {
      target: root
      property: "deckShiftProgress"
      to: 1.0
      duration: 300
      easing.type: Easing.OutCubic
    }

    onFinished: {
      root.performStackShift();
      root.isTransitioning = false;
      root.incomingNotification = null;
      root.deckShiftProgress = 0.0;
      root.currentCardOffsetY = 0;
      root.currentCardOpacity = 1.0;
      root.currentCardScale = 1.0;
      root.incomingCardOffsetY = 36;
      root.incomingCardOpacity = 0.0;
      root.incomingCardScale = 0.96;
      root.isDismissing = false;
    }
  }

  // Dismiss animation when only 1 notification remains in deck
  SequentialAnimation {
    id: dismissLastSequence

    PropertyAction { target: root; property: "isDismissing"; value: true }

    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "currentCardOffsetY"
        to: -32
        duration: 220
        easing.type: Easing.OutQuad
      }
      NumberAnimation {
        target: root
        property: "currentCardOpacity"
        to: 0.0
        duration: 200
        easing.type: Easing.OutQuad
      }
      NumberAnimation {
        target: root
        property: "currentCardScale"
        to: 0.96
        duration: 220
        easing.type: Easing.OutQuad
      }
    }

    ScriptAction {
      script: {
        root.performStackShift();
        root.currentCardOffsetY = 0;
        root.currentCardOpacity = 1.0;
        root.currentCardScale = 1.0;
        root.isDismissing = false;
      }
    }
  }

  // App Focus & Launch Animation (Tactile click pulse followed by slide to next or fly-out)
  SequentialAnimation {
    id: focusLaunchSequence

    PropertyAction { target: root; property: "isDismissing"; value: true }

    // Step 1: Tactile press-in
    NumberAnimation {
      target: root
      property: "currentCardScale"
      to: 0.94
      duration: 75
      easing.type: Easing.OutQuad
    }

    // Step 2: Trigger Hyprland focus / launch
    ScriptAction {
      script: {
        root.activateNotificationApp(root.activeNotification);
      }
    }

    // Step 3: Branch based on remaining stack items
    ScriptAction {
      script: {
        if (root.notificationStack.length > 1) {
          root.incomingNotification = root.notificationStack[1];
          root.isTransitioning = true;
          root.incomingCardOffsetY = 36;
          root.incomingCardOpacity = 0.0;
          root.incomingCardScale = 0.96;
          transitionToNextSequence.restart();
        } else {
          flyOutLastSequence.restart();
        }
      }
    }
  }

  // Fly-out animation for last notification after app focus
  SequentialAnimation {
    id: flyOutLastSequence

    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "currentCardScale"
        to: 1.04
        duration: 130
        easing.type: Easing.OutQuad
      }
      NumberAnimation {
        target: root
        property: "currentCardOffsetY"
        to: -28
        duration: 130
        easing.type: Easing.InQuad
      }
      NumberAnimation {
        target: root
        property: "currentCardOpacity"
        to: 0.0
        duration: 120
        easing.type: Easing.InQuad
      }
    }

    ScriptAction {
      script: {
        root.performStackShift();
        root.currentCardOffsetY = 0;
        root.currentCardOpacity = 1.0;
        root.currentCardScale = 1.0;
        root.isDismissing = false;
      }
    }
  }

  // Dismiss the frontmost active card; second card ascends to front with slide physics
  function dismissFront(isFocusLaunch) {
    if (root.isDismissing) return;
    if (root.notificationStack.length === 0) {
      transientTimer.stop();
      if (root.stateMode === "TRANSIENT") {
        root.stateMode = root.previousState || "IDLE";
      }
      return;
    }

    if (isFocusLaunch) {
      focusLaunchSequence.restart();
    } else {
      if (root.notificationStack.length > 1) {
        root.isDismissing = true;
        root.incomingNotification = root.notificationStack[1];
        root.isTransitioning = true;
        root.incomingCardOffsetY = 36;
        root.incomingCardOpacity = 0.0;
        root.incomingCardScale = 0.96;
        transitionToNextSequence.restart();
      } else {
        dismissLastSequence.restart();
      }
    }
  }

  // Internal stack shift logic executed when transition finishes
  function performStackShift() {
    if (root.notificationStack.length === 0) {
      transientTimer.stop();
      if (root.stateMode === "TRANSIENT") {
        root.stateMode = root.previousState || "IDLE";
      }
      return;
    }

    let nextStack = root.notificationStack.slice(1);
    root.notificationStack = nextStack;

    if (root.notificationStack.length > 0) {
      let nextNotif = root.notificationStack[0];
      startNotificationTimer(nextNotif.timeoutMs);
    } else {
      transientTimer.stop();
      if (root.stateMode === "TRANSIENT") {
        root.stateMode = root.previousState || "IDLE";
      }
    }
  }

  // Clear entire deck at once
  function clearNotificationStack() {
    if (transitionToNextSequence.running) transitionToNextSequence.stop();
    if (dismissLastSequence.running) dismissLastSequence.stop();
    if (focusLaunchSequence.running) focusLaunchSequence.stop();
    if (flyOutLastSequence.running) flyOutLastSequence.stop();

    root.isTransitioning = false;
    root.incomingNotification = null;
    root.deckShiftProgress = 0.0;
    root.isDismissing = false;
    root.currentCardOffsetY = 0;
    root.currentCardOpacity = 1.0;
    root.currentCardScale = 1.0;
    root.incomingCardOffsetY = 36;
    root.incomingCardOpacity = 0.0;
    root.incomingCardScale = 1.0;
    root.notificationStack = [];
    transientTimer.stop();
    if (root.stateMode === "TRANSIENT") {
      root.stateMode = root.previousState || "IDLE";
    }
    if (root.ipc && root.ipc.clearNotifications) {
      root.ipc.clearNotifications();
    }
  }

  // Start / restart timer for front card
  function startNotificationTimer(timeoutMs) {
    transientTimer.stop();
    let ms = (timeoutMs && timeoutMs > 0) ? timeoutMs : (Config.notificationTimeoutMs || 3500);
    transientTimer.interval = ms;
    if (!root.isIslandHovered) {
      transientTimer.restart();
    }
  }

  // Backward-compatible triggerNotification
  function triggerNotification(summary, body, appName, timeoutMs, urgency, notifId, icon, desktopEntry) {
    let t = (timeoutMs && timeoutMs > 0) ? timeoutMs : (Config.notificationTimeoutMs || (Config.notifications && Config.notifications.default_timeout_ms) || 3500);
    enqueueNotification({
      id: notifId || ("notif_" + Date.now() + "_" + Math.floor(Math.random() * 1000)),
      summary: summary && summary.length > 0 ? summary : "Notification",
      body: body || "",
      appName: appName || "System",
      urgency: urgency || "normal",
      icon: icon || "",
      timeoutMs: t,
      desktopEntry: desktopEntry || ""
    });
  }

  // Focus or launch the application associated with a notification
  function activateNotificationApp(notif) {
    if (!notif) return;

    // Capture notifications: Direct action callback takes priority
    if (notif.action && typeof notif.action === "function") {
      notif.action();
      return;
    }

    // Capture notifications: Open annotator for screenshots with filePath
    if (notif.filePath && notif.filePath.length > 0 && root.ipc && root.ipc.openAnnotator) {
      root.ipc.openAnnotator(notif.filePath);
      return;
    }

    let app = (notif.appName || notif.desktopEntry || "").trim();
    if (!app || app.toLowerCase() === "system" || app.toLowerCase() === "ogsshell" || app.toLowerCase() === "ogsshell capture") {
      return;
    }

    let found = false;
    let appLower = app.toLowerCase();
    let toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
    for (let i = 0; i < toplevels.length; i++) {
      let win = toplevels[i];
      let winClass = (win.initialClass || win.class || "").toLowerCase();
      let winTitle = (win.title || "").toLowerCase();
      if (winClass.includes(appLower) || winTitle.includes(appLower) || appLower.includes(winClass)) {
        if (win.address) {
          Hyprland.dispatch("focuswindow address:" + win.address);
          found = true;
          break;
        }
      }
    }

    if (!found) {
      if (root.ipc && root.ipc.launchApp) {
        root.ipc.launchApp(notif.desktopEntry || "", appLower);
      }
    }
  }

  // Dynamic geometry derived from active form-factor (Island vs Notch)
  implicitWidth: {
    let _rev = Config.configRevision
    // Recording pill compact width (overrides IDLE/HOVER when recording is active)
    let isRec = root.ipc && root.ipc.isRecording
    if (isRec && stateMode !== "EXPANDED" && stateMode !== "TRANSIENT") {
      return root.isIslandHovered ? 260 : 210
    }
    switch (stateMode) {
      case "HOVER":     return Config.isNotch ? Config.notchHoverWidth : Config.islandHoverWidth
      case "TRANSIENT": return Config.isNotch ? Config.notchTransientWidth : Config.islandTransientWidth
      case "EXPANDED":
        if (expandedActiveTab === "CONTROL_CENTER") {
          return (controlCenterLoader.item && controlCenterLoader.item.preferredIslandWidth) ? controlCenterLoader.item.preferredIslandWidth : (Config.isNotch ? Config.notchExpandedWidth : Config.islandExpandedWidth)
        }
        if (expandedActiveTab === "LAUNCHER") {
          return 520
        }
        if (expandedActiveTab === "MEDIA") {
          return 390
        }
        return Config.isNotch ? Config.notchExpandedWidth : Config.islandExpandedWidth
      default:          return Config.isNotch ? Config.notchIdleWidth : Config.islandIdleWidth
    }
  }

  implicitHeight: {
    let _rev = Config.configRevision
    switch (stateMode) {
      case "HOVER":     return Config.isNotch ? Config.notchHoverHeight : Config.islandHoverHeight
      case "TRANSIENT": return Config.isNotch ? Config.notchTransientHeight : Config.islandTransientHeight
      case "EXPANDED":
        if (expandedActiveTab === "CONTROL_CENTER") {
          return (controlCenterLoader.item && controlCenterLoader.item.preferredIslandHeight) ? controlCenterLoader.item.preferredIslandHeight : (Config.isNotch ? Config.notchExpandedHeight : Config.islandExpandedHeight)
        }
        if (expandedActiveTab === "LAUNCHER") {
          return 440
        }
        if (expandedActiveTab === "MEDIA") {
          return 170
        }
        return Config.isNotch ? Config.notchExpandedHeight : Config.islandExpandedHeight
      default:          return Config.isNotch ? Config.notchIdleHeight : Config.islandIdleHeight
    }
  }

  width: implicitWidth
  height: implicitHeight

  // Active parameters
  readonly property real activeRadius: {
    let _rev = Config.configRevision
    if (Config.isNotch) {
      let rawR = root.stateMode === "EXPANDED" ? Config.notchBottomRadiusExpanded : Config.notchBottomRadius
      return Math.min(rawR, root.height * 0.48)
    } else {
      return root.stateMode === "EXPANDED" ? Config.islandRadiusExpanded : (root.stateMode === "TRANSIENT" ? (Config.islandRadiusFull + 4) : Config.islandRadiusFull)
    }
  }

  // Proportional tall-slope notch parameters (Tight horizontal spread, generous vertical drape)
  readonly property real notchEarW: 5
  readonly property real notchEarH: Math.min(16, root.height * 0.45)

  readonly property color surfaceColor: (root.stateMode === "EXPANDED" || root.stateMode === "TRANSIENT") ? Style.bgSecondary : Style.bgPrimary

  // ==========================================
  // High-Performance GPU-Accelerated Animations (Fluid Easing Curves)
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
  // 3D Notification Deck: Tier 3 & Tier 2 Background Cards
  // Stacked depth visualization when multiple notifications are pending
  // =========================================================================
  NotificationDeckBackground {
    id: deckTier3
    tierLevel: 3
    isNotch: Config.isNotch
    baseWidth: root.width
    baseHeight: root.height
    activeRadius: root.activeRadius
    surfaceColor: root.surfaceColor
    visibleTier: root.stateMode === "TRANSIENT" && root.notificationCount >= 3
    urgency: root.thirdNotification ? (root.thirdNotification.urgency || "normal") : "normal"
    shiftProgress: root.deckShiftProgress
    hasCardBehind: root.notificationCount >= 4
    z: -3
  }

  NotificationDeckBackground {
    id: deckTier2
    tierLevel: 2
    isNotch: Config.isNotch
    baseWidth: root.width
    baseHeight: root.height
    activeRadius: root.activeRadius
    surfaceColor: root.surfaceColor
    visibleTier: root.stateMode === "TRANSIENT" && root.notificationCount >= 2
    urgency: root.secondNotification ? (root.secondNotification.urgency || "normal") : "normal"
    shiftProgress: root.deckShiftProgress
    hasCardBehind: root.notificationCount >= 3
    z: -2
  }

  // =========================================================================
  // SURFACE 1: Unified Vector Shape (Used for "notch" mode)
  // Borderless, pure black OLED silhouette with 8x MSAA anti-aliasing
  // =========================================================================
  RectangularGlow {
    id: notchShadowGlow
    anchors.fill: parent
    anchors.topMargin: (Config.shadowsEnabled && Config.shadowNotch) ? (root.stateMode === "EXPANDED" ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
    anchors.bottomMargin: (Config.shadowsEnabled && Config.shadowNotch) ? -(root.stateMode === "EXPANDED" ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
    glowRadius: (Config.shadowsEnabled && Config.shadowNotch) ? (root.stateMode === "EXPANDED" ? Config.shadowExpandedBlurRadius : Config.shadowBlurRadius) : 0
    spread: Config.shadowSpread
    color: Qt.rgba(0, 0, 0, (Config.shadowsEnabled && Config.shadowNotch) ? (root.stateMode === "EXPANDED" ? Config.shadowExpandedOpacity : Config.shadowOpacity) : 0)
    cornerRadius: root.activeRadius + glowRadius
    visible: (Config.shadowsEnabled && Config.shadowNotch) && Config.isNotch
    z: -1

    Behavior on glowRadius {
      NumberAnimation {
        duration: root.stateMode === "EXPANDED" ? Config.animation.duration_expanded : (root.stateMode === "TRANSIENT" ? Config.animation.duration_transient : Config.animation.duration_compact)
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color {
      ColorAnimation { duration: 220 }
    }
  }

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
  // Borderless, pure black OLED squircle with Dual Elevation Shadow
  // =========================================================================
  RectangularGlow {
    id: islandShadowGlow
    anchors.fill: islandSquircleShape
    anchors.topMargin: (Config.shadowsEnabled && Config.shadowIsland) ? (root.stateMode === "EXPANDED" ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
    anchors.bottomMargin: (Config.shadowsEnabled && Config.shadowIsland) ? -(root.stateMode === "EXPANDED" ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0
    glowRadius: (Config.shadowsEnabled && Config.shadowIsland) ? (root.stateMode === "EXPANDED" ? Config.shadowExpandedBlurRadius : Config.shadowBlurRadius) : 0
    spread: Config.shadowSpread
    color: Qt.rgba(0, 0, 0, (Config.shadowsEnabled && Config.shadowIsland) ? (root.stateMode === "EXPANDED" ? Config.shadowExpandedOpacity : Config.shadowOpacity) : 0)
    cornerRadius: root.activeRadius + glowRadius
    visible: (Config.shadowsEnabled && Config.shadowIsland) && !Config.isNotch
    z: -1

    Behavior on glowRadius {
      NumberAnimation {
        duration: root.stateMode === "EXPANDED" ? Config.animation.duration_expanded : (root.stateMode === "TRANSIENT" ? Config.animation.duration_transient : Config.animation.duration_compact)
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color {
      ColorAnimation { duration: 220 }
    }
  }

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
        duration: root.stateMode === "EXPANDED" ? Config.animation.duration_expanded : (root.stateMode === "TRANSIENT" ? Config.animation.duration_transient : Config.animation.duration_compact)
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
        if (root.stateMode === "TRANSIENT") {
          transientTimer.stop()
        }
      } else {
        if (root.stateMode === "HOVER") {
          root.stateMode = "IDLE"
        }
        if (root.stateMode === "EXPANDED") {
          expandedUnhoverTimer.restart()
        }
        if (root.stateMode === "TRANSIENT" && root.notificationStack.length > 0) {
          transientTimer.restart()
        }
      }
    }
  }

  // Left-Click Gesture: If transient notification, activates app with tactile pulse animation & dismisses
  // If recording is active in non-expanded mode, stops the recording
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      if (root.stateMode === "TRANSIENT") {
        root.dismissFront(true)
        return
      }
      if (root.ipc && root.ipc.isRecording && root.stateMode !== "EXPANDED") {
        root.ipc.stopRecording()
      }
    }
  }

  // Middle-Click Gesture: Dismisses front notification; second card ascends with spring physics
  TapHandler {
    acceptedButtons: Qt.MiddleButton
    onTapped: {
      if (root.stateMode === "TRANSIENT") {
        root.dismissFront(false)
      }
    }
  }

  // Right-Click Gesture: In TRANSIENT mode, clears entire notification deck; in HOVER/IDLE, opens Control Center
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: {
      if (root.stateMode === "TRANSIENT") {
        root.clearNotificationStack()
        return
      }
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
      opacity: ((root.stateMode === "IDLE" || root.stateMode === "HOVER") && (!root.ipc || !root.ipc.isRecording)) ? 1.0 : 0.0
      visible: opacity > 0.0

      Behavior on opacity {
        NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutQuad }
      }

      // Left Slot: MPRIS Media Status (Fades & Scales smoothly on hover)
      MediaWidget {
        id: mediaWidget
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(150, Math.floor(parent.width * 0.32))
        height: 30
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
        height: 30
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
    // Layer 1.5: Live Recording Pill (RECORDING state overrides IDLE/HOVER)
    // Pulsing red dot + live mm:ss timer + mic icon + hover stop button
    // ==========================================
    Item {
      id: recordingLayer
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      anchors.topMargin: 4
      anchors.bottomMargin: 4
      opacity: (root.ipc && root.ipc.isRecording && root.stateMode !== "EXPANDED" && root.stateMode !== "TRANSIENT") ? 1.0 : 0.0
      visible: opacity > 0.0

      Behavior on opacity {
        NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutQuad }
      }

      Row {
        anchors.centerIn: parent
        spacing: 8

        // Pulsing red recording dot
        Rectangle {
          width: 10
          height: 10
          radius: 5
          color: "#ed4245"
          anchors.verticalCenter: parent.verticalCenter

          SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: recordingLayer.visible
            NumberAnimation { from: 1.0; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
          }
        }

        // Live timer counter (mm:ss)
        Text {
          text: {
            let secs = (root.ipc && root.ipc.recordingDuration) ? root.ipc.recordingDuration : 0
            let m = Math.floor(secs / 60)
            let s = secs % 60
            return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s)
          }
          color: "#ed4245"
          font.family: Style.fontMono || Style.fontText
          font.pixelSize: 13
          font.weight: Font.Bold
          anchors.verticalCenter: parent.verticalCenter
        }

        // Microphone icon
        Text {
          text: "🎙"
          font.pixelSize: 12
          anchors.verticalCenter: parent.verticalCenter
        }

        // Hover-revealed stop button
        Rectangle {
          width: stopBtnRow.implicitWidth + 14
          height: 22
          radius: 11
          color: stopBtnMouse.containsMouse ? Qt.rgba(237/255, 66/255, 69/255, 0.35) : Qt.rgba(237/255, 66/255, 69/255, 0.15)
          border.color: "#ed4245"
          border.width: 1
          visible: root.isIslandHovered
          anchors.verticalCenter: parent.verticalCenter

          Row {
            id: stopBtnRow
            anchors.centerIn: parent
            spacing: 4

            Text {
              text: "⏹"
              font.pixelSize: 11
              color: "#ed4245"
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: "Kaydı Bitir"
              color: "#ed4245"
              font.family: Style.fontText
              font.pixelSize: 11
              font.weight: Font.DemiBold
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: stopBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.ipc && root.ipc.stopRecording) {
                root.ipc.stopRecording();
              }
            }
          }
        }
      }
    }

    // ==========================================
    // Layer 2: Transient Notification View
    // ==========================================
    Item {
      id: transientLayer
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      anchors.topMargin: 8
      anchors.bottomMargin: 8
      clip: true
      opacity: root.stateMode === "TRANSIENT" ? 1.0 : 0.0
      visible: opacity > 0.0

      Behavior on opacity {
        NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutQuad }
      }

      // Primary (Active / Outgoing) Notification Card Container
      Item {
        id: currentCardContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        opacity: root.currentCardOpacity
        scale: root.currentCardScale
        transformOrigin: Item.Center
        transform: Translate {
          y: root.currentCardOffsetY
        }

        NotificationCardView {
          anchors.fill: parent
          summary: root.transientSummary
          body: root.transientBody
          appName: root.transientAppName
          urgency: root.transientUrgency
          icon: root.transientIcon
          remainingStackCount: Math.max(0, root.notificationCount - 1)
          isTransitioning: root.isTransitioning
          notificationType: root.transientType
          thumbnail: root.transientThumbnail
          filePath: root.transientFilePath
          openAction: root.transientAction
        }
      }

      // Incoming (Next in Deck) Notification Card Container - Active only during dual-card slide transition
      Item {
        id: incomingCardContainer
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        visible: root.isTransitioning && root.incomingNotification !== null
        opacity: root.incomingCardOpacity
        scale: root.incomingCardScale
        transformOrigin: Item.Center
        transform: Translate {
          y: root.incomingCardOffsetY
        }

        NotificationCardView {
          anchors.fill: parent
          summary: root.incomingNotification ? (root.incomingNotification.summary || "") : ""
          body: root.incomingNotification ? (root.incomingNotification.body || "") : ""
          appName: root.incomingNotification ? (root.incomingNotification.appName || "System") : "System"
          urgency: root.incomingNotification ? (root.incomingNotification.urgency || "normal") : "normal"
          icon: root.incomingNotification ? (root.incomingNotification.icon || "") : ""
          remainingStackCount: Math.max(0, root.notificationCount - 2)
          isTransitioning: true
          notificationType: root.incomingNotification ? (root.incomingNotification.type || "normal") : "normal"
          thumbnail: root.incomingNotification ? (root.incomingNotification.thumbnail || "") : ""
          filePath: root.incomingNotification ? (root.incomingNotification.filePath || "") : ""
          openAction: root.incomingNotification ? (root.incomingNotification.action || null) : null
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
        NumberAnimation { duration: Config.animation.duration_compact; easing.type: Easing.OutQuad }
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
        root.dismissFront()
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
