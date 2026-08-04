---
title: "System Stats Service & Monitor Daemon"
type: service
tags:
  - service/sysinfo
  - daemon/c
created: 2026-08-03
updated: 2026-08-03
status: active
related_notes:
  - "[[Architecture-Overview]]"
  - "[[Shell-Bar-Components]]"
  - "[[ControlCenter-UI]]"
---

# System Stats Service & Monitor Daemon

> [!NOTE]
> `SystemStatsService.qml` runs `bin/monitor` in the background. The native C daemon streams JSON formatted hardware statistics, network transfer rates, media playback details, and audio levels to QML via `SplitParser`.

## Daemon Details (`bin/monitor`)

- **Source Code:** `shell/services/monitor/` (`main.c`, `sys_info.c`, `hw_controls.c`, `media_notif.c`)
- **Binary Output:** `bin/monitor`
- **Output Format:** Continuous newline-delimited JSON stream.

```json
{
  "cpu": 12.4,
  "ram": { "used": 4200, "total": 16000, "pct": 26.2 },
  "gpu": { "usage": 15, "temp": 45 },
  "net": { "rx_bytes_sec": 10240, "tx_bytes_sec": 5120 },
  "media": { "status": "Playing", "title": "Song", "artist": "Artist" }
}
```

## QML Integration (`SystemStatsService.qml`)

```qml
Item {
  id: service
  readonly property string binDir: (typeof Quickshell !== "undefined" && Quickshell.env("ROOT_DIR"))
                                     ? Quickshell.env("ROOT_DIR") + "/bin"
                                     : "/home/excalibur/WorkSpace/projects/OgsShell-qs/bin"

  property real cpuUsage: 0
  property real ramUsagePct: 0
  property string mediaTitle: ""

  Process {
    id: monitorProc
    command: [service.binDir + "/monitor"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        var data = JSON.parse(line);
        service.cpuUsage = data.cpu;
        service.ramUsagePct = data.ram.pct;
      }
    }
  }
}
```

## Related Notes
- Architecture Overview: `[[Architecture-Overview]]`
- Shell Bar UI Components: `[[Shell-Bar-Components]]`
- Control Center UI: `[[ControlCenter-UI]]`
