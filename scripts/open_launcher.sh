#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs App Launcher Open Script
# Sends an open_launcher command to the running daemon via Unix Domain Socket.
# ==============================================================================

SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;31m[ogsShell Launcher Error]\033[0m IPC soketi bulunamadı (${SOCK_PATH})." >&2
  echo -e "Lütfen önce './scripts/run_shell.sh' ile ogsShell'i başlatın." >&2
  exit 1
fi

echo '{"name":"open_launcher","args":{}}' | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
