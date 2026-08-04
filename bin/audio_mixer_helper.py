#!/usr/bin/env python3
import sys
import os
import json
import subprocess

STATE_FILE = os.path.expanduser("~/.config/ogsshell/state/audio_device")

def get_media_player_inputs(inputs_json=None):
    if inputs_json is None:
        try:
            raw = subprocess.check_output(["pactl", "-f", "json", "list", "sink-inputs"], text=True)
            inputs_json = json.loads(raw)
        except Exception:
            inputs_json = []

    player_name = ""
    try:
        player_name = subprocess.check_output(["playerctl", "-f", "{{playerName}}", "metadata"], text=True).strip().lower()
    except Exception:
        pass

    matched_inputs = []
    if player_name:
        for inp in inputs_json:
            props = inp.get("properties", {})
            app_name = props.get("application.name", "").lower()
            binary_name = props.get("application.process.binary", "").lower()
            node_name = props.get("node.name", "").lower()
            
            if (player_name in app_name or app_name in player_name or
                player_name in binary_name or binary_name in player_name or
                player_name in node_name or node_name in player_name):
                matched_inputs.append(inp)

    if not matched_inputs and inputs_json:
        for inp in inputs_json:
            if not inp.get("corked", False):
                matched_inputs.append(inp)
                break
        if not matched_inputs:
            matched_inputs = [inputs_json[0]]

    vol_pct = 100
    is_mute = False
    if matched_inputs:
        inp = matched_inputs[0]
        is_mute = inp.get("mute", False)
        if "volume" in inp and isinstance(inp["volume"], dict):
            for ch in inp["volume"].values():
                if isinstance(ch, dict) and "value_percent" in ch:
                    v_str = ch["value_percent"].replace("%", "").strip()
                    try:
                        vol_pct = int(v_str)
                        break
                    except Exception:
                        pass

    return {
        "found": len(matched_inputs) > 0,
        "player_name": player_name,
        "indices": [i.get("index") for i in matched_inputs if i.get("index") is not None],
        "volume": vol_pct,
        "mute": is_mute
    }

def get_audio_info():
    def_sink = ""
    try:
        def_sink = subprocess.check_output(["pactl", "get-default-sink"], text=True).strip()
    except Exception:
        pass

    sinks_json = []
    try:
        raw = subprocess.check_output(["pactl", "-f", "json", "list", "sinks"], text=True)
        sinks_json = json.loads(raw)
    except Exception:
        pass

    apps_json = []
    try:
        raw = subprocess.check_output(["pactl", "-f", "json", "list", "sink-inputs"], text=True)
        apps_json = json.loads(raw)
    except Exception:
        pass

    sinks = []
    for s in sinks_json:
        vol_pct = 0
        if "volume" in s and isinstance(s["volume"], dict):
            for ch in s["volume"].values():
                if isinstance(ch, dict) and "value_percent" in ch:
                    v_str = ch["value_percent"].replace("%", "").strip()
                    try:
                        vol_pct = int(v_str)
                        break
                    except Exception:
                        pass
        
        sink_name = s.get("name", "")
        desc = s.get("description", "")
        if not desc:
            desc = s.get("properties", {}).get("device.description", sink_name)
            
        sinks.append({
            "index": s.get("index", 0),
            "name": sink_name,
            "description": desc,
            "volume": vol_pct,
            "mute": s.get("mute", False),
            "is_default": (sink_name == def_sink)
        })

    apps = []
    for a in apps_json:
        vol_pct = 0
        if "volume" in a and isinstance(a["volume"], dict):
            for ch in a["volume"].values():
                if isinstance(ch, dict) and "value_percent" in ch:
                    v_str = ch["value_percent"].replace("%", "").strip()
                    try:
                        vol_pct = int(v_str)
                        break
                    except Exception:
                        pass

        props = a.get("properties", {})
        app_name = props.get("application.name", props.get("node.name", "Application"))
        media_name = props.get("media.name", "")
        if media_name == "(null)":
            media_name = ""

        apps.append({
            "index": a.get("index", 0),
            "name": app_name,
            "media_name": media_name,
            "volume": vol_pct,
            "mute": a.get("mute", False)
        })

    media_info = get_media_player_inputs(apps_json)

    return {
        "default_sink": def_sink,
        "sinks": sinks,
        "apps": apps,
        "media_player": media_info
    }

