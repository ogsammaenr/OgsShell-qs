package wifi

import (
	"context"
	"fmt"
	"strings"

	"github.com/godbus/dbus/v5"
)

const (
	nmBusName        = "org.freedesktop.NetworkManager"
	nmPath           = "/org/freedesktop/NetworkManager"
	nmSettingsPath   = "/org/freedesktop/NetworkManager/Settings"
	nmDeviceTypeWifi = 2 // NM_DEVICE_TYPE_WIFI
)

// DBusWifiClient is the production NetworkManager implementation of WifiManager.
type DBusWifiClient struct {
	conn     *dbus.Conn
	wifiPath dbus.ObjectPath
	iface    string
	agent    *SecretAgent
}

// NewDefaultDBusWifiClient connects to the system D-Bus and detects the primary Wi-Fi device.
func NewDefaultDBusWifiClient() (*DBusWifiClient, error) {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return nil, fmt.Errorf("system bus connection failed: %w", err)
	}
	return NewDBusWifiClient(conn)
}

// NewDBusWifiClient initializes the client with a given D-Bus connection and registers an in-process SecretAgent.
func NewDBusWifiClient(conn *dbus.Conn) (*DBusWifiClient, error) {
	client := &DBusWifiClient{conn: conn}
	path, iface, err := client.findWifiDevice()
	if err != nil {
		return nil, err
	}
	client.wifiPath = path
	client.iface = iface

	// Register in-process SecretAgent to suppress and satisfy desktop secret prompts (kded / kwallet)
	agent, err := NewSecretAgent(conn)
	if err == nil {
		client.agent = agent
	}

	return client, nil
}

// Close closes the underlying D-Bus connection and unregisters the SecretAgent.
func (c *DBusWifiClient) Close() error {
	if c.agent != nil {
		c.agent.Unregister()
	}
	if c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

func (c *DBusWifiClient) findWifiDevice() (dbus.ObjectPath, string, error) {
	nmObj := c.conn.Object(nmBusName, nmPath)

	var devicePaths []dbus.ObjectPath
	err := nmObj.Call("org.freedesktop.NetworkManager.GetDevices", 0).Store(&devicePaths)
	if err != nil {
		return "", "", fmt.Errorf("failed to list network devices: %w", err)
	}

	for _, path := range devicePaths {
		devObj := c.conn.Object(nmBusName, path)
		devTypeVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.DeviceType")
		if err == nil && devTypeVal.Value().(uint32) == nmDeviceTypeWifi {
			ifaceVal, errIface := devObj.GetProperty("org.freedesktop.NetworkManager.Device.Interface")
			ifaceName := "wlan0"
			if errIface == nil {
				if str, ok := ifaceVal.Value().(string); ok {
					ifaceName = str
				}
			}
			return path, ifaceName, nil
		}
	}

	return "", "", fmt.Errorf("no active Wi-Fi device found on system")
}

// findAccessPointPath resolves the D-Bus AccessPoint object path and exact beacon SSID for a target SSID.
func (c *DBusWifiClient) findAccessPointPath(targetSSID string) (dbus.ObjectPath, string) {
	wifiObj := c.conn.Object(nmBusName, c.wifiPath)
	var apPaths []dbus.ObjectPath
	if err := wifiObj.Call("org.freedesktop.NetworkManager.Device.Wireless.GetAccessPoints", 0).Store(&apPaths); err != nil {
		return dbus.ObjectPath("/"), targetSSID
	}

	var caseInsensitiveMatch dbus.ObjectPath
	var caseInsensitiveSSID string

	for _, path := range apPaths {
		apObj := c.conn.Object(nmBusName, path)
		if ssidVar, err := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Ssid"); err == nil {
			if ssidBytes, ok := ssidVar.Value().([]byte); ok {
				ssid := string(ssidBytes)
				if ssid == targetSSID {
					return path, ssid // Exact match
				}
				if strings.EqualFold(ssid, targetSSID) && caseInsensitiveMatch == "" {
					caseInsensitiveMatch = path
					caseInsensitiveSSID = ssid
				}
			}
		}
	}

	if caseInsensitiveMatch != "" {
		return caseInsensitiveMatch, caseInsensitiveSSID
	}
	return dbus.ObjectPath("/"), targetSSID
}

