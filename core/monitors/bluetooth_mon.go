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

// BluetoothMonitor manages the background synchronization and broadcasting of Bluetooth state.
type BluetoothMonitor struct {
	btMgr bluetooth.BluetoothManager
	ipc   *ipc.Server
	log   *slog.Logger
}

// NewBluetoothMonitor creates a new BluetoothMonitor instance.
func NewBluetoothMonitor(ipcServer *ipc.Server, btMgr bluetooth.BluetoothManager) *BluetoothMonitor {
	return &BluetoothMonitor{
		btMgr: btMgr,
		ipc:   ipcServer,
		log:   logger.Module("BT_MON"),
	}
}

// broadcastBluetoothState queries the BluetoothManager and broadcasts the state as a JSON event over IPC.
func (m *BluetoothMonitor) broadcastBluetoothState(ctx context.Context) {
	state, err := m.btMgr.GetState(ctx)
	if err != nil {
		m.log.Error("Bluetooth güncel durumu alınamadı", "err", err)
		return
	}

	payloadBytes, err := json.Marshal(state)
	if err != nil {
		m.log.Error("Bluetooth payload marshaling hatası", "err", err)
		return
	}

	m.ipc.Broadcast(ipc.Event{
		Type:    "bluetooth_update",
		Payload: payloadBytes,
	})
}

// Start runs the Bluetooth state listener with 500ms debouncing (fully event-driven).
func (m *BluetoothMonitor) Start(ctx context.Context) {
	m.log.Info("Bluetooth sinyal odaklı izleyici başlatıldı (D-Bus Event-Driven)")
	// 1. Initial Push: Send initial state immediately so QML frontend doesn't wait
	m.broadcastBluetoothState(ctx)

	subCh := m.btMgr.Subscribe()

	// 2. Event loop with 500ms debouncing to coalesce rapid RSSI and property fluctuations
	const debounceDuration = 500 * time.Millisecond
	var debounceTimer *time.Timer
	var debounceTimerCh <-chan time.Time

	for {
		select {
		case <-ctx.Done():
			if debounceTimer != nil {
				debounceTimer.Stop()
			}
			m.log.Info("Bluetooth sinyal izleyici durduruldu")
			return

		case _, ok := <-subCh:
			if !ok {
				m.log.Warn("Bluetooth bildirim kanalı kapandı")
				return
			}

			// Reset debounce timer on incoming state change notification
			if debounceTimer != nil {
				if !debounceTimer.Stop() {
					select {
					case <-debounceTimer.C:
					default:
					}
				}
			}
			debounceTimer = time.NewTimer(debounceDuration)
			debounceTimerCh = debounceTimer.C

		case <-debounceTimerCh:
			debounceTimer = nil
			debounceTimerCh = nil
			m.broadcastBluetoothState(ctx)
		}
	}
}
