#!/usr/bin/env bash

# ==============================================================================
# ogsShell-qs Standalone Settings Application Launcher
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Launch Quickshell Settings App in background
nohup quickshell -p "${PROJECT_ROOT}/settings_app" </dev/null >/dev/null 2>&1 &
