from settings_app.ui.qt_compat import (
    QWidget, QVBoxLayout, QLabel, QFont, QScrollArea
)
from settings_app.ui.widgets.card import CardWidget
from settings_app.ui.widgets.toggle import ToggleSwitch
from settings_app.ui.widgets.slider import LabeledSlider
from settings_app.utils.ipc_client import send_ipc_command

class ModulesPage(QWidget):
    """Bar Modules & Shell Dimension Customization page."""
    def __init__(self, config_mgr, parent=None):
        super().__init__(parent)
        self.config_mgr = config_mgr

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)

        header = QLabel("Bar Modülleri & Ada Ayarları")
        header.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        header.setStyleSheet("color: #eceff4;")
        layout.addWidget(header)

        sub = QLabel("Shell barının yüksekliğini, adaların genişliğini ve hangi adaların aktif olacağını canlı olarak özelleştirin.")
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

        # SECTION 1: Shell & Island Dimensions
        dim_title = QLabel("Shell Boyutları ve Ölçekleme")
        dim_title.setFont(QFont("Inter", 12, QFont.Weight.Bold))
        dim_title.setStyleSheet("color: #88c0d0; margin-top: 4px;")
        scroll_layout.addWidget(dim_title)

        # 1. Bar Height Slider Card
        bar_height_card = CardWidget(
            title="Shell / Bar Yüksekliği",
            subtitle="Üst bar adalarının ve Layer Shell yükseklik alanının piksel değeri (24px - 56px)"
        )
        self.bar_height_slider = LabeledSlider(
            min_val=24, max_val=56,
            val=self.config_mgr.get("bar_height", 34),
            suffix="px"
        )
        self.bar_height_slider.valueChanged.connect(self._on_bar_height_change)
        bar_height_card.add_action_widget(self.bar_height_slider)
        scroll_layout.addWidget(bar_height_card)

        # 2. Island Width Scale Slider Card
        island_width_card = CardWidget(
            title="Adaların Genişlik Ölçeği",
            subtitle="Merkez HUD adası ve sistem adalarının yatay genişleme çarpanı (70% - 150%)"
        )
        self.island_width_slider = LabeledSlider(
            min_val=70, max_val=150,
            val=self.config_mgr.get("island_width_scale", 100),
            suffix="%"
        )
        self.island_width_slider.valueChanged.connect(self._on_island_width_change)
        island_width_card.add_action_widget(self.island_width_slider)
        scroll_layout.addWidget(island_width_card)

        # SECTION 2: Active Island Toggles
        islands_title = QLabel("Aktif Bar Adaları & Modülleri")
        islands_title.setFont(QFont("Inter", 12, QFont.Weight.Bold))
        islands_title.setStyleSheet("color: #88c0d0; margin-top: 10px;")
        scroll_layout.addWidget(islands_title)

        # 3. Workspace Bar Toggle
        ws_card = CardWidget(
            title="Sol Çalışma Alanı (Workspaces) Adası",
            subtitle="Sol tarafta aktif Hyprland çalışma alanlarını ve nokta göstergelerini sunar."
        )
        self.ws_toggle = ToggleSwitch(checked=self.config_mgr.get("show_workspaces", True))
        self.ws_toggle.toggled.connect(lambda v: self._update_toggle("show_workspaces", v))
        ws_card.add_action_widget(self.ws_toggle)
        scroll_layout.addWidget(ws_card)

        # 4. System Stats Toggle
        sys_card = CardWidget(
            title="Sistem İstatistikleri Adası (CPU / RAM / GPU)",
            subtitle="Donanım kaynak kullanımını canlı yüzdelerle ve sıcaklıklarla takip eder."
        )
        self.sys_toggle = ToggleSwitch(checked=self.config_mgr.get("show_sys_stats", True))
        self.sys_toggle.toggled.connect(lambda v: self._update_toggle("show_sys_stats", v))
        sys_card.add_action_widget(self.sys_toggle)
        scroll_layout.addWidget(sys_card)

        # 5. Center HUD Island Toggle
        center_card = CardWidget(
            title="Orta HUD Adası (Saat, Tarih & Ses/Parlaklık HUD)",
            subtitle="Ekranın ortasındaki ana dinamik adayı ve tıklanabilir saat/tarih modülünü barındırır."
        )
        self.center_toggle = ToggleSwitch(checked=self.config_mgr.get("show_center_hud", True))
        self.center_toggle.toggled.connect(lambda v: self._update_toggle("show_center_hud", v))
        center_card.add_action_widget(self.center_toggle)
        scroll_layout.addWidget(center_card)

        # 6. Media Island Toggle
        media_card = CardWidget(
            title="Sağ Medya Oynatıcı & Bildirim Adaları",
            subtitle="Sağ tarafta çalan şarkı detayları, ses seviyesi ve bildirim adasını barındırır."
        )
        self.media_toggle = ToggleSwitch(checked=self.config_mgr.get("show_media", True))
        self.media_toggle.toggled.connect(lambda v: self._update_toggle("show_media", v))
        media_card.add_action_widget(self.media_toggle)
        scroll_layout.addWidget(media_card)

        # 7. Pomodoro Toggle
        pomo_card = CardWidget(
            title="Pomodoro & Kronometre Zamanlayıcısı",
            subtitle="Zaman yönetimi ve sayaç paneline doğrudan bar üzerinden erişim sağlar."
        )
        self.pomo_toggle = ToggleSwitch(checked=self.config_mgr.get("show_pomodoro", True))
        self.pomo_toggle.toggled.connect(lambda v: self._update_toggle("show_pomodoro", v))
        pomo_card.add_action_widget(self.pomo_toggle)
        scroll_layout.addWidget(pomo_card)

        # 8. 24h Clock Format Toggle
        clock_card = CardWidget(
            title="24 Saatlik Saat Formatı",
            subtitle="Açık olduğunda '23:15', kapalı olduğunda '11:15 PM' biçiminde gösterilir."
        )
        self.clock_toggle = ToggleSwitch(checked=(self.config_mgr.get("clock_format", "24h") == "24h"))
        self.clock_toggle.toggled.connect(lambda v: self._update_toggle("clock_format", "24h" if v else "12h"))
        clock_card.add_action_widget(self.clock_toggle)
        scroll_layout.addWidget(clock_card)

        scroll_layout.addStretch()
        scroll.setWidget(content)
        layout.addWidget(scroll)

    def _on_bar_height_change(self, val: int):
        self.config_mgr.set("bar_height", val)
        send_ipc_command("config_reload")

    def _on_island_width_change(self, val: int):
        self.config_mgr.set("island_width_scale", val)
        send_ipc_command("config_reload")

    def _update_toggle(self, key: str, val):
        self.config_mgr.set(key, val)
        send_ipc_command("config_reload")
