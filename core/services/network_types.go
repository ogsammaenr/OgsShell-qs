package services

// AccessPoint: Çevredeki veya bağlı olunan kablosuz ağı temsil eder.
type AccessPoint struct {
	SSID     string `json:"ssid"`
	BSSID    string `json:"bssid"`
	Signal   uint8  `json:"signal"`
	Security string `json:"security"`
	IsSaved  bool   `json:"is_saved"`
	IsActive bool   `json:"is_active"`
}

type WifiConnectionConfig struct {
	SSID        string   `json:"ssid"`
	Password    string   `json:"password,omitempty"`
	DNS         []string `json:"dns,omitempty"`
	AutoConnect bool     `json:"auto_connect"`
}
