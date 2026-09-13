# =============================================================================
# 10-options.zsh - Zsh Kabuk Davranışları ve Geçmiş (History) Yapılandırması
# =============================================================================

# 1. Komut Geçmişi (History) Ayarları
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ ! -d "${HISTFILE:h}" ]] && mkdir -p "${HISTFILE:h}"

HISTSIZE=50000
SAVEHIST=50000

# Geçmiş Seçenekleri
setopt EXTENDED_HISTORY          # Komut çalışma zaman damgası ve süresini kaydet
setopt SHARE_HISTORY             # Açık tüm terminal oturumları arasında geçmişi anında paylaş
setopt HIST_EXPIRE_DUPS_FIRST    # Boyut dolduğunda ilk olarak mükerrer kayıtları sil
setopt HIST_IGNORE_DUPS          # Üst üste aynı komut girildiğinde yalnızca bir kez kaydet
setopt HIST_IGNORE_ALL_DUPS      # Yeni komut girildiğinde eski kopyasını sil
setopt HIST_FIND_NO_DUPS         # Geçmiş aramalarında mükerrer komutları gösterme
setopt HIST_IGNORE_SPACE         # Boşlukla başlayan gizli/hassas komutları geçmişe yazma
setopt HIST_SAVE_NO_DUPS         # Dosyaya kaydederken tekrarları temizle
setopt HIST_REDUCE_BLANKS        # Gereksiz boşlukları kırp
setopt HIST_VERIFY               # Geçmiş genişletmesi yapıldığında hemen çalıştırma, teyit bekle

# 2. Dizin Gezinme Seçenekleri
setopt AUTO_CD                   # Dizin yolunu yazarak doğrudan içine gir (örn: .. veya ~/Masaüstü)
setopt AUTO_PUSHD                # cd ile gezilen her dizini yığına ekle (pushd)
setopt PUSHD_IGNORE_DUPS         # Dizin yığınında tekrarları önle
setopt PUSHD_SILENT              # pushd/popd çıktısını sessize al

# 3. Genel Kabuk Davranışları
setopt INTERACTIVE_COMMENTS      # Komut satırında '#' ile yorum yazabilmeye izin ver
setopt NO_BEEP                   # Can sıkıcı terminal bip/zil seslerini kapat
setopt EXTENDED_GLOB             # Gelişmiş dosya kalıp eşleme (globbing) desteğini aç
setopt PROMPT_SUBST              # Prompt içinde dinamik değişken genişletmesini etkinleştir
