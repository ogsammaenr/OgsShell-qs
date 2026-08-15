#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Quickshell Frontend Launcher (Standalone / Debug Mode)
# Runs Quickshell in the foreground with QML console prints & UI logs.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SHELL_DIR="${REPO_ROOT}/shell"
SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"

echo -e "\033[1;36m[ogsShell Frontend]\033[0m Önceki Quickshell oturumları sonlandırılıyor..."
killall -9 quickshell 2>/dev/null || true

# Check if IPC socket is alive
if [ ! -S "${SOCK_PATH}" ]; then
  echo -e "\033[1;33m[ogsShell Frontend] UYARI:\033[0m Backend IPC soketi (${SOCK_PATH}) bulunamadı!"
  echo -e "\033[0;90mİpucu: Backend'i başlatmak için ayrı bir terminalde ./scripts/run_backend.sh çalıştırabilirsiniz.\033[0m"
else
  echo -e "\033[1;32m[ogsShell Frontend]\033[0m Backend IPC soketi aktif (${SOCK_PATH})."
fi

echo -e "\033[1;36m[ogsShell Frontend]\033[0m Quickshell Dynamic Island başlatılıyor (QML Konsol Logları):"
echo -e "\033[0;90mDurdurmak için Ctrl+C tuşlarına basabilirsiniz.\033[0m"
echo "--------------------------------------------------------------------------------"

exec quickshell -p "${SHELL_DIR}"
