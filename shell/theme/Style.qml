pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // =========================================================================
  // Active Theme Identifiers & State
  // =========================================================================
  property string activeThemeId: "everforest"
  property string activeThemeName: "Everforest Dark"
  property var customColors: null

  // =========================================================================
  // 6 Core System Theme Palettes (Apple Pure OLED Black Silhouette Adapted)
  // Background is ALWAYS pure #000000 OLED black while glass surfaces and accents adapt.
  // =========================================================================
  readonly property var builtinPalettes: ({
    "everforest": {
      "id": "everforest",
      "name": "Everforest Dark",
      "fg": "#d3c6aa",
      "accent": "#a7c080",
      "accentSecondary": "#dbbc7f",
      "accentCyan": "#83c092",
      "accentGreen": "#a7c080",
      "accentOrange": "#e69875",
      "accentRed": "#e67e80"
    },
    "catppuccin": {
      "id": "catppuccin",
      "name": "Catppuccin Macchiato",
      "fg": "#cad3f5",
      "accent": "#c6a0f6",
      "accentSecondary": "#f5bde6",
      "accentCyan": "#8aadf4",
      "accentGreen": "#a6da95",
      "accentOrange": "#f5a97f",
      "accentRed": "#ed8796"
    },
    "tokyonight": {
      "id": "tokyonight",
      "name": "Tokyo Night",
      "fg": "#c0caf5",
      "accent": "#7aa2f7",
      "accentSecondary": "#bb9af7",
      "accentCyan": "#7dcfff",
      "accentGreen": "#9ece6a",
      "accentOrange": "#ff9e64",
      "accentRed": "#f7768e"
    },
    "nord": {
      "id": "nord",
      "name": "Nord",
      "fg": "#eceff4",
      "accent": "#88c0d0",
      "accentSecondary": "#81a1c1",
      "accentCyan": "#8fbcbb",
      "accentGreen": "#a3be8c",
      "accentOrange": "#ebcb8b",
      "accentRed": "#bf616a"
    },
    "gruvbox": {
      "id": "gruvbox",
      "name": "Gruvbox Dark",
      "fg": "#ebdbb2",
      "accent": "#fe8019",
      "accentSecondary": "#fabd2f",
      "accentCyan": "#8ec07c",
      "accentGreen": "#b8bb26",
      "accentOrange": "#fe8019",
      "accentRed": "#fb4934"
    },
    "monochrome": {
      "id": "monochrome",
      "name": "Monochrome Minimal",
      "fg": "#f0f0f0",
      "accent": "#e0e0e0",
      "accentSecondary": "#888888",
      "accentCyan": "#ffffff",
      "accentGreen": "#d0d0d0",
      "accentOrange": "#b0b0b0",
      "accentRed": "#ff6b6b"
    }
  })

  // Computed helper for active palette resolution
  readonly property var activePalette: {
    let p = builtinPalettes[activeThemeId]
    if (p) return p
    // Fallback or custom palette
    if (customColors && customColors.accent) {
      return {
        "id": activeThemeId,
        "name": activeThemeName,
        "fg": customColors.fg || "#ffffff",
        "accent": customColors.accent || "#0a84ff",
        "accentSecondary": customColors.accent_secondary || customColors.accent || "#64d2ff",
        "accentCyan": customColors.cyan || customColors.accent || "#64d2ff",
        "accentGreen": customColors.green || customColors.accent || "#30d158",
        "accentOrange": customColors.orange || customColors.yellow || customColors.accent || "#ff9f0a",
        "accentRed": customColors.red || "#ff453a"
      }
    }
    return builtinPalettes["everforest"]
  }

  // =========================================================================
  // 1. PURE OLED BLACK SILHOUETTE (Strictly #000000 in accordance with Apple Dynamic Island HIG)
  // =========================================================================
  readonly property color bgPrimary: "#000000"
  readonly property color bgSecondary: "#000000"

  // =========================================================================
  // 2. Translucent Frosted Glass Tiers (Adapts dynamically to active theme tint)
  // =========================================================================
  property color surface: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.06)
  property color surfaceVariant: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.10)
  property color surfaceHover: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.16)
  property color surfaceActive: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
  property color border: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.12)
  property color borderHover: Qt.rgba(accent.r, accent.g, accent.b, 0.40)

  // =========================================================================
  // 3. Dynamic Typography (Harmonized with Active Theme Foreground)
  // =========================================================================
  property color textPrimary: activePalette.fg ? activePalette.fg : "#ffffff"
  property color textSecondary: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.68)
  property color textMuted: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.42)

  // =========================================================================
  // 4. Dynamic Theme Semantic Accents
  // =========================================================================
  property color accent: activePalette.accent ? activePalette.accent : "#0a84ff"
  property color accentSecondary: activePalette.accentSecondary ? activePalette.accentSecondary : "#5ac8fa"
  property color accentCyan: activePalette.accentCyan ? activePalette.accentCyan : "#64d2ff"
  property color accentGreen: activePalette.accentGreen ? activePalette.accentGreen : "#30d158"
  property color accentOrange: activePalette.accentOrange ? activePalette.accentOrange : "#ff9f0a"
  property color accentRed: activePalette.accentRed ? activePalette.accentRed : "#ff453a"
  property color accentHover: Qt.lighter(accent, 1.15)

  // =========================================================================
  // 5. Geometry Constants
  // =========================================================================
  property int islandIdleWidth: 180
  property int islandIdleHeight: 36
  property int islandHoverWidth: 420
  property int islandHoverHeight: 50
  property int islandTransientWidth: 340
  property int islandTransientHeight: 56
  property int islandExpandedWidth: 420
  property int islandExpandedHeight: 280

  property int radiusFull: 18
  property int radiusTransient: 22
  property int radiusExpanded: 24

  // Smooth Animation Timings (in milliseconds)
  property int animationDurationExpanded: 320
  property int animationDurationCompact: 250
  property int animationDurationTransient: 280
  property real overshootFactor: 1.12

  // =========================================================================
  // Theme Config File Observer ($XDG_CONFIG_HOME/ogsShell/theme_config.json)
  // =========================================================================
  property var themeConfigFile: FileView {
    path: Quickshell.env("XDG_CONFIG_HOME") ? (Quickshell.env("XDG_CONFIG_HOME") + "/ogsShell/theme_config.json") : ""
    preload: true
    printErrors: false
    onTextChanged: {
      root.loadThemeConfigString(text())
    }
  }

  function loadThemeConfigString(jsonStr) {
    if (!jsonStr || jsonStr.trim().length === 0) return
    try {
      let cfg = JSON.parse(jsonStr)
      if (cfg.active_theme_id) {
        root.applyThemeById(cfg.active_theme_id)
      }
    } catch (e) {
      console.warn("[Style] Failed to parse theme_config.json:", e)
    }
  }

  // =========================================================================
  // Dynamic Theme Application Methods
  // =========================================================================
  function applyThemeById(themeId) {
    if (!themeId) return
    let normId = themeId.toLowerCase().trim()
    root.activeThemeId = normId
    if (builtinPalettes[normId]) {
      root.activeThemeName = builtinPalettes[normId].name
    }
    console.log("[Style] Active theme synchronized:", root.activeThemeId, root.activeThemeName)
  }

  function applyTheme(themeObj) {
    if (!themeObj) return
    if (themeObj.id) {
      root.activeThemeId = themeObj.id.toLowerCase().trim()
    }
    if (themeObj.name) {
      root.activeThemeName = themeObj.name
    }
    if (themeObj.colors) {
      root.customColors = themeObj.colors
    }
    console.log("[Style] Applied theme from IPC payload:", root.activeThemeId, root.activeThemeName)
  }

  Component.onCompleted: {
    if (themeConfigFile && themeConfigFile.text().length > 0) {
      loadThemeConfigString(themeConfigFile.text())
    }
  }
}
