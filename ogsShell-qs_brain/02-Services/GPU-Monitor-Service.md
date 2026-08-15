---
title: "GPU Monitor Subsystem Service"
type: service
tags:
  - service/gpu
  - go/monitors
  - nvidia/nvml
  - sysfs/hwmon
created: 2026-08-09
updated: 2026-08-09
status: active
related_notes:
  - "[[SysMetrics-Service]]"
  - "[[IPC-Socket-Schema]]"
  - "[[Daemon-IPC-Client]]"
  - "[[Go-Coding-Style]]"
---

# GPU Monitor Subsystem Service

> [!NOTE]
> `ReadGPU()` (`core/monitors/gpu.go`) implements a dual-backend hardware collector supporting both NVIDIA GPUs (via native NVML C-bindings) and AMD/Intel GPUs (via Linux DRM sysfs and hwmon paths).

---

## 1. Dual-Driver Architecture

```mermaid
graph TD
    START["ReadGPU()"] --> CHECK{"Check /proc/driver/nvidia/version"}
    CHECK -->|Exists| NVML["readNvidiaNVML()<br/>NVML C-API (go-nvml)"]
    CHECK -->|Not Found| SYSFS["Linux DRM / sysfs Fallback"]
    
    SYSFS --> USAGE["readSysfsGPUUsage()<br/>/sys/class/drm/card0/device/gpu_busy_percent"]
    SYSFS --> TEMP["readSysfsGPUTemp()<br/>/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input"]
    
    NVML --> OUT["GPUInfo {GPUTemp, GPUPercent}"]
    USAGE --> OUT
    TEMP --> OUT
```

---

## 2. Implementation Details (`core/monitors/gpu.go`)

### Data Structure
```go
type GPUInfo struct {
    GPUTemp    float64 `json:"gpu_temp"`
    GPUPercent float64 `json:"gpu_percent"`
}
```

### NVIDIA NVML Binding
Uses `github.com/NVIDIA/go-nvml/pkg/nvml` to read hardware registers directly without running heavy CLI tools like `nvidia-smi`:
```go
func readNvidiaNVML() (GPUInfo, error) {
    ret := nvml.Init()
    if ret != nvml.SUCCESS {
        return GPUInfo{GPUTemp: -1.0, GPUPercent: -1.0}, fmt.Errorf("NVML başlatılamadı: %s", nvml.ErrorString(ret))
    }
    defer nvml.Shutdown()

    device, ret := nvml.DeviceGetHandleByIndex(0)
    if ret != nvml.SUCCESS {
        return GPUInfo{GPUTemp: -1.0, GPUPercent: -1.0}, fmt.Errorf("GPU 0 alınamadı: %s", nvml.ErrorString(ret))
    }

    gpuPercent := -1.0
    if utilization, ret := device.GetUtilizationRates(); ret == nvml.SUCCESS {
        gpuPercent = float64(utilization.Gpu)
    }

    gpuTemp := -1.0
    if temp, ret := device.GetTemperature(nvml.TEMPERATURE_GPU); ret == nvml.SUCCESS {
        gpuTemp = float64(temp)
    }

    return GPUInfo{GPUTemp: gpuTemp, GPUPercent: gpuPercent}, nil
}
```

### AMD / Intel DRM sysfs Fallback
* **Usage:** Read from `/sys/class/drm/card0/device/gpu_busy_percent`.
* **Temperature:** Glob-matches `/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input` and divides millidegrees by 1000.

---

## 3. Related Links

* Aggregator Manager: `[[SysMetrics-Service]]`
* IPC Schema: `[[IPC-Socket-Schema]]`
* Frontend Socket Client: `[[Daemon-IPC-Client]]`
