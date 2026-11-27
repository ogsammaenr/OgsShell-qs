pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import ".."

Item {
  id: root
  visible: false

  // =========================================================================
  // Core Lock Session State
  // =========================================================================
  property bool locked: false
  property bool capturing: false
  property int captureRevision: 0
  property var capturedPaths: ({})

  // Shared Interactive Auth State (synchronized across multi-monitor lock surfaces)
  property bool inputExpanded: false
  property string passwordText: ""
  property bool authenticating: false
  property string errorMessage: ""
  property int failedAttempts: 0
  property int authFailedCount: 0
  property bool capsLockOn: false

  readonly property string currentUser: {
    let u = Quickshell.env("USER")
    return (u && u.trim().length > 0) ? u.trim() : "excalibur"
  }

  // Internal transient credential buffer (wiped immediately upon PAM respond)
  property string _pendingPassword: ""
  property var _pendingCapturedMap: ({})

  // =========================================================================
  // Native Linux PAM Context (Quickshell.Services.Pam)
  // =========================================================================
  PamContext {
    id: pam
    config: Config.lockscreenPamConfig || "login"
    user: root.currentUser

    onPamMessage: {
      if (pam.responseRequired) {
        let secret = root._pendingPassword
        root._pendingPassword = ""
        pam.respond(secret)
      } else if (pam.messageIsError && pam.message && pam.message.length > 0) {
        root.errorMessage = pam.message
      }
    }

    onCompleted: result => {
      root.authenticating = false
      root._pendingPassword = ""

      if (result === PamResult.Success) {
        console.log("[LockScreen] PAM authentication succeeded.")
        root.unlock()
      } else {
        root.failedAttempts++
        root.authFailedCount++
        root.passwordText = ""
        root.inputExpanded = true
        if (result === PamResult.MaxTries) {
          root.errorMessage = "Çok fazla hatalı deneme"
        } else if (result === PamResult.Error) {
          root.errorMessage = "Doğrulama hatası"
        } else {
          root.errorMessage = "Hatalı parola"
        }
        console.warn("[LockScreen] PAM authentication failed:", PamResult.toString(result))
      }
    }

    onError: err => {
      root.authenticating = false
      root._pendingPassword = ""
      root.authFailedCount++
      root.inputExpanded = true
      root.errorMessage = "PAM hatası: " + PamError.toString(err)
      console.warn("[LockScreen] PAM error:", PamError.toString(err))
    }
  }

  // =========================================================================
  // Pre-Lock Live Screenshot Capture Pipeline (Per-Monitor Parallel grim)
  // =========================================================================
  Timer {
    id: preCaptureDelayTimer
    interval: 45
    repeat: false
    onTriggered: root._runScreenCapture()
  }

  Timer {
    id: captureFallbackTimer
    interval: 900
    repeat: false
    onTriggered: {
      if (root.capturing && !root.locked) {
        console.warn("[LockScreen] Screenshot capture timed out; locking immediately.")
        root._finalizeLock()
      }
    }
  }

  Process {
    id: captureProc
    running: false
    onExited: {
      if (root.capturing && !root.locked) {
        root._finalizeLock()
      }
    }
  }

  Process {
    id: cleanupProc
    running: false
  }

  function _sanitizeName(name) {
    return (name || "default").replace(/[^a-zA-Z0-9_-]/g, "_")
  }

  function screenshotPathFor(screenName) {
    let key = screenName || ""
    if (root.capturedPaths && root.capturedPaths[key]) {
      return root.capturedPaths[key]
    }
    return ""
  }

  function _runScreenCapture() {
    let rev = root.captureRevision + 1
    let screens = Quickshell.screens
    let nextMap = {}
    let cmds = ["rm -f /tmp/ogs_lock_*.png"]

    if (screens && screens.length > 0) {
      let grabParts = []
      for (let i = 0; i < screens.length; i++) {
        let sName = screens[i].name
        let safe = _sanitizeName(sName)
        let outPath = "/tmp/ogs_lock_" + safe + "_" + rev + ".png"
        nextMap[sName] = outPath
        // Shell-quote output name cleanly; -l 0 disables PNG compression for ~35ms capture
        let quotedName = "'" + sName.replace(/'/g, "'\\''") + "'"
        let quotedPath = "'" + outPath.replace(/'/g, "'\\''") + "'"
        grabParts.push("grim -l 0 -o " + quotedName + " " + quotedPath + " &")
      }
      cmds.push(grabParts.join(" ") + " wait")
    }

    root._pendingCapturedMap = nextMap
    captureFallbackTimer.restart()
    captureProc.running = false
    captureProc.command = ["sh", "-c", cmds.join("; ")]
    captureProc.running = true
  }

  function _finalizeLock() {
    captureFallbackTimer.stop()
    root.capturing = false
    root.capturedPaths = root._pendingCapturedMap || ({})
    root.captureRevision++
    root.inputExpanded = false
    root.passwordText = ""
    root._pendingPassword = ""
    root.errorMessage = ""
    root.authenticating = false
    root.failedAttempts = 0
    root.locked = true
    console.log("[LockScreen] Session locked. Revision:", root.captureRevision)
  }

  // =========================================================================
  // Public Control API
  // =========================================================================
  function lock() {
    if (root.locked || root.capturing) return

    // Dismiss any open overlays so the captured frame is clean
    PowerService.close()
    BottomNotchService.close()
    SnippingService.close()
    WindowInspectorService.close()

    root.capturing = true
    preCaptureDelayTimer.restart()
  }

  function unlock() {
    captureFallbackTimer.stop()
    preCaptureDelayTimer.stop()
    if (pam.active) {
      pam.abort()
    }
    root.locked = false
    root.capturing = false
    root.inputExpanded = false
    root.passwordText = ""
    root._pendingPassword = ""
    root.errorMessage = ""
    root.authenticating = false
    root.failedAttempts = 0
    root.capturedPaths = ({})

    // Privacy & disk cleanup
    cleanupProc.running = false
    cleanupProc.command = ["sh", "-c", "rm -f /tmp/ogs_lock_*.png"]
    cleanupProc.running = true
  }

  function expandInput() {
    if (!root.locked) return
    root.inputExpanded = true
  }

  function resetInput() {
    if (root.authenticating) return
    root.passwordText = ""
    root.errorMessage = ""
    root.inputExpanded = false
  }

  function setPasswordText(val) {
    if (root.authenticating) return
    let next = val || ""
    root.passwordText = next
    if (next.length > 0) {
      root.inputExpanded = true
      if (root.errorMessage.length > 0) {
        root.errorMessage = ""
      }
    }
  }

  function submitPassword() {
    if (!root.locked || root.authenticating) return
    if (!root.passwordText || root.passwordText.length === 0) {
      root.authFailedCount++
      root.errorMessage = "Lütfen parolanızı girin"
      root.inputExpanded = true
      return
    }

    root.authenticating = true
    root.errorMessage = ""
    root._pendingPassword = root.passwordText

    if (pam.active) {
      pam.abort()
    }

    let started = pam.start()
    if (!started) {
      root.authenticating = false
      root._pendingPassword = ""
      root.authFailedCount++
      root.errorMessage = "PAM oturumu başlatılamadı"
    }
  }
}
