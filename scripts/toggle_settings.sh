#!/usr/bin/env bash
set -e

# ==============================================================================
# ogsShell-qs Standalone Qt Settings App Toggle Script
# Hyprland Binding Example:
#   bind = $mainMod, I, exec, ~/WorkSpace/projects/OgsShell-qs/scripts/toggle_settings.sh
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[toggle_settings.sh] Toggling settings_app..."
exec "${SCRIPT_DIR}/open_settings_app.sh" --toggle "$@"
