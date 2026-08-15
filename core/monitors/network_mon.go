package monitors

import (
	"context"
	"encoding/json"
	"log/slog"
	"ogsShell/core/ipc"
	"ogsShell/core/logger"
	"ogsShell/core/services"
	"strings"
	"time"

	"github.com/godbus/dbus/v5"
)

// NetworkMonitor listens to NetworkManager D-Bus signals for reactive Wi-Fi state broadcasts.
type NetworkMonitor struct {
	netSvc *services.NetworkService
	ipc    *ipc.Server
	log    *slog.Logger
}

// NewNetworkMonitor initializes a new NetworkMonitor instance.
func NewNetworkMonitor(ipcServer *ipc.Server) (*NetworkMonitor, error) {
	svc, err := services.NewNetworkService()
	if err != nil {
		return nil, err
	}

	return &NetworkMonitor{
		netSvc: svc,
		ipc:    ipcServer,
		log:    logger.Module("NET_MON"),
	}, nil
}

// broadcastWifiState scans available Wi-Fi access points and broadcasts the JSON event over IPC.
func (m *NetworkMonitor) broadcastWifiState() {
	aps, err := m.netSvc.ScanAccessPoints()
	if err != nil {
		m.log.Error("Wi-Fi güncel durumu alınamadı", "err", err)
		return
	}

	payloadBytes, err := json.Marshal(aps)
	if err != nil {
		m.log.Error("Wi-Fi payload marshaling hatası", "err", err)
		return
	}

	m.ipc.Broadcast(ipc.Event{
		Type:    "wifi_update",
		Payload: payloadBytes,
	})
}

// isRelevantSignal filters D-Bus signals relevant to Wi-Fi state and access points.
func (m *NetworkMonitor) isRelevantSignal(sig *dbus.Signal) bool {
	if sig == nil {
		return false
	}

	// Direct wireless device signals
	if sig.Name == "org.freedesktop.NetworkManager.Device.Wireless.AccessPointAdded" ||
		sig.Name == "org.freedesktop.NetworkManager.Device.Wireless.AccessPointRemoved" {
		return true
	}

	// PropertiesChanged on NetworkManager, Wireless Device, AccessPoints, or Settings
	if sig.Name == "org.freedesktop.DBus.Properties.PropertiesChanged" ||
		sig.Name == "org.freedesktop.DBus.PropertiesChanged" {
		path := string(sig.Path)
		if strings.HasPrefix(path, "/org/freedesktop/NetworkManager") {
			return true
		}
	}

	return false
}

// Start registers D-Bus signal matches and runs the event-driven signal listener with debouncing.
func (m *NetworkMonitor) Start(ctx context.Context) {
	conn := m.netSvc.Conn()
	if conn == nil {
		m.log.Error("D-Bus bağlantısı mevcut değil, Wi-Fi izleyici başlatılamadı")
		return
	}

	wifiPath := m.netSvc.WifiPath()

	// D-Bus match rules for NetworkManager wireless device and properties
	matchApAdded := []dbus.MatchOption{
		dbus.WithMatchSender("org.freedesktop.NetworkManager"),
		dbus.WithMatchInterface("org.freedesktop.NetworkManager.Device.Wireless"),
		dbus.WithMatchMember("AccessPointAdded"),
		dbus.WithMatchPathNamespace(wifiPath),
	}
	matchApRemoved := []dbus.MatchOption{
		dbus.WithMatchSender("org.freedesktop.NetworkManager"),
		dbus.WithMatchInterface("org.freedesktop.NetworkManager.Device.Wireless"),
		dbus.WithMatchMember("AccessPointRemoved"),
		dbus.WithMatchPathNamespace(wifiPath),
	}
	matchProps := []dbus.MatchOption{
		dbus.WithMatchSender("org.freedesktop.NetworkManager"),
		dbus.WithMatchInterface("org.freedesktop.DBus.Properties"),
		dbus.WithMatchMember("PropertiesChanged"),
	}

	_ = conn.AddMatchSignal(matchApAdded...)
	_ = conn.AddMatchSignal(matchApRemoved...)
	_ = conn.AddMatchSignal(matchProps...)

	sigCh := make(chan *dbus.Signal, 64)
	conn.Signal(sigCh)

	defer func() {
		conn.RemoveSignal(sigCh)
		_ = conn.RemoveMatchSignal(matchApAdded...)
		_ = conn.RemoveMatchSignal(matchApRemoved...)
		_ = conn.RemoveMatchSignal(matchProps...)
	}()

	m.log.Info("Wi-Fi sinyal odaklı izleyici başlatıldı (D-Bus Event-Driven)")

	// 1. Initial Push: Publish current Wi-Fi state immediately upon startup
	m.broadcastWifiState()

	// 2. Event Loop with 500ms Debouncing
	const debounceDuration = 500 * time.Millisecond
	var debounceTimer *time.Timer
	var debounceTimerCh <-chan time.Time

	for {
		select {
		case <-ctx.Done():
			if debounceTimer != nil {
				debounceTimer.Stop()
			}
			m.log.Info("Wi-Fi sinyal izleyici durduruldu")
			return

		case sig, ok := <-sigCh:
			if !ok {
				m.log.Warn("D-Bus sinyal kanalı kapandı")
				return
			}

			if m.isRelevantSignal(sig) {
				// Reset debounce timer to coalesce rapid signal bursts
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
			}

		case <-debounceTimerCh:
			debounceTimer = nil
			debounceTimerCh = nil
			m.broadcastWifiState()
		}
	}
}
