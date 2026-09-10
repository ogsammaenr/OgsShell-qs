#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Complete Installation & Environment Setup Script
# Analyzes required dependencies, installs missing tools, and builds the shell
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
CORE_DIR="${REPO_ROOT}/core"
BIN_DIR="${REPO_ROOT}/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ogsShell"

# ANSI Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BLUE="\033[1;34m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_CYAN="\033[1;36m"
C_MUTED="\033[0;90m"

echo -e "${C_BLUE}================================================================${C_RESET}"
echo -e "${C_BOLD}               ogsShell-qs Kurulum ve Kurulum Sihirbazı          ${C_RESET}"
echo -e "${C_BLUE}================================================================${C_RESET}"
echo ""

# ------------------------------------------------------------------------------
# 1. Dağıtım ve Paket Yöneticisi Tespiti
# ------------------------------------------------------------------------------
OS_ID="unknown"
AUR_HELPER=""

if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
fi

echo -e "${C_CYAN}[1/5] Sistem ve Dağıtım Tespiti...${C_RESET}"
echo -e "      Dağıtım: ${C_BOLD}${PRETTY_NAME:-$OS_ID}${C_RESET}"

if command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
fi

# ------------------------------------------------------------------------------
# 2. Bağımlılık Denetim Listesi
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_CYAN}[2/5] Gerekli Paketlerin ve Bağımlılıkların Taranması...${C_RESET}"

MISSING_PACKAGES=()
MISSING_AUR_PACKAGES=()

# Kontrol fonksiyonu
check_command() {
  local cmd="$1"
  local pkg_arch="$2"
  local pkg_fedora="$3"
  local is_aur="${4:-false}"
  local desc="$5"

  if command -v "$cmd" >/dev/null 2>&1; then
    echo -e "  ${C_GREEN}[✓]${C_RESET} ${C_BOLD}${cmd}${C_RESET} kurulu ${C_MUTED}(${desc})${C_RESET}"
    return 0
  else
    echo -e "  ${C_RED}[✗]${C_RESET} ${C_BOLD}${cmd}${C_RESET} ${C_RED}EKSİK!${C_RESET} ${C_MUTED}(${desc})${C_RESET}"
    if [ "$OS_ID" = "arch" ] || [ "$OS_ID" = "archarm" ] || [ "$OS_ID" = "endeavouros" ] || [ "$OS_ID" = "manjaro" ] || [ "$OS_ID" = "cachyos" ]; then
      if [ "$is_aur" = "true" ]; then
        MISSING_AUR_PACKAGES+=("$pkg_arch")
      else
        MISSING_PACKAGES+=("$pkg_arch")
      fi
    elif [ "$OS_ID" = "fedora" ]; then
      MISSING_PACKAGES+=("$pkg_fedora")
    fi
    return 1
  fi
}

check_command "go" "go" "golang" "false" "Go Derleyicisi (Backend daemon için)"
check_command "quickshell" "quickshell" "quickshell" "true" "Quickshell Wayland Framework"
check_command "hyprctl" "hyprland" "hyprland" "false" "Hyprland Compositor"
check_command "wl-copy" "wl-clipboard" "wl-clipboard" "false" "Wayland Pano Yöneticisi"
check_command "cliphist" "cliphist" "cliphist" "false" "Pano Geçmişi Servisi"
check_command "pw-play" "pipewire-audio" "pipewire-utils" "false" "PipeWire Ses & Geri Bildirim"
check_command "nmcli" "networkmanager" "NetworkManager" "false" "Wi-Fi & Ağ Yönetimi"
check_command "bluetoothctl" "bluez-utils" "bluez" "false" "Bluetooth Servisi"
check_command "inotifywait" "inotify-tools" "inotify-tools" "false" "Canlı Konfigürasyon İzleme"

# Font kontrolü
if fc-list : family | grep -iq "Nerd Font"; then
  echo -e "  ${C_GREEN}[✓]${C_RESET} ${C_BOLD}Nerd Fonts${C_RESET} algılandı (İkonlar ve semboller için)"
else
  echo -e "  ${C_YELLOW}[!]${C_RESET} ${C_BOLD}Nerd Font${C_RESET} bulunamadı! ${C_MUTED}(ttf-jetbrains-mono-nerd önerilir)${C_RESET}"
  if [ "$OS_ID" = "arch" ]; then
    MISSING_PACKAGES+=("ttf-jetbrains-mono-nerd")
  fi
fi

