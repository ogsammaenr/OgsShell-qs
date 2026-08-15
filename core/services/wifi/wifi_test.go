package wifi_test

import (
	"context"
	"ogsShell/core/services/wifi"
	"testing"
)

// TestBuilder_BuildConnectionDict tests NetworkManager settings dictionary generation.
func TestBuilder_BuildConnectionDict(t *testing.T) {
	// 1. WPA2-PSK with Custom DNS
	cfg1 := wifi.WifiProfileConfig{
		SSID:        "TestHome_WiFi",
		Password:    "SecurePass999!",
		Security:    wifi.SecurityWPA2PSK,
		AutoConnect: true,
		DNS:         []string{"1.1.1.1", "8.8.8.8"},
	}

	dict1 := wifi.BuildConnectionDict(cfg1)

	if connMeta, ok := dict1["connection"]; !ok {
		t.Fatal("expected 'connection' section in dict")
	} else if id, ok := connMeta["id"].Value().(string); !ok || id != "TestHome_WiFi" {
		t.Errorf("expected connection.id 'TestHome_WiFi', got %v", id)
	}

	if secMeta, ok := dict1["802-11-wireless-security"]; !ok {
		t.Fatal("expected '802-11-wireless-security' in dict")
	} else {
		if psk, ok := secMeta["psk"].Value().(string); !ok || psk != "SecurePass999!" {
			t.Errorf("expected psk 'SecurePass999!', got %v", psk)
		}
		if keyMgmt, ok := secMeta["key-mgmt"].Value().(string); !ok || keyMgmt != "wpa-psk" {
			t.Errorf("expected key-mgmt 'wpa-psk', got %v", keyMgmt)
		}
	}

	if ipv4Meta, ok := dict1["ipv4"]; !ok {
		t.Fatal("expected 'ipv4' in dict")
	} else {
		if dnsList, ok := ipv4Meta["dns"].Value().([]uint32); !ok || len(dnsList) != 2 {
			t.Errorf("expected 2 DNS entries, got %v", dnsList)
		}
	}

	// 2. WPA3-SAE
	cfg2 := wifi.WifiProfileConfig{
		SSID:     "NextGen_6G",
		Password: "Wpa3Password!",
		Security: wifi.SecurityWPA3SAE,
	}
	dict2 := wifi.BuildConnectionDict(cfg2)
	if secMeta, ok := dict2["802-11-wireless-security"]; !ok {
		t.Fatal("expected '802-11-wireless-security' for WPA3")
	} else if keyMgmt, ok := secMeta["key-mgmt"].Value().(string); !ok || keyMgmt != "sae" {
		t.Errorf("expected key-mgmt 'sae', got %v", keyMgmt)
	}
}

// TestBuilder_IPConversions tests IP parsing to uint32 and back.
func TestBuilder_IPConversions(t *testing.T) {
	testIPs := []string{"1.1.1.1", "192.168.1.1", "10.0.0.254", "8.8.8.8"}

	for _, ip := range testIPs {
		u, err := wifi.IPToUint32(ip)
		if err != nil {
			t.Fatalf("failed to convert IP %s: %v", ip, err)
		}
		reconstructed := wifi.Uint32ToIP(u)
		if reconstructed != ip {
			t.Errorf("roundtrip failed: expected %s, got %s", ip, reconstructed)
		}
	}

	// Invalid IP
	if _, err := wifi.IPToUint32("invalid.ip.address"); err == nil {
		t.Error("expected error for invalid IP, got nil")
	}
}

// TestBuilder_FrequencyHelpers tests frequency to channel and band categorization.
func TestBuilder_FrequencyHelpers(t *testing.T) {
	// 2.4 GHz
	if band := wifi.FrequencyToBand(2412); band != "2.4GHz" {
		t.Errorf("expected '2.4GHz', got %s", band)
	}
	if ch := wifi.FrequencyToChannel(2412); ch != 1 {
		t.Errorf("expected channel 1 for 2412MHz, got %d", ch)
	}
	if ch := wifi.FrequencyToChannel(2437); ch != 6 {
		t.Errorf("expected channel 6 for 2437MHz, got %d", ch)
	}

	// 5 GHz
	if band := wifi.FrequencyToBand(5180); band != "5GHz" {
		t.Errorf("expected '5GHz', got %s", band)
	}
	if ch := wifi.FrequencyToChannel(5180); ch != 36 {
		t.Errorf("expected channel 36 for 5180MHz, got %d", ch)
	}

	// 6 GHz
	if band := wifi.FrequencyToBand(6115); band != "6GHz" {
		t.Errorf("expected '6GHz', got %s", band)
	}
}

