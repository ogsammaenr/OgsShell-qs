#!/usr/bin/env bash
# ==============================================================================
#  ogsShell-qs: Starship Prompt Full Gallery & Module Tester
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PALETTES_DIR="${REPO_ROOT}/shared/app_configs/starship/palettes"
BASE_CONF="${REPO_ROOT}/shared/app_configs/starship/base.toml"

PREVIEW_DIR="/tmp/starship_full_preview"
rm -rf "${PREVIEW_DIR}"
mkdir -p "${PREVIEW_DIR}"

# 1. Mock Git Repo
(
  cd "${PREVIEW_DIR}"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Tester"
  echo "hello" > README.md
  git add README.md
  git commit -m "feat: initial commit" -q
  echo "modified line" >> README.md
  touch untracked_file.txt

  # 2. Mock Runtimes
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

echo -e "\033[1;34m================================================================\033[0m"
echo -e "\033[1;36m       OGSSHELL-QS: STARSHIP TÜM MODÜLLER VE TEMA TESTİ         \033[0m"
echo -e "\033[1;34m================================================================\033[0m"

render_theme() {
  local theme_id="$1"
  local palette_file="${PALETTES_DIR}/${theme_id}.toml"

  if [ ! -f "${palette_file}" ]; then
    echo "Tema paleti bulunamadı: ${palette_file}"
    return 1
  fi

  echo -e "\n\033[1;33m▶ TEMA: [${theme_id^^}]\033[0m"
  
  # Geçici TOML oluştur
  local tmp_cfg
  tmp_cfg=$(mktemp /tmp/starship_test_XXXXXX.toml)
  echo "palette = \"${theme_id}\"" > "${tmp_cfg}"
  echo "" >> "${tmp_cfg}"
  cat "${BASE_CONF}" >> "${tmp_cfg}"
  echo "" >> "${tmp_cfg}"
  cat "${palette_file}" >> "${tmp_cfg}"

  echo -e "\033[0;90m--- Başarılı Komut (Status 0, 3.5s süre): ---\033[0m"
  STARSHIP_CONFIG="${tmp_cfg}" TERM=xterm-256color starship prompt -p "${PREVIEW_DIR}" -d 3500 -s 0
  echo ""
  
  echo -e "\033[0;90m--- Hatalı Komut (Status 1, Hata ikonu): ---\033[0m"
  STARSHIP_CONFIG="${tmp_cfg}" TERM=xterm-256color starship prompt -p "${PREVIEW_DIR}" -d 1200 -s 1
  echo ""

  rm -f "${tmp_cfg}"
}

if [ "$1" == "--all" ] || [ "$1" == "-a" ]; then
  for p in "${PALETTES_DIR}"/*.toml; do
    t_id=$(basename "$p" .toml)
    render_theme "${t_id}"
  done
else
  # Sadece aktif temayı veya argüman olarak verileni göster
  ACTIVE_THEME="${1:-monochrome}"
  render_theme "${ACTIVE_THEME}"
  echo -e "\033[0;90m💡 İpucu: 7 temanın tamamını görmek için:\033[0m \033[1;32m./scripts/preview_starship.sh --all\033[0m"
fi
