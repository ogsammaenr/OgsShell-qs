#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Media Player Toggle Script
# Sends a toggle_media_player action to the daemon via Unix Domain Socket.
# Hyprland Binding Example:
#   bind = $mainMod, M, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_media_player.sh
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  exit 1
fi

echo '{"name":"toggle_media_player","args":{}}' | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
