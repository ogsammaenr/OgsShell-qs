import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../../.."

Item {
  id: root

  property var ipc
  signal backRequested()

  property int activeTab: 0 // 0: Uygulamalar (Apps), 1: Çıkış Cihazları (Sinks)
  property bool isLoading: false
  property bool isDragging: false
  property string activeDragKey: ""
  property bool pendingRefreshAfterDrag: false

  // Mutation generation counters & per-target edit protection to block stale poll overwrites
  property int streamMutationGen: 0
  property int sinkMutationGen: 0
  property int fetchStreamsGen: 0
  property int fetchSinksGen: 0
  property var recentEdits: ({})
  property var pendingVols: ({})
  property var streamGroupIds: ({})
  property var cmdQueue: []
  property string activeCmdKey: ""

  property string streamsAccum: ""
  property string sinksAccum: ""

  // Persistent ListModels keep ListView delegates & scroll position (contentY) intact across refreshes
  ListModel { id: streamsModel }
  ListModel { id: sinksModel }

  // Helper Python scripts for fast and robust JSON parsing from pactl
  readonly property string getStreamsCmd: "import subprocess, json\n" +
    "def parse_vol(vdict):\n" +
    "    vals = []\n" +
    "    for vinfo in (vdict or {}).values():\n" +
    "        if isinstance(vinfo, dict) and 'value_percent' in vinfo:\n" +
    "            try:\n" +
    "                vals.append(int(vinfo['value_percent'].strip().replace('%', '')))\n" +
    "            except Exception:\n" +
    "                pass\n" +
    "    return round(sum(vals) / len(vals)) if vals else 50\n" +
    "try:\n" +
    "    res = subprocess.run(['pactl', '--format=json', 'list', 'sink-inputs'], capture_output=True, text=True)\n" +
    "    txt = res.stdout.strip()\n" +
    "    idx = txt.find('[')\n" +
    "    if idx != -1: txt = txt[idx:]\n" +
    "    data = json.loads(txt)\n" +
    "    groups = {}\n" +
    "    for item in data:\n" +
    "        props = item.get('properties', {})\n" +
    "        sid = int(item.get('index', 0))\n" +
    "        app_name = (props.get('application.name') or props.get('node.name') or props.get('media.name') or 'Uygulama').strip()\n" +
    "        raw_group = (props.get('application.name') or props.get('application.process.binary') or props.get('node.name') or '').strip().lower()\n" +
    "        gkey = ('app:' + raw_group) if raw_group else ('stream:' + str(sid))\n" +
    "        icon = props.get('application.icon_name', '') or ''\n" +
    "        media = (props.get('media.name') or '').strip()\n" +
    "        vol = parse_vol(item.get('volume', {}))\n" +
    "        mute = bool(item.get('mute', False))\n" +
    "        corked = bool(item.get('corked', False))\n" +
    "        if gkey not in groups:\n" +
    "            groups[gkey] = {'key': gkey, 'name': app_name, 'icon': icon, 'items': []}\n" +
    "        grp = groups[gkey]\n" +
    "        if not grp['icon'] and icon:\n" +
    "            grp['icon'] = icon\n" +
    "        grp['items'].append({'id': sid, 'media': media, 'vol': vol, 'mute': mute, 'corked': corked})\n" +
    "    streams = []\n" +
    "    for grp in groups.values():\n" +
    "        items = sorted(grp['items'], key=lambda x: x['id'])\n" +
    "        active = [x for x in items if not x['corked']]\n" +
    "        primary = active if active else items\n" +
    "        rep_vol = round(sum(x['vol'] for x in primary) / len(primary))\n" +
    "        rep_mute = all(x['mute'] for x in primary)\n" +
    "        rep_media = next((x['media'] for x in primary if x['media'] and x['media'] != '(null)'), '')\n" +
    "        if not rep_media:\n" +
    "            rep_media = next((x['media'] for x in items if x['media'] and x['media'] != '(null)'), '')\n" +
    "        streams.append({'key': grp['key'], 'id': items[0]['id'], 'stream_ids': [x['id'] for x in items], 'name': grp['name'], 'media': rep_media, 'icon': grp['icon'], 'volume': rep_vol, 'mute': rep_mute})\n" +
    "    streams.sort(key=lambda x: x['id'])\n" +
    "    print(json.dumps(streams))\n" +
    "except Exception:\n" +
    "    print('[]')"

  readonly property string getSinksCmd: "import subprocess, json\n" +
    "def parse_vol(vdict):\n" +
    "    vals = []\n" +
    "    for vinfo in (vdict or {}).values():\n" +
    "        if isinstance(vinfo, dict) and 'value_percent' in vinfo:\n" +
    "            try:\n" +
    "                vals.append(int(vinfo['value_percent'].strip().replace('%', '')))\n" +
    "            except Exception:\n" +
    "                pass\n" +
    "    return round(sum(vals) / len(vals)) if vals else 50\n" +
    "try:\n" +
    "    def_res = subprocess.run(['pactl', 'get-default-sink'], capture_output=True, text=True)\n" +
    "    def_sink = def_res.stdout.strip()\n" +
    "    res = subprocess.run(['pactl', '--format=json', 'list', 'sinks'], capture_output=True, text=True)\n" +
    "    txt = res.stdout.strip()\n" +
    "    idx = txt.find('[')\n" +
    "    if idx != -1: txt = txt[idx:]\n" +
    "    data = json.loads(txt)\n" +
    "    sinks = []\n" +
    "    for item in data:\n" +
    "        sid = int(item.get('index', 0))\n" +
    "        name = item.get('name', '')\n" +
    "        desc = item.get('description', name)\n" +
    "        active_port = item.get('active_port', '') or ''\n" +
    "        sinks.append({'key': 'sink:' + str(sid), 'id': sid, 'name': name, 'description': desc, 'volume': parse_vol(item.get('volume', {})), 'mute': bool(item.get('mute', False)), 'port': active_port, 'is_default': (name == def_sink)})\n" +
    "    sinks.sort(key=lambda x: x['id'])\n" +
    "    print(json.dumps(sinks))\n" +
    "except Exception:\n" +
    "    print('[]')"

  // =========================================================================
  // Background Process Runners
  // =========================================================================
  Process {
    id: fetchStreamsProc
    command: ["python3", "-c", root.getStreamsCmd]
    stdout: SplitParser {
      onRead: data => {
        root.streamsAccum += data
      }
    }
    onExited: (exitCode, exitStatus) => {
      let raw = root.streamsAccum.trim()
      root.streamsAccum = ""
      root.updateLoadingState()
      if (exitCode !== 0 || raw.length === 0) return
      if (root.isDragging) {
        root.pendingRefreshAfterDrag = true
        return
      }
      try {
        let list = JSON.parse(raw)
        if (Array.isArray(list)) {
          root.reconcileModel(streamsModel, list, true, root.fetchStreamsGen === root.streamMutationGen)
        }
      } catch (e) {}
    }
  }

  Process {
    id: fetchSinksProc
    command: ["python3", "-c", root.getSinksCmd]
    stdout: SplitParser {
      onRead: data => {
        root.sinksAccum += data
      }
    }
    onExited: (exitCode, exitStatus) => {
      let raw = root.sinksAccum.trim()
      root.sinksAccum = ""
      root.updateLoadingState()
      if (exitCode !== 0 || raw.length === 0) return
      if (root.isDragging) {
        root.pendingRefreshAfterDrag = true
        return
      }
      try {
        let list = JSON.parse(raw)
        if (Array.isArray(list)) {
          root.reconcileModel(sinksModel, list, false, root.fetchSinksGen === root.sinkMutationGen)
        }
      } catch (e) {}
    }
  }

  // Sequential non-interrupting command executor (never SIGTERMs an in-flight pactl command)
  Process {
    id: controlCmdProc
    onExited: (exitCode, exitStatus) => {
      root.activeCmdKey = ""
      root.dispatchNextControlCmd()
    }
  }

  Timer {
    id: volThrottleTimer
    interval: 35
    repeat: false
    onTriggered: root.dispatchPendingVolumes()
  }

  // Gentle post-command confirmation refresh after queue drains
  Timer {
    id: postCommandSyncTimer
    interval: 450
    repeat: false
    onTriggered: {
      if (!root.isDragging && root.cmdQueue.length === 0 && !controlCmdProc.running) {
        root.refreshAudio()
      }
    }
  }

  function updateLoadingState() {
    root.isLoading = fetchStreamsProc.running || fetchSinksProc.running
  }

  function refreshAudio() {
    if (root.isDragging) {
      root.pendingRefreshAfterDrag = true
      return
    }
    if (!fetchStreamsProc.running) {
      root.streamsAccum = ""
      root.fetchStreamsGen = root.streamMutationGen
      fetchStreamsProc.running = true
    }
    if (!fetchSinksProc.running) {
      root.sinksAccum = ""
      root.fetchSinksGen = root.sinkMutationGen
      fetchSinksProc.running = true
    }
    root.updateLoadingState()
  }

  function hasPendingCmdFor(isStream, itemKey) {
    let prefix = isStream ? "stream" : "sink"
    let volKey = prefix + "_vol:" + itemKey
    let muteKey = prefix + "_mute:" + itemKey
    if (root.pendingVols[volKey] !== undefined) return true
    if (root.activeCmdKey === volKey || root.activeCmdKey === muteKey) return true
    for (let i = 0; i < root.cmdQueue.length; i++) {
      let k = root.cmdQueue[i].key
      if (k === volKey || k === muteKey) return true
    }
    return false
  }

  function isItemLocked(isStream, itemKey, nowMs) {
    if (root.isDragging && root.activeDragKey === itemKey) return true
    if (hasPendingCmdFor(isStream, itemKey)) return true
    let ts = root.recentEdits[itemKey]
    return ts !== undefined && (nowMs - ts) < 850
  }

  function resolveItemKey(item, isStream) {
    if (item && item.key) return String(item.key)
    return (isStream ? "stream:" : "sink:") + Number(item.id)
  }

  function toModelEntry(item, isStream) {
    let itemKey = resolveItemKey(item, isStream)
    if (isStream) {
      let ids = Array.isArray(item.stream_ids) ? item.stream_ids : [Number(item.id)]
      return {
        "itemKey": itemKey,
        "itemId": Number(item.id),
        "itemStreamCount": Number(ids.length),
        "itemName": String(item.name || "Uygulama"),
        "itemMedia": String(item.media || ""),
        "itemIcon": String(item.icon || ""),
        "itemVolume": Number(item.volume !== undefined ? item.volume : 50),
        "itemMute": Boolean(item.mute)
      }
    }
    return {
      "itemKey": itemKey,
      "itemId": Number(item.id),
      "itemName": String(item.name || ""),
      "itemDesc": String(item.description || item.name || "Çıkış Aygıtı"),
      "itemPort": String(item.port || ""),
      "itemVolume": Number(item.volume !== undefined ? item.volume : 50),
      "itemMute": Boolean(item.mute),
      "itemIsDefault": Boolean(item.is_default)
    }
  }

  function reconcileModel(model, incomingList, isStream, genMatches) {
    if (incomingList.length === 0) {
      if (model.count > 0) model.clear()
      if (isStream) root.streamGroupIds = ({})
      return
    }

    let nowMs = Date.now()
    let incomingKeys = {}
    let nextGroupIds = isStream ? {} : null
    for (let i = 0; i < incomingList.length; i++) {
      let rawItem = incomingList[i]
      let k = resolveItemKey(rawItem, isStream)
      incomingKeys[k] = true
      if (isStream) {
        let rawIds = Array.isArray(rawItem.stream_ids) ? rawItem.stream_ids : [Number(rawItem.id)]
        nextGroupIds[k] = rawIds.map(x => Number(x))
      }
    }
    if (isStream) {
      root.streamGroupIds = nextGroupIds
    }

    // 1. Remove items that no longer exist
    for (let r = model.count - 1; r >= 0; r--) {
      if (!incomingKeys[model.get(r).itemKey]) {
        model.remove(r, 1)
      }
    }

    // 2. Insert new items and update existing rows in-place (preserving scroll position & delegates)
    for (let targetIdx = 0; targetIdx < incomingList.length; targetIdx++) {
      let entry = toModelEntry(incomingList[targetIdx], isStream)
      let curIdx = -1
      for (let j = 0; j < model.count; j++) {
        if (model.get(j).itemKey === entry.itemKey) {
          curIdx = j
          break
        }
      }

      if (curIdx === -1) {
        model.insert(targetIdx, entry)
        continue
      }

      if (curIdx !== targetIdx) {
        model.move(curIdx, targetIdx, 1)
      }

      let row = model.get(targetIdx)
      if (isStream) {
        if (row.itemId !== entry.itemId) model.setProperty(targetIdx, "itemId", entry.itemId)
        if (row.itemStreamCount !== entry.itemStreamCount) model.setProperty(targetIdx, "itemStreamCount", entry.itemStreamCount)
        if (row.itemName !== entry.itemName) model.setProperty(targetIdx, "itemName", entry.itemName)
        if (row.itemMedia !== entry.itemMedia) model.setProperty(targetIdx, "itemMedia", entry.itemMedia)
        if (row.itemIcon !== entry.itemIcon) model.setProperty(targetIdx, "itemIcon", entry.itemIcon)
      } else {
        if (row.itemName !== entry.itemName) model.setProperty(targetIdx, "itemName", entry.itemName)
        if (row.itemDesc !== entry.itemDesc) model.setProperty(targetIdx, "itemDesc", entry.itemDesc)
        if (row.itemPort !== entry.itemPort) model.setProperty(targetIdx, "itemPort", entry.itemPort)
        let lockDef = root.recentEdits["default_sink"] !== undefined && (nowMs - root.recentEdits["default_sink"]) < 850
        if (!lockDef && row.itemIsDefault !== entry.itemIsDefault) {
          model.setProperty(targetIdx, "itemIsDefault", entry.itemIsDefault)
        }
      }

      if (genMatches && !root.isItemLocked(isStream, entry.itemKey, nowMs)) {
        if (row.itemVolume !== entry.itemVolume) model.setProperty(targetIdx, "itemVolume", entry.itemVolume)
        if (row.itemMute !== entry.itemMute) model.setProperty(targetIdx, "itemMute", entry.itemMute)
      }
    }
  }

  function updateLocalRow(model, itemKey, fields) {
    for (let i = 0; i < model.count; i++) {
      if (model.get(i).itemKey === itemKey) {
        for (let prop in fields) {
          model.setProperty(i, prop, fields[prop])
        }
        return
      }
    }
  }

  function buildControlCmd(isStream, itemKey, itemId, isMuteCmd, valueArg) {
    if (isStream) {
      let pactlSubCmd = isMuteCmd ? "set-sink-input-mute" : "set-sink-input-volume"
      let ids = root.streamGroupIds[itemKey]
      if (!ids || ids.length === 0) ids = [itemId]
      if (ids.length === 1) {
        return ["pactl", pactlSubCmd, "" + ids[0], "" + valueArg]
      }
      let args = ["/bin/sh", "-c", "val=\"$1\"; shift; for id in \"$@\"; do pactl " + pactlSubCmd + " \"$id\" \"$val\" >/dev/null 2>&1 || true; done", "_", "" + valueArg]
      for (let i = 0; i < ids.length; i++) {
        args.push("" + ids[i])
      }
      return args
    }
    let pactlSinkCmd = isMuteCmd ? "set-sink-mute" : "set-sink-volume"
    return ["pactl", pactlSinkCmd, "" + itemId, "" + valueArg]
  }

  function enqueueControlCmd(key, cmd) {
    let queue = root.cmdQueue.slice()
    let replaced = false
    for (let i = 0; i < queue.length; i++) {
      if (queue[i].key === key) {
        queue[i] = { "key": key, "cmd": cmd }
        replaced = true
        break
      }
    }
    if (!replaced) {
      queue.push({ "key": key, "cmd": cmd })
    }
    root.cmdQueue = queue
    if (!controlCmdProc.running) {
      root.dispatchNextControlCmd()
    }
  }

  function dispatchNextControlCmd() {
    if (controlCmdProc.running) return
    if (root.cmdQueue.length === 0) {
      postCommandSyncTimer.restart()
      return
    }
    let next = root.cmdQueue[0]
    root.cmdQueue = root.cmdQueue.slice(1)
    root.activeCmdKey = next.key
    controlCmdProc.command = next.cmd
    controlCmdProc.running = true
  }

  function setItemVolume(isStream, itemKey, itemId, targetVol, immediate) {
    let vol = Math.max(0, Math.min(Config.audioMaxVolume, Math.round(targetVol)))
    let model = isStream ? streamsModel : sinksModel
    let prefix = isStream ? "stream" : "sink"
    let volKey = prefix + "_vol:" + itemKey

    root.recentEdits[itemKey] = Date.now()
    if (isStream) root.streamMutationGen++
    else root.sinkMutationGen++

    root.updateLocalRow(model, itemKey, { "itemVolume": vol })

    if (immediate) {
      let pending = Object.assign({}, root.pendingVols)
      delete pending[volKey]
      root.pendingVols = pending
      root.enqueueControlCmd(volKey, root.buildControlCmd(isStream, itemKey, itemId, false, "" + vol + "%"))
      return
    }

    let pending = Object.assign({}, root.pendingVols)
    pending[volKey] = { "isStream": isStream, "key": itemKey, "id": itemId, "vol": vol }
    root.pendingVols = pending
    if (!volThrottleTimer.running) {
      volThrottleTimer.restart()
    }
  }

  function flushTargetVolume(isStream, itemKey) {
    let prefix = isStream ? "stream" : "sink"
    let volKey = prefix + "_vol:" + itemKey
    root.recentEdits[itemKey] = Date.now()
    let entry = root.pendingVols[volKey]
    if (entry !== undefined) {
      let pending = Object.assign({}, root.pendingVols)
      delete pending[volKey]
      root.pendingVols = pending
      if (Object.keys(pending).length === 0) {
        volThrottleTimer.stop()
      }
      root.enqueueControlCmd(volKey, root.buildControlCmd(entry.isStream, entry.key, entry.id, false, "" + entry.vol + "%"))
    }
    if (root.pendingRefreshAfterDrag && !root.isDragging) {
      root.pendingRefreshAfterDrag = false
      postCommandSyncTimer.restart()
    }
  }

  function dispatchPendingVolumes() {
    let keys = Object.keys(root.pendingVols)
    if (keys.length === 0) return
    let pending = root.pendingVols
    root.pendingVols = {}
    for (let i = 0; i < keys.length; i++) {
      let k = keys[i]
      let entry = pending[k]
      root.enqueueControlCmd(k, root.buildControlCmd(entry.isStream, entry.key, entry.id, false, "" + entry.vol + "%"))
    }
  }

  function toggleItemMute(isStream, itemKey, itemId, currentMute) {
    let nextMute = !currentMute
    let model = isStream ? streamsModel : sinksModel
    let prefix = isStream ? "stream" : "sink"
    let muteKey = prefix + "_mute:" + itemKey

    root.recentEdits[itemKey] = Date.now()
    if (isStream) root.streamMutationGen++
    else root.sinkMutationGen++

    root.updateLocalRow(model, itemKey, { "itemMute": nextMute })
    root.enqueueControlCmd(muteKey, root.buildControlCmd(isStream, itemKey, itemId, true, nextMute ? "1" : "0"))
  }

  function setDefaultSink(sinkName, sinkId) {
    root.recentEdits["default_sink"] = Date.now()
    root.sinkMutationGen++
    for (let i = 0; i < sinksModel.count; i++) {
      sinksModel.setProperty(i, "itemIsDefault", sinksModel.get(i).itemId === sinkId)
    }
    root.enqueueControlCmd("default_sink", ["pactl", "set-default-sink", "" + (sinkName || sinkId)])
  }

  function getAppGlyph(name) {
    let n = (name || "").toLowerCase()
    if (n.includes("firefox") || n.includes("zen") || n.includes("librewolf") || n.includes("browser")) return "󰖟"
    if (n.includes("spotify")) return "󰓇"
    if (n.includes("discord") || n.includes("vesktop") || n.includes("vencord")) return "󰙯"
    if (n.includes("chromium") || n.includes("chrome") || n.includes("brave")) return "󰊯"
    if (n.includes("steam") || n.includes("game") || n.includes("wine") || n.includes("proton")) return "󰊴"
    if (n.includes("vlc") || n.includes("mpv") || n.includes("player") || n.includes("video")) return "󰕼"
    if (n.includes("telegram")) return "󰀨"
    return "󰎆"
  }

  function getSinkGlyph(name, desc, port) {
    let s = (name + " " + desc + " " + port).toLowerCase()
    if (s.includes("headphone") || s.includes("headset") || s.includes("kulaklık")) return "󰋋"
    if (s.includes("hdmi") || s.includes("displayport") || s.includes("dp")) return "󰡁"
    if (s.includes("usb") || s.includes("dac")) return "󱡬"
    return "󰓃"
  }

  Component.onCompleted: {
    refreshAudio()
  }

  onVisibleChanged: {
    if (visible) refreshAudio()
  }

  // Periodic poll timer while view is open
  Timer {
    id: pollTimer
    interval: 1800
    repeat: true
    running: root.visible
    onTriggered: refreshAudio()
  }

  // =========================================================================
  // Main Layout
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    spacing: 8

    // -----------------------------------------------------------------------
    // 1. Header Bar: Navigation, Title & Refresh Action
    // -----------------------------------------------------------------------
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      // Back Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: backHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant
        border.color: backHover.containsMouse ? Style.borderHover : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "󰁍"
          font.pixelSize: 13
          color: Style.textPrimary
        }

        MouseArea {
          id: backHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.backRequested()
        }
      }

      // Title & Badge
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
          width: 24
          height: 24
          radius: 6
          color: Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.16)

          Text {
            anchors.centerIn: parent
            text: "󰓃"
            font.pixelSize: 14
            color: Style.accent
          }
        }

        Text {
          text: "Ses Karıştırıcısı"
          font.pixelSize: 13
          font.weight: Font.Bold
          color: Style.textPrimary
        }
      }

      // Refresh Button
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: refHover.containsMouse ? Style.surfaceHover : Style.surfaceVariant
        border.color: refHover.containsMouse ? Style.borderHover : Style.border
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "󰑐"
          font.pixelSize: 13
          color: root.isLoading ? Style.accent : Style.textPrimary

          RotationAnimation on rotation {
            running: root.isLoading
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 800
          }
        }

        MouseArea {
          id: refHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.refreshAudio()
        }
      }
    }

    // -----------------------------------------------------------------------
    // 2. Apple Segmented Pill Tab Bar (Uygulamalar / Çıkış Cihazları)
    // -----------------------------------------------------------------------
    Rectangle {
      Layout.fillWidth: true
      height: 30
      radius: 8
      color: Style.surfaceVariant
      border.color: Style.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2

        // Tab 0: Uygulamalar
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: root.activeTab === 0 ? Style.surfaceActive : "transparent"
          border.color: root.activeTab === 0 ? Style.borderHover : "transparent"
          border.width: root.activeTab === 0 ? 1 : 0

          Behavior on color { ColorAnimation { duration: 150 } }

          Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Uygulamalar"
              font.pixelSize: 11
              font.weight: root.activeTab === 0 ? Font.Bold : Font.Normal
              color: root.activeTab === 0 ? Style.textPrimary : Style.textMuted
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: appBadgeTxt.implicitWidth + 8
              height: 14
              radius: 7
              color: root.activeTab === 0 ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.25) : Style.surface
              visible: streamsModel.count > 0

              Text {
                id: appBadgeTxt
                anchors.centerIn: parent
                text: "" + streamsModel.count
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: root.activeTab === 0 ? Style.accent : Style.textMuted
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activeTab = 0
          }
        }

        // Tab 1: Çıkış Cihazları
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: root.activeTab === 1 ? Style.surfaceActive : "transparent"
          border.color: root.activeTab === 1 ? Style.borderHover : "transparent"
          border.width: root.activeTab === 1 ? 1 : 0

          Behavior on color { ColorAnimation { duration: 150 } }

          Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Çıkış Aygıtları"
              font.pixelSize: 11
              font.weight: root.activeTab === 1 ? Font.Bold : Font.Normal
              color: root.activeTab === 1 ? Style.textPrimary : Style.textMuted
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: sinkBadgeTxt.implicitWidth + 8
              height: 14
              radius: 7
              color: root.activeTab === 1 ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.25) : Style.surface
              visible: sinksModel.count > 0

              Text {
                id: sinkBadgeTxt
                anchors.centerIn: parent
                text: "" + sinksModel.count
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: root.activeTab === 1 ? Style.accent : Style.textMuted
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activeTab = 1
          }
        }
      }
    }

    // -----------------------------------------------------------------------
    // 3. Tab Content View
    // -----------------------------------------------------------------------
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      // =====================================================================
      // VIEW 1: Active Application Streams
      // =====================================================================
      Item {
        anchors.fill: parent
        visible: root.activeTab === 0

        // Empty State: No active audio streams
        ColumnLayout {
          anchors.centerIn: parent
          visible: streamsModel.count === 0
          spacing: 8

          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 44
            radius: 22
            color: Style.surfaceVariant
            border.color: Style.border
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "󰎆"
              font.pixelSize: 20
              color: Style.textMuted
            }
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Aktif ses akışı yok"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.textPrimary
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bir müzik, video veya oyun sesi başlatın"
            font.pixelSize: 10
            color: Style.textMuted
          }
        }

        // Active Streams List
        ListView {
          id: streamsList
          anchors.fill: parent
          visible: streamsModel.count > 0
          model: streamsModel
          clip: true
          spacing: 6
          interactive: !root.isDragging
          boundsBehavior: Flickable.StopAtBounds
          highlightFollowsCurrentItem: false

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 3
            interactive: false
            contentItem: Rectangle {
              implicitWidth: 3
              radius: 2
              color: Style.textMuted
              opacity: 0.45
            }
          }

          delegate: Rectangle {
            id: streamDelegateItem
            width: streamsList.width
            height: 64
            radius: 10
            color: Style.surfaceVariant
            border.color: Style.border
            border.width: 1

            readonly property string rowKey: model.itemKey
            readonly property int rowId: model.itemId
            readonly property int rowStreamCount: model.itemStreamCount
            readonly property string rowName: model.itemName
            readonly property string rowMedia: model.itemMedia
            readonly property int rowVol: model.itemVolume
            readonly property bool rowMute: model.itemMute

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 8
              spacing: 4

              // Stream Title Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App Glyph Badge
                Rectangle {
                  width: 22
                  height: 22
                  radius: 5
                  color: Style.surface

                  Text {
                    anchors.centerIn: parent
                    text: root.getAppGlyph(streamDelegateItem.rowName)
                    font.pixelSize: 13
                    color: Style.accent
                  }
                }

                // App Name & Subtitle
                Column {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    width: parent.width
                    text: streamDelegateItem.rowName || "Uygulama"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Style.textPrimary
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: {
                      let mediaTxt = (streamDelegateItem.rowMedia && streamDelegateItem.rowMedia !== "(null)") ? streamDelegateItem.rowMedia : "Ses Akışı"
                      return streamDelegateItem.rowStreamCount > 1 ? (streamDelegateItem.rowStreamCount + " akış • " + mediaTxt) : mediaTxt
                    }
                    font.pixelSize: 9
                    color: Style.textMuted
                    elide: Text.ElideRight
                  }
                }

                // Stream Mute Toggle Button
                Rectangle {
                  width: 24
                  height: 24
                  radius: 12
                  color: streamDelegateItem.rowMute ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.20) : (streamMuteHover.containsMouse ? Style.surfaceHover : Style.surface)
                  border.color: streamDelegateItem.rowMute ? Style.accentRed : Style.border
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: streamDelegateItem.rowMute ? "󰖁" : (streamDelegateItem.rowVol > 50 ? "󰕾" : (streamDelegateItem.rowVol > 0 ? "󰖀" : "󰕿"))
                    font.pixelSize: 12
                    color: streamDelegateItem.rowMute ? Style.accentRed : Style.textPrimary
                  }

                  MouseArea {
                    id: streamMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleItemMute(true, streamDelegateItem.rowKey, streamDelegateItem.rowId, streamDelegateItem.rowMute)
                  }
                }
              }

              // Stream Volume Slider Capsule
              VolumeCapsuleSlider {
                volume: streamDelegateItem.rowVol
                muted: streamDelegateItem.rowMute
                onDragStarted: {
                  root.activeDragKey = streamDelegateItem.rowKey
                  root.isDragging = true
                }
                onVolumeEdited: newVol => root.setItemVolume(true, streamDelegateItem.rowKey, streamDelegateItem.rowId, newVol, false)
                onDragFinished: {
                  root.isDragging = false
                  root.activeDragKey = ""
                  root.flushTargetVolume(true, streamDelegateItem.rowKey)
                }
                onWheelStepped: newVol => root.setItemVolume(true, streamDelegateItem.rowKey, streamDelegateItem.rowId, newVol, true)
              }
            }
          }
        }
      }

      // =====================================================================
      // VIEW 2: Output Sinks (Devices)
      // =====================================================================
      Item {
        anchors.fill: parent
        visible: root.activeTab === 1

        ListView {
          id: sinksList
          anchors.fill: parent
          model: sinksModel
          clip: true
          spacing: 6
          interactive: !root.isDragging
          boundsBehavior: Flickable.StopAtBounds
          highlightFollowsCurrentItem: false

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 3
            interactive: false
            contentItem: Rectangle {
              implicitWidth: 3
              radius: 2
              color: Style.textMuted
              opacity: 0.45
            }
          }

          delegate: Rectangle {
            id: sinkDelegateItem
            width: sinksList.width
            height: 64
            radius: 10
            color: Style.surfaceVariant
            border.color: sinkDelegateItem.rowIsDefault ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.45) : Style.border
            border.width: 1

            readonly property string rowKey: model.itemKey
            readonly property int rowId: model.itemId
            readonly property string rowName: model.itemName
            readonly property string rowDesc: model.itemDesc
            readonly property string rowPort: model.itemPort
            readonly property int rowVol: model.itemVolume
            readonly property bool rowMute: model.itemMute
            readonly property bool rowIsDefault: model.itemIsDefault

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 8
              spacing: 4

              // Sink Device Header Row
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Device Glyph Badge
                Rectangle {
                  width: 22
                  height: 22
                  radius: 5
                  color: Style.surface

                  Text {
                    anchors.centerIn: parent
                    text: root.getSinkGlyph(sinkDelegateItem.rowName, sinkDelegateItem.rowDesc, sinkDelegateItem.rowPort)
                    font.pixelSize: 13
                    color: Style.accent
                  }
                }

                // Device Description
                Column {
                  Layout.fillWidth: true
                  spacing: 1

                  Text {
                    width: parent.width
                    text: sinkDelegateItem.rowDesc || sinkDelegateItem.rowName
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Style.textPrimary
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: sinkDelegateItem.rowPort ? ("Port: " + sinkDelegateItem.rowPort) : "Çıkış Aygıtı"
                    font.pixelSize: 9
                    color: Style.textMuted
                    elide: Text.ElideRight
                  }
                }

                // Default Sink Set Button
                Rectangle {
                  width: defaultTxt.implicitWidth + 10
                  height: 20
                  radius: 10
                  color: sinkDelegateItem.rowIsDefault
                    ? Qt.rgba(Style.accent.r, Style.accent.g, Style.accent.b, 0.18)
                    : (defaultHover.containsMouse ? Style.surfaceHover : Style.surface)
                  border.color: sinkDelegateItem.rowIsDefault ? Style.accent : Style.border
                  border.width: 1

                  Text {
                    id: defaultTxt
                    anchors.centerIn: parent
                    text: sinkDelegateItem.rowIsDefault ? "✓ Varsayılan" : "Varsayılan"
                    font.pixelSize: 9
                    font.weight: sinkDelegateItem.rowIsDefault ? Font.DemiBold : Font.Medium
                    color: sinkDelegateItem.rowIsDefault ? Style.accent : Style.textSecondary
                  }

                  MouseArea {
                    id: defaultHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setDefaultSink(sinkDelegateItem.rowName, sinkDelegateItem.rowId)
                  }
                }

                // Sink Mute Button
                Rectangle {
                  width: 24
                  height: 24
                  radius: 12
                  color: sinkDelegateItem.rowMute ? Qt.rgba(Style.accentRed.r, Style.accentRed.g, Style.accentRed.b, 0.20) : (sinkMuteHover.containsMouse ? Style.surfaceHover : Style.surface)
                  border.color: sinkDelegateItem.rowMute ? Style.accentRed : Style.border
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: sinkDelegateItem.rowMute ? "󰖁" : (sinkDelegateItem.rowVol > 50 ? "󰕾" : (sinkDelegateItem.rowVol > 0 ? "󰖀" : "󰕿"))
                    font.pixelSize: 12
                    color: sinkDelegateItem.rowMute ? Style.accentRed : Style.textPrimary
                  }

                  MouseArea {
                    id: sinkMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleItemMute(false, sinkDelegateItem.rowKey, sinkDelegateItem.rowId, sinkDelegateItem.rowMute)
                  }
                }
              }

              // Master Sink Volume Slider Capsule
              VolumeCapsuleSlider {
                volume: sinkDelegateItem.rowVol
                muted: sinkDelegateItem.rowMute
                onDragStarted: {
                  root.activeDragKey = sinkDelegateItem.rowKey
                  root.isDragging = true
                }
                onVolumeEdited: newVol => root.setItemVolume(false, sinkDelegateItem.rowKey, sinkDelegateItem.rowId, newVol, false)
                onDragFinished: {
                  root.isDragging = false
                  root.activeDragKey = ""
                  root.flushTargetVolume(false, sinkDelegateItem.rowKey)
                }
                onWheelStepped: newVol => root.setItemVolume(false, sinkDelegateItem.rowKey, sinkDelegateItem.rowId, newVol, true)
              }
            }
          }
        }
      }
    }
  }
}
