from settings_app.ui.qt_compat import (
    QFrame, QVBoxLayout, QHBoxLayout, QLabel, QWidget, QFont, AlignmentFlag
)

class CardWidget(QFrame):
    """Modern rounded card container for settings items."""
    def __init__(self, title: str = "", subtitle: str = "", parent=None):
        super().__init__(parent)
        self.setObjectName("SettingsCard")
        self.setStyleSheet("""
            QFrame#SettingsCard {
                background-color: #2b303c;
                border: 1px solid #3b4252;
                border-radius: 12px;
                padding: 12px;
            }
            QFrame#SettingsCard:hover {
                border-color: #4c566a;
            }
        """)

        self.main_layout = QHBoxLayout(self)
        self.main_layout.setContentsMargins(16, 14, 16, 14)
        self.main_layout.setSpacing(12)

        self.text_layout = QVBoxLayout()
        self.text_layout.setSpacing(4)

        if title:
            self.title_label = QLabel(title)
            self.title_label.setFont(QFont("Inter", 11, QFont.Weight.Bold))
            self.title_label.setStyleSheet("color: #eceff4;")
            self.text_layout.addWidget(self.title_label)

        if subtitle:
            self.subtitle_label = QLabel(subtitle)
            self.subtitle_label.setFont(QFont("Inter", 9))
            self.subtitle_label.setStyleSheet("color: #d8dee9;")
            self.subtitle_label.setWordWrap(True)
            self.text_layout.addWidget(self.subtitle_label)

        self.main_layout.addLayout(self.text_layout, 1)

    def add_action_widget(self, widget: QWidget):
        """Add action button/toggle/slider to the right side of card."""
        self.main_layout.addWidget(widget, 0, AlignmentFlag.AlignRight | AlignmentFlag.AlignVCenter)
