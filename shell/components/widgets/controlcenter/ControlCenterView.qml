import QtQuick
import QtQuick.Layouts
import "./views"
import "../../.."

Item {
  id: root

  property var ipc
  property string currentView: "MAIN" // "MAIN" | "WIFI" | "BLUETOOTH" | "NOTIFICATIONS" | "CLIPBOARD" | "KEYBOARD" | "THEMES"

  function resetToMain() {
    currentView = "MAIN"
  }

  onVisibleChanged: {
    if (visible) {
      resetToMain()
    }
  }

  // Geometry hints for DynamicIsland container
  readonly property int preferredIslandWidth: (currentView === "MAIN") ? 440 : 450
  readonly property int preferredIslandHeight: (currentView === "MAIN") ? 310 : 320

  // ==========================================
  // Sub-Views Container (Lazy Loaded via Loaders)
  // ==========================================
  Item {
    anchors.fill: parent

    // 1. Main Dashboard (Immediate)
    ControlCenterMain {
      anchors.fill: parent
      ipc: root.ipc
      visible: root.currentView === "MAIN"
      onOpenView: viewName => {
        root.currentView = viewName
      }
    }

    // 2. Wi-Fi Sub-App (Lazy Loaded)
    Loader {
      anchors.fill: parent
      active: root.currentView === "WIFI"
      visible: active
      sourceComponent: WifiView {
        ipc: root.ipc
        onBackRequested: root.currentView = "MAIN"
      }
    }

    // 3. Bluetooth Sub-App (Lazy Loaded)
    Loader {
      anchors.fill: parent
      active: root.currentView === "BLUETOOTH"
      visible: active
      sourceComponent: BluetoothView {
        ipc: root.ipc
        onBackRequested: root.currentView = "MAIN"
      }
    }

    // 4. Notifications Sub-App (Lazy Loaded)
    Loader {
      anchors.fill: parent
      active: root.currentView === "NOTIFICATIONS"
      visible: active
      sourceComponent: NotificationsView {
        ipc: root.ipc
        onBackRequested: root.currentView = "MAIN"
      }
    }

    // 5. Clipboard Sub-App (Lazy Loaded)
    Loader {
      anchors.fill: parent
      active: root.currentView === "CLIPBOARD"
      visible: active
      sourceComponent: ClipboardView {
        ipc: root.ipc
        onBackRequested: root.currentView = "MAIN"
      }
    }

    // 6. Keyboard Layout Sub-App (Lazy Loaded)
    Loader {
      anchors.fill: parent
      active: root.currentView === "KEYBOARD"
      visible: active
      sourceComponent: KeyboardLayoutView {
        ipc: root.ipc
        onBackRequested: root.currentView = "MAIN"
      }
    }

    // 7. Themes Sub-App (Lazy Loaded)
    Loader {
      anchors.fill: parent
      active: root.currentView === "THEMES"
      visible: active
      sourceComponent: ThemesView {
        ipc: root.ipc
        onBackRequested: root.currentView = "MAIN"
      }
    }
  }
}
