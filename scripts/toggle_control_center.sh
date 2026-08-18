#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Control Center Toggle Script
# Sends a toggle_control_center action to the daemon via Unix Domain Socket.
# Hyprland Binding Example:
#   bind = $mainMod, C, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_control_center.sh
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  exit 1
fi

echo '{"name":"toggle_control_center","args":{}}' | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
