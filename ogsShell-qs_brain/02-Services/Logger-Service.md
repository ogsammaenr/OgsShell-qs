---
title: "Structured ANSI Logger Service"
type: service
tags:
  - service/logger
  - go/slog
  - logging/ansi
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Server-Service]]"
  - "[[SysMetrics-Service]]"
  - "[[Go-Coding-Style]]"
---

# Structured ANSI Logger Service

> [!NOTE]
> `core/logger/logger.go` wraps Go's standard `log/slog` library with a custom thread-safe `CustomHandler` rendering colorized ANSI console output with module names and structured attributes.

---

## 1. Design & ANSI Formatting

The logger outputs log messages in the following structured format:
`HH:MM:SS [LEVEL] [MODULE] Message key1=value1 key2=value2`

### Color Palette Codes
* **DEBUG:** Cyan (`\033[36m`)
* **INFO:** Green (`\033[32m`)
* **WARN:** Yellow (`\033[33m`)
* **ERROR:** Red (`\033[31m`)

---

## 2. Implementation (`core/logger/logger.go`)

### Custom Handler Struct
```go
type CustomHandler struct {
    opts slog.HandlerOptions
    out  io.Writer
    mu   sync.Mutex
}
```

### Module Scoping Function
Allows any Go subsystem to spawn a module-tagged logger instance:
```go
func Module(name string) *slog.Logger {
    return slog.Default().With("module", name)
}
```

### Initialization
```go
func Init() {
    handler := NewCustomHandler(os.Stdout, &slog.HandlerOptions{
        Level: slog.LevelDebug,
    })
    slog.SetDefault(slog.New(handler))
}
```

---

## 3. Related Links

* Go Daemon Core: `[[Go-Daemon-Core]]`
* IPC Server: `[[IPC-Server-Service]]`
* SysMetrics Manager: `[[SysMetrics-Service]]`
