package bluetooth

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
)

// MockBluetoothClient is an in-memory implementation of BluetoothManager for tests and fallback.
type MockBluetoothClient struct {
	mu                 sync.RWMutex
	adapterPowered     bool
	adapterDiscovering bool
	devices            map[string]*BluetoothDevice

	listenersMu sync.Mutex
	listeners   []chan struct{}

	scanMu     sync.Mutex
	scanCancel context.CancelFunc

	done      chan struct{}
	closeOnce sync.Once
}

// NewMockBluetoothClient returns a initialized mock Bluetooth manager with sample peripherals.
func NewMockBluetoothClient() *MockBluetoothClient {
	m := &MockBluetoothClient{
		adapterPowered:     true,
		adapterDiscovering: false,
		devices:            make(map[string]*BluetoothDevice),
		listeners:          make([]chan struct{}, 0),
		done:               make(chan struct{}),
	}

	m.devices["38:18:4C:BE:11:92"] = &BluetoothDevice{
		MAC:       "38:18:4C:BE:11:92",
		Name:      "Sony WH-1000XM4",
		Icon:      "audio-headset",
		Connected: true,
		Paired:    true,
		RSSI:      -58,
	}

	m.devices["DC:2C:26:A1:84:10"] = &BluetoothDevice{
		MAC:       "DC:2C:26:A1:84:10",
		Name:      "Keychron K2 Pro",
		Icon:      "input-keyboard",
		Connected: true,
		Paired:    true,
		RSSI:      -62,
	}

	m.devices["F4:4E:FC:2B:99:34"] = &BluetoothDevice{
		MAC:       "F4:4E:FC:2B:99:34",
		Name:      "Logitech MX Master 3S",
		Icon:      "input-mouse",
		Connected: false,
		Paired:    true,
		RSSI:      -75,
	}

	return m
}

func (m *MockBluetoothClient) notifyListeners() {
	m.listenersMu.Lock()
	defer m.listenersMu.Unlock()

	for _, ch := range m.listeners {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

// GetState returns the current simulated adapter and device state.
func (m *MockBluetoothClient) GetState(ctx context.Context) (BluetoothState, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	deviceList := make([]BluetoothDevice, 0, len(m.devices))
	for _, dev := range m.devices {
		deviceList = append(deviceList, *dev)
	}

	sort.Slice(deviceList, func(i, j int) bool {
		if deviceList[i].Connected != deviceList[j].Connected {
			return deviceList[i].Connected
		}
		if deviceList[i].Paired != deviceList[j].Paired {
			return deviceList[i].Paired
		}
		return deviceList[i].Name < deviceList[j].Name
	})

	return BluetoothState{
		AdapterPowered: m.adapterPowered,
		Discovering:    m.adapterDiscovering,
		Devices:        deviceList,
	}, nil
}

// TogglePower toggles the mock adapter power.
func (m *MockBluetoothClient) TogglePower(ctx context.Context) error {
	m.mu.Lock()
	m.adapterPowered = !m.adapterPowered
	m.mu.Unlock()

	m.notifyListeners()
	return nil
}

// SetPowered sets the mock adapter power state.
func (m *MockBluetoothClient) SetPowered(ctx context.Context, powered bool) error {
	m.mu.Lock()
	m.adapterPowered = powered
	m.mu.Unlock()

	m.notifyListeners()
	return nil
}

// StartDiscovery starts discovery and simulates finding an additional nearby device.
func (m *MockBluetoothClient) StartDiscovery(ctx context.Context) error {
	m.mu.Lock()
	m.adapterDiscovering = true
	m.devices["A0:B1:C2:D3:E4:F5"] = &BluetoothDevice{
		MAC:       "A0:B1:C2:D3:E4:F5",
		Name:      "DualSense Wireless Controller",
		Icon:      "input-gaming",
		Connected: false,
		Paired:    false,
		RSSI:      -80,
	}
	m.mu.Unlock()

	m.notifyListeners()
	return nil
}

// StopDiscovery stops discovery.
func (m *MockBluetoothClient) StopDiscovery(ctx context.Context) error {
	m.mu.Lock()
	m.adapterDiscovering = false
	m.mu.Unlock()

	m.notifyListeners()
	return nil
}

// StartDiscoveryWithTimeout starts discovery with a timer.
func (m *MockBluetoothClient) StartDiscoveryWithTimeout(ctx context.Context, timeout time.Duration) error {
	m.scanMu.Lock()
	if m.scanCancel != nil {
		m.scanCancel()
	}

	scanCtx, cancel := context.WithCancel(context.Background())
	m.scanCancel = cancel
	m.scanMu.Unlock()

	if err := m.StartDiscovery(ctx); err != nil {
		return err
	}

	go func() {
		select {
		case <-time.After(timeout):
			_ = m.StopDiscovery(context.Background())
		case <-scanCtx.Done():
		case <-m.done:
		}
	}()

	return nil
}

// ConnectDevice marks the simulated device as connected.
func (m *MockBluetoothClient) ConnectDevice(ctx context.Context, mac string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for k, dev := range m.devices {
		if strings.EqualFold(k, mac) || strings.EqualFold(dev.MAC, mac) {
			dev.Connected = true
			m.notifyListeners()
			return nil
		}
	}

	return fmt.Errorf("device with MAC %s not found", mac)
}

// DisconnectDevice marks the simulated device as disconnected.
func (m *MockBluetoothClient) DisconnectDevice(ctx context.Context, mac string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for k, dev := range m.devices {
		if strings.EqualFold(k, mac) || strings.EqualFold(dev.MAC, mac) {
			dev.Connected = false
			m.notifyListeners()
			return nil
		}
	}

	return fmt.Errorf("device with MAC %s not found", mac)
}

// Subscribe returns a channel that is triggered on state changes.
func (m *MockBluetoothClient) Subscribe() <-chan struct{} {
	m.listenersMu.Lock()
	defer m.listenersMu.Unlock()

	ch := make(chan struct{}, 16)
	m.listeners = append(m.listeners, ch)
	return ch
}

// Close cleans up resources.
func (m *MockBluetoothClient) Close() error {
	m.closeOnce.Do(func() {
		m.scanMu.Lock()
		if m.scanCancel != nil {
			m.scanCancel()
		}
		m.scanMu.Unlock()
		close(m.done)
	})
	return nil
}
