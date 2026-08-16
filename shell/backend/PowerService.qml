pragma Singleton

import QtQuick

QtObject {
  id: root

  property bool isPowerMenuOpen: false

  function open() {
    isPowerMenuOpen = true
  }

  function close() {
    isPowerMenuOpen = false
  }

  function toggle() {
    isPowerMenuOpen = !isPowerMenuOpen
  }
}
