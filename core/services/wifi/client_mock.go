package wifi

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// MockWifiClient is an in-memory, thread-safe implementation of WifiManager for testing and simulation.
type MockWifiClient struct {
	mu           sync.RWMutex
	enabled      bool
	accessPoints []AccessPoint
	profiles     map[string]WifiProfile
	secrets      map[string]WifiSecrets // Keyed by SSID and UUID
	activeSSID   string
}

// NewMockWifiClient creates a mock client pre-populated with realistic simulation data.
func NewMockWifiClient() *MockWifiClient {
	client := &MockWifiClient{
		enabled:  true,
		profiles: make(map[string]WifiProfile),
		secrets:  make(map[string]WifiSecrets),
		accessPoints: []AccessPoint{
			{SSID: "OgsHome_5G", BSSID: "00:11:22:33:44:55", Signal: 92, Frequency: 5180, Band: "5GHz", Security: SecurityWPA2PSK, IsSaved: true, IsActive: true, Channel: 36},
			{SSID: "OgsHome_2.4G", BSSID: "00:11:22:33:44:56", Signal: 85, Frequency: 2412, Band: "2.4GHz", Security: SecurityWPA2PSK, IsSaved: true, IsActive: false, Channel: 1},
			{SSID: "CoffeeShop_Free", BSSID: "AA:BB:CC:DD:EE:FF", Signal: 64, Frequency: 2437, Band: "2.4GHz", Security: SecurityOpen, IsSaved: false, IsActive: false, Channel: 6},
			{SSID: "SecureCorp_Guest", BSSID: "12:34:56:78:90:AB", Signal: 48, Frequency: 5240, Band: "5GHz", Security: SecurityWPA3SAE, IsSaved: false, IsActive: false, Channel: 48},
		},
		activeSSID: "OgsHome_5G",
	}

	// Pre-populate saved profiles & secrets
	p1 := WifiProfile{UUID: "uuid-ogshome-5g", Name: "OgsHome_5G", SSID: "OgsHome_5G", SecurityType: SecurityWPA2PSK, AutoConnect: true, LastUsed: uint64(time.Now().Unix()), HasPassword: true}
	p2 := WifiProfile{UUID: "uuid-ogshome-24g", Name: "OgsHome_2.4G", SSID: "OgsHome_2.4G", SecurityType: SecurityWPA2PSK, AutoConnect: false, LastUsed: uint64(time.Now().Unix() - 86400), HasPassword: true}
	client.profiles["OgsHome_5G"] = p1
	client.profiles["uuid-ogshome-5g"] = p1
	client.profiles["OgsHome_2.4G"] = p2
	client.profiles["uuid-ogshome-24g"] = p2

	s1 := WifiSecrets{SSID: "OgsHome_5G", UUID: "uuid-ogshome-5g", Password: "SuperSecretPassword123!", KeyMgmt: "wpa-psk"}
	s2 := WifiSecrets{SSID: "OgsHome_2.4G", UUID: "uuid-ogshome-24g", Password: "LegacyPassword456!", KeyMgmt: "wpa-psk"}
	client.secrets["OgsHome_5G"] = s1
	client.secrets["uuid-ogshome-5g"] = s1
	client.secrets["OgsHome_2.4G"] = s2
	client.secrets["uuid-ogshome-24g"] = s2

	return client
}

func (m *MockWifiClient) ScanNetworks(ctx context.Context) ([]AccessPoint, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if !m.enabled {
		return nil, fmt.Errorf("wi-fi is disabled")
	}
	result := make([]AccessPoint, len(m.accessPoints))
	copy(result, m.accessPoints)
	return result, nil
}

func (m *MockWifiClient) RequestScan(ctx context.Context) error {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if !m.enabled {
		return fmt.Errorf("wi-fi is disabled")
	}
	return nil
}

func (m *MockWifiClient) GetSavedProfiles(ctx context.Context) ([]WifiProfile, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	seen := make(map[string]bool)
	var list []WifiProfile
	for _, p := range m.profiles {
		if !seen[p.UUID] {
			seen[p.UUID] = true
			list = append(list, p)
		}
	}
	return list, nil
}

