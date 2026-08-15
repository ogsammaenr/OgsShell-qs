#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Go Backend Daemon Launcher (Standalone / Debug Mode)
# Runs the Go daemon in the foreground with real-time stdout/stderr logs.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CORE_BIN="${REPO_ROOT}/bin/ogsshell-core"
SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

echo -e "\033[1;34m[ogsShell Backend]\033[0m Temizleniyor ve önceki servisler durduruluyor..."
killall -9 ogsshell-core 2>/dev/null || true
killall swaync 2>/dev/null || true
killall dunst 2>/dev/null || true
killall mako 2>/dev/null || true
rm -f "${SOCK_PATH}"

# Trap signals for clean shutdown
cleanup() {
  echo ""
  echo -e "\033[1;33m[ogsShell Backend]\033[0m Backend kapatılıyor..."
  rm -f "${SOCK_PATH}"
  echo -e "\033[1;32m[ogsShell Backend]\033[0m Temizlik tamamlandı."
}
trap cleanup EXIT INT TERM

echo -e "\033[1;34m[ogsShell Backend]\033[0m Go backend derleniyor..."
mkdir -p "${REPO_ROOT}/bin"
(cd "${REPO_ROOT}/core" && go build -o "${CORE_BIN}" .)

echo -e "\033[1;32m[ogsShell Backend]\033[0m Go daemon başlatılıyor (Canlı Log Akışı):"
echo -e "\033[0;90mSocket: ${SOCK_PATH}\033[0m"
echo -e "\033[0;90mDurdurmak için Ctrl+C tuşlarına basabilirsiniz.\033[0m"
echo "--------------------------------------------------------------------------------"

exec "${CORE_BIN}"