def set_default_sink(sink_name):
    if not sink_name:
        return
    subprocess.run(["pactl", "set-default-sink", sink_name], check=False)
    
    try:
        raw_inputs = subprocess.check_output(["pactl", "-f", "json", "list", "sink-inputs"], text=True)
        inputs_json = json.loads(raw_inputs)
        for inp in inputs_json:
            idx = str(inp.get("index"))
            if idx:
                subprocess.run(["pactl", "move-sink-input", idx, sink_name], check=False)
    except Exception:
        pass

    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    try:
        with open(STATE_FILE, "w") as f:
            f.write(sink_name + "\n")
    except Exception:
        pass

def restore_saved_sink():
    if not os.path.exists(STATE_FILE):
        return
    try:
        with open(STATE_FILE, "r") as f:
            saved_sink = f.read().strip()
        if saved_sink:
            raw = subprocess.check_output(["pactl", "-f", "json", "list", "sinks"], text=True)
            sinks_json = json.loads(raw)
            valid_names = [s.get("name") for s in sinks_json]
            if saved_sink in valid_names:
                set_default_sink(saved_sink)
    except Exception:
        pass

def set_sink_volume(sink_target, pct):
    try:
        vol = max(0, min(100, int(pct)))
        subprocess.run(["pactl", "set-sink-volume", str(sink_target), f"{vol}%"], check=False)
    except Exception:
        pass

def set_sink_mute(sink_target):
    try:
        subprocess.run(["pactl", "set-sink-mute", str(sink_target), "toggle"], check=False)
    except Exception:
        pass

def set_app_volume(app_index, pct):
    try:
        vol = max(0, min(100, int(pct)))
        subprocess.run(["pactl", "set-sink-input-volume", str(app_index), f"{vol}%"], check=False)
    except Exception:
        pass

def set_app_mute(app_index):
    try:
        subprocess.run(["pactl", "set-sink-input-mute", str(app_index), "toggle"], check=False)
    except Exception:
        pass

def set_media_volume(pct):
    try:
        vol = max(0, min(100, int(pct)))
        media_info = get_media_player_inputs()
        indices = media_info.get("indices", [])
        for idx in indices:
            subprocess.run(["pactl", "set-sink-input-volume", str(idx), f"{vol}%"], check=False)
    except Exception:
        pass

def set_media_mute():
    try:
        media_info = get_media_player_inputs()
        indices = media_info.get("indices", [])
        for idx in indices:
            subprocess.run(["pactl", "set-sink-input-mute", str(idx), "toggle"], check=False)
    except Exception:
        pass

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "--json":
        print(json.dumps(get_audio_info()))
    elif sys.argv[1] == "--set-default" and len(sys.argv) >= 3:
        set_default_sink(sys.argv[2])
        print(json.dumps(get_audio_info()))
    elif sys.argv[1] == "--restore":
        restore_saved_sink()
        print(json.dumps(get_audio_info()))
    elif sys.argv[1] == "--set-sink-vol" and len(sys.argv) >= 4:
        set_sink_volume(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "--set-sink-mute" and len(sys.argv) >= 3:
        set_sink_mute(sys.argv[2])
    elif sys.argv[1] == "--set-app-vol" and len(sys.argv) >= 4:
        set_app_volume(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "--set-app-mute" and len(sys.argv) >= 3:
        set_app_mute(sys.argv[2])
    elif sys.argv[1] == "--set-media-vol" and len(sys.argv) >= 3:
        set_media_volume(sys.argv[2])
    elif sys.argv[1] == "--set-media-mute":
        set_media_mute()

if __name__ == "__main__":
    main()
