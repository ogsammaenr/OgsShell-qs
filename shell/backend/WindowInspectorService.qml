pragma Singleton

import QtQuick

QtObject {
  id: root

  property bool isOpen: false
  property string copiedClass: ""
  property double copiedTimestamp: 0

  function open() {
    copiedClass = "";
    isOpen = true;
  }

  function close() {
    isOpen = false;
    copiedClass = "";
  }

  function toggle() {
    if (isOpen) {
      close();
    } else {
      open();
    }
  }

  function notifyCopied(className) {
    copiedClass = className;
    copiedTimestamp = Date.now();
  }
}
