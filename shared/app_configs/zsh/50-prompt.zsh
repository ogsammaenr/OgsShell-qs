# =============================================================================
# 50-prompt.zsh - Komut İstemi (Prompt) Yapılandırması
# =============================================================================

# Starship Prompt Entegrasyonu
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
