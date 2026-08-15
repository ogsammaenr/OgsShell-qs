package wifi

import (
	"fmt"
	"sync"

	"github.com/godbus/dbus/v5"
)

const (
	secretAgentPath  = "/org/freedesktop/NetworkManager/SecretAgent"
	secretAgentIface = "org.freedesktop.NetworkManager.SecretAgent"
	nmAgentMgrPath   = "/org/freedesktop/NetworkManager/AgentManager"
	nmAgentMgrIface  = "org.freedesktop.NetworkManager.AgentManager"
)

// SecretAgent is an in-process, headless NetworkManager secret agent that intercepts
// and satisfies credential queries directly from memory, preventing external desktop popups (e.g. kded / kwallet).
type SecretAgent struct {
	conn       *dbus.Conn
	mu         sync.RWMutex
	passwords  map[string]string // Keyed by SSID and UUID
	registered bool
}

// NewSecretAgent creates and registers a headless secret agent on D-Bus.
func NewSecretAgent(conn *dbus.Conn) (*SecretAgent, error) {
	agent := &SecretAgent{
		conn:      conn,
		passwords: make(map[string]string),
	}

	// Export SecretAgent interface on D-Bus
	err := conn.Export(agent, secretAgentPath, secretAgentIface)
	if err != nil {
		return nil, fmt.Errorf("failed to export SecretAgent object: %w", err)
	}

	// Register with NetworkManager AgentManager
	agentMgr := conn.Object(nmBusName, nmAgentMgrPath)
	err = agentMgr.Call(nmAgentMgrIface+".RegisterWithCapabilities", 0, "ogsShell-wifi-agent", uint32(1)).Err
	if err != nil {
		// Fallback to basic Register if RegisterWithCapabilities is not supported
		err = agentMgr.Call(nmAgentMgrIface+".Register", 0, "ogsShell-wifi-agent").Err
		if err != nil {
			return nil, fmt.Errorf("failed to register with AgentManager: %w", err)
		}
	}

	agent.registered = true
	return agent, nil
}

// SetPassword stores a password in the in-process cache for immediate query resolution.
func (a *SecretAgent) SetPassword(ssidOrUUID, password string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.passwords[ssidOrUUID] = password
}

// GetSecrets is called by NetworkManager when credentials are required for a connection.
func (a *SecretAgent) GetSecrets(
	connection map[string]map[string]dbus.Variant,
	connectionPath dbus.ObjectPath,
	settingName string,
	hints []string,
	flags uint32,
) (map[string]map[string]dbus.Variant, *dbus.Error) {
	a.mu.RLock()
	defer a.mu.RUnlock()

	ssid := ""
	uuid := ""
	if wireless, ok := connection["802-11-wireless"]; ok {
		if b, ok := wireless["ssid"].Value().([]byte); ok {
			ssid = string(b)
		}
	}
	if connMeta, ok := connection["connection"]; ok {
		if u, ok := connMeta["uuid"].Value().(string); ok {
			uuid = u
		}
	}

	// Check password cache
	pwd := ""
	if p, ok := a.passwords[uuid]; ok && p != "" {
		pwd = p
	} else if p, ok := a.passwords[ssid]; ok && p != "" {
		pwd = p
	}

	// Check if connection dict already had a psk
	if pwd == "" {
		if sec, ok := connection["802-11-wireless-security"]; ok {
			if p, ok := sec["psk"].Value().(string); ok && p != "" {
				pwd = p
			}
		}
	}

	if pwd == "" {
		return nil, dbus.NewError("org.freedesktop.NetworkManager.SecretAgent.NoSecrets", []interface{}{"No password available"})
	}

	result := map[string]map[string]dbus.Variant{
		"802-11-wireless-security": {
			"psk":       dbus.MakeVariant(pwd),
			"psk-flags": dbus.MakeVariant(uint32(0)), // NM_SETTING_SECRET_FLAG_NONE
		},
	}

	return result, nil
}

// CancelGetSecrets handles cancellation of a secret request.
func (a *SecretAgent) CancelGetSecrets(connectionPath dbus.ObjectPath, settingName string) *dbus.Error {
	return nil
}

// SaveSecrets handles saving secrets from NetworkManager.
func (a *SecretAgent) SaveSecrets(connection map[string]map[string]dbus.Variant, connectionPath dbus.ObjectPath) *dbus.Error {
	return nil
}

// DeleteSecrets handles deletion of secrets.
func (a *SecretAgent) DeleteSecrets(connection map[string]map[string]dbus.Variant, connectionPath dbus.ObjectPath) *dbus.Error {
	return nil
}

// Unregister removes the agent from NetworkManager.
func (a *SecretAgent) Unregister() {
	if a.registered && a.conn != nil {
		agentMgr := a.conn.Object(nmBusName, nmAgentMgrPath)
		_ = agentMgr.Call(nmAgentMgrIface+".Unregister", 0).Err
		_ = a.conn.Export(nil, secretAgentPath, secretAgentIface)
		a.registered = false
	}
}
