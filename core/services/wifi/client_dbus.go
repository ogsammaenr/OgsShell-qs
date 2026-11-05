package wifi

import (
	"context"
	"fmt"
	"sort"
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
	hasPasswordMap := make(map[string]bool)
	for _, p := range savedProfiles {
		savedMap[p.SSID] = true
		if p.HasPassword {
			hasPasswordMap[p.SSID] = true
		}
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
						SSID:        ssid,
						BSSID:       bssid,
						Signal:      strength,
						Frequency:   freq,
						Band:        FrequencyToBand(freq),
						Channel:     FrequencyToChannel(freq),
						Security:    ParseSecurityFlags(flags, wpaFlags, rsnFlags),
						IsSaved:     savedMap[ssid],
						HasPassword: hasPasswordMap[ssid],
						IsActive:    path == activeApPath,
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
				if secMeta, hasSec := settings["802-11-wireless-security"]; hasSec {
					secType = SecurityWPA2PSK
					pskFlags := uint32(0)
					if flagsVal, okFlags := secMeta["psk-flags"]; okFlags {
						if f, ok := flagsVal.Value().(uint32); ok {
							pskFlags = f
						}
					}
					// If psk-flags == 0, password is saved on system disk.
					// If psk-flags == 1 (agent-owned), check if agent has cached it.
					if pskFlags == 0 {
						hasPassword = true
					} else if c.agent != nil && c.agent.HasPassword(ssid, uuid) {
						hasPassword = true
					}
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

// SanitizeSettingsForUpdate cleans up legacy tuple arrays (like addresses, routes) that cause D-Bus type unmarshaling mismatches on Update.
func SanitizeSettingsForUpdate(settings map[string]map[string]dbus.Variant) map[string]map[string]dbus.Variant {
	if settings == nil {
		return nil
	}

	// 1. Sanitize IPv6
	if ipv6, ok := settings["ipv6"]; ok {
		method := ""
		if m, ok := ipv6["method"].Value().(string); ok {
			method = m
		}
		// For auto, disabled, ignore, or link-local, strip legacy/empty addresses & routes to avoid 'a(ayuay)' mismatch
		if method == "auto" || method == "disabled" || method == "ignore" || method == "link-local" || method == "" {
			delete(ipv6, "addresses")
			delete(ipv6, "routes")
			delete(ipv6, "address-data")
			delete(ipv6, "route-data")
		} else {
			if addrVal, exists := ipv6["addresses"]; exists {
				if arr, ok := addrVal.Value().([]interface{}); ok && len(arr) == 0 {
					delete(ipv6, "addresses")
				}
			}
			if routeVal, exists := ipv6["routes"]; exists {
				if arr, ok := routeVal.Value().([]interface{}); ok && len(arr) == 0 {
					delete(ipv6, "routes")
				}
			}
		}
	}

	// 2. Sanitize IPv4
	if ipv4, ok := settings["ipv4"]; ok {
		method := ""
		if m, ok := ipv4["method"].Value().(string); ok {
			method = m
		}
		if method == "auto" || method == "disabled" || method == "" {
			delete(ipv4, "addresses")
			delete(ipv4, "routes")
			delete(ipv4, "address-data")
			delete(ipv4, "route-data")
		} else {
			if addrVal, exists := ipv4["addresses"]; exists {
				if arr, ok := addrVal.Value().([]interface{}); ok && len(arr) == 0 {
					delete(ipv4, "addresses")
				}
			}
			if routeVal, exists := ipv4["routes"]; exists {
				if arr, ok := routeVal.Value().([]interface{}); ok && len(arr) == 0 {
					delete(ipv4, "routes")
				}
			}
		}
	}

	return settings
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

	settings = SanitizeSettingsForUpdate(settings)
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

	// 2. Check if a saved profile already exists for this SSID / UUID (checking both resolved and raw SSID)
	connObj, _, err := c.findConnectionObject(resolvedSSID)
	if err != nil && resolvedSSID != req.SSID {
		connObj, _, err = c.findConnectionObject(req.SSID)
	}
	if err == nil && connObj != nil {
		// Existing profile found! Reuse existing profile to preserve custom DNS and settings
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
	err = nmObj.Call(
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

// reactivateIfActive checks if the given connection (by connObj and settings) is currently active,
// and if so, re-activates it with its corresponding device to apply DNS/IPv6 changes immediately.
func (c *DBusWifiClient) reactivateIfActive(connObj dbus.BusObject, settings map[string]map[string]dbus.Variant) {
	uuid := ""
	id := ""
	isWireless := false
	ssid := ""
	if meta, ok := settings["connection"]; ok {
		if u, ok := meta["uuid"].Value().(string); ok {
			uuid = u
		}
		if name, ok := meta["id"].Value().(string); ok {
			id = name
		}
	}
	if wireless, ok := settings["802-11-wireless"]; ok {
		isWireless = true
		if b, ok := wireless["ssid"].Value().([]byte); ok {
			ssid = string(b)
		}
	}

	nmObj := c.conn.Object(nmBusName, nmPath)
	var activePaths []dbus.ObjectPath
	if val, err := nmObj.GetProperty("org.freedesktop.NetworkManager.ActiveConnections"); err == nil {
		if paths, ok := val.Value().([]dbus.ObjectPath); ok {
			activePaths = paths
		}
	}

	for _, aPath := range activePaths {
		acObj := c.conn.Object(nmBusName, aPath)
		var acProps map[string]dbus.Variant
		if err := acObj.Call("org.freedesktop.DBus.Properties.GetAll", 0, "org.freedesktop.NetworkManager.Connection.Active").Store(&acProps); err == nil {
			acUUID, _ := acProps["Uuid"].Value().(string)
			acId, _ := acProps["Id"].Value().(string)
			acConnPath, _ := acProps["Connection"].Value().(dbus.ObjectPath)

			match := (acConnPath == connObj.Path()) ||
				(uuid != "" && strings.EqualFold(acUUID, uuid)) ||
				(id != "" && acId == id) ||
				(ssid != "" && acId == ssid)

			if match {
				var devPath dbus.ObjectPath = "/"
				if devs, ok := acProps["Devices"].Value().([]dbus.ObjectPath); ok && len(devs) > 0 {
					devPath = devs[0]
				}

				if isWireless {
					apPath, _ := c.findAccessPointPath(ssid)
					var activeConnPath dbus.ObjectPath
					_ = nmObj.Call("org.freedesktop.NetworkManager.ActivateConnection", 0, connObj.Path(), devPath, apPath).Store(&activeConnPath)
				} else {
					var activeConnPath dbus.ObjectPath
					_ = nmObj.Call("org.freedesktop.NetworkManager.ActivateConnection", 0, connObj.Path(), devPath, dbus.ObjectPath("/")).Store(&activeConnPath)
				}
				return
			}
		}
	}
}

// GetWiredConnections returns all Ethernet devices and connection profiles.
func (c *DBusWifiClient) GetWiredConnections(ctx context.Context) ([]WiredConnection, error) {
	nmObj := c.conn.Object(nmBusName, nmPath)

	type activeConnInfo struct {
		id        string
		uuid      string
		connPath  dbus.ObjectPath
		devPath   dbus.ObjectPath
		ip4Path   dbus.ObjectPath
		connType  string
		ipAddress string
		prefix    int
		gateway   string
		dnsList   []string
	}

	activeConns := make(map[string]*activeConnInfo)
	activeByDev := make(map[string]*activeConnInfo)

	if val, err := nmObj.GetProperty("org.freedesktop.NetworkManager.ActiveConnections"); err == nil {
		if paths, ok := val.Value().([]dbus.ObjectPath); ok {
			for _, aPath := range paths {
				acObj := c.conn.Object(nmBusName, aPath)
				var acProps map[string]dbus.Variant
				if err := acObj.Call("org.freedesktop.DBus.Properties.GetAll", 0, "org.freedesktop.NetworkManager.Connection.Active").Store(&acProps); err == nil {
					u, _ := acProps["Uuid"].Value().(string)
					name, _ := acProps["Id"].Value().(string)
					cPath, _ := acProps["Connection"].Value().(dbus.ObjectPath)
					cType, _ := acProps["Type"].Value().(string)
					ip4, _ := acProps["Ip4Config"].Value().(dbus.ObjectPath)

					var devPath dbus.ObjectPath = "/"
					if devs, ok := acProps["Devices"].Value().([]dbus.ObjectPath); ok && len(devs) > 0 {
						devPath = devs[0]
					}

					info := &activeConnInfo{
						id:       name,
						uuid:     u,
						connPath: cPath,
						devPath:  devPath,
						ip4Path:  ip4,
						connType: cType,
						prefix:   24,
					}

					if ip4 != "/" && ip4 != "" {
						ip4Obj := c.conn.Object(nmBusName, ip4)
						if addrDataVal, err := ip4Obj.GetProperty("org.freedesktop.NetworkManager.IP4Config.AddressData"); err == nil {
							if addrData, ok := addrDataVal.Value().([]map[string]dbus.Variant); ok && len(addrData) > 0 {
								if a, ok := addrData[0]["address"].Value().(string); ok {
									info.ipAddress = a
								}
								if p, ok := addrData[0]["prefix"].Value().(uint32); ok {
									info.prefix = int(p)
								}
							}
						}
						if gwVal, err := ip4Obj.GetProperty("org.freedesktop.NetworkManager.IP4Config.Gateway"); err == nil {
							if g, ok := gwVal.Value().(string); ok {
								info.gateway = g
							}
						}
						if nsVal, err := ip4Obj.GetProperty("org.freedesktop.NetworkManager.IP4Config.Nameservers"); err == nil {
							if nsList, ok := nsVal.Value().([]uint32); ok {
								for _, ns := range nsList {
									info.dnsList = append(info.dnsList, Uint32ToIP(ns))
								}
							}
						}
					}

					if u != "" {
						activeConns[strings.ToLower(u)] = info
					}
					if name != "" {
						activeConns[strings.ToLower(name)] = info
					}
					if cPath != "/" && cPath != "" {
						activeConns[string(cPath)] = info
					}
					if devPath != "/" && devPath != "" {
						activeByDev[string(devPath)] = info
					}
				}
			}
		}
	}

	type ethDeviceInfo struct {
		path      dbus.ObjectPath
		iface     string
		hwAddress string
		state     uint32
		carrier   bool
		speed     int
		acPath    dbus.ObjectPath
	}

	var ethDevices []ethDeviceInfo
	if val, err := nmObj.GetProperty("org.freedesktop.NetworkManager.AllDevices"); err == nil {
		if devPaths, ok := val.Value().([]dbus.ObjectPath); ok {
			for _, dPath := range devPaths {
				devObj := c.conn.Object(nmBusName, dPath)
				typeVal, errType := devObj.GetProperty("org.freedesktop.NetworkManager.Device.DeviceType")
				if errType != nil {
					continue
				}
				devType, ok := typeVal.Value().(uint32)
				if !ok || devType != 1 { // 1 = NM_DEVICE_TYPE_ETHERNET
					continue
				}

				iface := ""
				if ifaceVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.Interface"); err == nil {
					iface, _ = ifaceVal.Value().(string)
				}
				hw := ""
				if hwVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.HwAddress"); err == nil {
					hw, _ = hwVal.Value().(string)
				}
				state := uint32(0)
				if stateVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.State"); err == nil {
					state, _ = stateVal.Value().(uint32)
				}
				carrier := false
				if carrierVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.Wired.Carrier"); err == nil {
					if b, ok := carrierVal.Value().(bool); ok {
						carrier = b
					}
				}
				speed := 0
				if speedVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.Wired.Speed"); err == nil {
					if s, ok := speedVal.Value().(uint32); ok {
						speed = int(s)
					}
				}
				var acPath dbus.ObjectPath
				if acVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.ActiveConnection"); err == nil {
					acPath, _ = acVal.Value().(dbus.ObjectPath)
				}

				ethDevices = append(ethDevices, ethDeviceInfo{
					path:      dPath,
					iface:     iface,
					hwAddress: hw,
					state:     state,
					carrier:   carrier,
					speed:     speed,
					acPath:    acPath,
				})
			}
		}
	}

	settingsObj := c.conn.Object(nmBusName, nmSettingsPath)
	var connPaths []dbus.ObjectPath
	_ = settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths)

	var results []WiredConnection
	claimedDevs := make(map[string]bool)

	for _, cPath := range connPaths {
		connObj := c.conn.Object(nmBusName, cPath)
		var settings map[string]map[string]dbus.Variant
		if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings); err == nil {
			connMeta, ok := settings["connection"]
			if !ok {
				continue
			}
			cType, _ := connMeta["type"].Value().(string)
			if cType != "802-3-ethernet" {
				if _, hasEther := settings["802-3-ethernet"]; !hasEther {
					continue
				}
			}

			uuid, _ := connMeta["uuid"].Value().(string)
			name, _ := connMeta["id"].Value().(string)
			boundIface, _ := connMeta["interface-name"].Value().(string)

			var dnsList []string
			ignoreAutoDNS := false
			if ipv4Meta, ok := settings["ipv4"]; ok {
				if ig, ok := ipv4Meta["ignore-auto-dns"].Value().(bool); ok {
					ignoreAutoDNS = ig
				}
				if dnsVal, ok := ipv4Meta["dns"]; ok {
					if dnsUint32, ok := dnsVal.Value().([]uint32); ok {
						for _, u := range dnsUint32 {
							dnsList = append(dnsList, Uint32ToIP(u))
						}
					}
				}
			}

			ipv6Method := "auto"
			if ipv6Meta, ok := settings["ipv6"]; ok {
				if m, ok := ipv6Meta["method"].Value().(string); ok {
					ipv6Method = m
				}
			}
			ipv6Disabled := (ipv6Method == "disabled" || ipv6Method == "ignore")

			var active *activeConnInfo
			if a, ok := activeConns[strings.ToLower(uuid)]; ok {
				active = a
			} else if a, ok := activeConns[string(cPath)]; ok {
				active = a
			} else if a, ok := activeConns[strings.ToLower(name)]; ok {
				active = a
			}

			isConnected := active != nil
			ipAddr := ""
			prefix := 24
			gateway := ""
			if active != nil {
				ipAddr = active.ipAddress
				prefix = active.prefix
				gateway = active.gateway
				if len(active.dnsList) > 0 {
					dnsList = active.dnsList
				}
			}

			matchedIface := boundIface
			hwAddr := ""
			carrier := false
			speed := 0

			for _, dev := range ethDevices {
				isThisDev := false
				if active != nil && active.devPath == dev.path {
					isThisDev = true
				} else if boundIface != "" && dev.iface == boundIface {
					isThisDev = true
				} else if !claimedDevs[dev.iface] && (matchedIface == "" || matchedIface == dev.iface) {
					isThisDev = true
				}

				if isThisDev {
					matchedIface = dev.iface
					hwAddr = dev.hwAddress
					carrier = dev.carrier
					speed = dev.speed
					if isConnected {
						claimedDevs[dev.iface] = true
					}
					break
				}
			}

			results = append(results, WiredConnection{
				UUID:          uuid,
				Name:          name,
				Interface:     matchedIface,
				HwAddress:     hwAddr,
				IsConnected:   isConnected,
				Carrier:       carrier,
				SpeedMbps:     speed,
				IPAddress:     ipAddr,
				Prefix:        prefix,
				Gateway:       gateway,
				DNS:           dnsList,
				IgnoreAutoDNS: ignoreAutoDNS,
				IPv6Method:    ipv6Method,
				IPv6Disabled:  ipv6Disabled,
			})
		}
	}

	for _, dev := range ethDevices {
		if claimedDevs[dev.iface] {
			continue
		}
		alreadyListed := false
		for _, r := range results {
			if r.Interface == dev.iface {
				alreadyListed = true
				break
			}
		}
		if alreadyListed {
			continue
		}

		active := activeByDev[string(dev.path)]
		isConnected := active != nil || dev.state == 100
		ipAddr := ""
		prefix := 24
		gateway := ""
		var dnsList []string
		if active != nil {
			ipAddr = active.ipAddress
			prefix = active.prefix
			gateway = active.gateway
			dnsList = active.dnsList
		}

		results = append(results, WiredConnection{
			UUID:          "",
			Name:          fmt.Sprintf("Kablolu Ağ (%s)", dev.iface),
			Interface:     dev.iface,
			HwAddress:     dev.hwAddress,
			IsConnected:   isConnected,
			Carrier:       dev.carrier,
			SpeedMbps:     dev.speed,
			IPAddress:     ipAddr,
			Prefix:        prefix,
			Gateway:       gateway,
			DNS:           dnsList,
			IgnoreAutoDNS: false,
			IPv6Method:    "auto",
			IPv6Disabled:  false,
		})
	}

	sort.SliceStable(results, func(i, j int) bool {
		if results[i].IsConnected != results[j].IsConnected {
			return results[i].IsConnected
		}
		if results[i].Carrier != results[j].Carrier {
			return results[i].Carrier
		}
		return results[i].Name < results[j].Name
	})

	return results, nil
}

