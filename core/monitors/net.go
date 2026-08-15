package monitors

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type NetworkInfo struct {
	RxBytesPerSec float64 `json:"rx_bytes_sec"`
	TxBytesPerSec float64 `json:"tx_bytes_sec"`
	Interface     string  `json:"interface"`
	IsConnected   bool    `json:"is_connected"`
}

type netSnapshot struct {
	rxBytes   uint64
	txBytes   uint64
	timestamp time.Time
}

type NetMonitor struct {
	prevSnapshot netSnapshot
}

func NewNetMonitor() *NetMonitor {
	return &NetMonitor{}
}

// readNetSnapshot: /proc/net/dev dosyasını tarayarak lo dışındaki ilk aktif arayüzün verilerini okur
func readNetSnapshot() (string, uint64, uint64, error) {
	targetIface, err := getDefaultInterface()
	if err != nil {
		return "", 0, 0, err
	}

	file, err := os.Open("/proc/net/dev")
	if err != nil {
		return "", 0, 0, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.Contains(line, ":") {
			continue
		}

		parts := strings.Split(line, ":")
		if len(parts) < 2 {
			continue
		}

		iface := strings.TrimSpace(parts[0])
		if iface != targetIface {
			continue
		}

		fields := strings.Fields(parts[1])
		if len(fields) < 9 {
			continue
		}

		rxBytes, errRx := strconv.ParseUint(fields[0], 10, 64)
		txBytes, errTx := strconv.ParseUint(fields[8], 10, 64)
		if errRx != nil || errTx != nil {
			continue
		}

		return iface, rxBytes, txBytes, nil
	}

	return "", 0, 0, fmt.Errorf("aktif ağ arayüzü bulunamadı")
}

// getDefaultInterface: Linux kernel yönlendirme tablosundan (route table)
// varsayılan internet çıkışına (00000000) sahip arayüzü bulur
func getDefaultInterface() (string, error) {
	file, err := os.Open("/proc/net/route")
	if err != nil {
		return "", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) >= 2 && fields[1] == "00000000" {
			return fields[0], nil
		}
	}

	return "", fmt.Errorf("aktif default gateway bulunamadı")
}

func (n *NetMonitor) GetInfo() (NetworkInfo, error) {
	iface, rx, tx, err := readNetSnapshot()
	if err != nil {
		return NetworkInfo{
			RxBytesPerSec: 0.0,
			TxBytesPerSec: 0.0,
			IsConnected:   false,
			Interface:     "none",
		}, nil
	}

	now := time.Now()

	if n.prevSnapshot.timestamp.IsZero() {
		n.prevSnapshot = netSnapshot{
			rxBytes:   rx,
			txBytes:   tx,
			timestamp: now,
		}
		return NetworkInfo{
			RxBytesPerSec: 0.0,
			TxBytesPerSec: 0.0,
			Interface:     iface,
			IsConnected:   true,
		}, nil
	}

	deltaTime := now.Sub(n.prevSnapshot.timestamp).Seconds()
	if deltaTime <= 0 {
		deltaTime = 1.0
	}

	var rxSpeed, txSpeed float64
	if rx >= n.prevSnapshot.rxBytes {
		rxSpeed = float64(rx-n.prevSnapshot.rxBytes) / deltaTime
	}
	if tx >= n.prevSnapshot.txBytes {
		txSpeed = float64(tx-n.prevSnapshot.txBytes) / deltaTime
	}

	n.prevSnapshot = netSnapshot{
		rxBytes:   rx,
		txBytes:   tx,
		timestamp: now,
	}

	return NetworkInfo{
		RxBytesPerSec: rxSpeed,
		TxBytesPerSec: txSpeed,
		Interface:     iface,
		IsConnected:   true,
	}, nil
}
