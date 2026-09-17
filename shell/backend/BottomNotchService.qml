pragma Singleton

import QtQuick

QtObject {
  id: root

  // Visibility and activation state
  property bool isOpen: false
  property string initialQuery: ""

  signal toggled(bool openState)
  signal opened()
  signal closed()

  function open(query) {
    if (query !== undefined) {
      initialQuery = query
    }
    isOpen = true
    opened()
    toggled(true)
  }

  function close() {
    isOpen = false
    initialQuery = ""
    closed()
    toggled(false)
  }

  function toggle(query) {
    if (isOpen) {
      close()
    } else {
      open(query)
    }
  }
}
