from settings_app.ui.qt_compat import (
    QMainWindow, QWidget, QHBoxLayout, QVBoxLayout, QListWidget, QListWidgetItem,
    QStackedWidget, QLabel, QFont, QFrame, ItemDataRole
)
from settings_app.config import ConfigManager
from settings_app.ui.pages.general_page import GeneralPage
from settings_app.ui.pages.appearance_page import AppearancePage
from settings_app.ui.pages.modules_page import ModulesPage
from settings_app.ui.pages.system_page import SystemPage
from settings_app.ui.pages.about_page import AboutPage

class SettingsMainWindow(QMainWindow):
    """Main Window for OgsShell Settings Application."""
    def __init__(self):
        super().__init__()
        self.config_mgr = ConfigManager()

        self.setWindowTitle("OgsShell - Masaüstü Ayarları")
        self.resize(920, 620)
        self.setMinimumSize(800, 520)

        # Global Dark Stylesheet
        self.setStyleSheet("""
            QMainWindow {
                background-color: #242831;
            }
            QWidget {
                color: #eceff4;
                font-family: 'Inter', sans-serif;
            }
            QListWidget {
                background-color: #1e222a;
                border: none;
                border-right: 1px solid #2e3440;
                outline: 0;
            }
            QListWidget::item {
                height: 48px;
                padding-left: 16px;
                color: #d8dee9;
                font-weight: bold;
                border-radius: 8px;
                margin: 4px 8px;
            }
            QListWidget::item:hover {
                background-color: #2e3440;
                color: #eceff4;
            }
            QListWidget::item:selected {
                background-color: #3b4252;
                color: #88c0d0;
                border-left: 3px solid #88c0d0;
            }
        """)

        # Main Widget & Layout
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QHBoxLayout(central)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Left Sidebar
        sidebar_widget = QWidget()
        sidebar_widget.setFixedWidth(220)
        sidebar_layout = QVBoxLayout(sidebar_widget)
        sidebar_layout.setContentsMargins(0, 0, 0, 0)
        sidebar_layout.setSpacing(0)

        # Sidebar App Title
        title_box = QWidget()
        title_box.setStyleSheet("background-color: #1e222a; border-right: 1px solid #2e3440;")
        title_layout = QVBoxLayout(title_box)
        title_layout.setContentsMargins(20, 20, 20, 16)

        app_title = QLabel("OgsShell")
        app_title.setFont(QFont("Inter", 14, QFont.Weight.Bold))
        app_title.setStyleSheet("color: #88c0d0;")

        app_sub = QLabel("Ayarlar Paneli")
        app_sub.setFont(QFont("Inter", 9))
        app_sub.setStyleSheet("color: #d8dee9;")

        title_layout.addWidget(app_title)
        title_layout.addWidget(app_sub)
        sidebar_layout.addWidget(title_box)

        # Nav List
        self.nav_list = QListWidget()
        nav_items = [
            ("⚙  Genel", 0),
            ("🎨  Görünüm & Tema", 1),
            ("🧩  Bar Modülleri", 2),
            ("⚡  Sistem & IPC", 3),
            ("ℹ  Hakkında", 4)
        ]

        for text, page_idx in nav_items:
            item = QListWidgetItem(text)
            item.setData(ItemDataRole.UserRole, page_idx)
            self.nav_list.addItem(item)

        self.nav_list.currentRowChanged.connect(self._on_nav_change)
        sidebar_layout.addWidget(self.nav_list, 1)

        main_layout.addWidget(sidebar_widget)

        # Right Content Area (Pages Stack)
        self.stack = QStackedWidget()
        self.stack.setStyleSheet("background-color: #242831;")

        self.general_page = GeneralPage(self.config_mgr)
        self.appearance_page = AppearancePage(self.config_mgr)
        self.modules_page = ModulesPage(self.config_mgr)
        self.system_page = SystemPage(self.config_mgr)
        self.about_page = AboutPage(self.config_mgr)

        self.stack.addWidget(self.general_page)
        self.stack.addWidget(self.appearance_page)
        self.stack.addWidget(self.modules_page)
        self.stack.addWidget(self.system_page)
        self.stack.addWidget(self.about_page)

        main_layout.addWidget(self.stack, 1)

        # Select first nav item by default
        self.nav_list.setCurrentRow(0)

    def _on_nav_change(self, row: int):
        if row >= 0:
            self.stack.setCurrentIndex(row)
