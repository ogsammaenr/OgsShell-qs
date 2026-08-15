package monitors

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// RAMInfo: RAM ile ilgili anlık ölçüm sonuçları
type RAMInfo struct {
	UsedMB  uint64  `json:"ram_used_mb"`
	TotalMB uint64  `json:"ram_total_mb"`
	Percent float64 `json:"ram_percent"`
}

// ReadRAM: /proc/meminfo dosyasını okuyarak RAM kullanımını döndürür.
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
