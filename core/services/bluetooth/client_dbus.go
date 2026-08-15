package bluetooth

import (
	"context"
	"fmt"
	"log/slog"
	"ogsShell/core/logger"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/godbus/dbus/v5"
)

const (
	bluezBusName = "org.bluez"
	adapterIface = "org.bluez.Adapter1"
	deviceIface  = "org.bluez.Device1"
	propIface    = "org.freedesktop.DBus.Properties"
	objMgrIface  = "org.freedesktop.DBus.ObjectManager"
)

// DBusBluetoothClient is the production BlueZ D-Bus implementation of BluetoothManager.
type DBusBluetoothClient struct {
	conn        *dbus.Conn
	adapterPath dbus.ObjectPath
	log         *slog.Logger

	mu                 sync.RWMutex
	adapterPowered     bool
	adapterDiscovering bool
	devices            map[dbus.ObjectPath]*BluetoothDevice

	listenersMu sync.Mutex
	listeners   []chan struct{}

	scanMu     sync.Mutex
	scanCancel context.CancelFunc

	done      chan struct{}
	closeOnce sync.Once
}

// NewDefaultDBusClient connects to the system D-Bus and detects the default Bluetooth adapter.
func NewDefaultDBusClient() (*DBusBluetoothClient, error) {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return nil, fmt.Errorf("system bus connection failed: %w", err)
	}
	return NewDBusClient(conn)
}

// NewDBusClient initializes the client with an existing D-Bus connection and begins watching signals.
func NewDBusClient(conn *dbus.Conn) (*DBusBluetoothClient, error) {
	client := &DBusBluetoothClient{
		conn:      conn,
		log:       logger.Module("BLUETOOTH_DBUS"),
		devices:   make(map[dbus.ObjectPath]*BluetoothDevice),
		listeners: make([]chan struct{}, 0),
		done:      make(chan struct{}),
	}

	if err := client.initAdapter(); err != nil {
		return nil, err
	}

	// Initial population of adapter properties and devices
	if err := client.refreshAll(); err != nil {
		client.log.Warn("Initial Bluetooth state refresh had warnings", "err", err)
	}

	// Start listening for D-Bus signals (PropertiesChanged, InterfacesAdded, InterfacesRemoved)
	go client.signalLoop()

	return client, nil
}

// initAdapter locates the primary BlueZ adapter (defaulting to /org/bluez/hci0 or first available).
func (c *DBusBluetoothClient) initAdapter() error {
	obj := c.conn.Object(bluezBusName, "/")
	var managedObjects map[dbus.ObjectPath]map[string]map[string]dbus.Variant

	err := obj.Call(objMgrIface+".GetManagedObjects", 0).Store(&managedObjects)
	if err != nil {
		return fmt.Errorf("failed to query BlueZ managed objects: %w", err)
	}

	var firstAdapter dbus.ObjectPath
	for path, ifaces := range managedObjects {
		if _, ok := ifaces[adapterIface]; ok {
			if path == "/org/bluez/hci0" {
				c.adapterPath = path
				c.log.Info("Found primary Bluetooth adapter", "path", path)
				return nil
			}
			if firstAdapter == "" {
				firstAdapter = path
			}
		}
	}

	if firstAdapter != "" {
		c.adapterPath = firstAdapter
		c.log.Info("Selected fallback Bluetooth adapter", "path", firstAdapter)
		return nil
	}

	return fmt.Errorf("no BlueZ adapter (e.g. hci0) found on system")
}

