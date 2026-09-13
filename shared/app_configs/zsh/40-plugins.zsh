# =============================================================================
# 40-plugins.zsh - Eklentiler ve Tuş Eşlemeleri (Plugins & Keybindings)
# =============================================================================

# 1. Standart Tuş Eşlemeleri (Emacs Modu & Terminal Standartları)
bindkey -e

# Home / End / Delete tuşları
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

# Ctrl+Sol / Ctrl+Sağ ile kelime atlama
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Yukarı / Aşağı ok ile komut geçmişinde filtreli arama
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# 2. Zsh Autosuggestions (Yazarken Otomatik Komut Önerileri)
if [[ -f "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  # Ctrl+Space veya Sağ Ok ile öneriyi kabul etme
  bindkey '^ ' autosuggest-accept
fi

# 3. Zsh Syntax Highlighting (Sözdizimi Renklendirmesi - Daima En Sonda Yüklenmeli)
if [[ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
