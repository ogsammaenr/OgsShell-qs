from settings_app.ui.qt_compat import (
    QWidget, QHBoxLayout, QSlider, QLabel, Signal, QFont, AlignmentFlag, Orientation
)

class LabeledSlider(QWidget):
    """Custom slider with live numeric display label."""
    valueChanged = Signal(int)

    def __init__(self, min_val: int = 0, max_val: int = 100, val: int = 50, suffix: str = "", parent=None):
        super().__init__(parent)
        self.suffix = suffix

        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)

        self.slider = QSlider(Orientation.Horizontal)
        self.slider.setRange(min_val, max_val)
        self.slider.setValue(val)
        self.slider.setStyleSheet("""
            QSlider::groove:horizontal {
                height: 6px;
                background: #3b4252;
                border-radius: 3px;
            }
            QSlider::sub-page:horizontal {
                background: #88c0d0;
                border-radius: 3px;
            }
            QSlider::handle:horizontal {
                background: #eceff4;
                width: 16px;
                height: 16px;
                margin: -5px 0;
                border-radius: 8px;
            }
            QSlider::handle:horizontal:hover {
                background: #88c0d0;
            }
        """)

        self.val_label = QLabel(f"{val}{suffix}")
        self.val_label.setFont(QFont("Inter", 10, QFont.Weight.Bold))
        self.val_label.setStyleSheet("color: #88c0d0; min-width: 40px;")
        self.val_label.setAlignment(AlignmentFlag.AlignRight | AlignmentFlag.AlignVCenter)

        self.slider.valueChanged.connect(self._on_change)

        layout.addWidget(self.slider, 1)
        layout.addWidget(self.val_label, 0)

    def _on_change(self, value: int):
        self.val_label.setText(f"{value}{self.suffix}")
        self.valueChanged.emit(value)

    def value(self) -> int:
        return self.slider.value()

    def setValue(self, val: int):
        self.slider.setValue(val)
