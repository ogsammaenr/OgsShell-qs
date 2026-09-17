pragma Singleton

import QtQuick

QtObject {
  id: root

  property bool isOpen: false
  property string mode: "SS" // "SS" | "OCR" | "RECORD"
  property int freezeTimestamp: 0
  property var monitors: []

  function setMonitors(monList) {
    if (Array.isArray(monList)) {
      monitors = monList;
    }
  }

  function getMonitorX(name) {
    for (let i = 0; i < monitors.length; i++) {
      if (monitors[i].name === name) return monitors[i].x;
    }
    return 0;
  }

  function getMonitorY(name) {
    for (let i = 0; i < monitors.length; i++) {
      if (monitors[i].name === name) return monitors[i].y;
    }
    return 0;
  }

  function openWithPayload(payload) {
    if (payload && payload.mode) {
      mode = payload.mode;
    }
    if (payload && payload.monitors) {
      setMonitors(payload.monitors);
    }
    freezeTimestamp = (payload && payload.timestamp) ? payload.timestamp : Date.now();
    isOpen = true;
  }

  function open(initialMode) {
    if (initialMode && (initialMode === "SS" || initialMode === "OCR" || initialMode === "RECORD")) {
      mode = initialMode;
    }
    freezeTimestamp = Date.now();
    isOpen = true;
  }

  function close() {
    isOpen = false;
  }

  function toggle(initialMode) {
    if (isOpen) {
      close();
    } else {
      open(initialMode);
    }
  }

  function setMode(newMode) {
    if (newMode === "SS" || newMode === "OCR" || newMode === "RECORD") {
      mode = newMode;
    }
  }
}
