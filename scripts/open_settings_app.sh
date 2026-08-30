#!/usr/bin/env bash

# ==============================================================================
# ogsShell-qs Standalone Qt Settings Application Launcher
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "[open_settings_app.sh] Launcher triggered at $(date '+%H:%M:%S'). Args: '$*'"

get_settings_pid() {
    for pid in $(pgrep quickshell 2>/dev/null); do
        if [ "$pid" != "$$" ] && grep -q "settings_app" "/proc/${pid}/cmdline" 2>/dev/null; then
            echo "${pid}"
            return 0
        fi
    done
    return 1
}

SETTINGS_PID=$(get_settings_pid || true)

if [ -n "${SETTINGS_PID}" ]; then
    echo "[open_settings_app.sh] Found existing settings_app process (PID: ${SETTINGS_PID})."
    if [ "$1" = "--toggle" ]; then
        echo "[open_settings_app.sh] --toggle requested, terminating PID ${SETTINGS_PID}."
        kill "${SETTINGS_PID}" 2>/dev/null || true
        exit 0
    fi
    echo "[open_settings_app.sh] Restarting fresh on current workspace..."
    kill "${SETTINGS_PID}" 2>/dev/null || true
    sleep 0.1
fi

echo "[open_settings_app.sh] Spawning: quickshell -p ${PROJECT_ROOT}/settings_app"
nohup quickshell -p "${PROJECT_ROOT}/settings_app" </dev/null >/dev/null 2>&1 & disown
echo "[open_settings_app.sh] Settings app process dispatched successfully."