// ScanNetworks scans for all nearby access points.
func (c *DBusWifiClient) ScanNetworks(ctx context.Context) ([]AccessPoint, error) {
	wifiObj := c.conn.Object(nmBusName, c.wifiPath)

	savedProfiles, _ := c.GetSavedProfiles(ctx)
	savedMap := make(map[string]bool)
	for _, p := range savedProfiles {
		savedMap[p.SSID] = true
	}

	var activeApPath dbus.ObjectPath
	if val, err := wifiObj.GetProperty("org.freedesktop.NetworkManager.Device.Wireless.ActiveAccessPoint"); err == nil {
		if path, ok := val.Value().(dbus.ObjectPath); ok {
			activeApPath = path
		}
	}

	var apPaths []dbus.ObjectPath
	err := wifiObj.Call("org.freedesktop.NetworkManager.Device.Wireless.GetAllAccessPoints", 0).Store(&apPaths)
	if err != nil || len(apPaths) == 0 {
		_ = wifiObj.Call("org.freedesktop.NetworkManager.Device.Wireless.GetAccessPoints", 0).Store(&apPaths)
	}

	bestApMap := make(map[string]AccessPoint)
	for _, path := range apPaths {
		apObj := c.conn.Object(nmBusName, path)

		ssidVar, errSsid := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Ssid")
		strengthVar, errStr := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Strength")
		freqVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Frequency")
		flagsVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Flags")
		wpaFlagsVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.WpaFlags")
		rsnFlagsVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.RsnFlags")
		hwAddrVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.HwAddress")

		if errSsid == nil && errStr == nil {
			ssidBytes, okSsid := ssidVar.Value().([]byte)
			strength, okStr := strengthVar.Value().(uint8)
			freq, _ := freqVar.Value().(uint32)
			flags, _ := flagsVar.Value().(uint32)
			wpaFlags, _ := wpaFlagsVar.Value().(uint32)
			rsnFlags, _ := rsnFlagsVar.Value().(uint32)
			bssid, _ := hwAddrVar.Value().(string)

			if okSsid && okStr {
				ssid := string(ssidBytes)
				if ssid != "" {
					ap := AccessPoint{
						SSID:      ssid,
						BSSID:     bssid,
						Signal:    strength,
						Frequency: freq,
						Band:      FrequencyToBand(freq),
						Channel:   FrequencyToChannel(freq),
						Security:  ParseSecurityFlags(flags, wpaFlags, rsnFlags),
						IsSaved:   savedMap[ssid],
						IsActive:  path == activeApPath,
					}

					// Deduplicate by SSID, keep active or strongest signal
					if existing, exists := bestApMap[ssid]; exists {
						if ap.IsActive || (!existing.IsActive && ap.Signal > existing.Signal) {
							bestApMap[ssid] = ap
						}
					} else {
						bestApMap[ssid] = ap
					}
				}
			}
		}
	}

	var aps []AccessPoint
	for _, ap := range bestApMap {
		aps = append(aps, ap)
	}
	return aps, nil
}

// RequestScan triggers an active Wi-Fi hardware scan.
func (c *DBusWifiClient) RequestScan(ctx context.Context) error {
	wifiObj := c.conn.Object(nmBusName, c.wifiPath)
	options := map[string]dbus.Variant{}
	return wifiObj.Call("org.freedesktop.NetworkManager.Device.Wireless.RequestScan", 0, options).Err
}

