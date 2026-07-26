import QtQuick

QtObject {
  id: themeManager

  property string currentTheme: "nord"

  readonly property var activeConfig: (typeof themeConfigService !== "undefined" && themeConfigService.activeThemeConfig)
    ? themeConfigService.activeThemeConfig
    : ({})

  readonly property color bg: activeConfig.bg || "#e62e3440"
  readonly property color border: activeConfig.border || "#3088c0d0"
  readonly property color textPrimary: activeConfig.textPrimary || "#eceff4"
  readonly property color textSecondary: activeConfig.textSecondary || "#d8dee9"
  readonly property color accent: activeConfig.accent || "#88c0d0"
  readonly property color green: activeConfig.green || "#a3be8c"
  readonly property color red: activeConfig.red || "#bf616a"
  readonly property color buttonBg: activeConfig.buttonBg || "#20ffffff"
}
