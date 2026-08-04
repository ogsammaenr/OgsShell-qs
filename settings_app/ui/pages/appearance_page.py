import os
import json
from settings_app.ui.qt_compat import (
    QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QLabel, QPushButton,
    QFrame, QFont, QScrollArea, CursorShape
)
from settings_app.ui.widgets.card import CardWidget
from settings_app.ui.widgets.toggle import ToggleSwitch
from settings_app.ui.widgets.slider import LabeledSlider
from settings_app.utils.ipc_client import send_ipc_command

class AppearancePage(QWidget):
    """Theme & Visual Appearance settings page."""
    def __init__(self, config_mgr, parent=None):
        super().__init__(parent)
        self.config_mgr = config_mgr

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(16)

        # Header
        header = QLabel("Görünüm ve Tema Ayarları")
        header.setFont(QFont("Inter", 16, QFont.Weight.Bold))
        header.setStyleSheet("color: #eceff4;")
        layout.addWidget(header)

        sub = QLabel("Masaüstü barı ve tüm sistem uygulamaları için canlı tema seçimi yapın.")
        sub.setFont(QFont("Inter", 10))
        sub.setStyleSheet("color: #d8dee9;")
        layout.addWidget(sub)

        # Scroll Area for themes
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("QScrollArea { border: none; background: transparent; }")

        scroll_content = QWidget()
        scroll_layout = QVBoxLayout(scroll_content)
        scroll_layout.setSpacing(14)
        scroll_layout.setContentsMargins(0, 0, 10, 0)

        # Theme Selector Section
        theme_title = QLabel("Mevcut Renk Temaları")
        theme_title.setFont(QFont("Inter", 12, QFont.Weight.Bold))
        theme_title.setStyleSheet("color: #88c0d0; margin-top: 8px;")
        scroll_layout.addWidget(theme_title)

        grid_widget = QWidget()
        self.grid = QGridLayout(grid_widget)
        self.grid.setSpacing(12)
        self.grid.setContentsMargins(0, 0, 0, 0)

        self.theme_cards = {}
        self.load_themes()
        scroll_layout.addWidget(grid_widget)

        # Radius Slider Card
        radius_card = CardWidget(
            title="Pencere ve Bar Köşe Yuvarlaklığı",
            subtitle="Bar adalarının ve pencere kartlarının köşe kavis yarıçapı (px)"
        )
        self.radius_slider = LabeledSlider(
            min_val=4, max_val=24,
            val=self.config_mgr.get("corner_radius", 12),
            suffix="px"
        )
        self.radius_slider.valueChanged.connect(self._on_radius_change)
        radius_card.add_action_widget(self.radius_slider)
        scroll_layout.addWidget(radius_card)

        # Compact Mode Toggle
        compact_card = CardWidget(
            title="Kompakt Bar Düzeni",
            subtitle="Üst bar adalarını daha dar yükseklikte ve sıkışık gösterir."
        )
        self.compact_toggle = ToggleSwitch(checked=self.config_mgr.get("compact_mode", False))
        self.compact_toggle.toggled.connect(self._on_compact_toggle)
        compact_card.add_action_widget(self.compact_toggle)
        scroll_layout.addWidget(compact_card)

        scroll_layout.addStretch()
        scroll.setWidget(scroll_content)
        layout.addWidget(scroll)

    def load_themes(self):
        themes_path = os.path.expanduser("~/WorkSpace/projects/OgsShell-qs/shared/themes/themes.json")
        themes = []
        if os.path.exists(themes_path):
            try:
                with open(themes_path, "r", encoding="utf-8") as f:
                    themes = json.load(f)
            except Exception as e:
                print(f"[AppearancePage] Failed to load themes.json: {e}")

        if not themes:
            themes = [
                {"id": "nord", "name": "Nord", "accent": "#88c0d0", "bg": "#2e3440"},
                {"id": "catppuccin", "name": "Catppuccin", "accent": "#c6a0f6", "bg": "#24273a"},
                {"id": "everforest", "name": "Everforest", "accent": "#a7c080", "bg": "#2d353b"},
                {"id": "tokyonight", "name": "Tokyo Night", "accent": "#7aa2f7", "bg": "#1a1b26"},
                {"id": "gruvbox", "name": "Gruvbox", "accent": "#fe8019", "bg": "#282828"},
                {"id": "monochrome", "name": "Monochrome", "accent": "#e0e0e0", "bg": "#121212"}
            ]

        current_theme = self.config_mgr.get("theme", "nord")

        for idx, t in enumerate(themes):
            tid = t.get("id")
            tname = t.get("name")
            accent = t.get("accent", "#88c0d0")
            bg = t.get("bg", "#2e3440")

            card = QFrame()
            card.setCursor(CursorShape.PointingHandCursor)
            card.setFixedHeight(85)
            
            card_layout = QVBoxLayout(card)
            card_layout.setContentsMargins(12, 10, 12, 10)

            # Title
            lbl = QLabel(tname)
            lbl.setFont(QFont("Inter", 10, QFont.Weight.Bold))
            lbl.setStyleSheet("color: #eceff4;")

            # Swatch preview
            swatch_layout = QHBoxLayout()
            swatch_layout.setSpacing(6)
            
            circle1 = QFrame()
            circle1.setFixedSize(14, 14)
            circle1.setStyleSheet(f"background-color: {accent}; border-radius: 7px;")

            circle2 = QFrame()
            circle2.setFixedSize(14, 14)
            circle2.setStyleSheet(f"background-color: {bg}; border-radius: 7px; border: 1px solid #4c566a;")

            swatch_layout.addWidget(circle1)
            swatch_layout.addWidget(circle2)
            swatch_layout.addStretch()

            card_layout.addWidget(lbl)
            card_layout.addLayout(swatch_layout)

            is_selected = (tid == current_theme)
            self._update_card_style(card, is_selected, accent)

            # Click listener
            card.mousePressEvent = lambda ev, theme_id=tid: self.select_theme(theme_id)

            row, col = divmod(idx, 2)
            self.grid.addWidget(card, row, col)
            self.theme_cards[tid] = (card, accent)

    def _update_card_style(self, card, is_selected: bool, accent: str):
        if is_selected:
            card.setStyleSheet(f"""
                QFrame {{
                    background-color: #3b4252;
                    border: 2px solid {accent};
                    border-radius: 10px;
                }}
            """)
        else:
            card.setStyleSheet("""
                QFrame {
                    background-color: #2e3440;
                    border: 1px solid #3b4252;
                    border-radius: 10px;
                }
                QFrame:hover {
                    border-color: #4c566a;
                }
            """)

    def select_theme(self, theme_id: str):
        self.config_mgr.set("theme", theme_id)
        for tid, (card, accent) in self.theme_cards.items():
            self._update_card_style(card, tid == theme_id, accent)

        # Trigger live IPC sync
        send_ipc_command(f"control_center:theme")
        send_ipc_command(f"theme:{theme_id}")

    def _on_radius_change(self, val: int):
        self.config_mgr.set("corner_radius", val)

    def _on_compact_toggle(self, checked: bool):
        self.config_mgr.set("compact_mode", checked)