# ------------------------------------------------------------------------------
# 3. Eksik Paketlerin Kurulumu (İsteğe Bağlı)
# ------------------------------------------------------------------------------
TOTAL_MISSING=$((${#MISSING_PACKAGES[@]} + ${#MISSING_AUR_PACKAGES[@]}))

if [ $TOTAL_MISSING -gt 0 ]; then
  echo ""
  echo -e "${C_YELLOW}[!] Toplam ${TOTAL_MISSING} adet eksik paket tespit edildi:${C_RESET}"
  if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo -e "    Resmi Depo Paketleri: ${C_BOLD}${MISSING_PACKAGES[*]}${C_RESET}"
  fi
  if [ ${#MISSING_AUR_PACKAGES[@]} -gt 0 ]; then
    echo -e "    AUR Paketleri:       ${C_BOLD}${MISSING_AUR_PACKAGES[*]}${C_RESET}"
  fi
  echo ""

  read -p "Eksik paketleri şimdi otomatik kurmak ister misiniz? [E/h]: " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Ee]$ ]] || [[ -z $REPLY ]]; then
    if [ "$OS_ID" = "arch" ] || [ "$OS_ID" = "endeavouros" ] || [ "$OS_ID" = "cachyos" ] || [ "$OS_ID" = "manjaro" ]; then
      if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo -e "${C_BLUE}Pacman ile resmi paketler kuruluyor...${C_RESET}"
        sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
      fi
      if [ ${#MISSING_AUR_PACKAGES[@]} -gt 0 ]; then
        if [ -n "$AUR_HELPER" ]; then
          echo -e "${C_BLUE}${AUR_HELPER} ile AUR paketleri kuruluyor...${C_RESET}"
          $AUR_HELPER -S --needed "${MISSING_AUR_PACKAGES[@]}"
        else
          echo -e "${C_RED}[UYARI] yay veya paru bulunamadı. Lütfen şu AUR paketlerini elle kurun:${C_RESET} ${MISSING_AUR_PACKAGES[*]}"
        fi
      fi
    elif [ "$OS_ID" = "fedora" ]; then
      if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo -e "${C_BLUE}DNF ile paketler kuruluyor...${C_RESET}"
        sudo dnf install -y "${MISSING_PACKAGES[@]}"
      fi
    else
      echo -e "${C_YELLOW}Lütfen eksik paketleri dağıtımınızın paket yöneticisi ile kurun.${C_RESET}"
    fi
  else
    echo -e "${C_MUTED}Paket kurulumu atlandı. Devam ediliyor...${C_RESET}"
  fi
else
  echo -e "  ${C_GREEN}Tüm temel sistem gereksinimleri tam!${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 4. Backend Derleme (ogsshell-core)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_CYAN}[3/5] Go Backend Daemon Derleniyor (${CORE_DIR})...${C_RESET}"
mkdir -p "${BIN_DIR}"

if command -v go >/dev/null 2>&1; then
  (
    cd "${CORE_DIR}"
    echo -e "      Modüller indiriliyor (go mod download)..."
    go mod download
    echo -e "      Derleniyor (go build -> bin/ogsshell-core)..."
    go build -o "${BIN_DIR}/ogsshell-core" .
  )
  echo -e "  ${C_GREEN}[✓]${C_RESET} Backend başarıyla derlendi: ${C_BOLD}${BIN_DIR}/ogsshell-core${C_RESET}"
else
  echo -e "  ${C_RED}[✗] Go bulunamadığı için backend derlenemedi!${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 5. Konfigürasyon ve Şablon Kurulumu (~/.config/ogsShell/)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_CYAN}[4/5] Kullanıcı Konfigürasyon Dizini Hazırlanıyor...${C_RESET}"
mkdir -p "${CONFIG_DIR}"

# Varsayılan config.json kopyalama
if [ ! -f "${CONFIG_DIR}/config.json" ]; then
  cp "${REPO_ROOT}/shell/config.json" "${CONFIG_DIR}/config.json"
  echo -e "  ${C_GREEN}[✓]${C_RESET} Varsayılan config.json kopyalandı -> ${C_BOLD}${CONFIG_DIR}/config.json${C_RESET}"
else
  echo -e "  ${C_GREEN}[✓]${C_RESET} Mevcut config.json korundu."
fi

# Temaları ve paylaşılan dosyaları kopyalama
if [ -d "${REPO_ROOT}/shared/themes" ]; then
  mkdir -p "${CONFIG_DIR}/themes"
  cp -rn "${REPO_ROOT}/shared/themes/"* "${CONFIG_DIR}/themes/" 2>/dev/null || true
  echo -e "  ${C_GREEN}[✓]${C_RESET} Tema paletleri eşitlendi -> ${C_BOLD}${CONFIG_DIR}/themes/${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 6. Global Çalıştırıcı ve Kısayol Entegrasyonu
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_CYAN}[5/5] Global Kısayol ve Çalıştırıcı Entegrasyonu...${C_RESET}"

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "${LOCAL_BIN}"

cat << RUNNER_EOF > "${LOCAL_BIN}/ogsshell"
#!/usr/bin/env bash
exec "${REPO_ROOT}/scripts/run_shell.sh" "\$@"
RUNNER_EOF
chmod +x "${LOCAL_BIN}/ogsshell"

echo -e "  ${C_GREEN}[✓]${C_RESET} Çalıştırıcı komut oluşturuldu: ${C_BOLD}${LOCAL_BIN}/ogsshell${C_RESET}"
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
  echo -e "      ${C_YELLOW}Not:${C_RESET} ~/.local/bin dizini PATH'inizde değilse kabuk konfigürasyonunuza (~/.bashrc veya ~/.zshrc) ekleyin:"
  echo -e "      ${C_MUTED}export PATH=\"\$HOME/.local/bin:\$PATH\"${C_RESET}"
fi

echo ""
echo -e "${C_GREEN}================================================================${C_RESET}"
echo -e "${C_BOLD}🎉 ogsShell-qs Kurulumu Başarıyla Tamamlandı!${C_RESET}"
echo -e "${C_GREEN}================================================================${C_RESET}"
echo ""
echo -e "${C_BOLD}Nasıl Başlatılır?${C_RESET}"
echo -e "  1. Terminalden çalıştırmak için:       ${C_CYAN}ogsshell${C_RESET} veya ${C_CYAN}./scripts/run_shell.sh${C_RESET}"
echo -e "  2. Hyprland otomatik başlatma için:   ${C_BOLD}~/.config/hypr/hyprland.conf${C_RESET} dosyasına ekleyin:"
echo -e "     ${C_YELLOW}exec-once = ogsshell${C_RESET}"
echo ""
