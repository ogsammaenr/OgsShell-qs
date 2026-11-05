#!/usr/bin/env bash
# ==============================================================================
# ogsShell-qs - Close System Tray Application Helper
#
# Locates a running StatusNotifierItem by its ID, Title, or Tooltip, attempts a
# graceful DBusMenu "Quit" trigger, falls back to SIGTERM/SIGKILL on the owning
# D-Bus process PID, and finally falls back to process name matching.
#
# Usage:
#   scripts/close_tray_app.sh "<id>" "<title>" "<tooltip>"
# ==============================================================================

TARGET_ID="$1"
TARGET_TITLE="$2"
TARGET_TOOLTIP="$3"

# Clean app name helper (strips suffixes like _status_icon_1, -1234, etc.)
clean_name() {
  local s="$1"
  if [ -z "$s" ]; then return; fi
  s=$(echo "$s" | sed -E 's/(_status_icon.*|[-_][0-9]+.*)//g')
  echo "$s" | tr '[:upper:]' '[:lower:]' | xargs
}

APP_NAME="$(clean_name "$TARGET_ID")"
if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "app" ] || [ "$APP_NAME" = "statusnotifieritem" ]; then
  APP_NAME="$(clean_name "$TARGET_TITLE")"
fi
if [ -z "$APP_NAME" ]; then
  APP_NAME="$(clean_name "$TARGET_TOOLTIP")"
fi

# 1. Query StatusNotifierWatcher items
items=$(busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null | sed 's/as [0-9]* //; s/"//g')

found_srv=""
found_pth=""
found_pid=""

for it in $items; do
  srv="${it%%/*}"
  pth="/${it#*/}"
  id=$(busctl --user get-property "$srv" "$pth" org.kde.StatusNotifierItem Id 2>/dev/null | cut -d'"' -f2)
  title=$(busctl --user get-property "$srv" "$pth" org.kde.StatusNotifierItem Title 2>/dev/null | cut -d'"' -f2)
  tooltip=$(busctl --user get-property "$srv" "$pth" org.kde.StatusNotifierItem ToolTip 2>/dev/null | cut -d'"' -f4)

  if [ -n "$TARGET_ID" ] && [ "$id" = "$TARGET_ID" ]; then
    found_srv="$srv"; found_pth="$pth"; break
  fi
  if [ -n "$TARGET_TITLE" ] && [ "$title" = "$TARGET_TITLE" ]; then
    found_srv="$srv"; found_pth="$pth"; break
  fi
  if [ -n "$TARGET_TOOLTIP" ] && [ "$tooltip" = "$TARGET_TOOLTIP" ]; then
    found_srv="$srv"; found_pth="$pth"; break
  fi
  if [ -n "$APP_NAME" ] && [[ "$id" =~ "$APP_NAME" ]]; then
    found_srv="$srv"; found_pth="$pth"; break
  fi
done

# 2. If StatusNotifierItem found, try DBusMenu Quit action first
if [ -n "$found_srv" ] && [ -n "$found_pth" ]; then
  found_pid=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID s "$found_srv" 2>/dev/null | awk '{print $2}')
  
  menu_pth=$(busctl --user get-property "$found_srv" "$found_pth" org.kde.StatusNotifierItem Menu 2>/dev/null | cut -d'"' -f2)
  if [ -n "$menu_pth" ]; then
    layout=$(busctl --user call "$found_srv" "$menu_pth" com.canonical.dbusmenu GetLayout -- iias 0 -1 0 2>/dev/null)
    quit_match=$(echo "$layout" | grep -oEi '\(ia\{sv\}av\) ([0-9]+) [0-9]+ "label" s "(quit|exit|çıkış|kapat|close)' | head -n 1)
    if [ -n "$quit_match" ]; then
      quit_id=$(echo "$quit_match" | awk '{print $2}')
      if [ -n "$quit_id" ]; then
        busctl --user call "$found_srv" "$menu_pth" com.canonical.dbusmenu Event isvu "$quit_id" "clicked" i 0 0 2>/dev/null || true
      fi
    fi
  fi
fi

# 3. If owning PID exists, check if process terminates gracefully; if still alive, send SIGTERM then SIGKILL
if [ -n "$found_pid" ] && [ "$found_pid" -gt 0 ] 2>/dev/null; then
  sleep 0.25
  if kill -0 "$found_pid" 2>/dev/null; then
    kill -15 "$found_pid" 2>/dev/null || true
    sleep 0.6
    if kill -0 "$found_pid" 2>/dev/null; then
      kill -9 "$found_pid" 2>/dev/null || true
    fi
  fi
  exit 0
fi

# 4. Fallback: Process name termination
if [ -n "$APP_NAME" ]; then
  pkill -15 -x "$APP_NAME" 2>/dev/null || pkill -15 -f "$APP_NAME" 2>/dev/null || true
  sleep 0.5
  if pgrep -x "$APP_NAME" >/dev/null 2>&1 || pgrep -f "$APP_NAME" >/dev/null 2>&1; then
    pkill -9 -x "$APP_NAME" 2>/dev/null || true
  fi
fi
