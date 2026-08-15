package wifi

// SecurityType represents the Wi-Fi authentication standard
type SecurityType string

const (
	SecurityOpen    SecurityType = "OPEN"
	SecurityWPAPSK  SecurityType = "WPA-PSK"
	SecurityWPA2PSK SecurityType = "WPA2-PSK"
	SecurityWPA3SAE SecurityType = "WPA3-SAE"
	SecurityWPAEAP  SecurityType = "WPA-EAP"
	SecurityWEP     SecurityType = "WEP"
	SecurityUnknown SecurityType = "UNKNOWN"
)

// AccessPoint represents a discovered wireless access point
type AccessPoint struct {
	SSID      string       `json:"ssid"`
	BSSID     string       `json:"bssid"`
	Signal    uint8        `json:"signal"`
	Frequency uint32       `json:"frequency"` // MHz (e.g. 2412, 5180)
	Band      string       `json:"band"`      // "2.4GHz", "5GHz", "6GHz"
	Security  SecurityType `json:"security"`
	IsSaved   bool         `json:"is_saved"`
	IsActive  bool         `json:"is_active"`
	Channel   int          `json:"channel"`
}

// WifiProfile represents a saved NetworkManager connection configuration
type WifiProfile struct {
	UUID         string       `json:"uuid"`
	Name         string       `json:"name"`
	SSID         string       `json:"ssid"`
	SecurityType SecurityType `json:"security_type"`
	AutoConnect  bool         `json:"auto_connect"`
	LastUsed     uint64       `json:"last_used"`
	HasPassword  bool         `json:"has_password"`
}

// WifiSecrets represents sensitive credentials associated with a Wi-Fi profile
type WifiSecrets struct {
	SSID     string `json:"ssid"`
	UUID     string `json:"uuid"`
	Password string `json:"password"`
	KeyMgmt  string `json:"key_mgmt"`
}

// WifiProfileConfig holds parameters for creating or updating a Wi-Fi connection
type WifiProfileConfig struct {
	SSID        string       `json:"ssid"`
	Password    string       `json:"password,omitempty"`
	Security    SecurityType `json:"security,omitempty"`
	AutoConnect bool         `json:"auto_connect"`
	Hidden      bool         `json:"hidden,omitempty"`
	DNS         []string     `json:"dns,omitempty"`
	Gateway     string       `json:"gateway,omitempty"`
	StaticIP    string       `json:"static_ip,omitempty"`
}

// ConnectRequest encapsulates the data required to initiate a network connection
type ConnectRequest struct {
	SSID     string `json:"ssid"`
	Password string `json:"password,omitempty"`
	BSSID    string `json:"bssid,omitempty"`
	Hidden   bool   `json:"hidden,omitempty"`
}

// ActiveWifiInfo holds real-time telemetry for the currently connected wireless network
type ActiveWifiInfo struct {
	SSID        string       `json:"ssid"`
	BSSID       string       `json:"bssid"`
	Device      string       `json:"device"`
	IPAddress   string       `json:"ip_address"`
	Gateway     string       `json:"gateway"`
	DNS         []string     `json:"dns"`
	Signal      uint8        `json:"signal"`
	Frequency   uint32       `json:"frequency"`
	BitrateKbps uint32       `json:"bitrate_kbps"`
	Security    SecurityType `json:"security"`
}
