#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Unified Management & Control CLI (ogsshell.sh)
#
# Consolidates all lifecycle runners, frontend/backend launchers, IPC toggles,
# and tool utilities into a single canonical script.
#
# Usage:
#   ~/.config/ogsShell/ogsshell.sh <command> [args...]
#   ./scripts/ogsshell.sh <command> [args...]
# ==============================================================================

# ANSI Color Codes
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BLUE="\033[1;34m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_CYAN="\033[1;36m"
C_MAGENTA="\033[1;35m"
C_MUTED="\033[0;90m"

# Path & Environment Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_repo_root() {
  if [ -n "${OGSSHELL_REPO_ROOT:-}" ] && [ -d "${OGSSHELL_REPO_ROOT}" ]; then
    echo "${OGSSHELL_REPO_ROOT}"
    return 0
  fi
  if [ -f "${SCRIPT_DIR}/../core/main.go" ] && [ -d "${SCRIPT_DIR}/../shell" ]; then
    (cd "${SCRIPT_DIR}/.." && pwd)
    return 0
  fi
  if [ -f "${HOME}/Workspace/projects/OgsShell-qs/core/main.go" ]; then
    echo "${HOME}/Workspace/projects/OgsShell-qs"
    return 0
  fi
  if [ -f "${HOME}/WorkSpace/projects/OgsShell-qs/core/main.go" ]; then
    echo "${HOME}/WorkSpace/projects/OgsShell-qs"
    return 0
  fi
  if [ -f "/home/excalibur/Workspace/projects/OgsShell-qs/core/main.go" ]; then
    echo "/home/excalibur/Workspace/projects/OgsShell-qs"
    return 0
  fi
  if [ -f "./core/main.go" ] && [ -d "./shell" ]; then
    pwd
    return 0
  fi
  echo "/home/excalibur/Workspace/projects/OgsShell-qs"
}

REPO_ROOT="$(find_repo_root)"
CORE_BIN="${REPO_ROOT}/bin/ogsshell-core"
SHELL_DIR="${REPO_ROOT}/shell"
SETTINGS_APP_DIR="${REPO_ROOT}/settings_app"
SHARED_DIR="${REPO_ROOT}/shared"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ogsShell"
SOCK_PATH="${XDG_RUNTIME_DIR:-/tmp}/ogs_shell.sock"
LOG_FILE="/tmp/ogsshell-core.log"
export OGSSHELL_SHARED_DIR="${SHARED_DIR}"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

send_ipc_action() {
  local action_name="$1"
  local args_json="${2}"
  if [ -z "${args_json}" ]; then
    args_json="{}"
  fi

  if [ ! -S "${SOCK_PATH}" ]; then
    echo -e "${C_RED}[ogsShell IPC Error]${C_RESET} IPC soketi bulunamadı (${SOCK_PATH})." >&2
    echo -e "Lütfen önce '${C_CYAN}ogsshell.sh run${C_RESET}' ile ogsShell'i başlatın." >&2
    return 1
  fi

  echo "{\"name\":\"${action_name}\",\"args\":${args_json}}" | nc -U "${SOCK_PATH}" -w 1 >/dev/null 2>&1 || true
}

ensure_config() {
  mkdir -p "${CONFIG_DIR}"
  if [ ! -f "${CONFIG_DIR}/config.json" ]; then
    if [ -f "${SHELL_DIR}/config.json" ]; then
      cp "${SHELL_DIR}/config.json" "${CONFIG_DIR}/config.json" 2>/dev/null || true
    fi
  fi
}

build_backend() {
  echo -e "${C_BLUE}[ogsShell]${C_RESET} Go backend derleniyor..."
  mkdir -p "${REPO_ROOT}/bin"
  export CGO_CFLAGS="${CGO_CFLAGS:-} -Wno-deprecated-declarations"
  (cd "${REPO_ROOT}/core" && go build -o "${CORE_BIN}" .)
}

get_settings_pid() {
  for pid in $(pgrep quickshell 2>/dev/null); do
    if [ "$pid" != "$$" ] && grep -q "settings_app" "/proc/${pid}/cmdline" 2>/dev/null; then
      echo "${pid}"
      return 0
    fi
  done
  return 1
}

