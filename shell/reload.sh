#!/usr/bin/env bash

# ==============================================================================
# ogsShell-qs Shell Reload Script
# Ensures Go backend daemon is active and restarts Quickshell Dynamic Island
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CORE_BIN="${REPO_ROOT}/bin/ogsshell-core"
SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

# 1. Stop conflicting notification servers so Quickshell claims org.freedesktop.Notifications
killall swaync 2>/dev/null || true
killall dunst 2>/dev/null || true
killall mako 2>/dev/null || true

# 2. Ensure Go daemon is running
if ! pgrep -x "ogsshell-core" > /dev/null; then
  echo "[ogsShell] Go backend daemon is not running. Starting..."
  if [ ! -f "${CORE_BIN}" ]; then
    (cd "${REPO_ROOT}/core" && go build -o "${CORE_BIN}" .)
  fi
  "${CORE_BIN}" > /tmp/ogsshell-core.log 2>&1 &
  
  # Wait for socket
  for i in {1..20}; do
    if [ -S "${SOCK_PATH}" ]; then
      break
    fi
    sleep 0.1
  done
fi

# 3. Kill existing quickshell instances
killall -9 quickshell 2>/dev/null || true

echo "[ogsShell] Reloading Quickshell Dynamic Island from: ${SCRIPT_DIR}"
exec quickshell -p "${SCRIPT_DIR}"