// GetNetworkDetails retrieves detailed IP/DNS/IPv6 configuration for a connection or the active network.
func (c *DBusWifiClient) GetNetworkDetails(ctx context.Context, ssidOrUUID string) (*NetworkDetails, error) {
	activeInfo, _ := c.GetActiveConnection(ctx)

	if ssidOrUUID == "" {
		if activeInfo != nil {
			ssidOrUUID = activeInfo.SSID
		} else {
			// Wi-Fi is not active; fallback to any active wired connection
			wiredList, errWired := c.GetWiredConnections(ctx)
			if errWired == nil {
				for _, w := range wiredList {
					if w.IsConnected {
						ssidOrUUID = w.UUID
						if ssidOrUUID == "" {
							ssidOrUUID = w.Name
						}
						break
					}
				}
			}
		}
		if ssidOrUUID == "" {
			return nil, fmt.Errorf("no active connection and no SSID/UUID provided")
		}
	}

	connObj, settings, err := c.findConnectionObject(ssidOrUUID)
	if err != nil {
		if activeInfo != nil && (activeInfo.SSID == ssidOrUUID || ssidOrUUID == "") {
			return &NetworkDetails{
				SSID:        activeInfo.SSID,
				Device:      activeInfo.Device,
				IPAddress:   activeInfo.IPAddress,
				Gateway:     activeInfo.Gateway,
				DNS:         activeInfo.DNS,
				Security:    activeInfo.Security,
				IsConnected: true,
				Signal:      activeInfo.Signal,
			}, nil
		}
		return nil, err
	}

	uuid := ""
	id := ""
	ssid := ""
	isWireless := false
	if connMeta, ok := settings["connection"]; ok {
		if u, ok := connMeta["uuid"].Value().(string); ok {
			uuid = u
		}
		if name, ok := connMeta["id"].Value().(string); ok {
			id = name
		}
	}
	if wireless, ok := settings["802-11-wireless"]; ok {
		isWireless = true
		if ssidBytes, ok := wireless["ssid"].Value().([]byte); ok {
			ssid = string(ssidBytes)
		}
	}
	if ssid == "" {
		ssid = id
	}

	var dnsList []string
	ignoreAutoDNS := false
	ipAddr := ""
	gateway := ""
	prefix := 24

	if ipv4Meta, ok := settings["ipv4"]; ok {
		if ig, ok := ipv4Meta["ignore-auto-dns"].Value().(bool); ok {
			ignoreAutoDNS = ig
		}
		if dnsVal, ok := ipv4Meta["dns"]; ok {
			if dnsUint32, ok := dnsVal.Value().([]uint32); ok {
				for _, u := range dnsUint32 {
					dnsList = append(dnsList, Uint32ToIP(u))
				}
			}
		}
		if gw, ok := ipv4Meta["gateway"].Value().(string); ok {
			gateway = gw
		}
	}

	ipv6Method := "auto"
	if ipv6Meta, ok := settings["ipv6"]; ok {
		if m, ok := ipv6Meta["method"].Value().(string); ok {
			ipv6Method = m
		}
	}
	ipv6Disabled := ipv6Method == "disabled" || ipv6Method == "ignore"

	secType := SecurityOpen
	if _, ok := settings["802-11-wireless-security"]; ok {
		secType = SecurityWPA2PSK
	}

	isConnected := false
	signal := uint8(0)
	devIface := c.iface
	if !isWireless {
		devIface = ""
		if connMeta, ok := settings["connection"]; ok {
			if ifName, ok := connMeta["interface-name"].Value().(string); ok {
				devIface = ifName
			}
		}
	}

	// Look up active connection across all active connections on NetworkManager
	nmObj := c.conn.Object(nmBusName, nmPath)
	var activePaths []dbus.ObjectPath
	if val, err := nmObj.GetProperty("org.freedesktop.NetworkManager.ActiveConnections"); err == nil {
		if paths, ok := val.Value().([]dbus.ObjectPath); ok {
			activePaths = paths
		}
	}

	for _, aPath := range activePaths {
		acObj := c.conn.Object(nmBusName, aPath)
		var acProps map[string]dbus.Variant
		if err := acObj.Call("org.freedesktop.DBus.Properties.GetAll", 0, "org.freedesktop.NetworkManager.Connection.Active").Store(&acProps); err == nil {
			acUUID, _ := acProps["Uuid"].Value().(string)
			acId, _ := acProps["Id"].Value().(string)
			acConnPath, _ := acProps["Connection"].Value().(dbus.ObjectPath)

			match := (acConnPath == connObj.Path()) ||
				(uuid != "" && strings.EqualFold(acUUID, uuid)) ||
				(id != "" && acId == id) ||
				(ssid != "" && acId == ssid)

			if match {
				isConnected = true
				if isWireless {
					if activeInfo != nil {
						signal = activeInfo.Signal
					} else {
						signal = 80
					}
				} else {
					signal = 100
				}

				if devs, ok := acProps["Devices"].Value().([]dbus.ObjectPath); ok && len(devs) > 0 {
					devObj := c.conn.Object(nmBusName, devs[0])
					if ifVal, err := devObj.GetProperty("org.freedesktop.NetworkManager.Device.Interface"); err == nil {
						if ifName, ok := ifVal.Value().(string); ok && ifName != "" {
							devIface = ifName
						}
					}
				}

				if ip4Path, ok := acProps["Ip4Config"].Value().(dbus.ObjectPath); ok && ip4Path != "/" && ip4Path != "" {
					ip4Obj := c.conn.Object(nmBusName, ip4Path)
					if addrDataVal, err := ip4Obj.GetProperty("org.freedesktop.NetworkManager.IP4Config.AddressData"); err == nil {
						if addrData, ok := addrDataVal.Value().([]map[string]dbus.Variant); ok && len(addrData) > 0 {
							if a, ok := addrData[0]["address"].Value().(string); ok {
								ipAddr = a
							}
							if p, ok := addrData[0]["prefix"].Value().(uint32); ok {
								prefix = int(p)
							}
						}
					}
					if gwVal, err := ip4Obj.GetProperty("org.freedesktop.NetworkManager.IP4Config.Gateway"); err == nil {
						if g, ok := gwVal.Value().(string); ok && g != "" {
							gateway = g
						}
					}
					if nsVal, err := ip4Obj.GetProperty("org.freedesktop.NetworkManager.IP4Config.Nameservers"); err == nil {
						if nsList, ok := nsVal.Value().([]uint32); ok && len(nsList) > 0 {
							dnsList = nil
							for _, ns := range nsList {
								dnsList = append(dnsList, Uint32ToIP(ns))
							}
						}
					}
				}
				break
			}
		}
	}

	if !isConnected && devIface == "" {
		// Fallback to first available ethernet device if wired
		if !isWireless {
			if wiredList, errWired := c.GetWiredConnections(ctx); errWired == nil && len(wiredList) > 0 {
				devIface = wiredList[0].Interface
			}
		}
	}

	_ = connObj
	return &NetworkDetails{
		UUID:          uuid,
		Name:          id,
		SSID:          ssid,
		Device:        devIface,
		IPAddress:     ipAddr,
		Prefix:        prefix,
		Gateway:       gateway,
		DNS:           dnsList,
		IgnoreAutoDNS: ignoreAutoDNS,
		IPv6Method:    ipv6Method,
		IPv6Disabled:  ipv6Disabled,
		Security:      secType,
		IsConnected:   isConnected,
		Signal:        signal,
	}, nil
}