# ------------------------------------------------------------------------------
# Core Commands
# ------------------------------------------------------------------------------

cmd_run() {
  echo -e "${C_BLUE}[ogsShell]${C_RESET} Önceki servisler ve çakışan bildirim yöneticileri temizleniyor..."
  killall -9 quickshell 2>/dev/null || true
  killall -9 ogsshell-core 2>/dev/null || true
  killall swaync 2>/dev/null || true
  killall dunst 2>/dev/null || true
  killall mako 2>/dev/null || true
  rm -f "${SOCK_PATH}"

  ensure_config

  if command -v awww-daemon >/dev/null 2>&1; then
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
      echo -e "${C_BLUE}[ogsShell]${C_RESET} awww-daemon başlatılıyor..."
      awww-daemon >/dev/null 2>&1 &
      sleep 0.1
    fi
  fi

  build_backend

  echo -e "${C_BLUE}[ogsShell]${C_RESET} Go backend başlatılıyor (PID kaydedildi)..."
  "${CORE_BIN}" > "${LOG_FILE}" 2>&1 &
  CORE_PID=$!

  echo -e "${C_GREEN}[ogsShell]${C_RESET} Backend arka planda çalışıyor (PID: ${CORE_PID})."
  echo -e "${C_CYAN}[ogsShell] 💡 İpucu:${C_RESET} Backend loglarını canlı izlemek için başka bir terminalde:"
  echo -e "          ${C_YELLOW}tail -f ${LOG_FILE}${C_RESET}"
  echo -e "          ${C_MUTED}(Veya ayrı ayrı test etmek için: ogsshell.sh run_backend ve ogsshell.sh run_frontend)${C_RESET}"

  cleanup() {
    echo ""
    echo -e "${C_YELLOW}[ogsShell]${C_RESET} Go backend durduruluyor (PID: ${CORE_PID})..."
    kill -TERM "${CORE_PID}" 2>/dev/null || true
    wait "${CORE_PID}" 2>/dev/null || true
    rm -f "${SOCK_PATH}"
    echo -e "${C_GREEN}[ogsShell]${C_RESET} Kapanış tamamlandı."
  }
  trap cleanup EXIT INT TERM

  echo -e "${C_BLUE}[ogsShell]${C_RESET} IPC soketinin hazır olması bekleniyor (${SOCK_PATH})..."
  READY=0
  for i in {1..30}; do
    if [ -S "${SOCK_PATH}" ]; then
      READY=1
      break
    fi
    sleep 0.1
  done

  if [ ${READY} -eq 1 ]; then
    echo -e "${C_GREEN}[ogsShell]${C_RESET} IPC Soketi hazır. Bağlantı kuruldu."
  else
    echo -e "${C_RED}[ogsShell] UYARI:${C_RESET} IPC Soketi 3 saniye içinde açılamadı. Hatalar için '${LOG_FILE}' dosyasını kontrol edin."
  fi

  echo -e "${C_BLUE}[ogsShell]${C_RESET} Quickshell Dynamic Island başlatılıyor..."
  quickshell -p "${SHELL_DIR}"
}

cmd_run_backend() {
  echo -e "${C_BLUE}[ogsShell Backend]${C_RESET} Temizleniyor ve önceki servisler durduruluyor..."
  killall -9 ogsshell-core 2>/dev/null || true
  killall swaync 2>/dev/null || true
  killall dunst 2>/dev/null || true
  killall mako 2>/dev/null || true
  rm -f "${SOCK_PATH}"

  cleanup_backend() {
    echo ""
    echo -e "${C_YELLOW}[ogsShell Backend]${C_RESET} Backend kapatılıyor..."
    rm -f "${SOCK_PATH}"
    echo -e "${C_GREEN}[ogsShell Backend]${C_RESET} Temizlik tamamlandı."
  }
  trap cleanup_backend EXIT INT TERM

  build_backend

  echo -e "${C_GREEN}[ogsShell Backend]${C_RESET} Go daemon başlatılıyor (Canlı Log Akışı):"
  echo -e "${C_MUTED}Socket: ${SOCK_PATH}${C_RESET}"
  echo -e "${C_MUTED}Durdurmak için Ctrl+C tuşlarına basabilirsiniz.${C_RESET}"
  echo "--------------------------------------------------------------------------------"

  exec "${CORE_BIN}"
}

