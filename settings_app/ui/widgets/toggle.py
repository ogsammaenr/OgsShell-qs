from settings_app.ui.qt_compat import (
    QWidget, Signal, Qt, QPainter, QBrush, QColor, QPen,
    QPropertyAnimation, Property, QRectF,
    CursorShape, MouseButton, EasingType, RenderHint, PenStyle
)

class ToggleSwitch(QWidget):
    """Custom smooth animated switch toggle pill."""
    toggled = Signal(bool)

    def __init__(self, checked: bool = False, parent=None):
        super().__init__(parent)
        self.setFixedSize(50, 26)
        self.setCursor(CursorShape.PointingHandCursor)

        self._checked = checked
        self._thumb_position = 22.0 if checked else 4.0
        self._bg_color_off = QColor("#4c566a")
        self._bg_color_on = QColor("#88c0d0")
        self._thumb_color = QColor("#eceff4")

        self.anim = QPropertyAnimation(self, b"thumb_position", self)
        self.anim.setDuration(180)
        self.anim.setEasingCurve(EasingType.InOutQuad)

    def isChecked(self) -> bool:
        return self._checked

    def setChecked(self, checked: bool):
        if self._checked != checked:
            self._checked = checked
            self.anim.stop()
            self.anim.setEndValue(22.0 if checked else 4.0)
            self.anim.start()
            self.toggled.emit(checked)
            self.update()

    def get_thumb_position(self) -> float:
        return self._thumb_position

    def set_thumb_position(self, pos: float):
        self._thumb_position = pos
        self.update()

    thumb_position = Property(float, get_thumb_position, set_thumb_position)

    def mousePressEvent(self, event):
        if event.button() == MouseButton.LeftButton:
            self.setChecked(not self._checked)
            event.accept()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(RenderHint.Antialiasing)

        bg = self._bg_color_on if self._checked else self._bg_color_off
        p.setBrush(QBrush(bg))
        p.setPen(PenStyle.NoPen)
        p.drawRoundedRect(0, 0, self.width(), self.height(), 13, 13)

        # Draw handle thumb
        p.setBrush(QBrush(self._thumb_color))
        p.drawEllipse(QRectF(self._thumb_position, 4, 18, 18))
