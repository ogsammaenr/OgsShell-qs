package wifi

import (
	"encoding/binary"
	"fmt"
	"net"

	"github.com/godbus/dbus/v5"
)

// BuildConnectionDict converts a WifiProfileConfig into a NetworkManager D-Bus settings dictionary.
func BuildConnectionDict(config WifiProfileConfig) map[string]map[string]dbus.Variant {
	dict := map[string]map[string]dbus.Variant{
		"connection": {
			"id":          dbus.MakeVariant(config.SSID),
			"type":        dbus.MakeVariant("802-11-wireless"),
			"permissions": dbus.MakeVariant([]string{}), // System-wide connection (prevents desktop agent prompts)
		},
		"802-11-wireless": {
			"ssid": dbus.MakeVariant([]byte(config.SSID)),
			"mode": dbus.MakeVariant("infrastructure"),
		},
		"ipv4": {
			"method": dbus.MakeVariant("auto"),
		},
		"ipv6": {
			"method": dbus.MakeVariant("auto"),
		},
	}

	if config.AutoConnect {
		dict["connection"]["autoconnect"] = dbus.MakeVariant(true)
	}

	if config.Hidden {
		dict["802-11-wireless"]["hidden"] = dbus.MakeVariant(true)
	}

	// Security configuration: psk-flags = 0 (NM_SETTING_SECRET_FLAG_NONE) forces system-level storage
	// and completely bypasses external desktop agents (kded / kwallet).
	if config.Password != "" || config.Security == SecurityWPAPSK || config.Security == SecurityWPA2PSK || config.Security == SecurityWPA3SAE {
		secMap := map[string]dbus.Variant{
			"psk-flags": dbus.MakeVariant(uint32(0)), // 0 = NM_SETTING_SECRET_FLAG_NONE (No agent popup)
		}

		if config.Security == SecurityWPA3SAE {
			secMap["key-mgmt"] = dbus.MakeVariant("sae")
			if config.Password != "" {
				secMap["psk"] = dbus.MakeVariant(config.Password)
			}
		} else {
			secMap["key-mgmt"] = dbus.MakeVariant("wpa-psk")
			if config.Password != "" {
				secMap["psk"] = dbus.MakeVariant(config.Password)
			}
		}
		dict["802-11-wireless-security"] = secMap
		dict["connection"]["security"] = dbus.MakeVariant("802-11-wireless-security")
	}

	// Custom DNS configuration
	if len(config.DNS) > 0 {
		var dnsUint32 []uint32
		for _, ipStr := range config.DNS {
			if u, err := IPToUint32(ipStr); err == nil {
				dnsUint32 = append(dnsUint32, u)
			}
		}
		if len(dnsUint32) > 0 {
			dict["ipv4"]["dns"] = dbus.MakeVariant(dnsUint32)
			dict["ipv4"]["ignore-auto-dns"] = dbus.MakeVariant(true)
		}
	}

	// Static IP configuration
	if config.StaticIP != "" && config.Gateway != "" {
		ip := net.ParseIP(config.StaticIP).To4()
		gw := net.ParseIP(config.Gateway).To4()
		if ip != nil && gw != nil {
			dict["ipv4"]["method"] = dbus.MakeVariant("manual")
			// NM IP4 Address structure: uint32 IP, uint32 prefix (24), uint32 Gateway
			ipVal := binary.NativeEndian.Uint32(ip)
			gwVal := binary.NativeEndian.Uint32(gw)
			dict["ipv4"]["addresses"] = dbus.MakeVariant([][]uint32{{ipVal, 24, gwVal}})
			dict["ipv4"]["gateway"] = dbus.MakeVariant(config.Gateway)
		}
	}

	return dict
}

// IPToUint32 converts a string IPv4 address (e.g. "1.1.1.1") into NetworkManager uint32 representation.
func IPToUint32(ipStr string) (uint32, error) {
	ip := net.ParseIP(ipStr).To4()
	if ip == nil {
		return 0, fmt.Errorf("invalid IPv4 address: %s", ipStr)
	}
	return binary.NativeEndian.Uint32(ip), nil
}

// Uint32ToIP converts a NetworkManager uint32 IPv4 address into a human-readable string.
func Uint32ToIP(val uint32) string {
	ip := make(net.IP, 4)
	binary.NativeEndian.PutUint32(ip, val)
	return ip.String()
}

// FrequencyToChannel maps Wi-Fi frequency (MHz) to channel number.
func FrequencyToChannel(freq uint32) int {
	if freq >= 2412 && freq <= 2484 {
		if freq == 2484 {
			return 14
		}
		return int((freq-2412)/5 + 1)
	} else if freq >= 5170 && freq <= 5825 {
		return int((freq - 5000) / 5)
	} else if freq >= 5955 && freq <= 7115 {
		return int((freq - 5950) / 5)
	}
	return 0
}

// FrequencyToBand categorizes a Wi-Fi frequency into standard bands.
func FrequencyToBand(freq uint32) string {
	if freq >= 2400 && freq < 2500 {
		return "2.4GHz"
	} else if freq >= 5000 && freq < 5900 {
		return "5GHz"
	} else if freq >= 5925 && freq < 7200 {
		return "6GHz"
	}
	return "Unknown"
}

// ParseSecurityFlags detects the security standard from NM 80211 AP flags.
// NM_802_11_AP_FLAGS_PRIVACY = 0x1
// NM_802_11_AP_SEC_KEY_MGMT_PSK = 0x4
// NM_802_11_AP_SEC_KEY_MGMT_802_1X = 0x8
// NM_802_11_AP_SEC_KEY_MGMT_SAE = 0x400
func ParseSecurityFlags(flags, wpaFlags, rsnFlags uint32) SecurityType {
	if rsnFlags&0x400 != 0 {
		return SecurityWPA3SAE
	}
	if rsnFlags&0x4 != 0 {
		return SecurityWPA2PSK
	}
	if rsnFlags&0x8 != 0 || wpaFlags&0x8 != 0 {
		return SecurityWPAEAP
	}
	if wpaFlags&0x4 != 0 {
		return SecurityWPAPSK
	}
	if flags&0x1 != 0 {
		return SecurityWEP
	}
	return SecurityOpen
}
