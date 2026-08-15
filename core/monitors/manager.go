package monitors

import (
	"context"
	"encoding/json"
	"log/slog"
	"ogsShell/core/ipc"
	"ogsShell/core/logger"
	"ogsShell/core/services/bluetooth"
	"time"
)

type SystemMetricsPayload struct {
	CPU CPUInfo     `json:"cpu"`
	RAM RAMInfo     `json:"ram"`
	GPU GPUInfo     `json:"gpu"`
	NET NetworkInfo `json:"net"`
}

type Manager struct {
	server     *ipc.Server
	cpuMon     *CPUMonitor
	netMon     *NetMonitor
	wifiMon    *NetworkMonitor
	btMon      *BluetoothMonitor
	log        *slog.Logger
	cancelFunc context.CancelFunc
}

// constructor
func NewManager(server *ipc.Server, btMgr bluetooth.BluetoothManager) *Manager {
	wifiMon, err := NewNetworkMonitor(server)
	if err != nil {
		logger.Module("MONITOR").Warn("Wi-Fi izleyici başlatılamadı", "err", err)
	}

	var btMon *BluetoothMonitor
	if btMgr != nil {
		btMon = NewBluetoothMonitor(server, btMgr)
	}

	return &Manager{
		server:  server,
		cpuMon:  NewCPUMonitor(),
		netMon:  NewNetMonitor(),
		wifiMon: wifiMon,
		btMon:   btMon,
		log:     logger.Module("MONITOR"),
	}
}

// Start: Arka planda 1 saniyelk periyorlarla izleyici döngüsü başlatır.
func (m *Manager) Start(parentCtx context.Context) {
	ctx, cancel := context.WithCancel(parentCtx)
	m.cancelFunc = cancel

	if m.wifiMon != nil {
		go m.wifiMon.Start(ctx)
	}

	if m.btMon != nil {
		go m.btMon.Start(ctx)
	}

	go func() {
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		m.log.Info("Sistem izleyici başlatıldı (Periyot 1s)")

		for {
			select {
			case <-ctx.Done():
				m.log.Info("Sistem izleyici durduruldu")
				return
			case <-ticker.C:
				m.collectAndBroadcast()
			}
		}
	}()
}

// Stop: İzleyici goroutine'ini güvenli bir şekilde sonlandırır.
func (m *Manager) Stop() {
	if m.cancelFunc != nil {
		m.cancelFunc()
	}
}

func (m *Manager) collectAndBroadcast() {
	// CPU
	cpu, err := m.cpuMon.GetInfo()
	if err != nil {
		m.log.Warn("CPU verisi okunamadı", "err", err)
	}

	// RAM
	ram, err := ReadRAM()
	if err != nil {
		m.log.Warn("Ram verisi okunamadı", "err", err)
	}

	// GPU
	gpu, err := ReadGPU()
	if err != nil {
		m.log.Warn("GPU verisi okunamadı", "err", err)
	}

	// NET
	netInfo, err := m.netMon.GetInfo()
	if err != nil {
		m.log.Warn("Nework verisi okunamadı", "err ", err)
	}

	payload := SystemMetricsPayload{
		CPU: cpu,
		RAM: ram,
		GPU: gpu,
		NET: netInfo,
	}
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		m.log.Error("Metrics payload JSON formatına dönüştürülemedi", "err", err)
		return
	}

	m.server.Broadcast(ipc.Event{
		Type:    "sys_metrics",
		Payload: payloadBytes,
	})
}