// SetConnectionDNS configures custom DNS and automatic DNS ignore flag on a connection profile.
func (c *DBusWifiClient) SetConnectionDNS(ctx context.Context, req SetConnectionDNSRequest) error {
	connObj, settings, err := c.findConnectionObject(req.SSIDOrUUID)
	if err != nil {
		return err
	}

	if _, ok := settings["ipv4"]; !ok {
		settings["ipv4"] = make(map[string]dbus.Variant)
		settings["ipv4"]["method"] = dbus.MakeVariant("auto")
	}

	var dnsUint32 []uint32
	for _, ipStr := range req.DNS {
		cleanIP := strings.TrimSpace(ipStr)
		if cleanIP == "" {
			continue
		}
		if u, err := IPToUint32(cleanIP); err == nil {
			dnsUint32 = append(dnsUint32, u)
		}
	}

	if len(dnsUint32) > 0 {
		settings["ipv4"]["dns"] = dbus.MakeVariant(dnsUint32)
		settings["ipv4"]["ignore-auto-dns"] = dbus.MakeVariant(req.IgnoreAutoDNS)
	} else {
		settings["ipv4"]["dns"] = dbus.MakeVariant([]uint32{})
		delete(settings["ipv4"], "dns-data")
		settings["ipv4"]["ignore-auto-dns"] = dbus.MakeVariant(false)
	}

	settings = SanitizeSettingsForUpdate(settings)
	err = connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Update", 0, settings).Err
	if err != nil {
		return fmt.Errorf("failed to update DNS for %s: %w", req.SSIDOrUUID, err)
	}

	// If currently active, reactivate connection to apply DNS changes immediately
	c.reactivateIfActive(connObj, settings)

	return nil
}

