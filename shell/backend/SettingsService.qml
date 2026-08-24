pragma Singleton

import QtQuick

QtObject {
  id: root

  property bool isOpen: false
  property string activeCategory: "network"

  function open(category) {
    if (category) activeCategory = category
    isOpen = true
  }

  function close() {
    isOpen = false
  }

  function toggle(category) {
    if (category && !isOpen) activeCategory = category
    isOpen = !isOpen
  }
}
