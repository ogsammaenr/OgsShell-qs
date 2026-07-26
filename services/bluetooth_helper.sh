#!/bin/bash
# Scan for bluetooth devices and list them with statuses (MAC|Name|Paired|Trusted|Connected)

# 1. Output already known/paired/discovered devices instantly
bluetoothctl devices | while read -r _ mac name; do
    echo -n "$mac|$name|"
    bluetoothctl info "$mac" 2>/dev/null | grep -E "Paired:|Connected:|Trusted:" | tr '\n' '|'
    echo ""
done

# 2. Run scan for 4 seconds to discover new devices
bluetoothctl --timeout 4 scan on >/dev/null 2>&1

# 3. Output the updated devices list (known + newly discovered)
bluetoothctl devices | while read -r _ mac name; do
    echo -n "$mac|$name|"
    bluetoothctl info "$mac" 2>/dev/null | grep -E "Paired:|Connected:|Trusted:" | tr '\n' '|'
    echo ""
done
