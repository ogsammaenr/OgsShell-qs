package services

import (
	"fmt"

	"github.com/godbus/dbus/v5"
)

// ScanAccessPoints, çevredeki AP'leri taranıp güvenli tip dönüşümleriyle döner.
func (s *NetworkService) ScanAccessPoints() ([]AccessPoint, error) {
	wifiObj := s.conn.Object("org.freedesktop.NetworkManager", s.wifiPath)

	savedMap, _ := s.GetSavedSSIDs()

	// Aktif AP yolunu güvenli oku
	var activeApPath dbus.ObjectPath
	if activeApVal, err := wifiObj.GetProperty("org.freedesktop.NetworkManager.Device.Wireless.ActiveAccessPoint"); err == nil {
		if path, ok := activeApVal.Value().(dbus.ObjectPath); ok {
			activeApPath = path
		}
	}

	var apPaths []dbus.ObjectPath
	err := wifiObj.Call("org.freedesktop.NetworkManager.Device.Wireless.GetAccessPoints", 0).Store(&apPaths)
	if err != nil {
		return nil, fmt.Errorf("AP listesi alınamadı: %w", err)
	}

	var list []AccessPoint
	for _, path := range apPaths {
		apObj := s.conn.Object("org.freedesktop.NetworkManager", path)

		ssidVar, errSsid := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Ssid")
		strengthVar, errStr := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Strength")

		if errSsid == nil && errStr == nil {
			ssidBytes, okSsid := ssidVar.Value().([]byte)
			strength, okStr := strengthVar.Value().(uint8)

			// Her iki tip de doğrulandıysa ekle
			if okSsid && okStr {
				ssid := string(ssidBytes)
				if ssid != "" {
					list = append(list, AccessPoint{
						SSID:     ssid,
						Signal:   strength,
						IsSaved:  savedMap[ssid],
						IsActive: path == activeApPath,
					})
				}
			}
		}
	}
	return list, nil
}

// RequestScan: Wi-Fi kartına donanım seviyesinde aktif frekans taraması yaptırır.
func (s *NetworkService) RequestScan() error {
	wifiObj := s.conn.Object("org.freedesktop.NetworkManager", s.wifiPath)

	// NM RequestScan metodu parametre olarak boş bir D-Bus dictionary (map) bekler.
	options := map[string]dbus.Variant{}

	err := wifiObj.Call("org.freedesktop.NetworkManager.Device.Wireless.RequestScan", 0, options).Err
	if err != nil {
		return fmt.Errorf("aktif tarama isteği gönderilemedi: %w", err)
	}
	return nil
}

// GetSavedSSIDs: NetworkManager'da kayıtlı olan tüm Wi-Fi profillerinin SSID'lerini döner
func (s *NetworkService) GetSavedSSIDs() (map[string]bool, error) {
	settingsObj := s.conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings")

	var connPaths []dbus.ObjectPath
	err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths)
	if err != nil {
		return nil, fmt.Errorf("kayıtlı bağlantılar listelenemedi: %w", err)
	}

	savedSSIDs := make(map[string]bool)
	for _, path := range connPaths {
		connObj := s.conn.Object("org.freedesktop.NetworkManager", path)

		// Baglantı ayarlarını (Settings Dict) al
		var settings map[string]map[string]dbus.Variant
		err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings)
		if err == nil {
			if wireless, ok := settings["802-11-wireless"]; ok {
				if ssidBytes, ok := wireless["ssid"].Value().([]byte); ok {
					savedSSIDs[string(ssidBytes)] = true
				}
			}
		}

	}

	return savedSSIDs, nil
}

// IsWifiEnabled, NetworkManager üzerindeki WirelessEnabled anahtarını sorgular.
func (s *NetworkService) IsWifiEnabled() (bool, error) {
	nmObj := s.conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")

	val, err := nmObj.GetProperty("org.freedesktop.NetworkManager.WirelessEnabled")
	if err != nil {
		return false, fmt.Errorf("wifi durumu okunamadi: %w", err)
	}

	enabled, ok := val.Value().(bool)
	if !ok {
		return false, fmt.Errorf("WirelessEnabled tipi bool degil")
	}

	return enabled, nil
}
