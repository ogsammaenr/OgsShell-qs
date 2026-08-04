from settings_app.ui.qt_compat import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QFont, QFrame, QScrollArea, QT_API
)
from settings_app.ui.widgets.card import CardWidget

class AboutPage(QWidget):
    """About & Shortcuts Reference page."""
    def __init__(self, config_mgr, parent=None):
        super().__init__(parent)
        self.config_mgr = config_mgr

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)

        header = QLabel("OgsShell-qs Hakkında")
        header.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        header.setStyleSheet("color: #eceff4;")
        layout.addWidget(header)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("QScrollArea { border: none; background: transparent; }")

        content = QWidget()
        scroll_layout = QVBoxLayout(content)
        scroll_layout.setSpacing(14)
        scroll_layout.setContentsMargins(0, 0, 10, 0)

        # Banner Card
        banner = QFrame()
        banner.setStyleSheet("""
            QFrame {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #3b4252, stop:1 #4c566a);
                border-radius: 12px;
                padding: 16px;
            }
        """)
        b_layout = QVBoxLayout(banner)
        
        app_title = QLabel("OgsShell Desktop Environment Shell v2.5")
        app_title.setFont(QFont("Inter", 14, QFont.Weight.Bold))
        app_title.setStyleSheet("color: #88c0d0;")
        
        app_desc = QLabel("Quickshell (QML/C++) ve Qt for Python (PySide6) ile geliştirilmiş modüler, performanslı ve dinamik masaüstü kabuk ekosistemi.")
        app_desc.setFont(QFont("Inter", 10))
        app_desc.setStyleSheet("color: #eceff4;")
        app_desc.setWordWrap(True)

        qt_info = QLabel(f"Python GUI Framework: {QT_API} | Mimari: Service-Window-Component")
        qt_info.setFont(QFont("Inter", 9))
        qt_info.setStyleSheet("color: #a3be8c; margin-top: 6px;")

        b_layout.addWidget(app_title)
        b_layout.addWidget(app_desc)
        b_layout.addWidget(qt_info)

        scroll_layout.addWidget(banner)

        # Shortcuts Table
        shortcuts_title = QLabel("IPC Kısayolları Reference")
        shortcuts_title.setFont(QFont("Inter", 12, QFont.Weight.Bold))
        shortcuts_title.setStyleSheet("color: #88c0d0; margin-top: 10px;")
        scroll_layout.addWidget(shortcuts_title)

        shortcuts = [
            ("./ipc.sh control_center", "Kontrol Merkezini Aç/Kapat"),
            ("./ipc.sh workspace_switcher", "Görsel Çalışma Alanı Geçiş Arayüzünü Aç"),
            ("./ipc.sh app_launcher", "Uygulama Arayıcı / Hızlı Arama Overlay'ini Aç"),
            ("./ipc.sh app_dashboard", "Tam Ekran Kütüphane Paneli"),
            ("./ipc.sh calendar", "Takvim & Resmi Tatiller Overlay'i"),
            ("./ipc.sh time_manager", "Pomodoro & Kronometre Zamanlayıcısı"),
            ("./ipc.sh gamemode", "Oyun Modunu Aç/Kapat")
        ]

        for cmd, desc in shortcuts:
            card = CardWidget(title=desc, subtitle=cmd)
            scroll_layout.addWidget(card)

        scroll_layout.addStretch()
        scroll.setWidget(content)
        layout.addWidget(scroll)
