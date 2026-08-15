package services

import (
	"fmt"

	"github.com/godbus/dbus/v5"
)

type NetworkService struct {
	conn     *dbus.Conn
	wifiPath dbus.ObjectPath
}

func NewNetworkService() (*NetworkService, error) {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return nil, fmt.Errorf("system bus bağlantısı başarısız: %w", err)
	}

	svc := &NetworkService{conn: conn}
	path, err := svc.getWifiDevicePath()
	if err != nil {
		conn.Close()
		return nil, err
	}

	svc.wifiPath = path
	return svc, nil
}

func (s *NetworkService) getWifiDevicePath() (dbus.ObjectPath, error) {
	nmObj := s.conn.Object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")

	var devicePaths []dbus.ObjectPath
	err := nmObj.Call("org.freedesktop.NetworkManager.GetDevices", 0).Store(&devicePaths)
	if err != nil {
		return "", fmt.Errorf("cihazlar listelenemedi: %w", err)
	}

	for _, path := range devicePaths {
		devObj := s.conn.Object("org.freedesktop.NetworkManager", path)
		devTypeVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.DeviceType")
		if err == nil && devTypeVal.Value().(uint32) == 2 { // 2 = NM_DEVICE_TYPE_WIFI
			return path, nil
		}
	}

	return "", fmt.Errorf("herhangi bir Wi-Fi cihazı bulunamadı")
}

// Conn returns the underlying system D-Bus connection.
func (s *NetworkService) Conn() *dbus.Conn {
	return s.conn
}

// WifiPath returns the D-Bus object path of the primary wireless device.
func (s *NetworkService) WifiPath() dbus.ObjectPath {
	return s.wifiPath
}

// Close closes the D-Bus connection.
func (s *NetworkService) Close() error {
	if s.conn != nil {
		return s.conn.Close()
	}
	return nil
}

