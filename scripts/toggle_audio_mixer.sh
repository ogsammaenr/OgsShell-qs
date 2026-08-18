#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Audio Mixer Toggle Script
# Sends a toggle_audio_mixer action to the daemon via Unix Domain Socket.
# Opens the application streams & output devices volume mixer.
# Hyprland Binding Example:
#   bind = $mainMod, A, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_audio_mixer.sh
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  exit 1
fi

echo '{"name":"toggle_audio_mixer","args":{}}' | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
