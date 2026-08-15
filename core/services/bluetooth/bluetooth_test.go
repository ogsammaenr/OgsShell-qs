package bluetooth

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/godbus/dbus/v5"
)

func TestMockBluetoothClientLifecycle(t *testing.T) {
	ctx := context.Background()
	mock := NewMockBluetoothClient()
	defer mock.Close()

	// Initial State Check
	state, err := mock.GetState(ctx)
	if err != nil {
		t.Fatalf("GetState failed: %v", err)
	}

	if !state.AdapterPowered {
		t.Errorf("expected adapter to be powered initially")
	}

	if len(state.Devices) != 3 {
		t.Errorf("expected 3 initial mock devices, got %d", len(state.Devices))
	}

	// Test Power Toggle
	if err := mock.TogglePower(ctx); err != nil {
		t.Fatalf("TogglePower failed: %v", err)
	}

	state, _ = mock.GetState(ctx)
	if state.AdapterPowered {
		t.Errorf("expected adapter to be powered off after toggle")
	}

	// Test SetPowered
	if err := mock.SetPowered(ctx, true); err != nil {
		t.Fatalf("SetPowered failed: %v", err)
	}

	state, _ = mock.GetState(ctx)
	if !state.AdapterPowered {
		t.Errorf("expected adapter to be powered on")
	}

	// Test Connect / Disconnect
	targetMAC := "F4:4E:FC:2B:99:34"
	if err := mock.ConnectDevice(ctx, targetMAC); err != nil {
		t.Fatalf("ConnectDevice failed: %v", err)
	}

	state, _ = mock.GetState(ctx)
	found := false
	for _, dev := range state.Devices {
		if dev.MAC == targetMAC {
			found = true
			if !dev.Connected {
				t.Errorf("expected device %s to be connected", targetMAC)
			}
		}
	}
	if !found {
		t.Errorf("target device %s not found in state", targetMAC)
	}

	if err := mock.DisconnectDevice(ctx, targetMAC); err != nil {
		t.Fatalf("DisconnectDevice failed: %v", err)
	}

	state, _ = mock.GetState(ctx)
	for _, dev := range state.Devices {
		if dev.MAC == targetMAC && dev.Connected {
			t.Errorf("expected device %s to be disconnected", targetMAC)
		}
	}

	// Test Discovery
	if err := mock.StartDiscovery(ctx); err != nil {
		t.Fatalf("StartDiscovery failed: %v", err)
	}
	state, _ = mock.GetState(ctx)
	if !state.Discovering {
		t.Errorf("expected discovering to be true")
	}

	if err := mock.StopDiscovery(ctx); err != nil {
		t.Fatalf("StopDiscovery failed: %v", err)
	}
	state, _ = mock.GetState(ctx)
	if state.Discovering {
		t.Errorf("expected discovering to be false")
	}

	// Test Discovery With Timeout
	if err := mock.StartDiscoveryWithTimeout(ctx, 50*time.Millisecond); err != nil {
		t.Fatalf("StartDiscoveryWithTimeout failed: %v", err)
	}
	time.Sleep(100 * time.Millisecond)
	state, _ = mock.GetState(ctx)
	if state.Discovering {
		t.Errorf("expected discovering to be automatically stopped after timeout")
	}
}

func TestSubscriberNotification(t *testing.T) {
	ctx := context.Background()
	mock := NewMockBluetoothClient()
	defer mock.Close()

	ch := mock.Subscribe()

	if err := mock.TogglePower(ctx); err != nil {
		t.Fatalf("TogglePower failed: %v", err)
	}

	select {
	case <-ch:
		// Succeeded
	case <-time.After(1 * time.Second):
		t.Fatalf("timed out waiting for subscription notification")
	}
}

func TestDeduceIcon(t *testing.T) {
	tests := []struct {
		class uint32
		name  string
		want  string
	}{
		{class: 0x240404, name: "Sony WH-1000XM4", want: "audio-headset"},
		{class: 0x002540, name: "Keychron K2", want: "input-keyboard"},
		{class: 0x002580, name: "MX Master 3S", want: "input-mouse"},
		{class: 0x002500, name: "Wireless Gamepad", want: "input-gaming"},
		{class: 0x000200, name: "iPhone 15 Pro", want: "phone"},
		{class: 0x000100, name: "ThinkPad X1", want: "computer"},
		{class: 0, name: "Galaxy Buds Pro", want: "audio-headset"},
		{class: 0, name: "Generic Beacon", want: "bluetooth"},
	}

	for _, tt := range tests {
		got := deduceIcon(tt.class, tt.name)
		if got != tt.want {
			t.Errorf("deduceIcon(%#x, %q) = %q; want %q", tt.class, tt.name, got, tt.want)
		}
	}
}

func TestParseDevice(t *testing.T) {
	props := map[string]dbus.Variant{
		"Address":   dbus.MakeVariant("11:22:33:44:55:66"),
		"Name":      dbus.MakeVariant("Bose QC45"),
		"Icon":      dbus.MakeVariant("audio-headphones"),
		"Connected": dbus.MakeVariant(true),
		"Paired":    dbus.MakeVariant(true),
		"RSSI":      dbus.MakeVariant(int16(-65)),
	}

	dev := parseDevice(props)
	if dev.MAC != "11:22:33:44:55:66" {
		t.Errorf("expected MAC 11:22:33:44:55:66, got %s", dev.MAC)
	}
	if dev.Name != "Bose QC45" {
		t.Errorf("expected Name Bose QC45, got %s", dev.Name)
	}
	if dev.Icon != "audio-headphones" {
		t.Errorf("expected Icon audio-headphones, got %s", dev.Icon)
	}
	if !dev.Connected || !dev.Paired {
		t.Errorf("expected Connected and Paired to be true")
	}
	if dev.RSSI != -65 {
		t.Errorf("expected RSSI -65, got %d", dev.RSSI)
	}
}

func TestJSONPayloadFormat(t *testing.T) {
	state := BluetoothState{
		AdapterPowered: true,
		Discovering:    false,
		Devices: []BluetoothDevice{
			{
				MAC:       "XX:XX:XX:XX:XX:XX",
				Name:      "Sony WH-1000XM4",
				Icon:      "audio-headset",
				Connected: true,
				Paired:    true,
				RSSI:      -65,
			},
		},
	}

	data, err := json.Marshal(state)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if parsed["adapter_powered"] != true {
		t.Errorf("expected adapter_powered to be true")
	}
	if parsed["discovering"] != false {
		t.Errorf("expected discovering to be false")
	}
	devs, ok := parsed["devices"].([]interface{})
	if !ok || len(devs) != 1 {
		t.Fatalf("expected 1 device in json payload")
	}
	devMap := devs[0].(map[string]interface{})
	if devMap["mac"] != "XX:XX:XX:XX:XX:XX" {
		t.Errorf("expected mac XX:XX:XX:XX:XX:XX, got %v", devMap["mac"])
	}
	if devMap["name"] != "Sony WH-1000XM4" {
		t.Errorf("expected name Sony WH-1000XM4, got %v", devMap["name"])
	}
	if devMap["icon"] != "audio-headset" {
		t.Errorf("expected icon audio-headset, got %v", devMap["icon"])
	}
	if devMap["connected"] != true {
		t.Errorf("expected connected true, got %v", devMap["connected"])
	}
	if devMap["paired"] != true {
		t.Errorf("expected paired true, got %v", devMap["paired"])
	}
	if devMap["rssi"] != float64(-65) {
		t.Errorf("expected rssi -65, got %v", devMap["rssi"])
	}
}
