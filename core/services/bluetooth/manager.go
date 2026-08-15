package bluetooth

import (
	"context"
	"time"
)

// BluetoothManager defines the standard interface for managing Bluetooth hardware and peripherals.
type BluetoothManager interface {
	// GetState retrieves the current status of the adapter and all known/discovered devices.
	GetState(ctx context.Context) (BluetoothState, error)

	// TogglePower toggles the Bluetooth adapter power state.
	TogglePower(ctx context.Context) error

	// SetPowered explicitly turns the Bluetooth adapter on or off.
	SetPowered(ctx context.Context, powered bool) error

	// StartDiscovery initiates Bluetooth device discovery.
	StartDiscovery(ctx context.Context) error

	// StopDiscovery cancels an active Bluetooth device discovery.
	StopDiscovery(ctx context.Context) error

	// StartDiscoveryWithTimeout initiates discovery and automatically stops it after the specified duration.
	StartDiscoveryWithTimeout(ctx context.Context, timeout time.Duration) error

	// ConnectDevice connects to a Bluetooth device identified by its MAC address.
	ConnectDevice(ctx context.Context, mac string) error

	// DisconnectDevice disconnects from a Bluetooth device identified by its MAC address.
	DisconnectDevice(ctx context.Context, mac string) error

	// Subscribe returns a read-only channel that receives notifications on Bluetooth state changes.
	Subscribe() <-chan struct{}

	// Close releases any resources and subscriptions associated with the manager.
	Close() error
}
