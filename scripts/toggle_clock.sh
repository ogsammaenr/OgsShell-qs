#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Clock & Pomodoro Suite Toggle Script
# Usage: ./scripts/toggle_clock.sh [WORLD|POMODORO|STOPWATCH|ALARMS]
# Hyprland Binding Example:
#   bind = $mainMod, K, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_clock.sh
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"
SUBVIEW="${1:-WORLD}"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  exit 1
fi

PAYLOAD=$(cat <<EOF
{"name":"toggle_app","args":{"app":"clock","subview":"${SUBVIEW}"}}
EOF
)

echo "${PAYLOAD}" | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