cmd_run_frontend() {
  echo -e "${C_CYAN}[ogsShell Frontend]${C_RESET} Önceki Quickshell oturumları sonlandırılıyor..."
  killall -9 quickshell 2>/dev/null || true

  if [ ! -S "${SOCK_PATH}" ]; then
    echo -e "${C_YELLOW}[ogsShell Frontend] UYARI:${C_RESET} Backend IPC soketi (${SOCK_PATH}) bulunamadı!"
    echo -e "${C_MUTED}İpucu: Backend'i başlatmak için ayrı bir terminalde ogsshell.sh run_backend çalıştırabilirsiniz.${C_RESET}"
  else
    echo -e "${C_GREEN}[ogsShell Frontend]${C_RESET} Backend IPC soketi aktif (${SOCK_PATH})."
  fi

  ensure_config

  echo -e "${C_CYAN}[ogsShell Frontend]${C_RESET} Quickshell Dynamic Island başlatılıyor (QML Konsol Logları):"
  echo -e "${C_MUTED}Durdurmak için Ctrl+C tuşlarına basabilirsiniz.${C_RESET}"
  echo "--------------------------------------------------------------------------------"

  exec quickshell -p "${SHELL_DIR}"
}

cmd_reload() {
  killall swaync 2>/dev/null || true
  killall dunst 2>/dev/null || true
  killall mako 2>/dev/null || true

  if ! pgrep -x "ogsshell-core" > /dev/null; then
    echo -e "${C_BLUE}[ogsShell]${C_RESET} Go backend daemon çalışmıyor. Başlatılıyor..."
    if [ ! -f "${CORE_BIN}" ]; then
      build_backend
    fi
    "${CORE_BIN}" > "${LOG_FILE}" 2>&1 &

    for i in {1..20}; do
      if [ -S "${SOCK_PATH}" ]; then
        break
      fi
      sleep 0.1
    done
  fi

  killall -9 quickshell 2>/dev/null || true
  echo -e "${C_GREEN}[ogsShell]${C_RESET} Quickshell Dynamic Island yeniden yükleniyor..."
  exec quickshell -p "${SHELL_DIR}"
}

cmd_settings() {
  local is_toggle=0
  if [ "${1:-}" = "--toggle" ] || [ "${1:-}" = "-t" ] || [ "${ACTION_SUBCOMMAND:-}" = "toggle_settings" ]; then
    is_toggle=1
  fi

  local pid
  pid=$(get_settings_pid || true)

  if [ -n "${pid}" ]; then
    if [ ${is_toggle} -eq 1 ]; then
      echo -e "${C_YELLOW}[ogsShell Settings]${C_RESET} Ayarlar uygulaması açık (PID: ${pid}), kapatılıyor..."
      kill "${pid}" 2>/dev/null || true
      return 0
    fi
    echo -e "${C_BLUE}[ogsShell Settings]${C_RESET} Ayarlar uygulaması zaten çalışıyor (PID: ${pid}). Yeniden odaklanıyor..."
    kill "${pid}" 2>/dev/null || true
    sleep 0.1
  fi

  echo -e "${C_GREEN}[ogsShell Settings]${C_RESET} Ayarlar uygulaması başlatılıyor..."
  nohup quickshell -p "${SETTINGS_APP_DIR}" </dev/null >/dev/null 2>&1 & disown
}

cmd_stop() {
  echo -e "${C_YELLOW}[ogsShell]${C_RESET} Tüm ogsShell servisleri sonlandırılıyor..."
  killall -9 quickshell 2>/dev/null || true
  killall -9 ogsshell-core 2>/dev/null || true
  rm -f "${SOCK_PATH}"
  echo -e "${C_GREEN}[ogsShell]${C_RESET} Servisler durduruldu."
}

