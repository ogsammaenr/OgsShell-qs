package monitors

import (
	"encoding/json"
	"ogsShell/core/services"
	"testing"

	"github.com/godbus/dbus/v5"
)

func TestNetworkMonitor_IsRelevantSignal(t *testing.T) {
	mon := &NetworkMonitor{}

	tests := []struct {
		name string
		sig  *dbus.Signal
		want bool
	}{
		{
			name: "AccessPointAdded Signal",
			sig: &dbus.Signal{
				Name: "org.freedesktop.NetworkManager.Device.Wireless.AccessPointAdded",
				Path: "/org/freedesktop/NetworkManager/Devices/3",
			},
			want: true,
		},
		{
			name: "AccessPointRemoved Signal",
			sig: &dbus.Signal{
				Name: "org.freedesktop.NetworkManager.Device.Wireless.AccessPointRemoved",
				Path: "/org/freedesktop/NetworkManager/Devices/3",
			},
			want: true,
		},
		{
			name: "PropertiesChanged on NetworkManager AccessPoint",
			sig: &dbus.Signal{
				Name: "org.freedesktop.DBus.Properties.PropertiesChanged",
				Path: "/org/freedesktop/NetworkManager/AccessPoint/42",
			},
			want: true,
		},
		{
			name: "PropertiesChanged on NetworkManager Device",
			sig: &dbus.Signal{
				Name: "org.freedesktop.DBus.Properties.PropertiesChanged",
				Path: "/org/freedesktop/NetworkManager/Devices/3",
			},
			want: true,
		},
		{
			name: "PropertiesChanged on unrelated D-Bus service",
			sig: &dbus.Signal{
				Name: "org.freedesktop.DBus.Properties.PropertiesChanged",
				Path: "/org/freedesktop/UPower/devices/battery_BAT0",
			},
			want: false,
		},
		{
			name: "Unrelated Signal",
			sig: &dbus.Signal{
				Name: "org.bluez.Device1.PropertyChanged",
				Path: "/org/bluez/hci0/dev_11_22_33_44_55_66",
			},
			want: false,
		},
		{
			name: "Nil Signal",
			sig:  nil,
			want: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := mon.isRelevantSignal(tt.sig)
			if got != tt.want {
				t.Errorf("isRelevantSignal() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestNetworkMonitor_JSONPayloadFormat(t *testing.T) {
	aps := []services.AccessPoint{
		{
			SSID:     "SuperOnline_WiFi_5G",
			BSSID:    "AA:BB:CC:DD:EE:FF",
			Signal:   85,
			Security: "WPA2-PSK",
			IsSaved:  true,
			IsActive: true,
		},
	}

	payloadBytes, err := json.Marshal(aps)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var parsed []map[string]interface{}
	if err := json.Unmarshal(payloadBytes, &parsed); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if len(parsed) != 1 {
		t.Fatalf("expected 1 AP in payload, got %d", len(parsed))
	}

	ap := parsed[0]
	if ap["ssid"] != "SuperOnline_WiFi_5G" {
		t.Errorf("expected ssid SuperOnline_WiFi_5G, got %v", ap["ssid"])
	}
	if ap["signal"] != float64(85) {
		t.Errorf("expected signal 85, got %v", ap["signal"])
	}
	if ap["is_saved"] != true {
		t.Errorf("expected is_saved true, got %v", ap["is_saved"])
	}
	if ap["is_active"] != true {
		t.Errorf("expected is_active true, got %v", ap["is_active"])
	}
}
