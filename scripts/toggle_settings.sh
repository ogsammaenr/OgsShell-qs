#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Settings App Toggle Script
# Sends a toggle_settings action to the daemon via Unix Domain Socket.
# Hyprland Binding Example:
#   bind = $mainMod, I, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_settings.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/open_settings_app.sh" "$@"