cmd_status() {
  echo -e "${C_BLUE}================================================================${C_RESET}"
  echo -e "${C_BOLD}                   ogsShell Durum Raporu                        ${C_RESET}"
  echo -e "${C_BLUE}================================================================${C_RESET}"
  if pgrep -x "ogsshell-core" >/dev/null 2>&1; then
    local core_pid
    core_pid=$(pgrep -x "ogsshell-core" | head -n 1)
    echo -e "  Backend Daemon:    ${C_GREEN}● ÇALIŞIYOR${C_RESET} (PID: ${core_pid})"
  else
    echo -e "  Backend Daemon:    ${C_RED}○ KAPALI${C_RESET}"
  fi

  if pgrep -x "quickshell" >/dev/null 2>&1; then
    local qs_pids
    qs_pids=$(pgrep -x "quickshell" | tr '\n' ' ')
    echo -e "  Quickshell:        ${C_GREEN}● ÇALIŞIYOR${C_RESET} (PIDs: ${qs_pids})"
  else
    echo -e "  Quickshell:        ${C_RED}○ KAPALI${C_RESET}"
  fi

  if [ -S "${SOCK_PATH}" ]; then
    echo -e "  IPC Soketi:        ${C_GREEN}● AKTİF${C_RESET} (${SOCK_PATH})"
  else
    echo -e "  IPC Soketi:        ${C_RED}○ BULUNAMADI${C_RESET} (${SOCK_PATH})"
  fi

  echo -e "  Konfigürasyon:     ${CONFIG_DIR}/config.json"
  echo -e "  Çalışma Dizini:    ${REPO_ROOT}"
  echo -e "${C_BLUE}================================================================${C_RESET}"
}

