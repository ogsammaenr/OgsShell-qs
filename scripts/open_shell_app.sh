#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Generic App Trigger Script
# Usage: ./scripts/open_shell_app.sh <app_name> [subview]
#
# Available Apps:
#   - themes / theme
#   - notifications / notif
#   - control_center / cc
#   - power / session
#   - media / media_player
#   - calendar / cal
#   - clipboard / clip
#   - clock / stopwatch / pomodoro / alarms / world
#   - wifi
#   - bluetooth / bt
#   - audio / mixer / audio_mixer
#   - launcher
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ -z "$1" ]; then
  echo -e "\033[1;33m[ogsShell Usage]\033[0m $0 <app_name> [subview]"
  echo -e "Kullanılabilir uygulamalar:"
  echo -e "  - themes, notifications, control_center, power, media"
  echo -e "  - calendar, clipboard, clock, wifi, bluetooth, audio/mixer, launcher"
  exit 1
fi

APP="$1"
SUBVIEW="${2:-}"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  echo -e "Lütfen önce './scripts/run_shell.sh' ile ogsShell'i başlatın." >&2
  exit 1
fi

PAYLOAD=$(cat <<EOF
{"name":"toggle_app","args":{"app":"${APP}","subview":"${SUBVIEW}"}}
EOF
)

echo "${PAYLOAD}" | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