// TestMockClient_FullLifecycle tests all MockWifiClient operations.
func TestMockClient_FullLifecycle(t *testing.T) {
	ctx := context.Background()
	client := wifi.NewMockWifiClient()

	// 1. Check Wi-Fi state
	enabled, err := client.IsWifiEnabled(ctx)
	if err != nil || !enabled {
		t.Fatalf("expected Wi-Fi to be enabled, got %v (err: %v)", enabled, err)
	}

	// 2. Scan networks
	aps, err := client.ScanNetworks(ctx)
	if err != nil || len(aps) == 0 {
		t.Fatalf("expected discovered APs, got %v (err: %v)", aps, err)
	}
	t.Logf("Discovered %d access points in mock environment", len(aps))

	// 3. Get saved profiles
	profiles, err := client.GetSavedProfiles(ctx)
	if err != nil || len(profiles) == 0 {
		t.Fatalf("expected saved profiles, got %v (err: %v)", profiles, err)
	}

	// 4. Retrieve saved password/secrets
	sec, err := client.GetProfileSecrets(ctx, "OgsHome_5G")
	if err != nil {
		t.Fatalf("expected secrets for 'OgsHome_5G', got error: %v", err)
	}
	if sec.Password != "SuperSecretPassword123!" {
		t.Errorf("expected 'SuperSecretPassword123!', got '%s'", sec.Password)
	}

	// 5. Create new profile & secrets
	newProfileCfg := wifi.WifiProfileConfig{
		SSID:        "Office_Network_Guest",
		Password:    "CompanySecret2026!",
		Security:    wifi.SecurityWPA2PSK,
		AutoConnect: true,
	}
	createdProfile, err := client.SaveProfile(ctx, newProfileCfg)
	if err != nil {
		t.Fatalf("failed to save profile: %v", err)
	}
	if createdProfile.SSID != "Office_Network_Guest" {
		t.Errorf("expected SSID 'Office_Network_Guest', got %s", createdProfile.SSID)
	}

	// Verify newly saved secrets
	newSec, err := client.GetProfileSecrets(ctx, "Office_Network_Guest")
	if err != nil || newSec.Password != "CompanySecret2026!" {
		t.Fatalf("expected new secret 'CompanySecret2026!', got %v (err: %v)", newSec, err)
	}

	// 6. Update secrets
	err = client.UpdateProfileSecrets(ctx, "Office_Network_Guest", "UpdatedSecret2027!")
	if err != nil {
		t.Fatalf("failed to update secrets: %v", err)
	}
	updatedSec, _ := client.GetProfileSecrets(ctx, "Office_Network_Guest")
	if updatedSec.Password != "UpdatedSecret2027!" {
		t.Errorf("expected updated password, got %s", updatedSec.Password)
	}

	// 7. Connect to network
	err = client.Connect(ctx, wifi.ConnectRequest{
		SSID:     "Office_Network_Guest",
		Password: "UpdatedSecret2027!",
	})
	if err != nil {
		t.Fatalf("failed to connect: %v", err)
	}

	// 8. Verify active connection info
	activeInfo, err := client.GetActiveConnection(ctx)
	if err != nil || activeInfo.SSID != "Office_Network_Guest" {
		t.Fatalf("expected active connection to 'Office_Network_Guest', got %v (err: %v)", activeInfo, err)
	}

	// 9. Disconnect
	if err := client.Disconnect(ctx); err != nil {
		t.Fatalf("failed to disconnect: %v", err)
	}

	// 10. Delete profile
	if err := client.DeleteProfile(ctx, "Office_Network_Guest"); err != nil {
		t.Fatalf("failed to delete profile: %v", err)
	}
	if _, err := client.GetProfileSecrets(ctx, "Office_Network_Guest"); err == nil {
		t.Error("expected error after profile deletion, got nil")
	}

	// 11. Radio toggle
	_ = client.SetWifiEnabled(ctx, false)
	en, _ := client.IsWifiEnabled(ctx)
	if en {
		t.Error("expected Wi-Fi to be disabled")
	}
	if _, err := client.ScanNetworks(ctx); err == nil {
		t.Error("expected scan error when Wi-Fi disabled")
	}
}

// TestDBusClient_LiveHardwareIntegration attempts live D-Bus communication if available.
func TestDBusClient_LiveHardwareIntegration(t *testing.T) {
	client, err := wifi.NewDefaultDBusWifiClient()
	if err != nil {
		t.Skipf("Skipping live D-Bus integration test (hardware or D-Bus unavailable): %v", err)
		return
	}
	defer client.Close()

	ctx := context.Background()

	enabled, err := client.IsWifiEnabled(ctx)
	if err != nil {
		t.Fatalf("failed to query Wi-Fi state over D-Bus: %v", err)
	}
	t.Logf("Live NetworkManager WirelessEnabled: %v", enabled)

	savedProfiles, err := client.GetSavedProfiles(ctx)
	if err != nil {
		t.Fatalf("failed to list saved profiles over D-Bus: %v", err)
	}
	t.Logf("Found %d saved profiles on host system", len(savedProfiles))

	for _, p := range savedProfiles {
		t.Logf("Profile: %-25s | UUID: %s | AutoConnect: %v", p.SSID, p.UUID, p.AutoConnect)
	}
}