// GetSavedProfiles lists all saved Wi-Fi profiles.
func (c *DBusWifiClient) GetSavedProfiles(ctx context.Context) ([]WifiProfile, error) {
	settingsObj := c.conn.Object(nmBusName, nmSettingsPath)

	var connPaths []dbus.ObjectPath
	if err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths); err != nil {
		return nil, fmt.Errorf("failed to list saved profiles: %w", err)
	}

	var profiles []WifiProfile
	for _, path := range connPaths {
		connObj := c.conn.Object(nmBusName, path)
		var settings map[string]map[string]dbus.Variant
		if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings); err == nil {
			if wireless, ok := settings["802-11-wireless"]; ok {
				ssidBytes, _ := wireless["ssid"].Value().([]byte)
				ssid := string(ssidBytes)

				connMeta := settings["connection"]
				uuid, _ := connMeta["uuid"].Value().(string)
				id, _ := connMeta["id"].Value().(string)
				autoConn, _ := connMeta["autoconnect"].Value().(bool)
				lastUsed, _ := connMeta["timestamp"].Value().(uint64)

				secType := SecurityOpen
				hasPassword := false
				if _, hasSec := settings["802-11-wireless-security"]; hasSec {
					secType = SecurityWPA2PSK
					hasPassword = true
				}

				profiles = append(profiles, WifiProfile{
					UUID:         uuid,
					Name:         id,
					SSID:         ssid,
					SecurityType: secType,
					AutoConnect:  autoConn,
					LastUsed:     lastUsed,
					HasPassword:  hasPassword,
				})
			}
		}
	}
	return profiles, nil
}

// GetProfileSecrets securely fetches password and security details for a profile.
func (c *DBusWifiClient) GetProfileSecrets(ctx context.Context, ssidOrUUID string) (*WifiSecrets, error) {
	connObj, settings, err := c.findConnectionObject(ssidOrUUID)
	if err != nil {
		return nil, err
	}

	ssid := ""
	uuid := ""
	if wireless, ok := settings["802-11-wireless"]; ok {
		if b, ok := wireless["ssid"].Value().([]byte); ok {
			ssid = string(b)
		}
	}
	if connMeta, ok := settings["connection"]; ok {
		if u, ok := connMeta["uuid"].Value().(string); ok {
			uuid = u
		}
	}

	// Request secrets from NM D-Bus Settings
	var secretsDict map[string]map[string]dbus.Variant
	err = connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSecrets", 0, "802-11-wireless-security").Store(&secretsDict)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve secrets: %w", err)
	}

	secMeta, ok := secretsDict["802-11-wireless-security"]
	if !ok {
		return &WifiSecrets{SSID: ssid, UUID: uuid, Password: "", KeyMgmt: "none"}, nil
	}

	psk := ""
	if val, ok := secMeta["psk"]; ok {
		if str, ok := val.Value().(string); ok {
			psk = str
		}
	}
	keyMgmt := "wpa-psk"
	if val, ok := secMeta["key-mgmt"]; ok {
		if str, ok := val.Value().(string); ok {
			keyMgmt = str
		}
	}

	return &WifiSecrets{
		SSID:     ssid,
		UUID:     uuid,
		Password: psk,
		KeyMgmt:  keyMgmt,
	}, nil
}

// SaveProfile creates or updates a Wi-Fi profile in NetworkManager.
func (c *DBusWifiClient) SaveProfile(ctx context.Context, config WifiProfileConfig) (*WifiProfile, error) {
	settingsObj := c.conn.Object(nmBusName, nmSettingsPath)
	connectionDict := BuildConnectionDict(config)

	var connPath dbus.ObjectPath
	err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.AddConnection", 0, connectionDict).Store(&connPath)
	if err != nil {
		return nil, fmt.Errorf("failed to add profile (%s): %w", config.SSID, err)
	}

	connObj := c.conn.Object(nmBusName, connPath)
	var settings map[string]map[string]dbus.Variant
	_ = connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings)

	uuid := ""
	if meta, ok := settings["connection"]; ok {
		if u, ok := meta["uuid"].Value().(string); ok {
			uuid = u
		}
	}

	if c.agent != nil && config.Password != "" {
		c.agent.SetPassword(config.SSID, config.Password)
		if uuid != "" {
			c.agent.SetPassword(uuid, config.Password)
		}
	}

	return &WifiProfile{
		UUID:         uuid,
		Name:         config.SSID,
		SSID:         config.SSID,
		SecurityType: config.Security,
		AutoConnect:  config.AutoConnect,
		HasPassword:  config.Password != "",
	}, nil
}

