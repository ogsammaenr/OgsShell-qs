import sys
import os

# Ensure project root is in sys.path
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from settings_app.ui.qt_compat import QApplication, QT_API
from settings_app.ui.main_window import SettingsMainWindow

def main():
    print(f"[OgsShell Settings] Starting app using {QT_API}...")
    app = QApplication(sys.argv)
    app.setApplicationName("OgsShell Settings")

    window = SettingsMainWindow()
    window.show()

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
