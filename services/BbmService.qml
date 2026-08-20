pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _dest: "org.bbm"
    readonly property string _path: "/org/bbm"
    readonly property string _iface: "org.bbm.Manager"

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
                const n = parseInt(raw, 10);
                result[key] = isNaN(n) ? raw : n;
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
        command: ["gdbus", "monitor", "--session", "--dest", root._dest,
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
        if (!listProc.running)
            listProc.running = true;
        if (!iconPathProc.running)
            iconPathProc.running = true;
    }

    Timer {
        id: retryTimer
        interval: 5000
        repeat: false
        onTriggered: root._init()
    }

    Component.onCompleted: _init()
}
