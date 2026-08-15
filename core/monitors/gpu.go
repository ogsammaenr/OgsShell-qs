package monitors

import (
		"fmt"
		"os"
		"path/filepath"
		"strconv"
		"strings"

		"github.com/NVIDIA/go-nvml/pkg/nvml"
)

type GPUInfo struct {
	GPUTemp			float64	`json:"gpu_temp"`
	GPUPercent	float64	`json:"gpu_percent"`
}

func ReadGPU() (GPUInfo, error) {
	if _, err := os.Stat("/proc/driver/nvidia/version"); err == nil {
		return readNvidiaNVML()
	}

	usage, _	:= readSysfsGPUUsage()
	temp, _ 	:= readSysfsGPUTemp()

	return GPUInfo{
		GPUPercent: 	usage,
		GPUTemp:			temp,
	}, nil
}

func readSysfsGPUUsage() (float64, error) {
	data, err := os.ReadFile("/sys/class/drm/card0/device/gpu_busy_percent")
	if err != nil {
		return -1.0, fmt.Errorf("GPU kullanım dosyası okunamadı: %w", err)
	}

	percent, err := strconv.ParseFloat(strings.TrimSpace(string(data)), 64)
	if err != nil {
		return -1.0, fmt.Errorf("geçersiz GPU kullanım verisi: %w", err)
	}

	return percent, nil 
}

// readSysfsGPUTemp: AMD/Intel GPU'lar için hwmon üzerindeki temp1_input dosyasını okur.
func readSysfsGPUTemp() (float64, error) {
	matches, err := filepath.Glob("/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input")
	if err != nil || len(matches) == 0 {
		return -1.0, fmt.Errorf("GPU hwmon sıcaklık sensörü bulunamadı")
	}

	data, err := os.ReadFile(matches[0])
	if err != nil {
		return -1.0, err
	}

	rawMilli, err := strconv.ParseFloat(strings.TrimSpace(string(data)), 64)
	if err != nil {
		return -1.0, err
	}
	
	return rawMilli / 1000.0, nil

}

// readNvidiaNVML: c-API (NVML) üzerinden doğrudan sü¶ücü belleğinden okuma yapar.
func readNvidiaNVML() (GPUInfo, error) {
	ret := nvml.Init()
	if ret != nvml.SUCCESS {
		return GPUInfo{
			GPUTemp:		-1.0,
			GPUPercent:	-1.0,
		}, fmt.Errorf("NVML başlatılamadı: %s", nvml.ErrorString(ret))
	}
	defer nvml.Shutdown()

	device, ret := nvml.DeviceGetHandleByIndex(0)
	if ret != nvml.SUCCESS {
		return GPUInfo{
			GPUTemp:		-1.0,
			GPUPercent:	-1.0,
		}, fmt.Errorf("GPU 0 alınamadı: %s", nvml.ErrorString(ret))
	}

	gpuPercent := -1.0
	if utilization, ret := device.GetUtilizationRates(); ret == nvml.SUCCESS {
		gpuPercent = float64(utilization.Gpu)
	}

	gpuTemp := -1.0
	if temp, ret := device.GetTemperature(nvml.TEMPERATURE_GPU); ret == nvml.SUCCESS {
		gpuTemp = float64(temp)
	}

	return GPUInfo{
		GPUTemp:		gpuTemp,
		GPUPercent:	gpuPercent,
	}, nil
}