// UpdateProfileSecrets updates the WPA password for an existing profile and sets psk-flags = 0 to prevent kded prompts.
func (c *DBusWifiClient) UpdateProfileSecrets(ctx context.Context, ssidOrUUID, password string) error {
	connObj, settings, err := c.findConnectionObject(ssidOrUUID)
	if err != nil {
		return err
	}

	secMap, ok := settings["802-11-wireless-security"]
	if !ok {
		secMap = make(map[string]dbus.Variant)
		secMap["key-mgmt"] = dbus.MakeVariant("wpa-psk")
	}
	secMap["psk"] = dbus.MakeVariant(password)
	secMap["psk-flags"] = dbus.MakeVariant(uint32(0)) // 0 = NM_SETTING_SECRET_FLAG_NONE (No external agent prompt)
	settings["802-11-wireless-security"] = secMap
	settings["connection"]["security"] = dbus.MakeVariant("802-11-wireless-security")

	err = connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Update", 0, settings).Err
	if err != nil {
		return fmt.Errorf("failed to update secrets for %s: %w", ssidOrUUID, err)
	}

	if c.agent != nil {
		c.agent.SetPassword(ssidOrUUID, password)
	}

	return nil
}

// DeleteProfile forgets/removes a connection profile.
func (c *DBusWifiClient) DeleteProfile(ctx context.Context, ssidOrUUID string) error {
	connObj, _, err := c.findConnectionObject(ssidOrUUID)
	if err != nil {
		return err
	}
	err = connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Delete", 0).Err
	if err != nil {
		return fmt.Errorf("failed to delete profile %s: %w", ssidOrUUID, err)
	}
	return nil
}

// Connect connects to a network with SSID and optional password, handling both new and saved profiles without external agent popups.
func (c *DBusWifiClient) Connect(ctx context.Context, req ConnectRequest) error {
	nmObj := c.conn.Object(nmBusName, nmPath)

	// 1. Resolve Access Point object path and exact beacon SSID from active scan
	apPath, resolvedSSID := c.findAccessPointPath(req.SSID)

	// Register password with in-process SecretAgent
	if c.agent != nil && req.Password != "" {
		c.agent.SetPassword(resolvedSSID, req.Password)
		c.agent.SetPassword(req.SSID, req.Password)
	}

	// 2. Check if a saved profile already exists for this SSID / UUID
	if connObj, _, err := c.findConnectionObject(resolvedSSID); err == nil {
		// Existing profile found!
		if req.Password != "" {
			_ = c.UpdateProfileSecrets(ctx, resolvedSSID, req.Password)
		}
		var activeConnPath dbus.ObjectPath
		err = nmObj.Call("org.freedesktop.NetworkManager.ActivateConnection", 0, connObj.Path(), c.wifiPath, apPath).Store(&activeConnPath)
		if err != nil {
			return fmt.Errorf("failed to activate existing profile (%s): %w", resolvedSSID, err)
		}
		return nil
	}

	// 3. New network connection profile (psk-flags=0, system-wide connection)
	config := WifiProfileConfig{
		SSID:        resolvedSSID,
		Password:    req.Password,
		AutoConnect: true,
		Hidden:      req.Hidden,
	}
	connectionDict := BuildConnectionDict(config)

	var connectionPath, activeConnPath dbus.ObjectPath
	err := nmObj.Call(
		"org.freedesktop.NetworkManager.AddAndActivateConnection", 0,
		connectionDict, c.wifiPath, apPath,
	).Store(&connectionPath, &activeConnPath)
	if err != nil {
		return fmt.Errorf("connection failed for %s: %w", resolvedSSID, err)
	}
	return nil
}

// Disconnect disconnects the Wi-Fi interface.
func (c *DBusWifiClient) Disconnect(ctx context.Context) error {
	devObj := c.conn.Object(nmBusName, c.wifiPath)
	return devObj.Call("org.freedesktop.NetworkManager.Device.Disconnect", 0).Err
}

