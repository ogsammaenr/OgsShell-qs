# =============================================================================
# 00-environment.zsh - Ortam Değişkenleri ve Yol (PATH) Yapılandırması
# =============================================================================

# 1. XDG Taban Dizin Standartları
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# 2. PATH Yönetimi (Tekrarları otomatik önler: typeset -U)
typeset -U path PATH

# Antigravity CLI & Kullanıcı Binary Dizinleri
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/go/bin" ]] && path=("$HOME/go/bin" $path)
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)
export PATH

# 3. Varsayılan Editör ve Sayfalayıcı
if command -v nvim &>/dev/null; then
  export EDITOR="nvim"
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
elif command -v nano &>/dev/null; then
  export EDITOR="nano"
fi
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R -F -X"

# 4. Dil ve Karakter Kodlaması
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
