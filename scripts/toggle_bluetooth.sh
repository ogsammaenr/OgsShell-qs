#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Bluetooth Devices Toggle Script
# Sends a toggle_bluetooth_view action to the daemon via Unix Domain Socket.
# Hyprland Binding Example:
#   bind = $mainMod, B, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_bluetooth.sh
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  exit 1
fi

echo '{"name":"toggle_bluetooth_view","args":{}}' | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
