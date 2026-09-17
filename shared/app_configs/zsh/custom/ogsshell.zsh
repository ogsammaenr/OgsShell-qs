# =============================================================================
# ogsShell-qs Tab Completion for Zsh
# Registers completion for ogsshell, ogsshell.sh, ogs, ogs.sh
# =============================================================================

_ogsshell() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  local -a subcommands
  subcommands=(
    'run:Tüm kabuğu (Backend daemon + Quickshell) birlikte başlatır'
    'run_shell:Tüm kabuğu (Backend daemon + Quickshell) birlikte başlatır'
    'run_backend:Go daemon arka plan servisini canlı loglarla ön planda başlatır'
    'backend:Go daemon arka plan servisini canlı loglarla ön planda başlatır'
    'core:Go daemon arka plan servisini canlı loglarla ön planda başlatır'
    'run_frontend:Quickshell Dynamic Island ön yüzünü başlatır'
    'frontend:Quickshell Dynamic Island ön yüzünü başlatır'
    'reload:Quickshell arayüzünü anında yeniden yükler'
    'restart:Quickshell arayüzünü anında yeniden yükler'
    'stop:Çalışan tüm ogsShell servislerini kapatır'
    'kill:Çalışan tüm ogsShell servislerini kapatır'
    'status:Backend, soket ve arayüz durumunu denetler'
    'info:Backend, soket ve arayüz durumunu denetler'
    'toggle_launcher:Uygulama Başlatıcıyı (Spotlight) açar/kapatır'
    'launcher:Uygulama Başlatıcıyı (Spotlight) açar/kapatır'
    'open_launcher:Uygulama Başlatıcıyı doğrudan açar'
    'toggle_settings:Ayarlar uygulamasını açar/kapatır'
    'settings:Ayarlar uygulamasını açar/kapatır'
    'open_settings:Ayarlar uygulamasını doğrudan açar'
    'toggle_bottom_notch:Alt Komut Çentiğini (Bottom Notch) açar/kapatır'
    'notch:Alt Komut Çentiğini (Bottom Notch) açar/kapatır'
    'toggle_control_center:Kontrol Merkezini açar/kapatır'
    'cc:Kontrol Merkezini açar/kapatır'
    'toggle_audio_mixer:Ses Karıştırıcısını açar/kapatır'
    'mixer:Ses Karıştırıcısını açar/kapatır'
    'audio:Ses Karıştırıcısını açar/kapatır'
    'toggle_bluetooth:Bluetooth cihaz panelini açar/kapatır'
    'bluetooth:Bluetooth cihaz panelini açar/kapatır'
    'bt:Bluetooth cihaz panelini açar/kapatır'
    'toggle_wifi:Wi-Fi ağ panelini açar/kapatır'
    'wifi:Wi-Fi ağ panelini açar/kapatır'
    'toggle_calendar:Takvim ve Etkinlikler görünümünü açar/kapatır'
    'calendar:Takvim ve Etkinlikler görünümünü açar/kapatır'
    'cal:Takvim ve Etkinlikler görünümünü açar/kapatır'
    'toggle_clipboard:Pano geçmişini açar/kapatır'
    'clipboard:Pano geçmişini açar/kapatır'
    'clip:Pano geçmişini açar/kapatır'
    'toggle_clock:Saat menüsünü açar'
    'clock:Saat menüsünü açar'
    'toggle_media_player:Medya oynatıcı kontrolünü açar/kapatır'
    'media:Medya oynatıcı kontrolünü açar/kapatır'
    'toggle_notifications:Bildirim merkezini açar/kapatır'
    'notif:Bildirim merkezini açar/kapatır'
    'toggle_power_menu:Güç ve Oturum menüsünü açar/kapatır'
    'power:Güç ve Oturum menüsünü açar/kapatır'
    'toggle_themes:Tema seçici panelini açar/kapatır'
    'themes:Tema seçici panelini açar/kapatır'
    'theme:Tema seçici panelini açar/kapatır'
    'toggle_dnd:Rahatsız Etme modunu (DND) açar/kapatır'
    'dnd:Rahatsız Etme modunu (DND) açar/kapatır'
    'switch_layout:Klavye dilini bir sonrakine geçirir'
    'next_wallpaper:Aktif temanın sıradaki duvar kağıdına geçer'
    'screenshot:Ekran görüntüsü alır (--region veya --full)'
    'snip:Ekran dondurmalı bölge kırpma aracını açar'
    'ocr:Bölgeden metin tanıma (OCR) yapar ve panoya kopyalar'
    'record:Ekran kaydını başlatır, durdurur veya tersine çevirir'
    'open_app:Genel uygulama veya alt görünüm tetikler'
    'preview_starship:Starship prompt tema paletlerini önizler'
    'starship:Starship prompt tema paletlerini önizler'
    'help:Yardım kılavuzunu görüntüler'
    '--help:Yardım kılavuzunu görüntüler'
  )

  _arguments -C \
    '1:komut:->subcmd' \
    '*::arg:->args'

  case "$state" in
    subcmd)
      _describe -t subcommands 'ogsShell komutu' subcommands
      ;;
    args)
      case "$words[1]" in
        toggle_clock|clock)
          local -a clock_modes
          clock_modes=(
            'WORLD:Dünya Saatleri'
            'POMODORO:Pomodoro Zamanlayıcı'
            'STOPWATCH:Kronometre'
            'ALARMS:Alarmlar ve Zamanlayıcılar'
          )
          _describe -t clock_modes 'Saat alt modu' clock_modes
          ;;
        screenshot|snip|capture)
          local -a ss_args
          ss_args=(
            '--region:Ekran dondurmalı interaktif bölge seçimi (varsayılan)'
            '--full:Anında tam ekran görüntüsü al'
          )
          _describe -t ss_args 'Ekran görüntüsü modu' ss_args
          ;;
        ocr)
          local -a ocr_args
          ocr_args=(
            '--region:Ekran dondurmalı interaktif OCR bölge seçimi'
          )
          _describe -t ocr_args 'OCR modu' ocr_args
          ;;
        record)
          local -a rec_args
          rec_args=(
            '--toggle:Ekran kaydını başlat/bitir (varsayılan)'
            '--start:Tam ekran video kaydını başlat'
            '--stop:Aktif video kaydını durdur'
            '--region:İnteraktif bölge seçerek kayıt başlat'
          )
          _describe -t rec_args 'Kayıt eylemi' rec_args
          ;;
        preview_starship|starship)
          local -a starship_themes
          starship_themes=(
            '--all:Tüm 7 temayı sırayla test et'
            'catppuccin:Catppuccin Mocha'
            'everforest:Everforest Dark'
            'gruvbox:Gruvbox Dark'
            'monochrome:Monochrome Minimal'
            'nord:Nord Arctic'
            'rosepine:Rosé Pine'
            'tokyonight:Tokyo Night'
          )
          _describe -t starship_themes 'Starship teması' starship_themes
          ;;
        open_app|toggle_app|app)
          local -a apps
          apps=(
            'themes:Tema Galerisi'
            'notifications:Bildirim Merkezi'
            'control_center:Kontrol Merkezi'
            'power:Güç ve Oturum Menüsü'
            'media:Medya Oynatıcı Kontrolleri'
            'calendar:Takvim ve Etkinlikler'
            'clipboard:Pano Geçmişi'
            'clock:Saat ve Süreölçerler'
            'wifi:Wi-Fi Bağlantıları'
            'bluetooth:Bluetooth Cihazları'
            'audio:Ses Karıştırıcısı'
            'launcher:Spotlight Uygulama Başlatıcı'
          )
          _describe -t apps 'Uygulama veya bileşen' apps
          ;;
      esac
      ;;
  esac
}

# Register compdef if compinit is initialized
if (( $+functions[compdef] )); then
  compdef _ogsshell ogsshell
  compdef _ogsshell ogsshell.sh
  compdef _ogsshell ogs
  compdef _ogsshell ogs.sh
fi
