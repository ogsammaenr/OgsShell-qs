---
title: "App Launcher Service"
type: service
tags:
  - service/launcher
  - daemon/c
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[Shell-Bar-Components]]"
---

# App Launcher Service

> [!NOTE]
> `AppLauncherService.qml` interfaces with `bin/app_launcher_helper` to scan system `.desktop` files, resolve application icons, track usage counts, and provide inline calculation capabilities.

## Binary Details (`bin/app_launcher_helper`)

- **Source:** `shell/services/app_launcher_helper.c`
- **Output:** `bin/app_launcher_helper`
- **Features:**
  - Fast multithreaded `.desktop` file parser.
  - Usage frequency stats logging via `--launch <path>`.

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Shell Bar UI Components: `[[Shell-Bar-Components]]`
