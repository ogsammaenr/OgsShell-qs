from settings_app.ui.qt_compat import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QFont, QPushButton, QScrollArea, CursorShape
)
from settings_app.ui.widgets.card import CardWidget
from settings_app.ui.widgets.toggle import ToggleSwitch
from settings_app.utils.ipc_client import send_ipc_command

class SystemPage(QWidget):
    """System & Audio Mixer & IPC test page."""
    def __init__(self, config_mgr, parent=None):
        super().__init__(parent)
        self.config_mgr = config_mgr

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)

        header = QLabel("Sistem ve Performans Ayarları")
        header.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        header.setStyleSheet("color: #eceff4;")
        layout.addWidget(header)

        sub = QLabel("Oyun modu, ses karıştırıcı ve IPC kısayol testlerini buradan yönetin.")
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

        # Game Mode Toggle
        game_card = CardWidget(
            title="Oyun Modu (Game Mode)",
            subtitle="Animasyonları ve arka plan efektlerini durdurarak maksimum FPS ve düşük gecikme sağlar."
        )
        self.game_toggle = ToggleSwitch(checked=self.config_mgr.get("game_mode", False))
        self.game_toggle.toggled.connect(self._on_game_mode_toggled)
        game_card.add_action_widget(self.game_toggle)
        scroll_layout.addWidget(game_card)

        # Audio Mixer Shortcut Card
        audio_card = CardWidget(
            title="Ses Karıştırıcı (Audio Mixer)",
            subtitle="Tüm uygulamaların ses seviyesini bağımsız olarak ayarlayan paneli açar."
        )
        audio_btn = QPushButton("Karıştırıcıyı Aç")
        audio_btn.setFont(QFont("Inter", 9, QFont.Weight.Bold))
        audio_btn.setCursor(CursorShape.PointingHandCursor)
        audio_btn.setStyleSheet("""
            QPushButton {
                background-color: #3b4252;
                color: #eceff4;
                border: 1px solid #4c566a;
                border-radius: 8px;
                padding: 6px 14px;
            }
            QPushButton:hover {
                background-color: #434c5e;
                border-color: #88c0d0;
            }
        """)
        audio_btn.clicked.connect(lambda: send_ipc_command("control_center"))
        audio_card.add_action_widget(audio_btn)
        scroll_layout.addWidget(audio_card)

        # IPC Test Panel
        ipc_title = QLabel("Canlı Shell Overlay Testleri (IPC Test Panel)")
        ipc_title.setFont(QFont("Inter", 12, QFont.Weight.Bold))
        ipc_title.setStyleSheet("color: #88c0d0; margin-top: 10px;")
        scroll_layout.addWidget(ipc_title)

        ipc_box = QWidget()
        ipc_layout = QHBoxLayout(ipc_box)
        ipc_layout.setContentsMargins(0, 0, 0, 0)
        ipc_layout.setSpacing(8)

        cmds = [
            ("Kontrol Merkezi", "control_center"),
            ("Çalışma Alanları", "workspace_switcher"),
            ("Uygulama Arayıcı", "app_launcher"),
            ("Takvim", "calendar"),
            ("Pomodoro", "time_manager")
        ]

        for label, cmd in cmds:
            btn = QPushButton(label)
            btn.setFont(QFont("Inter", 9))
            btn.setCursor(CursorShape.PointingHandCursor)
            btn.setStyleSheet("""
                QPushButton {
                    background-color: #2e3440;
                    color: #d8dee9;
                    border: 1px solid #3b4252;
                    border-radius: 8px;
                    padding: 8px;
                }
                QPushButton:hover {
                    background-color: #3b4252;
                    color: #88c0d0;
                    border-color: #88c0d0;
                }
            """)
            btn.clicked.connect(lambda _, c=cmd: send_ipc_command(c))
            ipc_layout.addWidget(btn)

        scroll_layout.addWidget(ipc_box)

        scroll_layout.addStretch()
        scroll.setWidget(content)
        layout.addWidget(scroll)

    def _on_game_mode_toggled(self, checked: bool):
        self.config_mgr.set("game_mode", checked)
        send_ipc_command(f"gamemode:{'on' if checked else 'off'}")