func (m *MockWifiClient) GetProfileSecrets(ctx context.Context, ssidOrUUID string) (*WifiSecrets, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	sec, ok := m.secrets[ssidOrUUID]
	if !ok {
		return nil, fmt.Errorf("secrets not found for profile: %s", ssidOrUUID)
	}
	return &sec, nil
}

func (m *MockWifiClient) SaveProfile(ctx context.Context, config WifiProfileConfig) (*WifiProfile, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	uuid := fmt.Sprintf("uuid-%s-%d", config.SSID, time.Now().Unix())
	profile := WifiProfile{
		UUID:         uuid,
		Name:         config.SSID,
		SSID:         config.SSID,
		SecurityType: config.Security,
		AutoConnect:  config.AutoConnect,
		LastUsed:     uint64(time.Now().Unix()),
		HasPassword:  config.Password != "",
	}
	m.profiles[config.SSID] = profile
	m.profiles[uuid] = profile

	if config.Password != "" {
		sec := WifiSecrets{
			SSID:     config.SSID,
			UUID:     uuid,
			Password: config.Password,
			KeyMgmt:  "wpa-psk",
		}
		m.secrets[config.SSID] = sec
		m.secrets[uuid] = sec
	}

	return &profile, nil
}

func (m *MockWifiClient) UpdateProfileSecrets(ctx context.Context, ssidOrUUID, password string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	profile, ok := m.profiles[ssidOrUUID]
	if !ok {
		return fmt.Errorf("profile not found: %s", ssidOrUUID)
	}

	sec := WifiSecrets{
		SSID:     profile.SSID,
		UUID:     profile.UUID,
		Password: password,
		KeyMgmt:  "wpa-psk",
	}
	m.secrets[profile.SSID] = sec
	m.secrets[profile.UUID] = sec

	profile.HasPassword = password != ""
	m.profiles[profile.SSID] = profile
	m.profiles[profile.UUID] = profile
	return nil
}

func (m *MockWifiClient) DeleteProfile(ctx context.Context, ssidOrUUID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	profile, ok := m.profiles[ssidOrUUID]
	if !ok {
		return fmt.Errorf("profile not found: %s", ssidOrUUID)
	}

	delete(m.profiles, profile.SSID)
	delete(m.profiles, profile.UUID)
	delete(m.secrets, profile.SSID)
	delete(m.secrets, profile.UUID)
	return nil
}

func (m *MockWifiClient) Connect(ctx context.Context, req ConnectRequest) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.enabled {
		return fmt.Errorf("wi-fi is disabled")
	}

	// Validate credentials if secured
	sec, hasSecrets := m.secrets[req.SSID]
	if hasSecrets && sec.Password != "" && req.Password != "" && req.Password != sec.Password {
		return fmt.Errorf("authentication failed: invalid password for %s", req.SSID)
	}

	m.activeSSID = req.SSID
	for i := range m.accessPoints {
		m.accessPoints[i].IsActive = (m.accessPoints[i].SSID == req.SSID)
	}
	return nil
}

func (m *MockWifiClient) Disconnect(ctx context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.activeSSID = ""
	for i := range m.accessPoints {
		m.accessPoints[i].IsActive = false
	}
	return nil
}

func (m *MockWifiClient) SetWifiEnabled(ctx context.Context, enabled bool) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.enabled = enabled
	if !enabled {
		m.activeSSID = ""
		for i := range m.accessPoints {
			m.accessPoints[i].IsActive = false
		}
	}
	return nil
}

func (m *MockWifiClient) IsWifiEnabled(ctx context.Context) (bool, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.enabled, nil
}

func (m *MockWifiClient) GetActiveConnection(ctx context.Context) (*ActiveWifiInfo, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if !m.enabled || m.activeSSID == "" {
		return nil, fmt.Errorf("not connected to any network")
	}

	return &ActiveWifiInfo{
		SSID:        m.activeSSID,
		BSSID:       "00:11:22:33:44:55",
		Device:      "wlan0",
		IPAddress:   "192.168.1.105",
		Gateway:     "192.168.1.1",
		DNS:         []string{"1.1.1.1", "8.8.8.8"},
		Signal:      92,
		Frequency:   5180,
		BitrateKbps: 866700,
		Security:    SecurityWPA2PSK,
	}, nil
}
