#!/bin/bash

# Determine project directory and root directory dynamically
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_DIR ROOT_DIR

# Compile C daemons if needed
make -C "$PROJECT_DIR" || exit 1

# Kill any existing instances of this quickshell configuration
qs -p "$PROJECT_DIR" kill 2>/dev/null || true

# Launch the new instance detached (daemonized)
qs -d -p "$PROJECT_DIR"
