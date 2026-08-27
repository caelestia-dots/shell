pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

Singleton {
    id: root

    readonly property string _dest: "org.bbm"
    readonly property string _path: "/org/bbm"
    readonly property string _iface: "org.bbm.Manager"

    readonly property int _retryIntervalMs: 5000
    readonly property string STATUS_CHARGING: "charging"
    readonly property string WIDGET_ANC_LEVEL: "box1RadioButtonState"

    // True when the org.bbm daemon is reachable on the session bus.
    property bool available: false

    // Absolute path to the BBM icon directory (set once from GetIconPath on connect).
    property string iconBasePath: ""

    // address → flat JS object matching GetDeviceData's a{sv} keys.
    property var deviceMap: ({})

    function dataFor(address) {
        return deviceMap[address] ?? null;
    }

    // Returns a file:// URL for a battery component icon (e.g. "earbuds-stem-left").
    // The BBM convention wraps the short name: bbm-<name>-symbolic.svg
    // encodeURI handles spaces in the icon directory path.
    function batteryIconUrl(iconName) {
        if (!iconName || !iconBasePath)
            return "";
        return "file://" + encodeURI(iconBasePath + "/bbm-" + iconName + "-symbolic.svg");
    }

    // Returns a file:// URL for a toggle button icon (e.g. "bbm-anc-on-symbolic").
    // These names are already fully qualified — just append .svg.
    function toggleIconUrl(iconName) {
        if (!iconName || !iconBasePath)
            return "";
        return "file://" + encodeURI(iconBasePath + "/" + iconName + ".svg");
    }

    // Maps a BlueZ device icon name to a BBM icon name, or returns null if unknown.
    function _bluezToBbm(bluezIcon) {
        const overrideMap = {
            'phone-apple-iphone-symbolic': 'phone',
            'phone-apple-iphone': 'phone',
            'phone-google-nexus-one': 'phone',
            'phone-samsung-galaxy-s': 'phone',
        };
        if (overrideMap[bluezIcon]) return overrideMap[bluezIcon];
        const direct = [
            'audio-card', 'audio-speakers', 'audio-speakers2', 'audio-speakers3',
            'audio-headphones', 'audio-headset', 'headphone1',
            'earbuds', 'earbuds-wingtip', 'earbuds-wingtip2', 'earbuds-neckband',
            'earbuds-stem', 'earbuds-stem2', 'earbuds-stem3', 'earbuds-bean',
            'input-microphone', 'input-gaming', 'input-gaming2', 'input-gaming3',
            'input-keyboard', 'input-keyboard2', 'input-split-keyboard',
            'input-mouse', 'input-tablet', 'touchpad',
            'phone', 'multimedia-player', 'pda', 'camera-photo', 'camera-video',
            'computer', 'video-display', 'printer', 'scanner', 'modem', 'network-wireless',
            'wearable', 'wearable2',
        ];
        return direct.includes(bluezIcon) ? bluezIcon : null;
    }

    // Returns the BBM icon name for a device, respecting (in order):
    //   1. User override in services.bluetoothDeviceIcons config
    //   2. DeviceIcon reported by the BBM daemon (albumArtIcon from device config)
    //   3. BlueZ icon field mapped to the closest BBM icon name
    function _deviceIconName(address, btIconFallback) {
        const overrides = GlobalConfig.services?.bluetoothDeviceIcons ?? [];
        for (const e of overrides)
            if (e?.address === address && e?.icon)
                return e.icon;
        const data = root.deviceMap[address];
        if (data?.DeviceIcon)
            return data.DeviceIcon;
        return root._bluezToBbm(btIconFallback ?? "");
    }

    // Returns a file:// URL for the device-level icon (e.g. the whole device silhouette).
    // btIconFallback is the BlueZ device.icon field used when BBM hasn't reported a specific icon.
    function deviceIconUrl(address, btIconFallback) {
        const name = root._deviceIconName(address, btIconFallback ?? "");
        return name ? root.batteryIconUrl(name) : "";
    }

    function batteryColorForLevel(levelPercent) {
        const level = Math.max(0, Math.min(100, Number(levelPercent) || 0));
        const error = Colours.palette.m3error;
        const tertiary = Colours.palette.m3tertiary;
        const primary = Colours.palette.m3primary;
        function lerp(a, b, t) {
            return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
        }
        if (level <= 15) return error;
        if (level <= 40) return lerp(error, tertiary, (level - 15) / 25);
        return lerp(tertiary, primary, (level - 40) / 60);
    }

    function batteriesFor(bbmData) {
        if (!bbmData) return [];
        return [
            {icon: bbmData.Battery1Icon ?? "", level: bbmData.Battery1Level ?? 0, charging: (bbmData.Battery1Status ?? "") === root.STATUS_CHARGING},
            {icon: bbmData.Battery2Icon ?? "", level: bbmData.Battery2Level ?? 0, charging: (bbmData.Battery2Status ?? "") === root.STATUS_CHARGING},
            {icon: bbmData.Battery3Icon ?? "", level: bbmData.Battery3Level ?? 0, charging: (bbmData.Battery3Status ?? "") === root.STATUS_CHARGING},
        ].filter(b => b.level > 0);
    }

    function togglesFor(bbmData) {
        if (!bbmData) return [];
        return [
            {title: bbmData.Toggle1Title ?? "", buttons: bbmData.Toggle1Buttons ?? [], buttonIcons: bbmData.Toggle1ButtonIcons ?? [], state: bbmData.Toggle1State ?? 0, visible: bbmData.Toggle1Visible ?? false, widgetId: "toggle1State"},
            {title: bbmData.Toggle2Title ?? "", buttons: bbmData.Toggle2Buttons ?? [], buttonIcons: bbmData.Toggle2ButtonIcons ?? [], state: bbmData.Toggle2State ?? 0, visible: bbmData.Toggle2Visible ?? false, widgetId: "toggle2State"},
        ].filter(t => t.visible && t.buttons.length > 0);
    }

    function sendUIAction(address, widgetId, value) {
        sendActionComp.createObject(root, {
            command: ["gdbus", "call", "--session", "--dest", root._dest,
                "--object-path", root._path, "--method", `${root._iface}.SendUIAction`,
                `'${address}'`, `'${widgetId}'`, String(value)]
        }).running = true;
    }

    // ── GVariant text parsers ─────────────────────────────────────────────────

    function _parseAddressList(text) {
        const re = /'([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})'/g;
        const addrs = [];
        let m;
        while ((m = re.exec(text)) !== null)
            addrs.push(m[1]);
        return addrs;
    }

    function _parseDeviceData(text) {
        const s = text.trim();
        const result = {};
        const start = s.indexOf('{');
        const end = s.lastIndexOf('}');
        if (start < 0 || end < 0)
            return result;
        const inner = s.slice(start + 1, end);
        let pos = 0;
        while (pos < inner.length) {
            const ks = inner.indexOf("'", pos);
            if (ks < 0)
                break;
            const ke = inner.indexOf("'", ks + 1);
            if (ke < 0)
                break;
            const key = inner.slice(ks + 1, ke);
            pos = ke + 1;
            const lt = inner.indexOf('<', pos);
            if (lt < 0)
                break;
            pos = lt + 1;
            let gt;
            if (inner[pos] === '[') {
                const arrEnd = inner.indexOf(']', pos);
                gt = inner.indexOf('>', arrEnd >= 0 ? arrEnd : pos);
            } else {
                gt = inner.indexOf('>', pos);
            }
            if (gt < 0)
                break;
            const raw = inner.slice(pos, gt).trim();
            pos = gt + 1;
            if (raw.startsWith("'") && raw.endsWith("'")) {
                result[key] = raw.slice(1, -1);
            } else if (raw === 'true') {
                result[key] = true;
            } else if (raw === 'false') {
                result[key] = false;
            } else if (raw.startsWith('@') || raw === '[]') {
                result[key] = [];
            } else if (raw.startsWith('[')) {
                const content = raw.slice(1, -1).trim();
                result[key] = content
                    ? content.split(/, (?=')/).map(item => item.replace(/^'|'$/g, ''))
                    : [];
            } else {
                // GVariant type-annotated number: "int32 65", "uint32 3", "double 1.5", etc.
                const typedNum = /^(?:byte|int16|uint16|int32|uint32|int64|uint64|double|handle) (-?\d+(?:\.\d+)?)$/.exec(raw);
                if (typedNum) {
                    result[key] = Number(typedNum[1]);
                } else {
                    const n = parseInt(raw, 10);
                    result[key] = isNaN(n) ? raw : n;
                }
            }
        }
        return result;
    }

    // ── Process components ────────────────────────────────────────────────────

    // Dynamic: one instance per GetDeviceData call, self-destroys on exit.
    Component {
        id: fetchDeviceComp
        Process {
            property string addr: ""
            command: ["gdbus", "call", "--session", "--dest", root._dest,
                "--object-path", root._path, "--method", `${root._iface}.GetDeviceData`,
                `'${addr}'`]
            stdout: StdioCollector {
                onStreamFinished: {
                    const data = root._parseDeviceData(text);
                    if (data.Address) {
                        const map = Object.assign({}, root.deviceMap);
                        map[data.Address] = data;
                        root.deviceMap = map;
                    }
                }
            }
            onExited: destroy()
        }
    }

    // Dynamic: fire-and-forget SendUIAction, self-destroys.
    Component {
        id: sendActionComp
        Process {
            onExited: destroy()
        }
    }

    // One-shot: fetch the icon base path from the daemon (called once on connect).
    Process {
        id: iconPathProc
        running: false
        command: ["gdbus", "call", "--session", "--dest", root._dest,
            "--object-path", root._path, "--method", `${root._iface}.GetIconPath`]
        stdout: StdioCollector {
            onStreamFinished: {
                // Output format: ('/path/to/icons',)\n
                const m = text.match(/'([^']+)'/);
                if (m)
                    root.iconBasePath = m[1];
            }
        }
    }

    // ── Persistent monitor ────────────────────────────────────────────────────

    Process {
        id: monitor
        running: false
        // stdbuf -oL forces line-buffering: gdbus switches to block-buffered
        // stdout when piped (not a tty), so signals would silently queue until
        // the 4-8KB buffer fills without this.
        command: ["stdbuf", "-oL", "gdbus", "monitor", "--session", "--dest", root._dest,
            "--object-path", root._path]
        stdout: SplitParser {
            onRead: line => {
                const ifaceEsc = root._iface.replace(/\./g, "\\.");
                const m = line.match(new RegExp(ifaceEsc + "\\.(\\w+) \\('([^']+)',\\)"));
                if (!m)
                    return;
                const [, signal, address] = m;
                if (signal === "DeviceAdded" || signal === "DeviceChanged") {
                    root._fetchDevice(address);
                } else if (signal === "DeviceRemoved") {
                    const map = Object.assign({}, root.deviceMap);
                    delete map[address];
                    root.deviceMap = map;
                }
            }
        }
        onExited: {
            root.available = false;
            root.deviceMap = {};
            retryTimer.restart();
        }
    }

    // Static: reused for each GetDevices check.
    Process {
        id: listProc
        running: false
        command: ["gdbus", "call", "--session", "--dest", root._dest,
            "--object-path", root._path, "--method", `${root._iface}.GetDevices`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim().startsWith("("))
                    return;
                root.available = true;
                root._parseAddressList(text).forEach(a => root._fetchDevice(a));
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.available = false;
                retryTimer.restart();
            }
        }
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    function _fetchDevice(address) {
        fetchDeviceComp.createObject(root, {addr: address}).running = true;
    }

    function _init() {
        if (!monitor.running)
            monitor.running = true;
        // Start listProc on the next tick so monitor connects to D-Bus before
        // we enumerate devices — prevents signals emitted between list response
        // and monitor startup from being silently dropped.
        Qt.callLater(() => {
            if (!listProc.running)
                listProc.running = true;
            if (!iconPathProc.running)
                iconPathProc.running = true;
        });
    }

    Timer {
        id: retryTimer
        interval: root._retryIntervalMs
        repeat: false
        onTriggered: root._init()
    }

    Component.onCompleted: _init()
}