cmd_preview_starship() {
  local palettes_dir="${REPO_ROOT}/shared/app_configs/starship/palettes"
  local base_conf="${REPO_ROOT}/shared/app_configs/starship/base.toml"
  local preview_dir="/tmp/starship_full_preview"

  rm -rf "${preview_dir}"
  mkdir -p "${preview_dir}"

  (
    cd "${preview_dir}"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Tester"
    echo "hello" > README.md
    git add README.md
    git commit -m "feat: initial commit" -q
    echo "modified line" >> README.md
    touch untracked_file.txt
    echo '{"name": "preview-app"}' > package.json
    echo 'module example.com/preview' > go.mod
    touch requirements.txt
    cat << 'CARGO' > Cargo.toml
[package]
name = "preview"
version = "0.1.0"
edition = "2021"
CARGO
    touch docker-compose.yml
  )

  render_one() {
    local theme_id="$1"
    local palette_file="${palettes_dir}/${theme_id}.toml"
    if [ ! -f "${palette_file}" ]; then
      echo "Tema paleti bulunamadı: ${palette_file}"
      return 1
    fi
    echo -e "\n${C_YELLOW}▶ TEMA: [${theme_id^^}]${C_RESET}"
    local tmp_cfg
    tmp_cfg=$(mktemp /tmp/starship_test_XXXXXX.toml)
    echo "palette = \"${theme_id}\"" > "${tmp_cfg}"
    echo "" >> "${tmp_cfg}"
    cat "${base_conf}" >> "${tmp_cfg}"
    echo "" >> "${tmp_cfg}"
    cat "${palette_file}" >> "${tmp_cfg}"

    echo -e "${C_MUTED}--- Başarılı Komut (Status 0, 3.5s süre): ---${C_RESET}"
    STARSHIP_CONFIG="${tmp_cfg}" TERM=xterm-256color starship prompt -p "${preview_dir}" -d 3500 -s 0
    echo ""

    echo -e "${C_MUTED}--- Hatalı Komut (Status 1, Hata ikonu): ---${C_RESET}"
    STARSHIP_CONFIG="${tmp_cfg}" TERM=xterm-256color starship prompt -p "${preview_dir}" -d 1200 -s 1
    echo ""

    rm -f "${tmp_cfg}"
  }

  if [ "${1:-}" = "--all" ] || [ "${1:-}" = "-a" ]; then
    for p in "${palettes_dir}"/*.toml; do
      local t_id
      t_id=$(basename "$p" .toml)
      render_one "${t_id}"
    done
  else
    local active_theme="${1:-monochrome}"
    render_one "${active_theme}"
    echo -e "${C_MUTED}💡 İpucu: Tüm temaları görmek için:${C_RESET} ${C_GREEN}ogsshell.sh preview_starship --all${C_RESET}"
  fi
}

cmd_screenshot() {
  local mode="${1:---region}"
  case "${mode}" in
    --all|-a|all)
      send_ipc_action "capture_screenshot" '{"geometry":"all"}'
      ;;
    --full|-f|full)
      send_ipc_action "capture_screenshot" '{"geometry":""}'
      ;;
    --region|-r|region|--ss|SS|*)
      send_ipc_action "toggle_app" '{"app":"snipping","subview":"SS"}'
      ;;
  esac
}

cmd_ocr() {
  local mode="${1:---region}"
  case "${mode}" in
    --full|-f|full)
      send_ipc_action "capture_ocr" '{"geometry":""}'
      ;;
    --region|-r|region|--ocr|OCR|*)
      send_ipc_action "toggle_app" '{"app":"snipping","subview":"OCR"}'
      ;;
  esac
}

cmd_record() {
  local mode="${1:---toggle}"
  case "${mode}" in
    --start|-s|start)
      send_ipc_action "start_recording" '{"geometry":""}'
      ;;
    --stop|-k|stop)
      send_ipc_action "stop_recording" "{}"
      ;;
    --region|-r|region)
      send_ipc_action "toggle_app" '{"app":"snipping","subview":"RECORD"}'
      ;;
    --toggle|-t|toggle|*)
      send_ipc_action "toggle_recording" "{}"
      ;;
  esac
}

cmd_completion() {
  local target="${1:-install}"
  local zsh_custom_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/custom"
  local bash_comp_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"

  case "${target}" in
    install)
      mkdir -p "${zsh_custom_dir}" "${bash_comp_dir}"
      if [ -f "${REPO_ROOT}/shared/app_configs/zsh/custom/ogsshell.zsh" ]; then
        cp "${REPO_ROOT}/shared/app_configs/zsh/custom/ogsshell.zsh" "${zsh_custom_dir}/ogsshell.zsh"
        echo -e "${C_GREEN}[✓]${C_RESET} Zsh tamamlama yüklendi -> ${C_BOLD}${zsh_custom_dir}/ogsshell.zsh${C_RESET}"
      fi
      if [ -f "${REPO_ROOT}/shared/completions/ogsshell.bash" ]; then
        cp "${REPO_ROOT}/shared/completions/ogsshell.bash" "${bash_comp_dir}/ogsshell"
        echo -e "${C_GREEN}[✓]${C_RESET} Bash tamamlama yüklendi -> ${C_BOLD}${bash_comp_dir}/ogsshell${C_RESET}"
      fi
      echo -e "${C_CYAN}💡 İpucu:${C_RESET} Mevcut açık terminalde anında etkinleştirmek için:"
      echo -e "          ${C_YELLOW}source ~/.config/zsh/custom/ogsshell.zsh${C_RESET}"
      ;;
    zsh)
      if [ -f "${REPO_ROOT}/shared/app_configs/zsh/custom/ogsshell.zsh" ]; then
        cat "${REPO_ROOT}/shared/app_configs/zsh/custom/ogsshell.zsh"
      elif [ -f "${zsh_custom_dir}/ogsshell.zsh" ]; then
        cat "${zsh_custom_dir}/ogsshell.zsh"
      fi
      ;;
    bash)
      if [ -f "${REPO_ROOT}/shared/completions/ogsshell.bash" ]; then
        cat "${REPO_ROOT}/shared/completions/ogsshell.bash"
      elif [ -f "${bash_comp_dir}/ogsshell" ]; then
        cat "${bash_comp_dir}/ogsshell"
      fi
      ;;
    *)
      echo -e "${C_YELLOW}Kullanım:${C_RESET} ogsshell completion [install | zsh | bash]"
      ;;
  esac
}

cmd_help() {
  echo -e "${C_BLUE}================================================================${C_RESET}"
  echo -e "${C_BOLD}             ogsShell-qs Birleşik Yönetim Scripti                ${C_RESET}"
  echo -e "${C_BLUE}================================================================${C_RESET}"
  echo -e "Kullanım: ${C_CYAN}ogsshell.sh <komut> [parametreler...]${C_RESET}"
  echo ""
  echo -e "${C_BOLD}🚀 Yaşam Döngüsü & Başlatma Komutları:${C_RESET}"
  echo -e "  ${C_GREEN}run${C_RESET} | ${C_GREEN}run_shell${C_RESET}          Tüm kabuğu (Backend + Quickshell) birlikte başlatır"
  echo -e "  ${C_GREEN}run_backend${C_RESET} | ${C_GREEN}backend${C_RESET}    Go daemon'u ön planda canlı loglarla başlatır (Hata ayıklama)"
  echo -e "  ${C_GREEN}run_frontend${C_RESET} | ${C_GREEN}frontend${C_RESET}  Quickshell Dynamic Island'ı ön planda başlatır"
  echo -e "  ${C_GREEN}reload${C_RESET} | ${C_GREEN}restart${C_RESET}        Quickshell arayüzünü anında yeniden yükler"
  echo -e "  ${C_GREEN}stop${C_RESET} | ${C_GREEN}kill${C_RESET}              Çalışan tüm ogsShell servislerini kapatır"
  echo -e "  ${C_GREEN}status${C_RESET} | ${C_GREEN}info${C_RESET}          Backend, soket ve arayüz durumunu denetler"
  echo ""
  echo -e "${C_BOLD}📱 Arayüz & Widget Tetikleyicileri (IPC):${C_RESET}"
  echo -e "  ${C_CYAN}toggle_launcher${C_RESET} | ${C_CYAN}launcher${C_RESET}         Uygulama Başlatıcıyı (Spotlight) açar/kapatır"
  echo -e "  ${C_CYAN}open_launcher${C_RESET}                    Uygulama Başlatıcıyı doğrudan açar"
  echo -e "  ${C_CYAN}toggle_settings${C_RESET} | ${C_CYAN}settings${C_RESET}         Ayarlar uygulamasını açar/kapatır"
  echo -e "  ${C_CYAN}open_settings${C_RESET}                    Ayarlar uygulamasını doğrudan açar"
  echo -e "  ${C_CYAN}toggle_bottom_notch${C_RESET} | ${C_CYAN}notch${C_RESET}        Alt Komut Çentiğini (Bottom Notch) açar/kapatır"
  echo -e "  ${C_CYAN}toggle_control_center${C_RESET} | ${C_CYAN}cc${C_RESET}         Kontrol Merkezini açar/kapatır"
  echo -e "  ${C_CYAN}toggle_audio_mixer${C_RESET} | ${C_CYAN}mixer${C_RESET} | ${C_CYAN}audio${C_RESET} Ses Karıştırıcısını açar/kapatır"
  echo -e "  ${C_CYAN}toggle_bluetooth${C_RESET} | ${C_CYAN}bluetooth${C_RESET} | ${C_CYAN}bt${C_RESET} Bluetooth panelini açar/kapatır"
  echo -e "  ${C_CYAN}toggle_wifi${C_RESET} | ${C_CYAN}wifi${C_RESET}                   Wi-Fi panelini açar/kapatır"
  echo -e "  ${C_CYAN}toggle_calendar${C_RESET} | ${C_CYAN}calendar${C_RESET} | ${C_CYAN}cal${C_RESET}    Takvim ve Etkinlikler görünümünü açar/kapatır"
  echo -e "  ${C_CYAN}toggle_clipboard${C_RESET} | ${C_CYAN}clipboard${C_RESET} | ${C_CYAN}clip${C_RESET}  Pano geçmişini açar/kapatır"
  echo -e "  ${C_CYAN}toggle_clock${C_RESET} [MOD] | ${C_CYAN}clock${C_RESET}        Saat menüsünü açar (WORLD, POMODORO, STOPWATCH, ALARMS)"
  echo -e "  ${C_CYAN}toggle_media_player${C_RESET} | ${C_CYAN}media${C_RESET}       Medya oynatıcı kontrolünü açar/kapatır"
  echo -e "  ${C_CYAN}toggle_notifications${C_RESET} | ${C_CYAN}notif${C_RESET}       Bildirim merkezini açar/kapatır"
  echo -e "  ${C_CYAN}toggle_power_menu${C_RESET} | ${C_CYAN}power${C_RESET}         Güç & Oturum menüsünü açar/kapatır"
  echo -e "  ${C_CYAN}toggle_themes${C_RESET} | ${C_CYAN}themes${C_RESET} | ${C_CYAN}theme${C_RESET}     Tema seçici panelini açar/kapatır"
  echo -e "  ${C_CYAN}toggle_dnd${C_RESET} | ${C_CYAN}dnd${C_RESET}                       Rahatsız Etme modunu (DND) açar/kapatır"
  echo -e "  ${C_CYAN}switch_layout${C_RESET}                    Klavye dilini bir sonrakine geçirir"
  echo -e "  ${C_CYAN}next_wallpaper${C_RESET}                   Aktif temanın sıradaki duvar kağıdına geçer"
  echo -e "  ${C_CYAN}screenshot${C_RESET} [--region | --full]   Ekran görüntüsü alır (bölge dondurma veya tam ekran)"
  echo -e "  ${C_CYAN}ocr${C_RESET} [--region]                   Seçilen bölgedeki metni tanır (OCR) ve panoya kopyalar"
  echo -e "  ${C_CYAN}record${C_RESET} [--start | --stop | --toggle] Ekran kaydı başlatır / bitirir / tersine çevirir"
  echo -e "  ${C_CYAN}open_app${C_RESET} <app> [subview]          Genel uygulama/alt görünüm tetikler"
  echo ""
  echo -e "${C_BOLD}🛠️  Araçlar, Tamamlama & Önizleme:${C_RESET}"
  echo -e "  ${C_MAGENTA}preview_starship${C_RESET} [--all | tema]  Starship tema paletlerini önizler"
  echo -e "  ${C_MAGENTA}completion${C_RESET} [install | zsh | bash] Otomatik sekme (Tab) tamamlama betiklerini yönetir"
  echo ""
  echo -e "${C_BOLD}Örnekler:${C_RESET}"
  echo -e "  ~/.config/ogsShell/ogsshell.sh run_backend"
  echo -e "  ~/.config/ogsShell/ogsshell.sh toggle_wifi"
  echo -e "  ~/.config/ogsShell/ogsshell.sh toggle_clock POMODORO"
  echo -e "  ~/.config/ogsShell/ogsshell.sh launcher"
  echo -e "${C_BLUE}================================================================${C_RESET}"
}

# ------------------------------------------------------------------------------
# Dispatcher
# ------------------------------------------------------------------------------

ACTION="${1:-}"

if [ -z "${ACTION}" ]; then
  INVOKED_AS="$(basename "$0")"
  case "${INVOKED_AS}" in
    run_backend.sh) ACTION="run_backend" ;;
    run_frontend.sh) ACTION="run_frontend" ;;
    run_shell.sh) ACTION="run" ;;
    reload.sh) ACTION="reload" ;;
    toggle_launcher.sh) ACTION="toggle_launcher" ;;
    open_launcher.sh) ACTION="open_launcher" ;;
    toggle_settings.sh) ACTION="toggle_settings" ;;
    open_settings_app.sh) ACTION="open_settings" ;;
    toggle_bottom_notch.sh) ACTION="toggle_bottom_notch" ;;
    toggle_audio_mixer.sh) ACTION="toggle_audio_mixer" ;;
    toggle_bluetooth.sh) ACTION="toggle_bluetooth" ;;
    toggle_calendar.sh) ACTION="toggle_calendar" ;;
    toggle_clipboard.sh) ACTION="toggle_clipboard" ;;
    toggle_clock.sh) ACTION="toggle_clock" ;;
    toggle_control_center.sh) ACTION="toggle_control_center" ;;
    toggle_media_player.sh) ACTION="toggle_media_player" ;;
    toggle_notifications.sh) ACTION="toggle_notifications" ;;
    toggle_power_menu.sh) ACTION="toggle_power_menu" ;;
    toggle_themes.sh) ACTION="toggle_themes" ;;
    toggle_wifi.sh) ACTION="toggle_wifi" ;;
    preview_starship.sh) ACTION="preview_starship" ;;
    open_shell_app.sh) ACTION="open_app" ;;
    screenshot.sh|snip.sh) ACTION="screenshot" ;;
    ocr.sh) ACTION="ocr" ;;
    record.sh) ACTION="record" ;;
    *) ACTION="run" ;;
  esac
  ARGS=()
else
  ARGS=("${@:2}")
fi

case "${ACTION}" in
  run|run_shell|start)
    cmd_run "${ARGS[@]}"
    ;;
  run_backend|backend|core)
    cmd_run_backend "${ARGS[@]}"
    ;;
  run_frontend|frontend|shell|ui)
    cmd_run_frontend "${ARGS[@]}"
    ;;
  reload|restart)
    cmd_reload "${ARGS[@]}"
    ;;
  stop|kill)
    cmd_stop "${ARGS[@]}"
    ;;
  status|info|check)
    cmd_status "${ARGS[@]}"
    ;;
  open_launcher)
    send_ipc_action "open_launcher" "{}"
    ;;
  toggle_launcher|launcher)
    send_ipc_action "toggle_launcher" "{}"
    ;;
  open_settings|open_settings_app)
    cmd_settings "${ARGS[@]}"
    ;;
  toggle_settings|settings)
    ACTION_SUBCOMMAND="toggle_settings" cmd_settings --toggle "${ARGS[@]}"
    ;;
  toggle_bottom_notch|bottom_notch|notch)
    send_ipc_action "toggle_app" '{"app":"bottom_notch"}'
    ;;
  toggle_audio_mixer|audio_mixer|mixer|audio)
    send_ipc_action "toggle_audio_mixer" "{}"
    ;;
  toggle_bluetooth|bluetooth|bt)
    send_ipc_action "toggle_bluetooth_view" "{}"
    ;;
  toggle_calendar|calendar|cal)
    send_ipc_action "toggle_calendar" "{}"
    ;;
  toggle_clipboard|clipboard|clip)
    send_ipc_action "toggle_clipboard" "{}"
    ;;
  toggle_clock|clock)
    SUBVIEW="${ARGS[0]:-WORLD}"
    send_ipc_action "toggle_app" "{\"app\":\"clock\",\"subview\":\"${SUBVIEW}\"}"
    ;;
  toggle_control_center|control_center|cc)
    send_ipc_action "toggle_control_center" "{}"
    ;;
  toggle_media_player|media_player|media)
    send_ipc_action "toggle_media_player" "{}"
    ;;
  toggle_notifications|notifications|notif)
    send_ipc_action "toggle_notifications" "{}"
    ;;
  toggle_power_menu|power_menu|power)
    send_ipc_action "toggle_power_menu" "{}"
    ;;
  toggle_themes|themes|theme)
    send_ipc_action "toggle_themes" "{}"
    ;;
  toggle_wifi|wifi)
    send_ipc_action "toggle_wifi_view" "{}"
    ;;
  toggle_dnd|dnd)
    send_ipc_action "toggle_dnd" "{}"
    ;;
  switch_layout|switch_keyboard)
    send_ipc_action "switch_keyboard_layout" '{"target":"next"}'
    ;;
  next_wallpaper|wallpaper)
    send_ipc_action "next_wallpaper" "{}"
    ;;
  toggle_snipping|snipping|snip|screenshot|capture)
    cmd_screenshot "${ARGS[@]}"
    ;;
  ocr)
    cmd_ocr "${ARGS[@]}"
    ;;
  record)
    cmd_record "${ARGS[@]}"
    ;;
  open_app|toggle_app|app)
    if [ -z "${ARGS[0]:-}" ]; then
      echo -e "${C_RED}[ogsShell] Hata:${C_RESET} Uygulama adı belirtilmelidir. Örn: ogsshell.sh open_app wifi" >&2
      exit 1
    fi
    send_ipc_action "toggle_app" "{\"app\":\"${ARGS[0]}\",\"subview\":\"${ARGS[1]:-}\"}"
    ;;
  preview_starship|starship)
    cmd_preview_starship "${ARGS[@]}"
    ;;
  completion|completions)
    cmd_completion "${ARGS[@]}"
    ;;
  help|--help|-h)
    cmd_help
    ;;
  *)
    echo -e "${C_RED}[ogsShell] Geçersiz komut: '${ACTION}'${C_RESET}" >&2
    echo -e "Kullanılabilir tüm komutlar için '${C_CYAN}ogsshell.sh --help${C_RESET}' çalıştırın." >&2
    exit 1
    ;;
esac
