package monitors

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type CPUSnapshot struct {
	Idle  uint64
	Total uint64
}

type CPUMonitor struct {
	prevSnapshot CPUSnapshot
}

type CPUInfo struct {
	UsagePercent float64 `json:"cpu_percent"`
	CPUTemp      float64 `json:"cpu_temp"`
}

func NewCPUMonitor() *CPUMonitor {
	return &CPUMonitor{}
}

// readSnapshot: /proc/stat dosyasının ilk satırını parse eder
func readSnapshot() (CPUSnapshot, error) {
	file, err := os.Open("/proc/stat")
	if err != nil {
		return CPUSnapshot{}, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	if !scanner.Scan() {
		return CPUSnapshot{}, fmt.Errorf("/proc/stat boş veya okunamadı")
	}

	line := scanner.Text()
	fields := strings.Fields(line)
	if len(fields) < 5 || fields[0] != "cpu" {
		return CPUSnapshot{}, fmt.Errorf("geçersiz cpu satırı")
	}

	var user, nice, system, idle, iowait, irq, softirq, steal uint64
	fmt.Sscanf(line, "cpu %d %d %d %d %d %d %d %d", &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal)

	idleTicks := idle + iowait
	totalTicks := user + nice + system + idle + iowait + irq + softirq + steal

	return CPUSnapshot{
		Idle:  idleTicks,
		Total: totalTicks,
	}, nil
}

// CalculateUsage: Son snapshot ile anlık snapshot arasındaki fark üzerinden CPU % değerini verir
func (c *CPUMonitor) CalculateUsage() (float64, error) {
	curr, err := readSnapshot()
	if err != nil {
		return 0.0, err
	}

	if c.prevSnapshot.Total == 0 {
		c.prevSnapshot = curr
		return 0.0, nil
	}

	totalDelta := curr.Total - c.prevSnapshot.Total
	idleDelta := curr.Idle - c.prevSnapshot.Idle

	// sıfıra bölünme hatasını önleme
	if totalDelta == 0 {
		return 0.0, nil
	}

	// kullanım yüzdesi hesabı
	usage := (float64(totalDelta-idleDelta) / float64(totalDelta)) * 100.0

	c.prevSnapshot = curr

	return usage, nil
}

// GetInfo: CPU kullanım yüzdesini ve sıcaklığını tek bir pakette birleştirip döndürür
func (c *CPUMonitor) GetInfo() (CPUInfo, error) {
	usage, err := c.CalculateUsage()
	if err != nil {
		return CPUInfo{}, err
	}

	temp, err := ReadCPUTemp()
	if err != nil {
		temp = -1.0
	}

	return CPUInfo{
		UsagePercent: usage,
		CPUTemp:      temp,
	}, nil
}

// ReadCPUTemp: hwmon ve sysfs thermal zone'lar üzerinden doğru CPU çekirdek/paket sıcaklığını okur
func ReadCPUTemp() (float64, error) {
	// 1. hwmon kontrolü (coretemp / k10temp / cpu_thermal)
	hwmonMatches, _ := filepath.Glob("/sys/class/hwmon/hwmon*/name")
	for _, namePath := range hwmonMatches {
		data, err := os.ReadFile(namePath)
		if err != nil {
			continue
		}
		name := strings.TrimSpace(string(data))
		if name == "coretemp" || name == "k10temp" || name == "cpu_thermal" || name == "zenpower" {
			dir := filepath.Dir(namePath)
			tempInputs, _ := filepath.Glob(filepath.Join(dir, "temp*_input"))
			for _, tempPath := range tempInputs {
				t, err := readMilliTempFile(tempPath)
				if err == nil && t > 0 {
					return t, nil
				}
			}
		}
	}

	// 2. thermal_zone type kontrolü (x86_pkg_temp / TCPU / cpu)
	zoneTypes, _ := filepath.Glob("/sys/class/thermal/thermal_zone*/type")
	for _, typePath := range zoneTypes {
		data, err := os.ReadFile(typePath)
		if err != nil {
			continue
		}
		typeName := strings.ToLower(strings.TrimSpace(string(data)))
		if strings.Contains(typeName, "pkg_temp") || strings.Contains(typeName, "tcpu") || strings.Contains(typeName, "cpu") {
			dir := filepath.Dir(typePath)
			t, err := readMilliTempFile(filepath.Join(dir, "temp"))
			if err == nil && t > 0 {
				return t, nil
			}
		}
	}

	// 3. Fallback: thermal_zone0
	return readMilliTempFile("/sys/class/thermal/thermal_zone0/temp")
}

func readMilliTempFile(path string) (float64, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return -1.0, err
	}

	rawStr := strings.TrimSpace(string(data))
	rawMilli, err := strconv.ParseFloat(rawStr, 64)
	if err != nil {
		return -1.0, err
	}

	return rawMilli / 1000.0, nil
}