// SetWifiEnabled enables or disables the wireless radio.
func (c *DBusWifiClient) SetWifiEnabled(ctx context.Context, enabled bool) error {
	nmObj := c.conn.Object(nmBusName, nmPath)
	return nmObj.SetProperty("org.freedesktop.NetworkManager.WirelessEnabled", dbus.MakeVariant(enabled))
}

// IsWifiEnabled checks wireless radio power state.
func (c *DBusWifiClient) IsWifiEnabled(ctx context.Context) (bool, error) {
	nmObj := c.conn.Object(nmBusName, nmPath)
	val, err := nmObj.GetProperty("org.freedesktop.NetworkManager.WirelessEnabled")
	if err != nil {
		return false, err
	}
	if b, ok := val.Value().(bool); ok {
		return b, nil
	}
	return false, fmt.Errorf("invalid WirelessEnabled property type")
}

// GetActiveConnection retrieves details of current active connection.
func (c *DBusWifiClient) GetActiveConnection(ctx context.Context) (*ActiveWifiInfo, error) {
	wifiObj := c.conn.Object(nmBusName, c.wifiPath)

	val, err := wifiObj.GetProperty("org.freedesktop.NetworkManager.Device.Wireless.ActiveAccessPoint")
	if err != nil {
		return nil, fmt.Errorf("no active access point: %w", err)
	}
	apPath, ok := val.Value().(dbus.ObjectPath)
	if !ok || apPath == "/" || apPath == "" {
		return nil, fmt.Errorf("not connected to any access point")
	}

	apObj := c.conn.Object(nmBusName, apPath)
	ssidVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Ssid")
	strengthVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Strength")
	freqVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.Frequency")
	hwAddrVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.HwAddress")
	bitrateVar, _ := apObj.GetProperty("org.freedesktop.NetworkManager.AccessPoint.MaxBitrate")

	ssidBytes, _ := ssidVar.Value().([]byte)
	signal, _ := strengthVar.Value().(uint8)
	freq, _ := freqVar.Value().(uint32)
	bssid, _ := hwAddrVar.Value().(string)
	bitrate, _ := bitrateVar.Value().(uint32)

	return &ActiveWifiInfo{
		SSID:        string(ssidBytes),
		BSSID:       bssid,
		Device:      c.iface,
		Signal:      signal,
		Frequency:   freq,
		BitrateKbps: bitrate,
		Security:    SecurityWPA2PSK,
	}, nil
}

func (c *DBusWifiClient) findConnectionObject(ssidOrUUID string) (dbus.BusObject, map[string]map[string]dbus.Variant, error) {
	settingsObj := c.conn.Object(nmBusName, nmSettingsPath)

	var connPaths []dbus.ObjectPath
	if err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths); err != nil {
		return nil, nil, fmt.Errorf("failed to list connections: %w", err)
	}

	var caseInsensitiveObj dbus.BusObject
	var caseInsensitiveSettings map[string]map[string]dbus.Variant

	for _, path := range connPaths {
		connObj := c.conn.Object(nmBusName, path)
		var settings map[string]map[string]dbus.Variant
		if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings); err == nil {
			// Check UUID match
			if meta, ok := settings["connection"]; ok {
				if uuid, ok := meta["uuid"].Value().(string); ok && strings.EqualFold(uuid, ssidOrUUID) {
					return connObj, settings, nil
				}
				if id, ok := meta["id"].Value().(string); ok && id == ssidOrUUID {
					return connObj, settings, nil
				}
			}
			// Check SSID match
			if wireless, ok := settings["802-11-wireless"]; ok {
				if ssidBytes, ok := wireless["ssid"].Value().([]byte); ok {
					ssid := string(ssidBytes)
					if ssid == ssidOrUUID {
						return connObj, settings, nil // Exact match
					}
					if strings.EqualFold(ssid, ssidOrUUID) && caseInsensitiveObj == nil {
						caseInsensitiveObj = connObj
						caseInsensitiveSettings = settings
					}
				}
			}
		}
	}

	if caseInsensitiveObj != nil {
		return caseInsensitiveObj, caseInsensitiveSettings, nil
	}

	return nil, nil, fmt.Errorf("connection profile not found: %s", ssidOrUUID)
}