// refreshAll fetches and caches all adapter state and known devices under lock.
func (c *DBusBluetoothClient) refreshAll() error {
	obj := c.conn.Object(bluezBusName, "/")
	var managedObjects map[dbus.ObjectPath]map[string]map[string]dbus.Variant

	err := obj.Call(objMgrIface+".GetManagedObjects", 0).Store(&managedObjects)
	if err != nil {
		return fmt.Errorf("failed to get managed objects: %w", err)
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	// Clear old devices map and rebuild
	c.devices = make(map[dbus.ObjectPath]*BluetoothDevice)

	for path, ifaces := range managedObjects {
		if path == c.adapterPath {
			if props, ok := ifaces[adapterIface]; ok {
				c.adapterPowered = getBool(props, "Powered", false)
				c.adapterDiscovering = getBool(props, "Discovering", false)
			}
		}

		if devProps, ok := ifaces[deviceIface]; ok {
			// Ensure device belongs to our adapter
			adapterProp := devProps["Adapter"].Value()
			if adPath, ok := adapterProp.(dbus.ObjectPath); ok && adPath != c.adapterPath {
				continue
			}

			dev := parseDevice(devProps)
			c.devices[path] = dev
		}
	}

	return nil
}

func (c *DBusBluetoothClient) signalLoop() {
	// Subscribe to BlueZ signals
	ruleProps := fmt.Sprintf("type='signal',sender='%s',interface='%s',member='PropertiesChanged'", bluezBusName, propIface)
	ruleAdd := fmt.Sprintf("type='signal',sender='%s',interface='%s',member='InterfacesAdded'", bluezBusName, objMgrIface)
	ruleRem := fmt.Sprintf("type='signal',sender='%s',interface='%s',member='InterfacesRemoved'", bluezBusName, objMgrIface)

	_ = c.conn.BusObject().Call("org.freedesktop.DBus.AddMatch", 0, ruleProps).Err
	_ = c.conn.BusObject().Call("org.freedesktop.DBus.AddMatch", 0, ruleAdd).Err
	_ = c.conn.BusObject().Call("org.freedesktop.DBus.AddMatch", 0, ruleRem).Err

	sigCh := make(chan *dbus.Signal, 64)
	c.conn.Signal(sigCh)
	defer func() {
		c.conn.RemoveSignal(sigCh)
		_ = c.conn.BusObject().Call("org.freedesktop.DBus.RemoveMatch", 0, ruleProps).Err
		_ = c.conn.BusObject().Call("org.freedesktop.DBus.RemoveMatch", 0, ruleAdd).Err
		_ = c.conn.BusObject().Call("org.freedesktop.DBus.RemoveMatch", 0, ruleRem).Err
	}()

	for {
		select {
		case <-c.done:
			return
		case sig, ok := <-sigCh:
			if !ok {
				return
			}
			c.handleSignal(sig)
		}
	}
}

func (c *DBusBluetoothClient) handleSignal(sig *dbus.Signal) {
	if sig == nil {
		return
	}

	stateChanged := false

	switch sig.Name {
	case propIface + ".PropertiesChanged":
		if len(sig.Body) < 2 {
			return
		}
		iface, ok := sig.Body[0].(string)
		if !ok {
			return
		}
		changedProps, ok := sig.Body[1].(map[string]dbus.Variant)
		if !ok {
			return
		}

		c.mu.Lock()
		if iface == adapterIface && sig.Path == c.adapterPath {
			if v, ok := changedProps["Powered"]; ok {
				c.adapterPowered = getBoolVal(v, false)
				stateChanged = true
			}
			if v, ok := changedProps["Discovering"]; ok {
				c.adapterDiscovering = getBoolVal(v, false)
				stateChanged = true
			}
		} else if iface == deviceIface {
			dev, exists := c.devices[sig.Path]
			if !exists {
				// Fetch entire device properties
				devObj := c.conn.Object(bluezBusName, sig.Path)
				var allProps map[string]dbus.Variant
				if err := devObj.Call(propIface+".GetAll", 0, deviceIface).Store(&allProps); err == nil {
					dev = parseDevice(allProps)
					c.devices[sig.Path] = dev
					stateChanged = true
				}
			} else {
				updateDeviceProps(dev, changedProps)
				stateChanged = true
			}
		}
		c.mu.Unlock()

	case objMgrIface + ".InterfacesAdded":
		if len(sig.Body) < 2 {
			return
		}
		path, ok := sig.Body[0].(dbus.ObjectPath)
		if !ok {
			return
		}
		ifaces, ok := sig.Body[1].(map[string]map[string]dbus.Variant)
		if !ok {
			return
		}

		c.mu.Lock()
		if devProps, ok := ifaces[deviceIface]; ok {
			dev := parseDevice(devProps)
			c.devices[path] = dev
			stateChanged = true
		}
		if adapterProps, ok := ifaces[adapterIface]; ok && path == c.adapterPath {
			if v, ok := adapterProps["Powered"]; ok {
				c.adapterPowered = getBoolVal(v, false)
			}
			if v, ok := adapterProps["Discovering"]; ok {
				c.adapterDiscovering = getBoolVal(v, false)
			}
			stateChanged = true
		}
		c.mu.Unlock()

	case objMgrIface + ".InterfacesRemoved":
		if len(sig.Body) < 2 {
			return
		}
		path, ok := sig.Body[0].(dbus.ObjectPath)
		if !ok {
			return
		}
		ifaces, ok := sig.Body[1].([]string)
		if !ok {
			return
		}

		c.mu.Lock()
		for _, iface := range ifaces {
			if iface == deviceIface {
				delete(c.devices, path)
				stateChanged = true
			}
		}
		c.mu.Unlock()
	}

	if stateChanged {
		c.notifyListeners()
	}
}

func (c *DBusBluetoothClient) notifyListeners() {
	c.listenersMu.Lock()
	defer c.listenersMu.Unlock()

	for _, ch := range c.listeners {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

// GetState returns the current adapter and peripheral snapshot.
func (c *DBusBluetoothClient) GetState(ctx context.Context) (BluetoothState, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	deviceList := make([]BluetoothDevice, 0, len(c.devices))
	for _, dev := range c.devices {
		deviceList = append(deviceList, *dev)
	}

	// Sort devices: Connected first, then Paired, then by RSSI descending, then by Name
	sort.Slice(deviceList, func(i, j int) bool {
		if deviceList[i].Connected != deviceList[j].Connected {
			return deviceList[i].Connected
		}
		if deviceList[i].Paired != deviceList[j].Paired {
			return deviceList[i].Paired
		}
		if deviceList[i].RSSI != deviceList[j].RSSI {
			return deviceList[i].RSSI > deviceList[j].RSSI
		}
		return deviceList[i].Name < deviceList[j].Name
	})

	return BluetoothState{
		AdapterPowered: c.adapterPowered,
		Discovering:    c.adapterDiscovering,
		Devices:        deviceList,
	}, nil
}

// TogglePower toggles the Bluetooth adapter power state.
func (c *DBusBluetoothClient) TogglePower(ctx context.Context) error {
	c.mu.RLock()
	current := c.adapterPowered
	c.mu.RUnlock()

	return c.SetPowered(ctx, !current)
}

// SetPowered explicitly turns the Bluetooth adapter on or off.
func (c *DBusBluetoothClient) SetPowered(ctx context.Context, powered bool) error {
	adapterObj := c.conn.Object(bluezBusName, c.adapterPath)
	err := adapterObj.CallWithContext(ctx, propIface+".Set", 0, adapterIface, "Powered", dbus.MakeVariant(powered)).Err
	if err != nil {
		return fmt.Errorf("failed to set adapter powered to %v: %w", powered, err)
	}

	c.mu.Lock()
	c.adapterPowered = powered
	c.mu.Unlock()

	c.notifyListeners()
	return nil
}

// StartDiscovery initiates Bluetooth device discovery.
func (c *DBusBluetoothClient) StartDiscovery(ctx context.Context) error {
	adapterObj := c.conn.Object(bluezBusName, c.adapterPath)
	err := adapterObj.CallWithContext(ctx, adapterIface+".StartDiscovery", 0).Err
	if err != nil {
		// Ignore if already discovering
		if strings.Contains(err.Error(), "InProgress") || strings.Contains(err.Error(), "already") {
			return nil
		}
		return fmt.Errorf("failed to start discovery: %w", err)
	}

	c.mu.Lock()
	c.adapterDiscovering = true
	c.mu.Unlock()
	c.notifyListeners()
	return nil
}

// StopDiscovery cancels an active Bluetooth device discovery.
func (c *DBusBluetoothClient) StopDiscovery(ctx context.Context) error {
	adapterObj := c.conn.Object(bluezBusName, c.adapterPath)
	err := adapterObj.CallWithContext(ctx, adapterIface+".StopDiscovery", 0).Err
	if err != nil {
		// Ignore if not discovering
		if strings.Contains(err.Error(), "NotReady") || strings.Contains(err.Error(), "Failed") {
			return nil
		}
		return fmt.Errorf("failed to stop discovery: %w", err)
	}

	c.mu.Lock()
	c.adapterDiscovering = false
	c.mu.Unlock()
	c.notifyListeners()
	return nil
}

// StartDiscoveryWithTimeout starts discovery and automatically stops after duration.
func (c *DBusBluetoothClient) StartDiscoveryWithTimeout(ctx context.Context, timeout time.Duration) error {
	c.scanMu.Lock()
	if c.scanCancel != nil {
		c.scanCancel()
	}

	scanCtx, cancel := context.WithCancel(context.Background())
	c.scanCancel = cancel
	c.scanMu.Unlock()

	if err := c.StartDiscovery(ctx); err != nil {
		return err
	}

	go func() {
		select {
		case <-time.After(timeout):
			_ = c.StopDiscovery(context.Background())
		case <-scanCtx.Done():
		case <-c.done:
		}
	}()

	return nil
}

// ConnectDevice connects to a Bluetooth device identified by its MAC address.
func (c *DBusBluetoothClient) ConnectDevice(ctx context.Context, mac string) error {
	devPath := c.findDevicePath(mac)
	if devPath == "" {
		return fmt.Errorf("device with MAC %s not found", mac)
	}

	devObj := c.conn.Object(bluezBusName, devPath)
	err := devObj.CallWithContext(ctx, deviceIface+".Connect", 0).Err
	if err != nil {
		return fmt.Errorf("failed to connect to device %s: %w", mac, err)
	}

	return nil
}

// DisconnectDevice disconnects from a Bluetooth device identified by its MAC address.
func (c *DBusBluetoothClient) DisconnectDevice(ctx context.Context, mac string) error {
	devPath := c.findDevicePath(mac)
	if devPath == "" {
		return fmt.Errorf("device with MAC %s not found", mac)
	}

	devObj := c.conn.Object(bluezBusName, devPath)
	err := devObj.CallWithContext(ctx, deviceIface+".Disconnect", 0).Err
	if err != nil {
		return fmt.Errorf("failed to disconnect device %s: %w", mac, err)
	}

	return nil
}

// findDevicePath locates the D-Bus object path for a given MAC address.
func (c *DBusBluetoothClient) findDevicePath(mac string) dbus.ObjectPath {
	c.mu.RLock()
	defer c.mu.RUnlock()

	for path, dev := range c.devices {
		if strings.EqualFold(dev.MAC, mac) {
			return path
		}
	}

	// Fallback to convention path /org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX
	cleanMac := strings.ReplaceAll(strings.ToUpper(mac), ":", "_")
	return dbus.ObjectPath(fmt.Sprintf("%s/dev_%s", c.adapterPath, cleanMac))
}

// Subscribe returns a channel that is notified on Bluetooth state changes.
func (c *DBusBluetoothClient) Subscribe() <-chan struct{} {
	c.listenersMu.Lock()
	defer c.listenersMu.Unlock()

	ch := make(chan struct{}, 16)
	c.listeners = append(c.listeners, ch)
	return ch
}

// Close terminates D-Bus subscriptions and frees resources.
func (c *DBusBluetoothClient) Close() error {
	c.closeOnce.Do(func() {
		c.scanMu.Lock()
		if c.scanCancel != nil {
			c.scanCancel()
		}
		c.scanMu.Unlock()

		close(c.done)
		if c.conn != nil {
			_ = c.conn.Close()
		}
	})
	return nil
}

// Helper methods for property conversion
func getBool(m map[string]dbus.Variant, key string, def bool) bool {
	if v, ok := m[key]; ok {
		return getBoolVal(v, def)
	}
	return def
}

func getBoolVal(v dbus.Variant, def bool) bool {
	if b, ok := v.Value().(bool); ok {
		return b
	}
	return def
}

func getString(m map[string]dbus.Variant, key string, def string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.Value().(string); ok {
			return s
		}
	}
	return def
}

func getInt16(m map[string]dbus.Variant, key string, def int16) int16 {
	if v, ok := m[key]; ok {
		val := v.Value()
		switch n := val.(type) {
		case int16:
			return n
		case int32:
			return int16(n)
		case int64:
			return int16(n)
		case float64:
			return int16(n)
		}
	}
	return def
}

func getUint32(m map[string]dbus.Variant, key string, def uint32) uint32 {
	if v, ok := m[key]; ok {
		val := v.Value()
		switch n := val.(type) {
		case uint32:
			return n
		case uint16:
			return uint32(n)
		case uint64:
			return uint32(n)
		case int:
			return uint32(n)
		}
	}
	return def
}

func parseDevice(props map[string]dbus.Variant) *BluetoothDevice {
	mac := getString(props, "Address", "")
	name := getString(props, "Name", "")
	alias := getString(props, "Alias", "")
	if name == "" {
		name = alias
	}
	if name == "" {
		name = mac
	}

	icon := getString(props, "Icon", "")
	class := getUint32(props, "Class", 0)
	if icon == "" {
		icon = deduceIcon(class, name)
	}

	return &BluetoothDevice{
		MAC:       mac,
		Name:      name,
		Icon:      icon,
		Connected: getBool(props, "Connected", false),
		Paired:    getBool(props, "Paired", false),
		RSSI:      getInt16(props, "RSSI", 0),
	}
}

func updateDeviceProps(dev *BluetoothDevice, props map[string]dbus.Variant) {
	if v, ok := props["Address"]; ok {
		if s, ok := v.Value().(string); ok {
			dev.MAC = s
		}
	}
	if v, ok := props["Name"]; ok {
		if s, ok := v.Value().(string); ok {
			dev.Name = s
		}
	} else if v, ok := props["Alias"]; ok && dev.Name == "" {
		if s, ok := v.Value().(string); ok {
			dev.Name = s
		}
	}
	if v, ok := props["Icon"]; ok {
		if s, ok := v.Value().(string); ok {
			dev.Icon = s
		}
	}
	if v, ok := props["Connected"]; ok {
		dev.Connected = getBoolVal(v, dev.Connected)
	}
	if v, ok := props["Paired"]; ok {
		dev.Paired = getBoolVal(v, dev.Paired)
	}
	if _, ok := props["RSSI"]; ok {
		dev.RSSI = getInt16(props, "RSSI", dev.RSSI)
	}
}

// deduceIcon infers icon name from Bluetooth CoD (Class of Device) or device name.
func deduceIcon(class uint32, name string) string {
	majorClass := (class >> 8) & 0x1F
	switch majorClass {
	case 0x04: // Audio / Video
		return "audio-headset"
	case 0x05: // Peripheral (keyboard, mouse, gamepad)
		minorClass := (class >> 2) & 0x3F
		if minorClass&0x10 != 0 {
			return "input-keyboard"
		}
		if minorClass&0x20 != 0 {
			return "input-mouse"
		}
		return "input-gaming"
	case 0x02: // Phone
		return "phone"
	case 0x01: // Computer
		return "computer"
	}

	lowerName := strings.ToLower(name)
	if strings.Contains(lowerName, "headset") || strings.Contains(lowerName, "wh-") || strings.Contains(lowerName, "buds") || strings.Contains(lowerName, "airpods") {
		return "audio-headset"
	}
	if strings.Contains(lowerName, "keyboard") || strings.Contains(lowerName, "keychron") {
		return "input-keyboard"
	}
	if strings.Contains(lowerName, "mouse") || strings.Contains(lowerName, "mx master") {
		return "input-mouse"
	}

	return "bluetooth"
}
