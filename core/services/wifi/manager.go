package wifi

import "context"

// WifiManager defines the standard interface for managing wireless hardware, profiles, and credentials.
type WifiManager interface {
	// ScanNetworks performs a scan of all reachable Wi-Fi access points.
	ScanNetworks(ctx context.Context) ([]AccessPoint, error)

	// RequestScan triggers an active hardware frequency scan on the wireless adapter.
	RequestScan(ctx context.Context) error

	// GetSavedProfiles returns a list of all saved Wi-Fi connection profiles stored in NetworkManager.
	GetSavedProfiles(ctx context.Context) ([]WifiProfile, error)

	// GetProfileSecrets securely retrieves the stored credentials (passwords/PSK) for a given SSID or UUID.
	GetProfileSecrets(ctx context.Context, ssidOrUUID string) (*WifiSecrets, error)

	// SaveProfile creates or updates a Wi-Fi connection profile and its associated security parameters.
	SaveProfile(ctx context.Context, config WifiProfileConfig) (*WifiProfile, error)

	// UpdateProfileSecrets updates the stored password/PSK of an existing profile.
	UpdateProfileSecrets(ctx context.Context, ssidOrUUID, password string) error

	// DeleteProfile removes a saved connection profile from NetworkManager by SSID or UUID.
	DeleteProfile(ctx context.Context, ssidOrUUID string) error

	// Connect initiates a connection to a wireless network using the provided credentials or existing profile.
	Connect(ctx context.Context, req ConnectRequest) error

	// Disconnect disconnects the active wireless interface from its current network.
	Disconnect(ctx context.Context) error

	// SetWifiEnabled turns the Wi-Fi radio on or off.
	SetWifiEnabled(ctx context.Context, enabled bool) error

	// IsWifiEnabled checks if the Wi-Fi radio is currently active.
	IsWifiEnabled(ctx context.Context) (bool, error)

	// GetActiveConnection retrieves telemetry for the currently connected wireless network.
	GetActiveConnection(ctx context.Context) (*ActiveWifiInfo, error)
}
