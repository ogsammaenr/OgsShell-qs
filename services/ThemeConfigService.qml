import Quickshell
import Quickshell.Io
import QtQuick

Item {
  id: service

  property string activeTheme: "nord"
  property var themeList: []
  property var activeThemeConfig: ({})
  property bool isLoading: false
  property string lineBuffer: ""

  onActiveThemeChanged: {
    updateActiveConfig();
  }

  onThemeListChanged: {
    updateActiveConfig();
  }

  function updateActiveConfig() {
    if (!themeList || themeList.length === 0) return;
    for (var i = 0; i < themeList.length; i++) {
      if (themeList[i].id === activeTheme) {
        service.activeThemeConfig = themeList[i];
        return;
      }
    }
    // Fallback to first theme if active theme id is not found
    service.activeThemeConfig = themeList[0];
  }

  Process {
    id: loadProcess
    running: false
    stdout: SplitParser {
      onRead: (line) => {
        service.lineBuffer += line + "\n";
      }
    }

    onRunningChanged: {
      if (!running) {
        try {
          var data = JSON.parse(service.lineBuffer.trim());
          if (Array.isArray(data) && data.length > 0) {
            service.themeList = data;
          }
        } catch (e) {
          console.log("Error parsing theme config JSON: " + e);
        }
        service.lineBuffer = "";
        service.isLoading = false;
        service.updateActiveConfig();
      }
    }
  }

  function reloadThemes() {
    service.isLoading = true;
    service.lineBuffer = "";

    var cmd = "python3 -c '\n" +
              "import os, glob, json\n" +
              "cfg_dir = os.path.expanduser(\"~/.config/ogsshell/themes\")\n" +
              "os.makedirs(cfg_dir, exist_ok=True)\n" +
              "defaults = {\n" +
              "  \"catppuccin\": {\"id\":\"catppuccin\",\"name\":\"Catppuccin\",\"folder\":\"Catppuccin\",\"bg\":\"#e61e1e2e\",\"border\":\"#30cba6f7\",\"textPrimary\":\"#cdd6f4\",\"textSecondary\":\"#a6adc8\",\"accent\":\"#cba6f7\",\"green\":\"#a6e3a1\",\"red\":\"#f38ba8\",\"buttonBg\":\"#18ffffff\",\"workspaces\":[\"#cba6f7\",\"#a6adc8\",\"#313244\"]},\n" +
              "  \"nord\": {\"id\":\"nord\",\"name\":\"Nord Night\",\"folder\":\"Nord\",\"bg\":\"#e62e3440\",\"border\":\"#3088c0d0\",\"textPrimary\":\"#eceff4\",\"textSecondary\":\"#d8dee9\",\"accent\":\"#88c0d0\",\"green\":\"#a3be8c\",\"red\":\"#bf616a\",\"buttonBg\":\"#20ffffff\",\"workspaces\":[\"#88c0d0\",\"#d8dee9\",\"#4c566a\"]},\n" +
              "  \"tokyonight\": {\"id\":\"tokyonight\",\"name\":\"Tokyo Night\",\"folder\":\"TokyoNight\",\"bg\":\"#e61a1b26\",\"border\":\"#307aa2f7\",\"textPrimary\":\"#c0caf5\",\"textSecondary\":\"#9aa5ce\",\"accent\":\"#7aa2f7\",\"green\":\"#9ece6a\",\"red\":\"#f7768e\",\"buttonBg\":\"#20ffffff\",\"workspaces\":[\"#7aa2f7\",\"#c0caf5\",\"#24283b\"]},\n" +
              "  \"everforest\": {\"id\":\"everforest\",\"name\":\"Everforest\",\"folder\":\"Everforest\",\"bg\":\"#e62d353b\",\"border\":\"#30a7c080\",\"textPrimary\":\"#d3c6aa\",\"textSecondary\":\"#9da9a0\",\"accent\":\"#a7c080\",\"green\":\"#a7c080\",\"red\":\"#e67e80\",\"buttonBg\":\"#20ffffff\",\"workspaces\":[\"#a7c080\",\"#d3c6aa\",\"#475258\"]},\n" +
              "  \"gruvbox\": {\"id\":\"gruvbox\",\"name\":\"Retro Gruvbox\",\"folder\":\"Gruvbox\",\"bg\":\"#e6282828\",\"border\":\"#30fabd2f\",\"textPrimary\":\"#fbf1c7\",\"textSecondary\":\"#bdae93\",\"accent\":\"#fabd2f\",\"green\":\"#b8bb26\",\"red\":\"#fb4934\",\"buttonBg\":\"#20ffffff\",\"workspaces\":[\"#fabd2f\",\"#bdae93\",\"#504945\"]},\n" +
              "  \"monochrome\": {\"id\":\"monochrome\",\"name\":\"Monochrome\",\"folder\":\"Monochrome\",\"bg\":\"#e6181818\",\"border\":\"#40ffffff\",\"textPrimary\":\"#ffffff\",\"textSecondary\":\"#a0a0a0\",\"accent\":\"#e0e0e0\",\"green\":\"#d0d0d0\",\"red\":\"#888888\",\"buttonBg\":\"#20ffffff\",\"workspaces\":[\"#ffffff\",\"#a0a0a0\",\"#333333\"]}\n" +
              "}\n" +
              "for k, v in defaults.items():\n" +
              "  p = os.path.join(cfg_dir, f\"{k}.json\")\n" +
              "  if not os.path.exists(p):\n" +
              "    with open(p, \"w\") as fp:\n" +
              "      json.dump(v, fp, indent=2)\n" +
              "themes = []\n" +
              "for f in sorted(glob.glob(os.path.join(cfg_dir, \"*.json\"))):\n" +
              "  try:\n" +
              "    with open(f) as fp:\n" +
              "      data = json.load(fp)\n" +
              "      if isinstance(data, dict) and \"id\" in data:\n" +
              "        themes.append(data)\n" +
              "  except Exception:\n" +
              "    pass\n" +
              "print(json.dumps(themes))\n" +
              "'";

    loadProcess.command = ["sh", "-c", cmd];
    loadProcess.running = true;
  }

  Component.onCompleted: {
    reloadThemes();
  }
}
