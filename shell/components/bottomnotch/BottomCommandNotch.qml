import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.."
import "../../theme"
import "../../backend"

FocusScope {
  id: root

  // IPC Service Reference
  required property var ipc

  focus: true

  // Visibility & Open/Close State
  readonly property bool isOpen: BottomNotchService.isOpen

  // Dynamic Notch Ear Geometry (Mirrored from top notch in DynamicIsland.qml)
  readonly property real notchEarW: 5
  readonly property real notchEarH: Math.min(16, root.height * 0.45)
  readonly property real activeRadius: Math.min(Config.notchBottomRadiusExpanded, root.height * 0.48)

  // Surface colors
  readonly property color surfaceColor: hasSuggestions ? Style.bgSecondary : Style.bgPrimary

  // Dimensions
  readonly property bool hasSuggestions: suggestionsModel.count > 0
  readonly property int baseHeight: 52
  readonly property int expandedMaxHeight: 340
  readonly property int calculatedHeight: {
    if (!hasSuggestions) return baseHeight
    let listH = suggestionsList.contentHeight
    return Math.min(expandedMaxHeight, Math.max(baseHeight, 64 + listH))
  }

  implicitWidth: hasSuggestions ? 580 : 520
  implicitHeight: calculatedHeight
  width: implicitWidth
  height: implicitHeight

  // Animations on width and height
  Behavior on width {
    NumberAnimation {
      duration: Config.animation.duration_expanded
      easing.type: Easing.OutCubic
    }
  }

  Behavior on height {
    NumberAnimation {
      duration: Config.animation.duration_expanded
      easing.type: Easing.OutCubic
    }
  }

  // Slide up/down translation animation relative to screen bottom bezel
  property real slideProgress: isOpen ? 1.0 : 0.0
  Behavior on slideProgress {
    NumberAnimation {
      duration: isOpen ? 280 : 180
      easing.type: isOpen ? Easing.OutBack : Easing.InQuad
      easing.overshoot: 1.08
    }
  }

  // Translates downwards below screen when closed
  y: Math.round((1.0 - slideProgress) * (root.height + 24))
  opacity: Math.max(0.0, Math.min(1.0, slideProgress * 1.2))

  // Auto focus when opened
  Connections {
    target: BottomNotchService
    function onOpened() {
      cmdInput.text = BottomNotchService.initialQuery || ""
      cmdInput.forceActiveFocus()
      updateSuggestions()
    }
    function onClosed() {
      cmdInput.text = ""
      suggestionsModel.clear()
    }
  }

  // Command Execution Process
  Process {
    id: cmdExecProc
    onExited: (code, status) => {
      console.log("[BottomNotch] Command process finished. Exit code:", code)
    }
  }

  function executeExternal(args) {
    if (!args || args.length === 0) return
    console.log("[BottomNotch] Spawning process:", JSON.stringify(args))
    cmdExecProc.running = false
    cmdExecProc.command = args
    cmdExecProc.running = true
  }

  // =========================================================================
  // SURFACE 1: RectangularGlow (Upward Glow into the screen)
  // =========================================================================
  RectangularGlow {
    id: notchShadowGlow
    anchors.fill: parent
    anchors.topMargin: -((Config.shadowsEnabled && Config.shadowNotch) ? (hasSuggestions ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0)
    anchors.bottomMargin: ((Config.shadowsEnabled && Config.shadowNotch) ? (hasSuggestions ? Config.shadowExpandedVerticalOffset : Config.shadowVerticalOffset) : 0)
    glowRadius: (Config.shadowsEnabled && Config.shadowNotch) ? (hasSuggestions ? Config.shadowExpandedBlurRadius : Config.shadowBlurRadius) : 0
    spread: Config.shadowSpread
    color: Qt.rgba(0, 0, 0, (Config.shadowsEnabled && Config.shadowNotch) ? (hasSuggestions ? Config.shadowExpandedOpacity : Config.shadowOpacity) : 0)
    cornerRadius: root.activeRadius + glowRadius
    visible: (Config.shadowsEnabled && Config.shadowNotch)
    z: -1

    Behavior on glowRadius {
      NumberAnimation {
        duration: Config.animation.duration_compact
        easing.type: Easing.OutCubic
      }
    }
    Behavior on color { ColorAnimation { duration: 220 } }
  }

  // =========================================================================
  // SURFACE 2: Inverted Notch Vector Shape (Exact Mirrored Bézier Curvature)
  // =========================================================================
  Shape {
    id: invertedNotchShape
    anchors.fill: parent
    anchors.leftMargin: -root.notchEarW
    anchors.rightMargin: -root.notchEarW

    // 8x/4x Multi-Sample Anti-Aliasing for razor-sharp Retina lines
    layer.enabled: true
    layer.samples: 4
    layer.smooth: true

    ShapePath {
      strokeWidth: 0
      strokeColor: "transparent"
      fillColor: root.surfaceColor
      startX: 0
      startY: root.height

      // 1. Left Ear: Smooth Cubic Bezier rising UP & RIGHT from bottom edge
      PathCubic {
        control1X: root.notchEarW * 0.35
        control1Y: root.height
        control2X: root.notchEarW
        control2Y: root.height - root.notchEarH * 0.65
        x: root.notchEarW
        y: root.height - root.notchEarH
      }

      // 2. Left Vertical Wall
      PathLine {
        x: root.notchEarW
        y: root.activeRadius
      }

      // 3. Top-Left Corner Arc (Clockwise turning into top ceiling)
      PathArc {
        x: root.notchEarW + root.activeRadius
        y: 0
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Clockwise
      }

      // 4. Top Ceiling Line
      PathLine {
        x: root.notchEarW + root.width - root.activeRadius
        y: 0
      }

      // 5. Top-Right Corner Arc (Clockwise turning down into right wall)
      PathArc {
        x: root.notchEarW + root.width
        y: root.activeRadius
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Clockwise
      }

      // 6. Right Vertical Wall
      PathLine {
        x: root.notchEarW + root.width
        y: root.height - root.notchEarH
      }

      // 7. Right Ear: Smooth Cubic Bezier dipping DOWN & RIGHT into bottom edge
      PathCubic {
        control1X: root.notchEarW + root.width
        control1Y: root.height - root.notchEarH * 0.65
        control2X: root.notchEarW + root.width + root.notchEarW * 0.65
        control2Y: root.height
        x: root.notchEarW * 2 + root.width
        y: root.height
      }

      // 8. Bottom Edge: Closes solid fill flush against screen bottom bezel
      PathLine {
        x: 0
        y: root.height
      }
    }
  }

  // Subtle Border Outline for Contrast on Non-OLED screens
  Shape {
    id: invertedNotchBorder
    anchors.fill: invertedNotchShape
    layer.enabled: true
    layer.samples: 4
    layer.smooth: true
    opacity: 0.25

    ShapePath {
      strokeWidth: 1
      strokeColor: Style.borderSubtle
      fillColor: "transparent"
      startX: 0
      startY: root.height

      PathCubic {
        control1X: root.notchEarW * 0.35
        control1Y: root.height
        control2X: root.notchEarW
        control2Y: root.height - root.notchEarH * 0.65
        x: root.notchEarW
        y: root.height - root.notchEarH
      }

      PathLine {
        x: root.notchEarW
        y: root.activeRadius
      }

      PathArc {
        x: root.notchEarW + root.activeRadius
        y: 0
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Clockwise
      }

      PathLine {
        x: root.notchEarW + root.width - root.activeRadius
        y: 0
      }

      PathArc {
        x: root.notchEarW + root.width
        y: root.activeRadius
        radiusX: root.activeRadius
        radiusY: root.activeRadius
        direction: PathArc.Clockwise
      }

      PathLine {
        x: root.notchEarW + root.width
        y: root.height - root.notchEarH
      }

      PathCubic {
        control1X: root.notchEarW + root.width
        control1Y: root.height - root.notchEarH * 0.65
        control2X: root.notchEarW + root.width + root.notchEarW * 0.65
        control2Y: root.height
        x: root.notchEarW * 2 + root.width
        y: root.height
      }
    }
  }

  // =========================================================================
  // DATA MODEL & SUGGESTION PARSER
  // =========================================================================
  ListModel {
    id: suggestionsModel
  }

  function getThemeColors(thm) {
    if (!thm) return ["#7aa2f7", "#bb9af7", "#9ece6a", "#1a1b26"]
    let c = thm.colors || thm
    let a1 = c.accent || "#7aa2f7"
    let a2 = c.accent_secondary || c.accentSecondary || "#bb9af7"
    let a3 = c.green || c.accentGreen || c.cyan || "#9ece6a"
    let a4 = c.surface || c.bgCard || c.bg || "#1a1b26"
    return [a1, a2, a3, a4]
  }

  function updateSuggestions() {
    suggestionsModel.clear()
    let raw = cmdInput.text.trim()
    let query = raw.startsWith(":") ? raw.substring(1) : raw
    let parts = query.split(/\s+/)
    let verb = (parts[0] || "").toLowerCase()
    let arg1 = (parts[1] || "").toLowerCase()
    let arg2 = (parts[2] || "").toLowerCase()

    // 1. Theme Management (:theme)
    if (verb === "theme" || verb === "th" || (verb.length > 0 && "theme".startsWith(verb))) {
      let themes = (ipc && ipc.availableThemes && ipc.availableThemes.length > 0)
        ? ipc.availableThemes
        : [
            { "id": "catppuccin", "name": "Catppuccin Macchiato", "colors": { "accent": "#c6a0f6", "accent_secondary": "#f5bde6", "green": "#a6da95", "surface": "#24273a" } },
            { "id": "tokyonight", "name": "Tokyo Night", "colors": { "accent": "#7aa2f7", "accent_secondary": "#bb9af7", "green": "#9ece6a", "surface": "#1a1b26" } },
            { "id": "everforest", "name": "Everforest Dark", "colors": { "accent": "#a7c080", "accent_secondary": "#dbbc7f", "green": "#83c092", "surface": "#1e2326" } },
            { "id": "nord", "name": "Nord", "colors": { "accent": "#88c0d0", "accent_secondary": "#81a1c1", "green": "#a3be8c", "surface": "#2e3440" } },
            { "id": "gruvbox", "name": "Gruvbox Dark", "colors": { "accent": "#d65d0e", "accent_secondary": "#fabd2f", "green": "#98971a", "surface": "#282828" } },
            { "id": "monochrome", "name": "Monochrome Minimal", "colors": { "accent": "#e0e0e0", "accent_secondary": "#888888", "green": "#aaaaaa", "surface": "#141416" } }
          ]

      for (let i = 0; i < themes.length; i++) {
        let t = themes[i]
        let tId = (t.id || "").toLowerCase()
        let tName = (t.name || tId).toLowerCase()
        if (arg1 === "" || tId.indexOf(arg1) !== -1 || tName.indexOf(arg1) !== -1) {
          let cols = getThemeColors(t)
          suggestionsModel.append({
            "type": "theme",
            "title": t.name || t.id,
            "subtitle": t.id === (ipc.currentTheme ? ipc.currentTheme.id : "") ? "Aktif Tema" : "Temayı Uygula",
            "command": ":theme " + t.id,
            "themeId": t.id,
            "color1": cols[0],
            "color2": cols[1],
            "color3": cols[2],
            "color4": cols[3],
            "isActive": t.id === (ipc.currentTheme ? ipc.currentTheme.id : ""),
            "thumb": ""
          })
        }
      }
      return
    }

    // 2. Wallpaper Management (:wall)
    if (verb === "wall" || verb === "wallpaper" || (verb.length > 0 && "wall".startsWith(verb))) {
      // Option: Next Wallpaper
      if (arg1 === "" || "next".startsWith(arg1)) {
        suggestionsModel.append({
          "type": "wall_action",
          "title": "Sonraki Duvar Kağıdı (Next)",
          "subtitle": "Aktif temanın havuzundaki sıradaki görsele geçer",
          "command": ":wall next",
          "themeId": "",
          "color1": "", "color2": "", "color3": "", "color4": "",
          "isActive": false,
          "thumb": ""
        })
      }

      let walls = (ipc && ipc.themeWallpapers) ? ipc.themeWallpapers : []
      for (let j = 0; j < walls.length; j++) {
        let p = walls[j]
        let filename = p.substring(p.lastIndexOf("/") + 1)
        if (arg1 === "" || filename.toLowerCase().indexOf(arg1) !== -1) {
          suggestionsModel.append({
            "type": "wallpaper",
            "title": filename,
            "subtitle": p === (ipc ? ipc.activeWallpaper : "") ? "Aktif Duvar Kağıdı" : "Duvar Kağıdını Seç",
            "command": ":wall " + filename,
            "themeId": p,
            "color1": "", "color2": "", "color3": "", "color4": "",
            "isActive": p === (ipc ? ipc.activeWallpaper : ""),
            "thumb": p
          })
        }
      }
      return
    }

    // 3. Settings & Configuration (:set)
    if (verb === "set" || (verb.length > 0 && "set".startsWith(verb))) {
      let settingOptions = [
        {
          "key": "focus",
          "name": "Focus Mode",
          "val": Config.focusMode ? "Açık (ON)" : "Kapalı (OFF)",
          "cmdOn": ":set focus on",
          "cmdOff": ":set focus off",
          "desc": "Tiling pencereleri ekranın en tepesine kadar genişletir"
        },
        {
          "key": "factor",
          "name": "Form Faktörü",
          "val": Config.isNotch ? "Notch (Çentik)" : "Island (Dinamik Ada)",
          "cmdOn": ":set factor island",
          "cmdOff": ":set factor notch",
          "desc": "Yüzen ada ile üst panele yapışık çentik arasında geçiş yapar"
        },
        {
          "key": "corners",
          "name": "Ekran Köşe Yuvarlatması",
          "val": Config.screenCornersEnabled ? "Açık (ON)" : "Kapalı (OFF)",
          "cmdOn": ":set corners on",
          "cmdOff": ":set corners off",
          "desc": "Ekranın 4 köşesindeki OLED yuvarlatma maskelerini kontrol eder"
        },
        {
          "key": "dnd",
          "name": "Rahatsız Etme Modu (DND)",
          "val": (ipc && ipc.dndEnabled) ? "Açık (ON)" : "Kapalı (OFF)",
          "cmdOn": ":set dnd on",
          "cmdOff": ":set dnd off",
          "desc": "Ada üzerinde beliren bildirim pencerelerini susturur"
        },
        {
          "key": "volume",
          "name": "Ses Seviyesi (Volume)",
          "val": "%" + (Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 50),
          "cmdOn": ":set volume 75",
          "cmdOff": ":set volume 25",
          "desc": "0-100 arasında sistem genel ses seviyesini ayarlar"
        }
      ]

      for (let k = 0; k < settingOptions.length; k++) {
        let opt = settingOptions[k]
        if (arg1 === "" || opt.key.indexOf(arg1) !== -1 || opt.name.toLowerCase().indexOf(arg1) !== -1) {
          suggestionsModel.append({
            "type": "setting",
            "title": opt.name + " (" + opt.key + ")",
            "subtitle": "Mevcut: " + opt.val + " • " + opt.desc,
            "command": opt.cmdOn,
            "themeId": opt.key,
            "color1": "", "color2": "", "color3": "", "color4": "",
            "isActive": false,
            "thumb": ""
          })
        }
      }
      return
    }

    // 4. Mute (:mute)
    if (verb === "mute" || (verb.length > 0 && "mute".startsWith(verb))) {
      let isMuted = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
      suggestionsModel.append({
        "type": "action",
        "title": isMuted ? "Sesi Aç (Unmute)" : "Sesi Kapat (Mute)",
        "subtitle": "Sistem ana ses çıkışını susturur veya açar",
        "command": ":mute",
        "themeId": "mute",
        "color1": "", "color2": "", "color3": "", "color4": "",
        "isActive": isMuted,
        "thumb": ""
      })
      return
    }

    // 5. Session & Power Actions
    let powerActions = [
      { "cmd": ":lock", "title": "Ekranı Kilitle", "sub": "hyprlock ile masaüstünü kilitler", "icon": "󰌾" },
      { "cmd": ":sleep", "title": "Uyku Modu (Suspend)", "sub": "Sistemi RAM uyku durumuna geçirir", "icon": "󰤄" },
      { "cmd": ":reboot", "title": "Yeniden Başlat (Reboot)", "sub": "Bilgisayarı yeniden başlatır", "icon": "󰜉" },
      { "cmd": ":shutdown", "title": "Sistemi Kapat (Power Off)", "sub": "Bilgisayarı tamamen kapatır", "icon": "󰐥" }
    ]

    for (let pIdx = 0; pIdx < powerActions.length; pIdx++) {
      let pa = powerActions[pIdx]
      let pVerb = pa.cmd.substring(1)
      if (verb === pVerb || (verb.length > 0 && pVerb.startsWith(verb))) {
        suggestionsModel.append({
          "type": "power",
          "title": pa.title,
          "subtitle": pa.sub,
          "command": pa.cmd,
          "themeId": pVerb,
          "color1": "", "color2": "", "color3": "", "color4": "",
          "isActive": false,
          "thumb": pa.icon
        })
      }
    }

    // Default: If user just typed ":" or letters matching main verbs, show overview hints
    if (suggestionsModel.count === 0 && (raw === "" || raw === ":" || raw.length <= 2)) {
      let menuHints = [
        { "c": ":theme ", "t": "🎨 Tema Değiştir", "s": "Tokyo Night, Catppuccin, Everforest..." },
        { "c": ":wall ", "t": "🖼️ Duvar Kağıdı", "s": "Temaya ait havuz veya :wall next" },
        { "c": ":set ", "t": "⚙️ Kabuk Ayarları", "s": "focus, factor, corners, dnd, volume..." },
        { "c": ":lock", "t": "󰌾 Oturumu Kilitle", "s": "hyprlock ekran kilitleyiciyi çalıştırır" },
        { "c": ":sleep", "t": "󰤄 Uyku Modu", "s": "systemctl suspend" },
        { "c": ":reboot", "t": "󰜉 Yeniden Başlat", "s": "systemctl reboot" },
        { "c": ":shutdown", "t": "󰐥 Sistemi Kapat", "s": "systemctl poweroff" }
      ]
      for (let m = 0; m < menuHints.length; m++) {
        let mh = menuHints[m]
        let mClean = mh.c.trim().substring(1)
        if (verb === "" || mClean.startsWith(verb)) {
          suggestionsModel.append({
            "type": "hint",
            "title": mh.t,
            "subtitle": mh.s,
            "command": mh.c,
            "themeId": "",
            "color1": "", "color2": "", "color3": "", "color4": "",
            "isActive": false,
            "thumb": ""
          })
        }
      }
    }

    if (suggestionsModel.count > 0 && suggestionsList.currentIndex === -1) {
      suggestionsList.currentIndex = 0
    }
  }

  // =========================================================================
  // COMMAND EXECUTION ENGINE
  // =========================================================================
  function executeCommandString(cmdStr) {
    let clean = (cmdStr || "").trim()
    if (clean.length === 0) return
    let text = clean.startsWith(":") ? clean.substring(1).trim() : clean
    let parts = text.split(/\s+/)
    let verb = (parts[0] || "").toLowerCase()
    let arg1 = (parts[1] || "").toLowerCase()
    let arg2 = (parts[2] || "").toLowerCase()

    console.log("[BottomNotch] Executing command:", verb, "arg1:", arg1, "arg2:", arg2)

    // 1. Theme
    if (verb === "theme" || verb === "th") {
      if (arg1.length > 0) {
        if (ipc) ipc.setActiveTheme(arg1)
      }
      BottomNotchService.close()
      return
    }

    // 2. Wallpaper
    if (verb === "wall" || verb === "wallpaper") {
      if (arg1 === "next") {
        if (ipc) ipc.nextWallpaper()
      } else if (arg1.length > 0) {
        // Find matching wallpaper path
        let walls = (ipc && ipc.themeWallpapers) ? ipc.themeWallpapers : []
        let chosen = ""
        for (let i = 0; i < walls.length; i++) {
          if (walls[i].toLowerCase().indexOf(arg1) !== -1) {
            chosen = walls[i]
            break
          }
        }
        if (chosen.length > 0 && ipc) {
          ipc.setWallpaper(ipc.currentTheme ? ipc.currentTheme.id : "", chosen)
        }
      }
      BottomNotchService.close()
      return
    }

    // 3. Settings (:set)
    if (verb === "set") {
      if (arg1 === "focus") {
        let enable = (arg2 === "on" || arg2 === "1" || arg2 === "true") ? true : ((arg2 === "off" || arg2 === "0" || arg2 === "false") ? false : !Config.focusMode)
        Config.saveConfig({ "focus_mode": enable })
      } else if (arg1 === "factor" || arg1 === "form_factor") {
        let targetFactor = (arg2 === "notch") ? "notch" : ((arg2 === "island") ? "island" : (Config.isNotch ? "island" : "notch"))
        Config.saveConfig({ "form_factor": targetFactor })
      } else if (arg1 === "corners" || arg1 === "corner") {
        let enableCorners = (arg2 === "on" || arg2 === "1" || arg2 === "true") ? true : ((arg2 === "off" || arg2 === "0" || arg2 === "false") ? false : !Config.screenCornersEnabled)
        Config.saveConfig({ "screen_corners": { "enabled": enableCorners } })
      } else if (arg1 === "dnd") {
        let enableDnd = (arg2 === "on" || arg2 === "1" || arg2 === "true") ? true : ((arg2 === "off" || arg2 === "0" || arg2 === "false") ? false : !(ipc && ipc.dndEnabled))
        if (ipc) ipc.toggleDND(enableDnd)
      } else if (arg1 === "volume" || arg1 === "vol") {
        let volNum = parseInt(arg2)
        if (!isNaN(volNum)) {
          volNum = Math.max(0, Math.min(100, volNum))
          if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.volume = volNum / 100.0
          }
          executeExternal(["pamixer", "--set-volume", "" + volNum])
        }
      }
      BottomNotchService.close()
      return
    }

    // 4. Mute
    if (verb === "mute") {
      if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
      }
      executeExternal(["pamixer", "-t"])
      BottomNotchService.close()
      return
    }

    // 5. Power & Session
    if (verb === "lock") {
      executeExternal(["hyprlock"])
      BottomNotchService.close()
      return
    }
    if (verb === "sleep" || verb === "suspend") {
      executeExternal(["systemctl", "suspend"])
      BottomNotchService.close()
      return
    }
    if (verb === "reboot") {
      executeExternal(["systemctl", "reboot"])
      BottomNotchService.close()
      return
    }
    if (verb === "shutdown" || verb === "poweroff") {
      executeExternal(["systemctl", "poweroff"])
      BottomNotchService.close()
      return
    }

    // Fallback: If unknown, try closing
    BottomNotchService.close()
  }

  // =========================================================================
  // KEYBOARD NAVIGATION & SHORTCUTS
  // =========================================================================
  Keys.onEscapePressed: {
    BottomNotchService.close()
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Escape) {
      BottomNotchService.close()
      event.accepted = true
      return
    }

    if (event.key === Qt.Key_Down) {
      if (suggestionsModel.count > 0) {
        suggestionsList.currentIndex = (suggestionsList.currentIndex + 1) % suggestionsModel.count
        suggestionsList.positionViewAtIndex(suggestionsList.currentIndex, ListView.Contain)
        event.accepted = true
      }
      return
    }

    if (event.key === Qt.Key_Up) {
      if (suggestionsModel.count > 0) {
        suggestionsList.currentIndex = (suggestionsList.currentIndex - 1 + suggestionsModel.count) % suggestionsModel.count
        suggestionsList.positionViewAtIndex(suggestionsList.currentIndex, ListView.Contain)
        event.accepted = true
      }
      return
    }

    if (event.key === Qt.Key_Tab) {
      if (suggestionsModel.count > 0 && suggestionsList.currentIndex >= 0) {
        let item = suggestionsModel.get(suggestionsList.currentIndex)
        if (item && item.command) {
          cmdInput.text = item.command + " "
          cmdInput.cursorPosition = cmdInput.text.length
          updateSuggestions()
          event.accepted = true
        }
      }
      return
    }

    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (suggestionsModel.count > 0 && suggestionsList.currentIndex >= 0) {
        let cur = suggestionsModel.get(suggestionsList.currentIndex)
        if (cur && cur.command && !cur.command.endsWith(" ")) {
          executeCommandString(cur.command)
          event.accepted = true
          return
        }
      }
      executeCommandString(cmdInput.text)
      event.accepted = true
      return
    }
  }

  // =========================================================================
  // UI LAYOUT
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: root.notchEarW + 16
    anchors.rightMargin: root.notchEarW + 16
    anchors.topMargin: 12
    anchors.bottomMargin: 8
    spacing: 8

    // AREA 1: Interactive Suggestions Popover List (Expands Upwards)
    Item {
      id: suggestionsContainer
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.hasSuggestions
      clip: true

      ListView {
        id: suggestionsList
        anchors.fill: parent
        model: suggestionsModel
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        delegate: Rectangle {
          id: itemDelegate
          width: suggestionsList.width
          height: 44
          radius: 8
          color: suggestionsList.currentIndex === index
            ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.16)
            : (itemHover.containsMouse ? Style.surfaceHover : "transparent")
          border.color: suggestionsList.currentIndex === index ? Style.accent : "transparent"
          border.width: 1

          Behavior on color { ColorAnimation { duration: 120 } }
          Behavior on border.color { ColorAnimation { duration: 120 } }

          MouseArea {
            id: itemHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              suggestionsList.currentIndex = index
              root.executeCommandString(model.command)
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Preview or Icon: Theme Color Cubes, Wallpaper Thumbnail, or Glyph
            Item {
              implicitWidth: 32
              implicitHeight: 32
              Layout.alignment: Qt.AlignVCenter

              // Type: Theme 4-Color Cubes
              Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: 3
                visible: model.type === "theme"

                Rectangle { width: 10; height: 10; radius: 2; color: model.color1 || "#7aa2f7" }
                Rectangle { width: 10; height: 10; radius: 2; color: model.color2 || "#bb9af7" }
                Rectangle { width: 10; height: 10; radius: 2; color: model.color3 || "#9ece6a" }
                Rectangle { width: 10; height: 10; radius: 2; color: model.color4 || "#1a1b26" }
              }

              // Type: Wallpaper Thumbnail
              Rectangle {
                anchors.fill: parent
                radius: 4
                clip: true
                color: Style.surfaceVariant
                visible: model.type === "wallpaper" && model.thumb && model.thumb.length > 0

                Image {
                  anchors.fill: parent
                  source: (model.thumb && model.thumb.length > 0) ? ("file://" + model.thumb) : ""
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  sourceSize.width: 64
                  sourceSize.height: 64
                }
              }

              // Type: Power or Generic Glyph
              Text {
                anchors.centerIn: parent
                visible: model.type !== "theme" && (model.type !== "wallpaper" || !model.thumb)
                text: {
                  if (model.type === "power") return model.thumb || "󰐥"
                  if (model.type === "setting") return "⚙"
                  if (model.type === "action") return "󰕾"
                  if (model.type === "wall_action") return "󰸉"
                  return "❯"
                }
                font.pixelSize: 18
                color: suggestionsList.currentIndex === index ? Style.accent : Style.textMuted
              }
            }

            // Title and Subtitle Column
            Column {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              spacing: 2

              Text {
                text: model.title
                font.family: Style.fontText
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: suggestionsList.currentIndex === index ? Style.textPrimary : Style.textSecondary
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: model.subtitle
                font.family: Style.fontText
                font.pixelSize: 11
                color: Style.textMuted
                elide: Text.ElideRight
                width: parent.width
              }
            }

            // Active Badge or Action Tag
            Rectangle {
              implicitWidth: activeLabel.implicitWidth + 12
              implicitHeight: 20
              radius: 10
              color: model.isActive ? Qt.rgba(Style.accentGreen.r, Style.accentGreen.g, Style.accentGreen.b, 0.22) : Style.surfaceVariant
              border.color: model.isActive ? Style.accentGreen : "transparent"
              border.width: 1
              visible: model.isActive || (suggestionsList.currentIndex === index)

              Text {
                id: activeLabel
                anchors.centerIn: parent
                text: model.isActive ? "Aktif" : "↵ Seç"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: model.isActive ? Style.accentGreen : Style.textMuted
              }
            }
          }
        }
      }
    }

    // Divider between suggestions list and input row
    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: Style.borderSubtle
      opacity: 0.4
      visible: root.hasSuggestions
    }

    // AREA 2: Single-Line Command Input Bar (Fixed at bottom)
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 36
      Layout.alignment: Qt.AlignVCenter

      RowLayout {
        anchors.fill: parent
        spacing: 10

        // Command Prompt Prefix Icon (Glowing prompt badge)
        Rectangle {
          implicitWidth: 26
          implicitHeight: 26
          radius: 13
          color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.2)
          border.color: Style.accent
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: ":"
            font.family: Style.fontDisplay
            font.pixelSize: 15
            font.weight: Font.Bold
            color: Style.accent
          }
        }

        // The Command TextInput
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          TextInput {
            id: cmdInput
            anchors.fill: parent
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontText
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Style.textPrimary
            selectionColor: Style.accent
            selectedTextColor: "#000000"
            selectByMouse: true
            clip: true

            onTextChanged: {
              root.updateSuggestions()
            }

            // Ghost Placeholder Text
            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              visible: cmdInput.text.length === 0
              text: "Komut yazın... (:theme, :wall, :set, :lock, :sleep, :reboot)"
              font.family: Style.fontText
              font.pixelSize: 13
              color: Style.textMuted
              opacity: 0.65
            }
          }
        }

        // Trailing Keyboard Shortcut Badges
        Row {
          Layout.alignment: Qt.AlignVCenter
          spacing: 6

          Rectangle {
            implicitWidth: 42
            implicitHeight: 20
            radius: 4
            color: Style.surfaceVariant
            border.color: Style.borderSubtle
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "Tab 󰌒"
              font.pixelSize: 10
              font.weight: Font.DemiBold
              color: Style.textMuted
            }
          }

          Rectangle {
            implicitWidth: 40
            implicitHeight: 20
            radius: 4
            color: Style.surfaceVariant
            border.color: Style.borderSubtle
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "Esc 󰅖"
              font.pixelSize: 10
              font.weight: Font.DemiBold
              color: Style.textMuted
            }
          }
        }
      }
    }
  }
}
