pragma Singleton

import QtQuick
import Quickshell
import "../../../.."

QtObject {
  id: root

  // =========================================================================
  // 1. STOPWATCH ENGINE
  // =========================================================================
  property bool stopwatchRunning: false
  property double stopwatchStartTime: 0
  property int stopwatchAccumulatedMs: 0
  property int stopwatchElapsedMs: 0
  property var stopwatchLaps: []

  readonly property string stopwatchFormattedTime: formatMs(stopwatchElapsedMs, true)

  function startStopwatch() {
    if (stopwatchRunning) return
    stopwatchStartTime = Date.now()
    stopwatchRunning = true
  }

  function pauseStopwatch() {
    if (!stopwatchRunning) return
    stopwatchAccumulatedMs += (Date.now() - stopwatchStartTime)
    stopwatchElapsedMs = stopwatchAccumulatedMs
    stopwatchRunning = false
  }

  function toggleStopwatch() {
    if (stopwatchRunning) pauseStopwatch()
    else startStopwatch()
  }

  function resetStopwatch() {
    stopwatchRunning = false
    stopwatchStartTime = 0
    stopwatchAccumulatedMs = 0
    stopwatchElapsedMs = 0
    stopwatchLaps = []
  }

  function lapStopwatch() {
    let currentTotal = stopwatchElapsedMs
    let prevTotal = 0
    if (stopwatchLaps.length > 0) {
      prevTotal = stopwatchLaps[0].totalMs
    }
    let delta = currentTotal - prevTotal

    let newLap = {
      "lapNumber": stopwatchLaps.length + 1,
      "lapMs": delta,
      "totalMs": currentTotal,
      "lapFormatted": formatMs(delta, true),
      "totalFormatted": formatMs(currentTotal, true)
    }

    let updated = [newLap].concat(stopwatchLaps)
    stopwatchLaps = updated
  }

  // =========================================================================
  // 2. POMODORO ENGINE (Dual-Phase: Çalışma & Mola + Target Stack)
  // =========================================================================
  property bool pomodoroRunning: false
  property string pomodoroPhase: "work" // "work" | "break"

  // Configurable Durations & Goal
  property int pomodoroWorkMinutes: 25
  property int pomodoroBreakMinutes: 5
  property int pomodoroTargetSessions: 4
  property int pomodoroCompletedSessions: 0

  property int pomodoroRemainingSec: 25 * 60
  property int pomodoroTotalSec: 25 * 60

  readonly property string pomodoroFormattedTime: {
    let m = Math.floor(pomodoroRemainingSec / 60)
    let s = pomodoroRemainingSec % 60
    return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
  }

  readonly property real pomodoroProgress: pomodoroTotalSec > 0 ? (1.0 - (pomodoroRemainingSec / pomodoroTotalSec)) : 0.0

  signal pomodoroCompleted(string phaseName)

  function startPomodoro() {
    pomodoroRunning = true
  }

  function pausePomodoro() {
    pomodoroRunning = false
  }

  function togglePomodoro() {
    if (pomodoroRunning) pausePomodoro()
    else startPomodoro()
  }

  function stopPomodoro() {
    pomodoroRunning = false
    setPomodoroPhase(pomodoroPhase)
  }

  function resetPomodoro() {
    pomodoroRunning = false
    pomodoroCompletedSessions = 0
    setPomodoroPhase("work")
  }

  function setWorkMinutes(mins) {
    let clamped = Math.max(1, Math.min(120, mins))
    pomodoroWorkMinutes = clamped
    if (pomodoroPhase === "work" && !pomodoroRunning) {
      pomodoroTotalSec = clamped * 60
      pomodoroRemainingSec = clamped * 60
    }
  }

  function setBreakMinutes(mins) {
    let clamped = Math.max(1, Math.min(60, mins))
    pomodoroBreakMinutes = clamped
    if (pomodoroPhase === "break" && !pomodoroRunning) {
      pomodoroTotalSec = clamped * 60
      pomodoroRemainingSec = clamped * 60
    }
  }

  function setTargetSessions(count) {
    let clamped = Math.max(1, Math.min(16, count))
    pomodoroTargetSessions = clamped
  }

  function setPomodoroPhase(phase) {
    pomodoroPhase = phase
    pomodoroRunning = false
    if (phase === "work") {
      pomodoroTotalSec = pomodoroWorkMinutes * 60
      pomodoroRemainingSec = pomodoroWorkMinutes * 60
    } else {
      pomodoroTotalSec = pomodoroBreakMinutes * 60
      pomodoroRemainingSec = pomodoroBreakMinutes * 60
    }
  }

  function tickPomodoro() {
    if (!pomodoroRunning) return
    if (pomodoroRemainingSec > 0) {
      pomodoroRemainingSec--
      if (pomodoroRemainingSec === 0) {
        if (pomodoroPhase === "work") {
          pomodoroCompletedSessions++
          let wasTargetReached = pomodoroCompletedSessions >= pomodoroTargetSessions
          setPomodoroPhase("break")
          pomodoroRunning = true // Immediately transition and run break countdown

          if (wasTargetReached) {
            root.pomodoroCompleted("target_reached")
          } else {
            root.pomodoroCompleted("work")
          }
        } else {
          setPomodoroPhase("work")
          pomodoroRunning = true // Immediately transition and run next work session countdown
          root.pomodoroCompleted("break")
        }
      }
    }
  }

  // =========================================================================
  // 3. LIVE ACTIVITIES DECISION ENGINE
  // =========================================================================
  readonly property string activeLiveActivity: {
    if (stopwatchRunning || stopwatchElapsedMs > 0) {
      return "stopwatch"
    }
    if (pomodoroRunning || (pomodoroRemainingSec < pomodoroTotalSec && pomodoroRemainingSec > 0)) {
      return "pomodoro"
    }
    return "none"
  }

  readonly property color liveActivityColor: {
    if (activeLiveActivity === "stopwatch") return Style.accentGreen
    if (activeLiveActivity === "pomodoro") return Style.accentOrange
    return Style.accentCyan
  }

  readonly property string liveActivityTitle: {
    if (activeLiveActivity === "stopwatch") return formatMs(stopwatchElapsedMs, false)
    if (activeLiveActivity === "pomodoro") return pomodoroFormattedTime
    return ""
  }

  readonly property string liveActivitySubtitle: {
    if (activeLiveActivity === "stopwatch") return stopwatchRunning ? "Kronometre" : "Kronometre (Duraklatıldı)"
    if (activeLiveActivity === "pomodoro") {
      let phaseStr = pomodoroPhase === "work" ? "Çalışma" : "Mola"
      let countStr = " · " + pomodoroCompletedSessions + "/" + pomodoroTargetSessions
      return (pomodoroRunning ? phaseStr : (phaseStr + " Duraklatıldı")) + countStr
    }
    return ""
  }

  readonly property string liveActivityTargetTab: {
    if (activeLiveActivity === "stopwatch") return "STOPWATCH"
    if (activeLiveActivity === "pomodoro") return "POMODORO"
    return "WORLD"
  }

  // =========================================================================
  // 4. GLOBAL TIME & LOCATION ENGINE
  // =========================================================================
  property string selectedCity: "İstanbul"
  property string selectedCountry: "Türkiye"
  property int selectedUtcOffsetHours: 3 // Default TRT (UTC+3)
  property bool is24HourFormat: true
  property bool showSeconds: true
  property var currentDateTime: new Date()

  // 1-second master clock ticker
  property var masterClockTimer: Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      root.currentDateTime = new Date()
    }
  }

  // Reactive formatted time in chosen timezone and format
  readonly property string currentDisplayTime: {
    let utc = root.currentDateTime.getTime() + (root.currentDateTime.getTimezoneOffset() * 60000)
    let cityDate = new Date(utc + (3600000 * root.selectedUtcOffsetHours))
    let hh = cityDate.getHours()
    let mm = cityDate.getMinutes()

    let ampm = ""
    if (!root.is24HourFormat) {
      ampm = hh >= 12 ? " PM" : " AM"
      hh = hh % 12
      if (hh === 0) hh = 12
    }

    let hStr = hh < 10 ? "0" + hh : "" + hh
    let mStr = mm < 10 ? "0" + mm : "" + mm
    return hStr + ":" + mStr + ampm
  }

  readonly property string currentDisplaySeconds: {
    let utc = root.currentDateTime.getTime() + (root.currentDateTime.getTimezoneOffset() * 60000)
    let cityDate = new Date(utc + (3600000 * root.selectedUtcOffsetHours))
    let ss = cityDate.getSeconds()
    return ss < 10 ? "0" + ss : "" + ss
  }

  readonly property string currentDisplayDate: {
    let utc = root.currentDateTime.getTime() + (root.currentDateTime.getTimezoneOffset() * 60000)
    let cityDate = new Date(utc + (3600000 * root.selectedUtcOffsetHours))
    return Qt.formatDateTime(cityDate, "d MMM ddd")
  }

  readonly property string currentFullDate: {
    let utc = root.currentDateTime.getTime() + (root.currentDateTime.getTimezoneOffset() * 60000)
    let cityDate = new Date(utc + (3600000 * root.selectedUtcOffsetHours))
    return Qt.formatDateTime(cityDate, "dddd, d MMMM yyyy")
  }

  readonly property string currentUtcOffsetStr: "UTC" + (root.selectedUtcOffsetHours >= 0 ? "+" + root.selectedUtcOffsetHours : "" + root.selectedUtcOffsetHours)

  function setLocation(city, country, utcOffsetHours) {
    selectedCity = city
    selectedCountry = country
    selectedUtcOffsetHours = utcOffsetHours
  }

  // =========================================================================
  // Timers
  // =========================================================================
  // High-frequency Stopwatch Timer (approx 30fps update)
  property var stopwatchTimer: Timer {
    interval: 33
    running: root.stopwatchRunning
    repeat: true
    onTriggered: {
      if (root.stopwatchRunning) {
        root.stopwatchElapsedMs = root.stopwatchAccumulatedMs + (Date.now() - root.stopwatchStartTime)
      }
    }
  }

  // 1-second Pomodoro Timer
  property var pomodoroTimer: Timer {
    interval: 1000
    running: root.pomodoroRunning
    repeat: true
    onTriggered: {
      root.tickPomodoro()
    }
  }

  // Utility Time Formatter
  function formatMs(ms, includeHundredths) {
    let totalSec = Math.floor(ms / 1000)
    let m = Math.floor(totalSec / 60)
    let s = totalSec % 60
    let mStr = m < 10 ? "0" + m : m
    let sStr = s < 10 ? "0" + s : s

    if (includeHundredths) {
      let hundredths = Math.floor((ms % 1000) / 10)
      let hStr = hundredths < 10 ? "0" + hundredths : hundredths
      return mStr + ":" + sStr + "." + hStr
    } else {
      let tenths = Math.floor((ms % 1000) / 100)
      return mStr + ":" + sStr + "." + tenths
    }
  }
}
