#!/bin/bash
# OgsShell-qs IPC Control Script
# Usage: ./ipc.sh [command]
# Commands:
#   control_center           - Toggle main Control Center
#   control_center:wifi      - Open Wi-Fi panel
#   control_center:bluetooth - Open Bluetooth panel
#   control_center:theme     - Open Theme selection panel
#   control_center:clipboard - Open Clipboard panel
#   time_manager             - Toggle Time/Pomodoro panel
#   calendar                 - Toggle Calendar panel
#   app_launcher             - Toggle Application Launcher / Search overlay
#   app_dashboard            - Toggle full Application Dashboard / Library
#   workspace_switcher       - Visual workspace overview (workspace_switcher:next, workspace_switcher:prev, workspace_switcher:select, workspace_switcher:close)
#   gamemode                 - Toggle Game Mode (gamemode:on, gamemode:off, gamemode:toggle)

PIPE_PATH="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ogsshell-ipc"

# Create the named pipe if it doesn't exist
if [ ! -p "$PIPE_PATH" ]; then
    mkfifo "$PIPE_PATH"
fi

if [ -z "$1" ]; then
    echo "Usage: $0 [control_center|control_center:wifi|control_center:bluetooth|control_center:theme|control_center:clipboard|time_manager|calendar|app_launcher|app_dashboard|workspace_switcher|workspace_switcher:next|workspace_switcher:prev|workspace_switcher:select|workspace_switcher:close|gamemode]"
    exit 1
fi

# Check if qs is running
if ! pgrep -x "qs" > /dev/null; then
    echo "Error: quickshell (qs) is not running."
    exit 1
fi

# Write with a timeout to prevent hanging
timeout 0.5s sh -c "echo '$1' > '$PIPE_PATH'" 2>/dev/null
