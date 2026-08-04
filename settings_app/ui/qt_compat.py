"""
Qt compatibility module: tries PySide6, then PyQt6, then PyQt5.
Exposes unified Signal, Slot, Property, and Qt enum accessors.
"""
try:
    from PySide6 import QtCore, QtGui, QtWidgets
    from PySide6.QtCore import Qt, Signal, Slot, Property, QPropertyAnimation, QEasingCurve, QRectF
    from PySide6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QFrame, QLabel, QPushButton,
        QVBoxLayout, QHBoxLayout, QGridLayout, QStackedWidget, QCheckBox,
        QSlider, QGraphicsDropShadowEffect, QListWidget, QListWidgetItem,
        QScrollArea, QSizePolicy
    )
    from PySide6.QtGui import QColor, QFont, QIcon, QPainter, QBrush, QPen, QPainterPath
    QT_API = "PySide6"
except ImportError:
    try:
        from PyQt6 import QtCore, QtGui, QtWidgets
        from PyQt6.QtCore import Qt, pyqtSignal as Signal, pyqtSlot as Slot, pyqtProperty as Property, QPropertyAnimation, QEasingCurve, QRectF
        from PyQt6.QtWidgets import (
            QApplication, QMainWindow, QWidget, QFrame, QLabel, QPushButton,
            QVBoxLayout, QHBoxLayout, QGridLayout, QStackedWidget, QCheckBox,
            QSlider, QGraphicsDropShadowEffect, QListWidget, QListWidgetItem,
            QScrollArea, QSizePolicy
        )
        from PyQt6.QtGui import QColor, QFont, QIcon, QPainter, QBrush, QPen, QPainterPath
        QT_API = "PyQt6"
    except ImportError:
        from PyQt5 import QtCore, QtGui, QtWidgets
        from PyQt5.QtCore import Qt, pyqtSignal as Signal, pyqtSlot as Slot, pyqtProperty as Property, QPropertyAnimation, QEasingCurve, QRectF
        from PyQt5.QtWidgets import (
            QApplication, QMainWindow, QWidget, QFrame, QLabel, QPushButton,
            QVBoxLayout, QHBoxLayout, QGridLayout, QStackedWidget, QCheckBox,
            QSlider, QGraphicsDropShadowEffect, QListWidget, QListWidgetItem,
            QScrollArea, QSizePolicy
        )
        from PyQt5.QtGui import QColor, QFont, QIcon, QPainter, QBrush, QPen, QPainterPath
        QT_API = "PyQt5"

# Enum compatibility wrappers across Qt5 and Qt6
CursorShape = getattr(Qt, 'CursorShape', Qt)
MouseButton = getattr(Qt, 'MouseButton', Qt)
AlignmentFlag = getattr(Qt, 'AlignmentFlag', Qt)
EasingType = getattr(QEasingCurve, 'Type', QEasingCurve)
RenderHint = getattr(QPainter, 'RenderHint', QPainter)
PenStyle = getattr(Qt, 'PenStyle', Qt)
ItemDataRole = getattr(Qt, 'ItemDataRole', Qt)
Orientation = getattr(Qt, 'Orientation', Qt)
