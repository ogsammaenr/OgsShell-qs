import os
import json

CONFIG_DIR = os.path.expanduser("~/.config/ogsshell")
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.json")

DEFAULT_CONFIG = {
    "theme": "nord",
    "bar_position": "top",
    "bar_floating": False,
    "bar_height": 34,
    "island_width_scale": 100,
    "clock_format": "24h",
    "show_pomodoro": True,
    "show_media": True,
    "show_sys_stats": True,
    "show_center_hud": True,
    "show_workspaces": True,
    "game_mode": False,
    "autostart": True,
    "compact_mode": False,
    "corner_radius": 12
}

class ConfigManager:
    def __init__(self, path=CONFIG_PATH):
        self.path = path
        self.data = dict(DEFAULT_CONFIG)
        self.load()

    def load(self):
        if os.path.exists(self.path):
            try:
                with open(self.path, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                    self.data.update(loaded)
            except Exception as e:
                print(f"[ConfigManager] Failed to load config: {e}")
        else:
            self.save()

    def save(self):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        try:
            with open(self.path, "w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"[ConfigManager] Failed to save config: {e}")

    def get(self, key, default=None):
        return self.data.get(key, default if default is not None else DEFAULT_CONFIG.get(key))

    def set(self, key, value):
        self.data[key] = value
        self.save()