// SetConnectionIPv6 sets IPv6 method (disabled or auto) on a connection profile.
func (c *DBusWifiClient) SetConnectionIPv6(ctx context.Context, req SetConnectionIPv6Request) error {
	connObj, settings, err := c.findConnectionObject(req.SSIDOrUUID)
	if err != nil {
		return err
	}

	if _, ok := settings["ipv6"]; !ok {
		settings["ipv6"] = make(map[string]dbus.Variant)
	}

	if req.Disabled {
		settings["ipv6"]["method"] = dbus.MakeVariant("disabled")
	} else {
		settings["ipv6"]["method"] = dbus.MakeVariant("auto")
	}

	settings = SanitizeSettingsForUpdate(settings)
	err = connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Update", 0, settings).Err
	if err != nil {
		return fmt.Errorf("failed to update IPv6 method for %s: %w", req.SSIDOrUUID, err)
	}

	// If currently active, reactivate to apply immediately
	c.reactivateIfActive(connObj, settings)

	return nil
}

// CleanupDuplicateProfiles removes redundant duplicate NetworkManager connection profiles for the same SSID.
func (c *DBusWifiClient) CleanupDuplicateProfiles(ctx context.Context, targetSSID ...string) (*CleanupDuplicatesResponse, error) {
	settingsObj := c.conn.Object(nmBusName, nmSettingsPath)

	var connPaths []dbus.ObjectPath
	if err := settingsObj.Call("org.freedesktop.NetworkManager.Settings.ListConnections", 0).Store(&connPaths); err != nil {
		return nil, fmt.Errorf("failed to list connections: %w", err)
	}

	type profileEntry struct {
		path         dbus.ObjectPath
		uuid         string
		id           string
		ssid         string
		hasCustomDNS bool
		timestamp    uint64
		isConnected  bool
	}

	activeInfo, _ := c.GetActiveConnection(ctx)
	ssidGroups := make(map[string][]profileEntry)

	filterSSID := ""
	if len(targetSSID) > 0 && targetSSID[0] != "" {
		filterSSID = targetSSID[0]
	}

	for _, path := range connPaths {
		connObj := c.conn.Object(nmBusName, path)
		var settings map[string]map[string]dbus.Variant
		if err := connObj.Call("org.freedesktop.NetworkManager.Settings.Connection.GetSettings", 0).Store(&settings); err == nil {
			if wireless, ok := settings["802-11-wireless"]; ok {
				ssidBytes, _ := wireless["ssid"].Value().([]byte)
				ssid := string(ssidBytes)
				if ssid == "" {
					continue
				}
				if filterSSID != "" && !strings.EqualFold(ssid, filterSSID) {
					continue
				}

				connMeta := settings["connection"]
				uuid, _ := connMeta["uuid"].Value().(string)
				id, _ := connMeta["id"].Value().(string)
				ts, _ := connMeta["timestamp"].Value().(uint64)

				hasCustomDNS := false
				if ipv4Meta, ok := settings["ipv4"]; ok {
					if ig, ok := ipv4Meta["ignore-auto-dns"].Value().(bool); ok && ig {
						hasCustomDNS = true
					}
					if dnsVal, ok := ipv4Meta["dns"]; ok {
						if dnsList, ok := dnsVal.Value().([]uint32); ok && len(dnsList) > 0 {
							hasCustomDNS = true
						}
					}
				}

				isConn := activeInfo != nil && (activeInfo.SSID == ssid || activeInfo.SSID == id)

				ssidGroups[ssid] = append(ssidGroups[ssid], profileEntry{
					path:         path,
					uuid:         uuid,
					id:           id,
					ssid:         ssid,
					hasCustomDNS: hasCustomDNS,
					timestamp:    ts,
					isConnected:  isConn,
				})
			}
		}
	}

	var deletedUUIDs []string

	for _, profiles := range ssidGroups {
		if len(profiles) <= 1 {
			continue
		}

		// Pick the best profile to keep:
		bestIdx := 0
		for i := 1; i < len(profiles); i++ {
			if profiles[i].isConnected && !profiles[bestIdx].isConnected {
				bestIdx = i
			} else if !profiles[bestIdx].isConnected && profiles[i].hasCustomDNS && !profiles[bestIdx].hasCustomDNS {
				bestIdx = i
			} else if !profiles[bestIdx].isConnected && profiles[i].timestamp > profiles[bestIdx].timestamp {
				bestIdx = i
			}
		}

		// Delete all redundant profiles
		for i, p := range profiles {
			if i == bestIdx {
				continue
			}
			delObj := c.conn.Object(nmBusName, p.path)
			if err := delObj.Call("org.freedesktop.NetworkManager.Settings.Connection.Delete", 0).Err; err == nil {
				deletedUUIDs = append(deletedUUIDs, p.uuid)
			}
		}
	}

	return &CleanupDuplicatesResponse{
		DeletedCount: len(deletedUUIDs),
		DeletedUUIDs: deletedUUIDs,
	}, nil
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
