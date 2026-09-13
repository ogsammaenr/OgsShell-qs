# =============================================================================
# 20-completion.zsh - Zsh Otomatik Tamamlama (Completion) Sistemi
# =============================================================================

# 1. Yüksek Performanslı compinit Başlatıcısı (24 Saatlik Önbellek)
autoload -Uz compinit

_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
[[ ! -d "${_zcompdump:h}" ]] && mkdir -p "${_zcompdump:h}"

# Önbellek dosyasını yalnızca günde bir kez derle (hızlı terminal açılışı için)
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

# 2. Tamamlama Menüsü ve Stiller
zstyle ':completion:*' menu select                                      # Sekme (Tab) ile gezilebilen görsel menü
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*' # Büyük/küçük harf duyarsız ve akıllı eşleme
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"                # Dosya türlerine göre renkli listeleme
zstyle ':completion:*:descriptions' format '%F{cyan}[%d]%f'            # Açıklama başlık rengi
zstyle ':completion:*:warnings' format '%F{red}-- Eşleşen sonuç bulunamadı --%f'
zstyle ':completion:*' verbose yes

# Süreç (kill) tamamlama renklendirmesi
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
