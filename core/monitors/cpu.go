package monitors

import (
	"bufio"
	"fmt"
	"os"
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

// GetInfo: CPU kulanım yüzdesini ve sıcaklığını yek bir pakette birleştirip döndürür
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

// ReadCPUTemp: sysfs üzerinden CPU sıcaklığını derece cinsinden okur
func ReadCPUTemp() (float64, error) {
	data, err := os.ReadFile("/sys/class/thermal/thermal_zone0/temp")
	if err != nil {
		return 0.0, fmt.Errorf("sıcaklık dosyası okunamadı: %w", err)
	}

	rawStr := strings.TrimSpace(string(data))
	rawMilli, err := strconv.ParseFloat(rawStr, 64)
	if err != nil {
		return 0.0, fmt.Errorf("geçersiz sıcaklık verisi: %w", err)
	}

	return rawMilli / 1000.0, nil
}
