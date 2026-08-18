#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Wi-Fi Settings Toggle Script
# Sends a toggle_wifi_view action to the daemon via Unix Domain Socket.
# Hyprland Binding Example:
#   bind = $mainMod, W, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_wifi.sh
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  exit 1
fi

echo '{"name":"toggle_wifi_view","args":{}}' | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
