pragma Singleton

import QtQuick

QtObject {
  id: root

  // =========================================================================
  // Apple Dynamic Island & HIG Minimalist Color Palette
  // Pure OLED Black base with frosted translucent glass tiers and Apple accents
  // =========================================================================
  property color bgPrimary: "#000000"
  property color bgSecondary: "#0c0c0e"
  property color surface: Qt.rgba(1.0, 1.0, 1.0, 0.06)
  property color surfaceVariant: Qt.rgba(1.0, 1.0, 1.0, 0.10)
  property color surfaceHover: Qt.rgba(1.0, 1.0, 1.0, 0.14)
  property color surfaceActive: Qt.rgba(1.0, 1.0, 1.0, 0.20)
  property color border: Qt.rgba(1.0, 1.0, 1.0, 0.10)
  property color borderHover: Qt.rgba(1.0, 1.0, 1.0, 0.22)

  // Typography
  property color textPrimary: "#ffffff"
  property color textSecondary: Qt.rgba(1.0, 1.0, 1.0, 0.65)
  property color textMuted: Qt.rgba(1.0, 1.0, 1.0, 0.40)

  // Apple Semantic Accents
  property color accent: "#0a84ff"          // Apple System Blue
  property color accentCyan: "#64d2ff"      // Apple System Cyan (Glanceable Clock)
  property color accentOrange: "#ff9f0a"    // Apple System Orange (Timers & Focus)
  property color accentGreen: "#30d158"     // Apple System Green (Stopwatch & Active)
  property color accentRed: "#ff453a"       // Apple System Red (Destructive & Stop)
  property color accentHover: "#409cff"

  // Geometry Constants
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
}
