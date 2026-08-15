---
title: "Go Coding Style & Backend Guidelines"
type: rule
tags:
  - rules/go
  - backend/style
  - concurrency
  - memory-safety
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[Go-Daemon-Core]]"
  - "[[IPC-Server-Service]]"
  - "[[SysMetrics-Service]]"
  - "[[Agent-Workflow-Directives]]"
---

# Go Coding Style & Backend Guidelines

> [!NOTE]
> This document sets the coding conventions, concurrency rules, and performance standards for all Go code residing in `core/`.

---

## 1. Concurrency and Thread Safety

1. **Mutex Scoping:** Protect all shared state with `sync.Mutex` or `sync.RWMutex`. Always use `defer mu.Unlock()` or `defer mu.RUnlock()` immediately after acquiring the lock.
2. **Goroutine Lifecycle:** Every goroutine spawned must be tied to a `context.Context` cancellation or channel exit condition. Leaking un-cancelable goroutines is strictly forbidden.
3. **Non-Blocking Broadcasting:** Broadcasting over network sockets (`conn.Write`) must never stall background collection tickers.

---

## 2. Resource & Sysfs / Procfs Parsing

1. **File Descriptor Hygiene:** Every file opened via `os.Open` must have an associated `defer file.Close()`.
2. **Buffer Allocation:** Use `bufio.Scanner` or pre-allocated byte slices to prevent memory churn during high-frequency ticker loops.
3. **Defensive Math:** Always guard against division by zero when calculating deltas (e.g. CPU or throughput deltas).

---

## 3. Structured Logging

1. Use `core/logger` (`slog`) exclusively.
2. Avoid using raw `fmt.Println` in production logic.
3. Structure key-value attributes meaningfully: `log.Info("Metric gathered", "cpu", usage, "temp", temp)`.

---

## 4. Related Links

* Daemon Core: `[[Go-Daemon-Core]]`
* Agent Workflow: `[[Agent-Workflow-Directives]]`
