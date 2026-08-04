from settings_app.ui.qt_compat import (
    QWidget, QVBoxLayout, QLabel, QFont, QScrollArea
)
from settings_app.ui.widgets.card import CardWidget
from settings_app.ui.widgets.toggle import ToggleSwitch

class GeneralPage(QWidget):
    """General desktop & autostart preferences page."""
    def __init__(self, config_mgr, parent=None):
        super().__init__(parent)
        self.config_mgr = config_mgr

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)

        header = QLabel("Genel Masaüstü Tercihleri")
        header.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        header.setStyleSheet("color: #eceff4;")
        layout.addWidget(header)

        sub = QLabel("OgsShell başlatma davranışlarını ve sistem başlangıç seçeneklerini yapılandırın.")
        sub.setFont(QFont("Inter", 10))
        sub.setStyleSheet("color: #d8dee9;")
        layout.addWidget(sub)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("QScrollArea { border: none; background: transparent; }")

        content = QWidget()
        scroll_layout = QVBoxLayout(content)
        scroll_layout.setSpacing(14)
        scroll_layout.setContentsMargins(0, 0, 10, 0)

        # Autostart Toggle
        auto_card = CardWidget(
            title="Sistem Başlangıcında Otomatik Başlat",
            subtitle="Kullanıcı oturumu açıldığında OgsShell barını otomatik olarak çalıştırır."
        )
        self.auto_toggle = ToggleSwitch(checked=self.config_mgr.get("autostart", True))
        self.auto_toggle.toggled.connect(lambda v: self.config_mgr.set("autostart", v))
        auto_card.add_action_widget(self.auto_toggle)
        scroll_layout.addWidget(auto_card)

        # Floating Bar Toggle
        float_card = CardWidget(
            title="Yüzen (Floating) Bar Modu",
            subtitle="Barı ekranın en üst kenarına tam yapıştırmak yerine 8px boşluk bırakarak adalar halinde açar."
        )
        self.float_toggle = ToggleSwitch(checked=self.config_mgr.get("bar_floating", False))
        self.float_toggle.toggled.connect(lambda v: self.config_mgr.set("bar_floating", v))
        float_card.add_action_widget(self.float_toggle)
        scroll_layout.addWidget(float_card)

        scroll_layout.addStretch()
        scroll.setWidget(content)
        layout.addWidget(scroll)
