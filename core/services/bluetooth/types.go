package bluetooth

// BluetoothDevice represents a paired or discovered Bluetooth device.
type BluetoothDevice struct {
	MAC       string `json:"mac"`
	Name      string `json:"name"`
	Icon      string `json:"icon"`
	Connected bool   `json:"connected"`
	Paired    bool   `json:"paired"`
	RSSI      int16  `json:"rssi"`
}

// BluetoothState encapsulates the overall Bluetooth subsystem state for IPC broadcasts.
type BluetoothState struct {
	AdapterPowered bool              `json:"adapter_powered"`
	Discovering    bool              `json:"discovering"`
	Devices        []BluetoothDevice `json:"devices"`
}

// ConnectBluetoothPayload defines the payload for connect_bluetooth RPC action.
type ConnectBluetoothPayload struct {
	MAC string `json:"mac"`
}

// DisconnectBluetoothPayload defines the payload for disconnect_bluetooth RPC action.
type DisconnectBluetoothPayload struct {
	MAC string `json:"mac"`
}

// ToggleBluetoothPayload defines the optional payload for toggle_bluetooth RPC action.
type ToggleBluetoothPayload struct {
	Enabled *bool `json:"enabled,omitempty"`
}
