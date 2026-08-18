#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Unified Launcher Script
# Starts Go backend daemon (core/) in background and Quickshell frontend (shell/)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CORE_BIN="${REPO_ROOT}/bin/ogsshell-core"
SHELL_DIR="${REPO_ROOT}/shell"
SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"
LOG_FILE="/tmp/ogsshell-core.log"
export OGSSHELL_SHARED_DIR="${REPO_ROOT}/shared"

# 1. Clean up existing conflicting processes and stale sockets
echo -e "\033[1;34m[ogsShell]\033[0m Önceki servisler ve çakışan bildirim yöneticileri temizleniyor..."
killall -9 quickshell 2>/dev/null || true
killall -9 ogsshell-core 2>/dev/null || true
killall swaync 2>/dev/null || true
killall dunst 2>/dev/null || true
killall mako 2>/dev/null || true
rm -f "${SOCK_PATH}"

# 2. Ensure Go daemon binary is built
if [ ! -f "${CORE_BIN}" ]; then
  echo -e "\033[1;34m[ogsShell]\033[0m Go backend derleniyor: ${CORE_BIN}"
  mkdir -p "${REPO_ROOT}/bin"
  (cd "${REPO_ROOT}/core" && go build -o "${CORE_BIN}" .)
fi

# 3. Start Go Backend Daemon in background
echo -e "\033[1;34m[ogsShell]\033[0m Go backend başlatılıyor (PID kaydedildi)..."
"${CORE_BIN}" > "${LOG_FILE}" 2>&1 &
CORE_PID=$!

echo -e "\033[1;32m[ogsShell]\033[0m Backend arka planda çalışıyor (PID: ${CORE_PID})."
echo -e "\033[1;36m[ogsShell] 💡 İpucu:\033[0m Backend loglarını canlı izlemek için başka bir terminalde:"
echo -e "          \033[1;33mtail -f ${LOG_FILE}\033[0m"
echo -e "          \033[0;90m(Veya ayrı ayrı test etmek için: ./scripts/run_backend.sh ve ./scripts/run_frontend.sh)\033[0m"

# Trap signals to ensure background daemon is killed when user exits (Ctrl+C)
cleanup() {
  echo ""
  echo -e "\033[1;33m[ogsShell]\033[0m Go backend durduruluyor (PID: ${CORE_PID})..."
  kill -TERM "${CORE_PID}" 2>/dev/null || true
  wait "${CORE_PID}" 2>/dev/null || true
  rm -f "${SOCK_PATH}"
  echo -e "\033[1;32m[ogsShell]\033[0m Kapanış tamamlandı."
}
trap cleanup EXIT INT TERM

# 4. Wait for Unix Domain Socket to become ready (max 3 seconds)
echo -e "\033[1;34m[ogsShell]\033[0m IPC soketinin hazır olması bekleniyor (${SOCK_PATH})..."
READY=0
for i in {1..30}; do
  if [ -S "${SOCK_PATH}" ]; then
    READY=1
    break
  fi
  sleep 0.1
done

if [ ${READY} -eq 1 ]; then
  echo -e "\033[1;32m[ogsShell]\033[0m IPC Soketi hazır. Bağlantı kuruldu."
else
  echo -e "\033[1;31m[ogsShell] UYARI:\033[0m IPC Soketi 3 saniye içinde açılamadı. Hatalar için '${LOG_FILE}' dosyasını kontrol edin."
fi

# 5. Launch Quickshell Frontend (runs in foreground)
echo -e "\033[1;34m[ogsShell]\033[0m Quickshell Dynamic Island başlatılıyor..."
quickshell -p "${SHELL_DIR}"
