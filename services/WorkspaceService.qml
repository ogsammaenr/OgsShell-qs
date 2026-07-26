import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property var workspaceState: ({ "monitors": [], "workspaces": [] })
  property var activeNotifications: []
  property bool isShowingNotification: false

  function dismissNotification(index) {
    var list = service.activeNotifications.slice();
    list.splice(index, 1);
    service.activeNotifications = list;
    if (list.length === 0) {
      service.isShowingNotification = false;
      notificationTimer.stop();
    } else {
      notificationTimer.restart();
    }
  }

  // Notification Timer to automatically hide notifications
  Timer {
    id: notificationTimer
    interval: 4000 // Show notifications for 4 seconds
    running: false
    repeat: false
    onTriggered: {
      service.isShowingNotification = false;
      service.activeNotifications = [];
    }
  }

  // Background process to monitor Hyprland workspaces and monitors + notifications
  Process {
    id: workspaceMonitorProc
    command: ["/home/excalibur/WorkSpace/projects/OgsShell-qs/workspaces"]
    running: true

    stdout: SplitParser {
      onRead: (line) => {
        try {
          var data = JSON.parse(line);
          if (data && data.notification !== undefined) {
            var list = service.activeNotifications.slice();
            list.unshift({
              "title": data.notification.title || "",
              "body": data.notification.body || "",
              "app": data.notification.app || ""
            });
            if (list.length > 4) {
              list.pop();
            }
            service.activeNotifications = list;
            service.isShowingNotification = true;
            notificationTimer.restart();
          } else if (data && data.monitors && data.workspaces) {
            service.workspaceState = data;
          }
        } catch (e) {
          console.log("Error parsing workspaces output: " + e);
        }
      }
    }
  }
}
