# =============================================================================
# 30-aliases.zsh - Kısayollar ve Modern CLI Takma Adları (Aliases)
# =============================================================================

# 1. Modern Listeleme Komutları (eza / ls)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lah --color=auto'
fi

# 2. Hızlı Dizin Gezinme
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# 3. Güvenli Dosya İşlemleri (Teyit ve Bilgilendirme)
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias mkdir='mkdir -pv'
alias df='df -h'
alias free='free -h'
alias grep='grep --color=auto'

# 4. Git Sürüm Kontrol Kısayolları
alias g='git'
alias gst='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -n 20'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'

# 5. Arch Linux Paket Yönetimi (Pacman)
alias pacin='sudo pacman -S'
alias pacrem='sudo pacman -Rns'
alias pacup='sudo pacman -Syu'
alias pacsearch='pacman -Ss'

# 6. OgsShell / Quickshell Geliştirme ve Yönetim
alias qsl='quickshell list --all'
alias qsk='pkill quickshell'
alias qsr='pkill quickshell && sleep 0.5 && quickshell -d -p ~/Workspace/projects/OgsShell-qs/shell'
alias qslg='quickshell log -p ~/Workspace/projects/OgsShell-qs/shell -f'
