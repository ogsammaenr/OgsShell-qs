package services

import (
	"encoding/binary"
	"fmt"
	"net"

	"github.com/godbus/dbus/v5"
)

func buildWifiConnectionDict(ssid, password string) map[string]map[string]dbus.Variant {
	dict := map[string]map[string]dbus.Variant{
		"connection": {
			"id":   dbus.MakeVariant(ssid),
			"type": dbus.MakeVariant("802-11-wireless"), // 1. Connection tipi "802-11-wireless" olmalı
		},
		"802-11-wireless": {
			"ssid": dbus.MakeVariant([]byte(ssid)), // 2. SSID mutlaka []byte dilimi olmalı
			"mode": dbus.MakeVariant("infrastructure"),
		},
		"ipv4": {
			"method": dbus.MakeVariant("auto"),
		},
		"ipv6": {
			"method": dbus.MakeVariant("auto"),
		},
	}

	if password != "" {
		dict["802-11-wireless-security"] = map[string]dbus.Variant{
			"key-mgmt": dbus.MakeVariant("wpa-psk"),
			"psk":      dbus.MakeVariant(password),
		}
		dict["connection"]["security"] = dbus.MakeVariant("802-11-wireless-security")
	}

	return dict
}

// ConnectToNetwork, SSID ve Parola ile NetworkManager üzerinde bağlantı başlatır.
func (s *NetworkService) ConnectToNetwork(ssid, password string) error {
	nmObj := s.conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")

	connectionDict := buildWifiConnectionDict(ssid, password)

	// AddAndActivateConnection iki adet D-Bus ObjectPath döner:
	// 1. connectionPath: Oluşturulan profilin yolu
	// 2. activeConnPath: Aktif bağlantı durumunun yolu
	var connectionPath, activeConnPath dbus.ObjectPath

	err := nmObj.Call(
		"org.freedesktop.NetworkManager.AddAndActivateConnection", 0,
		connectionDict, s.wifiPath, dbus.ObjectPath("/"),
	).Store(&connectionPath, &activeConnPath) // İki değişkeni de geçiyoruz
	if err != nil {
		return fmt.Errorf("ağa bağlanma isteği başarısız (%s): %w", ssid, err)
	}

	return nil
}

// ipToUint32: "1.1.1.1" string IP adresini NetworkManager'in beklediği uint32 sayıya dönüştürür
func ipToUint32(ipStr string) (uint32, error) {
	ip := net.ParseIP(ipStr).To4()
	if ip == nil {
		return 0, fmt.Errorf("geçersiz IPv4 adresi: %s", ipStr)
	}
	return binary.NativeEndian.Uint32(ip), nil
}

func (s *NetworkService) SetCustomDNS(ssid string, dnsServers []string) error {
	settingsObj := s.conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings")

	var connPaths []dbus.ObjectPath
	if err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths); err != nil {
		return fmt.Errorf("bağlantılar listelenemedi: %w", err)
	}

	for _, path := range connPaths {
		connObj := s.conn.Object("org.freedesktop.NetworkManager", path)
		var settings map[string]map[string]dbus.Variant
		if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connnection.GetSettings", 0).Store(&settings); err == nil {
			if wireless, ok := settings["802-11-wireless"]; ok {
				if ssidBytes, _ := wireless["ssid"].Value().([]byte); string(ssidBytes) == ssid {
					// DNS string dizisini []uint32 formatına dönüştürüyoruz
					var dnsUint32 []uint32
					for _, ipStr := range dnsServers {
						u, err := ipToUint32(ipStr)
						if err != nil {
							return err
						}
						dnsUint32 = append(dnsUint32, u)
					}

					// ipv4 sözlüğünü güncelle veya sıfırdan oluştur
					ipv4Map, ok := settings["ipv4"]
					if !ok {
						ipv4Map = make(map[string]dbus.Variant)
					}
					ipv4Map["dns"] = dbus.MakeVariant(dnsUint32)
					ipv4Map["ignore-auto-dns"] = dbus.MakeVariant(true)
					ipv4Map["method"] = dbus.MakeVariant("auto")
					settings["ipv4"] = ipv4Map

					// Güncellenmiş ayarları NetworkManager'a kaydet (update)
					if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Update", 0, settings).Err; err != nil {
						return fmt.Errorf("DNS güncelleme başarısız: %w", err)
					}
					return nil

				}
			}
		}
	}

	return fmt.Errorf("kayıtlı profil bulunamadı: %s", ssid)
}

// Disconnect: aktif WIFI cihazının bağlantısını koparır
func (s *NetworkService) Disconnect() error {
	devObj := s.conn.Object("org.freedesktop.NetworkManager", s.wifiPath)
	err := devObj.Call("org.freedesktop.NetworkManager.Device.Disconnect", 0).Err
	if err != nil {
		return fmt.Errorf("bağlantı koparma hatası: %w", err)
	}
	return nil
}

// ForgetConnection: verilen SSID'ye ait kayılı profili NetworkManager'dan siler.
func (s *NetworkService) ForgetConnection(ssid string) error {
	settingsObj := s.conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings")

	var connPaths []dbus.ObjectPath
	if err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths); err != nil {
		return fmt.Errorf("bağlantılar listelenemedi: %w", err)
	}

	for _, path := range connPaths {
		connObj := s.conn.Object("org.freedesktop.NetworkManager", path)
		var settings map[string]map[string]dbus.Variant

		if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings); err == nil {
			if wireless, ok := settings["802-11-wireless"]; ok {
				if ssidBytes, _ := wireless["ssid"].Value().([]byte); string(ssidBytes) == ssid {
					// profil nesnesi üzerindeki delete metodunu çağırıyoruz
					if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Delete", 0).Err; err != nil {
						return fmt.Errorf("profil silinemedi (%s): %w", ssid, err)
					}
					return nil
				}
			}
		}
	}

	return fmt.Errorf("silinecek profil bulunamadı: %s", ssid)
}
