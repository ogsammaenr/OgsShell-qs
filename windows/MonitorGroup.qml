import Quickshell
import QtQuick
import "../components"

Item {
  id: monitorGroup
  required property var modelData
  readonly property var screen: modelData

  property bool isControlCenterOpen: false
  property bool isMediaManagerOpen: false
  property bool isTimeManagerOpen: false
  property bool isCalendarOpen: false
  property bool isAppLauncherOpen: false
  property bool isAppDashboardOpen: false
  property string activeIslandHud: ""
  property alias theme: theme

  Theme {
    id: theme
    currentTheme: root.activeTheme
  }

  Timer {
    id: islandHudTimeoutTimer
    interval: 1500
    running: false
    repeat: false
    onTriggered: {
      monitorGroup.activeIslandHud = "";
    }
  }

  function triggerIslandHud(type) {
    monitorGroup.activeIslandHud = type;
    islandHudTimeoutTimer.restart();
  }

  function restartIslandHudTimer() {
    islandHudTimeoutTimer.restart();
  }

  function openControlCenterPage(page) {
    monitorGroup.isTimeManagerOpen = false;
    monitorGroup.isCalendarOpen = false;
    monitorGroup.isAppLauncherOpen = false;
    monitorGroup.isAppDashboardOpen = false;

    controlCenterWindow.isSelectingNetwork = (page === "wifi");
    controlCenterWindow.isSelectingBluetooth = (page === "bluetooth");
    controlCenterWindow.isSelectingTheme = (page === "theme");
    controlCenterWindow.isSelectingClipboard = (page === "clipboard");

    monitorGroup.isControlCenterOpen = true;
  }

  TopBarWindow { targetScreen: monitorGroup.screen; monitorGroup: monitorGroup }
  ControlCenterWindow { id: controlCenterWindow; targetScreen: monitorGroup.screen; monitorGroup: monitorGroup }
  TimeManagerWindow { targetScreen: monitorGroup.screen; monitorGroup: monitorGroup }
  CalendarWindow { targetScreen: monitorGroup.screen; monitorGroup: monitorGroup }
  AppLauncherWindow { targetScreen: monitorGroup.screen; monitorGroup: monitorGroup }
  AppDashboardWindow { targetScreen: monitorGroup.screen; monitorGroup: monitorGroup }

  Connections {
    target: shellIpcService
    
    function onToggleControlCenter(targetMonitor, page) {
      if (targetMonitor === "" || targetMonitor === monitorGroup.screen.name) {
        if (page !== "") {
          // Close other panels
          monitorGroup.isTimeManagerOpen = false;
          monitorGroup.isCalendarOpen = false;
          monitorGroup.isAppLauncherOpen = false;
          monitorGroup.isAppDashboardOpen = false;
          
          // Select page
          if (page === "wifi") {
            controlCenterWindow.isSelectingNetwork = true;
            controlCenterWindow.isSelectingBluetooth = false;
            controlCenterWindow.isSelectingTheme = false;
            controlCenterWindow.isSelectingClipboard = false;
          } else if (page === "bluetooth") {
            controlCenterWindow.isSelectingNetwork = false;
            controlCenterWindow.isSelectingBluetooth = true;
            controlCenterWindow.isSelectingTheme = false;
            controlCenterWindow.isSelectingClipboard = false;
          } else if (page === "theme") {
            controlCenterWindow.isSelectingNetwork = false;
            controlCenterWindow.isSelectingBluetooth = false;
            controlCenterWindow.isSelectingTheme = true;
            controlCenterWindow.isSelectingClipboard = false;
          } else if (page === "clipboard") {
            controlCenterWindow.isSelectingNetwork = false;
            controlCenterWindow.isSelectingBluetooth = false;
            controlCenterWindow.isSelectingTheme = false;
            controlCenterWindow.isSelectingClipboard = true;
          }
          
          monitorGroup.isControlCenterOpen = true;
        } else {
          monitorGroup.isTimeManagerOpen = false;
          monitorGroup.isCalendarOpen = false;
          monitorGroup.isAppLauncherOpen = false;
          monitorGroup.isAppDashboardOpen = false;
          monitorGroup.isControlCenterOpen = !monitorGroup.isControlCenterOpen;
          
          if (monitorGroup.isControlCenterOpen) {
            controlCenterWindow.isSelectingNetwork = false;
            controlCenterWindow.isSelectingBluetooth = false;
            controlCenterWindow.isSelectingTheme = false;
            controlCenterWindow.isSelectingClipboard = false;
          }
        }
      } else {
        monitorGroup.isControlCenterOpen = false;
      }
    }

    function onToggleTimeManager(targetMonitor) {
      if (targetMonitor === "" || targetMonitor === monitorGroup.screen.name) {
        monitorGroup.isControlCenterOpen = false;
        monitorGroup.isCalendarOpen = false;
        monitorGroup.isAppLauncherOpen = false;
        monitorGroup.isAppDashboardOpen = false;
        monitorGroup.isTimeManagerOpen = !monitorGroup.isTimeManagerOpen;
      } else {
        monitorGroup.isTimeManagerOpen = false;
      }
    }

    function onToggleCalendar(targetMonitor) {
      if (targetMonitor === "" || targetMonitor === monitorGroup.screen.name) {
        monitorGroup.isControlCenterOpen = false;
        monitorGroup.isTimeManagerOpen = false;
        monitorGroup.isAppLauncherOpen = false;
        monitorGroup.isAppDashboardOpen = false;
        monitorGroup.isCalendarOpen = !monitorGroup.isCalendarOpen;
      } else {
        monitorGroup.isCalendarOpen = false;
      }
    }

    function onToggleAppLauncher(targetMonitor) {
      if (targetMonitor === "" || targetMonitor === monitorGroup.screen.name) {
        monitorGroup.isControlCenterOpen = false;
        monitorGroup.isTimeManagerOpen = false;
        monitorGroup.isCalendarOpen = false;
        monitorGroup.isAppDashboardOpen = false;
        
        monitorGroup.isAppLauncherOpen = !monitorGroup.isAppLauncherOpen;
        if (monitorGroup.isAppLauncherOpen) {
          appLauncherService.refresh(); // Refresh app list when opened
        }
      } else {
        monitorGroup.isAppLauncherOpen = false;
      }
    }

    function onToggleAppDashboard(targetMonitor) {
      if (targetMonitor === "" || targetMonitor === monitorGroup.screen.name) {
        monitorGroup.isControlCenterOpen = false;
        monitorGroup.isTimeManagerOpen = false;
        monitorGroup.isCalendarOpen = false;
        monitorGroup.isAppLauncherOpen = false;
        
        monitorGroup.isAppDashboardOpen = !monitorGroup.isAppDashboardOpen;
      } else {
        monitorGroup.isAppDashboardOpen = false;
      }
    }
  }
}
