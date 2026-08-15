---
title: "RAM Monitor Subsystem Service"
type: service
tags:
  - service/ram
  - go/monitors
  - procfs/meminfo
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[SysMetrics-Service]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Go-Coding-Style]]"
---

# RAM Monitor Subsystem Service

> [!NOTE]
> The RAM Monitor (`core/monitors/ram.go`) inspects `/proc/meminfo` to calculate total memory, used memory, and memory utilization percentage in real time.

---

## 1. Metric Calculation Formula

Linux tracks free memory, active buffers, and page caches separately. The most accurate metric for user-space memory consumption is derived from `MemAvailable`:

$$\text{Total MB} = \frac{\text{MemTotal}}{1024}$$
$$\text{Available MB} = \frac{\text{MemAvailable}}{1024}$$
$$\text{Used MB} = \text{Total MB} - \text{Available MB}$$
$$\text{Percent \%} = \left( \frac{\text{Used MB}}{\text{Total MB}} \right) \times 100.0$$

---

## 2. Source Code Implementation (`core/monitors/ram.go`)

### Data Structure
```go
type RAMInfo struct {
    UsedMB  uint64  `json:"ram_used_mb"`
    TotalMB uint64  `json:"ram_total_mb"`
    Percent float64 `json:"ram_percent"`
}
```

### Parsing `/proc/meminfo`
```go
func ReadRAM() (RAMInfo, error) {
    file, err := os.Open("/proc/meminfo")
    if err != nil {
        return RAMInfo{}, err
    }
    defer file.Close()

    var memTotal, memAvailable uint64
    scanner := bufio.NewScanner(file)

    for scanner.Scan() {
        line := scanner.Text()
        if strings.HasPrefix(line, "MemTotal:") {
            fmt.Sscanf(line, "MemTotal: %d kB", &memTotal)
        } else if strings.HasPrefix(line, "MemAvailable:") {
            fmt.Sscanf(line, "MemAvailable: %d kB", &memAvailable)
        }

        if memTotal > 0 && memAvailable > 0 {
            break
        }
    }

    if memTotal == 0 {
        return RAMInfo{}, fmt.Errorf("MemTotal okunamadı")
    }

    totalMB := memTotal / 1024
    availableMB := memAvailable / 1024
    usedMB := totalMB - availableMB
    percent := (float64(usedMB) / float64(totalMB)) * 100.0

    return RAMInfo{
        UsedMB:  usedMB,
        TotalMB: totalMB,
        Percent: percent,
    }, nil
}
```

---

## 3. Related Links

* Aggregator Manager: `[[SysMetrics-Service]]`
* IPC Schema: `[[IPC-Socket-Schema]]`
* Frontend Socket Client: `[[Daemon-IPC-Client]]`
