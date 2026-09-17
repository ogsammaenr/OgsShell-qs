# =============================================================================
# ogsShell-qs Tab Completion for Bash
# =============================================================================

_ogsshell_bash() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="run run_shell run_backend backend core run_frontend frontend reload restart stop kill status info toggle_launcher launcher open_launcher toggle_settings settings open_settings toggle_bottom_notch notch toggle_control_center cc toggle_audio_mixer mixer audio toggle_bluetooth bluetooth bt toggle_wifi wifi toggle_calendar calendar cal toggle_clipboard clipboard clip toggle_clock clock toggle_media_player media toggle_notifications notif toggle_power_menu power toggle_themes themes theme toggle_dnd dnd switch_layout next_wallpaper screenshot snip ocr record open_app preview_starship starship help --help"

  if [ $COMP_CWORD -eq 1 ]; then
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
    return 0
  fi

  case "${prev}" in
    toggle_clock|clock)
      COMPREPLY=( $(compgen -W "WORLD POMODORO STOPWATCH ALARMS" -- "${cur}") )
      ;;
    screenshot|snip)
      COMPREPLY=( $(compgen -W "--region --full" -- "${cur}") )
      ;;
    ocr)
      COMPREPLY=( $(compgen -W "--region" -- "${cur}") )
      ;;
    record)
      COMPREPLY=( $(compgen -W "--toggle --start --stop --region" -- "${cur}") )
      ;;
    preview_starship|starship)
      COMPREPLY=( $(compgen -W "--all catppuccin everforest gruvbox monochrome nord rosepine tokyonight" -- "${cur}") )
      ;;
    open_app|toggle_app|app)
      COMPREPLY=( $(compgen -W "themes notifications control_center power media calendar clipboard clock wifi bluetooth audio launcher" -- "${cur}") )
      ;;
    *)
      ;;
  esac
}

complete -F _ogsshell_bash ogsshell ogsshell.sh ogs ogs.sh
