pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Caelestia.Services

Singleton {
    id: root

    //
    // Devices and Status
    //

    readonly property WifiDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WiredDevice wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null

    property bool isConnected: (wifiDevice?.connected || wiredDevice?.connected) ?? false
    readonly property bool connecting: (wifiDevice?.state === ConnectionState.Connecting) || !!root.pendingConnection
    property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool scanning: wifiDevice?.scannerEnabled ?? false

    //
    // Wireless Networks and Profiles
    //

    readonly property list<var> networks: (wifiDevice?.networks.values ?? []).map(n => ({
                ssid: n.name,
                name: n.name,
                active: n.connected,
                connected: n.connected,
                strength: Math.round(n.signalStrength * 100),
                signalStrength: n.signalStrength,
                security: WifiSecurityType.toString(n.security),
                isSecure: n.security !== WifiSecurityType.None,
                frequency: root.getFrequency(n),
                known: n.known,
                raw: n
            }))

    readonly property var active: networks.find(n => n.connected) ?? null

    readonly property list<var> savedNetworks: networks.filter(n => n.known)
    property list<string> allSavedSsids: []
    readonly property list<string> savedConnectionSsids: allSavedSsids.length > 0 ? allSavedSsids : savedNetworks.map(n => n.ssid)
    readonly property list<string> savedConnections: savedConnectionSsids

    readonly property var savedConnectionSecurity: {
        const map = {};
        for (const n of savedNetworks) {
            map[normalizeName(n.ssid)] = n.security;
        }
        return map;
    }

    property var pendingConnection: null
    property list<var> activeProcesses: []

    //
    // Hardware and Connection Details
    //

    property var wirelessDeviceDetails: ({
            macAddress: wifiDevice?.address ?? "",
            ipAddress: "",
            gateway: "",
            dns: "",
            frequency: 0
        })

    property var ethernetDeviceDetails: ({
            macAddress: wiredDevice?.address ?? "",
            ipAddress: "",
            gateway: "",
            dns: ""
        })

    //
    // Ethernet Devices and State
    //

    readonly property list<var> ethernetDevices: (Networking.devices.values.filter(d => d.type === DeviceType.Wired) ?? []).map(d => ({
                iface: d.name,
                name: d.name,
                address: d.address,
                connected: d.connected,
                hasLink: d.hasLink,
                speed: d.linkSpeed,
                state: d.hasLink ? (d.connected ? "connected" : "disconnected") : "unavailable",
                connection: d.network?.name || d.name,
                device: d
            }))

    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    readonly property bool hasAvailableEthernet: ethernetDevices.some(d => d.state !== "unavailable")

    readonly property string ethernetSpeed: {
        const speed = wiredDevice?.linkSpeed ?? 0;
        if (speed <= 0)
            return "";
        return speed >= 1000 ? `${speed / 1000} Gbps` : `${speed} Mbps`;
    }

    readonly property string ethernetDataUsage: {
        if (!activeEthernet)
            return "";
        const res = NetworkUsage.formatBytes((NetworkUsage.downloadTotal ?? 0) + (NetworkUsage.uploadTotal ?? 0));
        return res ? `${res.value.toFixed(1)} ${res.unit}` : "";
    }

    signal connectionFailed(string ssid)

    //
    // Helpers and Formatters
    //

    function normalizeName(name: string): string {
        return (name || "").toLowerCase().trim();
    }

    function savedSecurityFor(ssid: string): string {
        if (!ssid)
            return "";
        return savedConnectionSecurity[normalizeName(ssid)] || "";
    }

    function findNetwork(ssid: string): var {
        if (!ssid)
            return null;
        const target = normalizeName(ssid);
        return root.networks.find(n => normalizeName(n.ssid) === target || normalizeName(n.name) === target) ?? null;
    }

    function findWifiNetwork(ssid: string): var {
        if (!ssid)
            return null;
        const target = normalizeName(ssid);
        return (wifiDevice?.networks.values ?? []).find(n => normalizeName(n.name) === target) ?? null;
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid)
            return false;
        const target = normalizeName(ssid);
        if (root.savedConnectionSsids.some(s => normalizeName(s) === target))
            return true;
        return root.savedNetworks.some(n => normalizeName(n.ssid) === target);
    }

    function securityLabel(security: string): string {
        if (!security || security === "None" || security === "Open")
            return qsTr("Open");
        return security;
    }

    function getFrequency(n: var): int {
        if (n?.frequency !== undefined && n.frequency > 0)
            return n.frequency;
        if (n?.connected && root.wirelessDeviceDetails?.frequency)
            return root.wirelessDeviceDetails.frequency;
        return 0;
    }

    function ipToUint32(ip: string): int {
        const parts = ip.trim().split(".").map(x => parseInt(x, 10));
        if (parts.length !== 4 || parts.some(isNaN))
            return 0;
        return (parts[0] | (parts[1] << 8) | (parts[2] << 16) | (parts[3] << 24)) >>> 0;
    }

    //
    // Command Process Execution
    //

    function executeCommand(args: list<string>, callback: var): void {
        const proc = commandProc.createObject(root);
        proc.cmdArgs = ["nmcli", ...args];
        proc.command = proc.cmdArgs;
        proc.callback = callback;

        activeProcesses.push(proc);

        proc.processFinished.connect(() => {
            const index = activeProcesses.indexOf(proc);
            if (index >= 0) {
                activeProcesses.splice(index, 1);
            }
            proc.destroy();
        });

        proc.running = true;
    }

    function updateWifiDetails(): void {
        if (root.wifiDevice?.name && root.wifiDevice.connected) {
            executeCommand(["-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR", "device", "show", root.wifiDevice.name], result => {
                let ip = "";
                let gw = "";
                let dnsList = [];
                let mac = root.wifiDevice?.address ?? "";
                if (result.success && result.output) {
                    const lines = result.output.split("\n");
                    for (const line of lines) {
                        const colon = line.indexOf(":");
                        if (colon === -1)
                            continue;
                        const key = line.slice(0, colon).trim();
                        const val = line.slice(colon + 1).trim();
                        if (key.startsWith("IP4.ADDRESS") && !ip)
                            ip = val;
                        else if (key.startsWith("IP4.GATEWAY") && !gw)
                            gw = val;
                        else if (key.startsWith("IP4.DNS") && val)
                            dnsList.push(val);
                        else if (key === "GENERAL.HWADDR" && val)
                            mac = val;
                    }
                }

                executeCommand(["-t", "-f", "IN-USE,FREQ", "dev", "wifi", "list", "ifname", root.wifiDevice.name], wifiResult => {
                    let freq = 0;
                    if (wifiResult.success && wifiResult.output) {
                        const match = wifiResult.output.split("\n").find(l => l.startsWith("*:"));
                        if (match)
                            freq = parseInt(match.slice(2), 10) || 0;
                    }
                    root.wirelessDeviceDetails = {
                        macAddress: mac,
                        ipAddress: ip,
                        gateway: gw,
                        dns: dnsList.join(", "),
                        frequency: freq
                    };
                });
            });
        } else {
            root.wirelessDeviceDetails = {
                macAddress: root.wifiDevice?.address ?? "",
                ipAddress: "",
                gateway: "",
                dns: "",
                frequency: 0
            };
        }
    }

    function updateEthDetails(): void {
        if (root.wiredDevice?.name && root.wiredDevice.connected) {
            executeCommand(["-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR", "device", "show", root.wiredDevice.name], result => {
                if (result.success && result.output) {
                    let ip = "";
                    let gw = "";
                    let dnsList = [];
                    let mac = root.wiredDevice?.address ?? "";
                    const lines = result.output.split("\n");
                    for (const line of lines) {
                        const colon = line.indexOf(":");
                        if (colon === -1)
                            continue;
                        const key = line.slice(0, colon).trim();
                        const val = line.slice(colon + 1).trim();
                        if (key.startsWith("IP4.ADDRESS") && !ip)
                            ip = val;
                        else if (key.startsWith("IP4.GATEWAY") && !gw)
                            gw = val;
                        else if (key.startsWith("IP4.DNS") && val)
                            dnsList.push(val);
                        else if (key === "GENERAL.HWADDR" && val)
                            mac = val;
                    }
                    root.ethernetDeviceDetails = {
                        macAddress: mac,
                        ipAddress: ip,
                        gateway: gw,
                        dns: dnsList.join(", ")
                    };
                }
            });
        } else {
            root.ethernetDeviceDetails = {
                macAddress: root.wiredDevice?.address ?? "",
                ipAddress: "",
                gateway: "",
                dns: ""
            };
        }
    }

    //
    // Wi-Fi Actions
    //

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function enableWifi(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    function enableScanner(enabled: bool): void {
        if (root.wifiDevice) {
            root.wifiDevice.scannerEnabled = enabled && root.wifiEnabled;
        }
    }

    function rescanWifi(): void {
        if (root.wifiDevice && root.wifiEnabled) {
            root.wifiDevice.scannerEnabled = false;
            root.wifiDevice.scannerEnabled = true;
        }
    }

    function connectingSsid(): string {
        const connectingNet = (root.wifiDevice?.networks.values ?? []).find(n => n.state === ConnectionState.Connecting);
        return connectingNet?.name ?? root.pendingConnection?.ssid ?? "";
    }

    function connectToNetwork(ssid: string, password: string, callback: var): void {
        if (!ssid)
            return;

        root.pendingConnection = {
            ssid: ssid
        };

        let cmd = [];
        if (password && password.length > 0) {
            cmd = ["dev", "wifi", "connect", ssid, "password", password];
        } else {
            cmd = ["connection", "up", "id", ssid];
        }

        executeCommand(cmd, result => {
            if (!result.success && !password && cmd[0] === "connection") {
                executeCommand(["dev", "wifi", "connect", ssid], fbResult => {
                    root.pendingConnection = null;
                    if (!fbResult.success) {
                        root.connectionFailed(ssid);
                    }
                    updateWifiDetails();
                    if (callback)
                        callback(fbResult);
                });
                return;
            }
            root.pendingConnection = null;
            if (!result.success) {
                root.connectionFailed(ssid);
            }
            updateWifiDetails();
            if (callback)
                callback(result);
        });
    }

    function disconnectFromNetwork(): void {
        root.pendingConnection = null;
        if (root.active && root.active.ssid) {
            executeCommand(["connection", "down", "id", root.active.ssid], result => {
                if (!result.success && root.wifiDevice?.name) {
                    executeCommand(["device", "disconnect", root.wifiDevice.name], () => {
                        updateWifiDetails();
                    });
                } else {
                    updateWifiDetails();
                }
            });
        } else if (root.wifiDevice?.name) {
            executeCommand(["device", "disconnect", root.wifiDevice.name], result => {
                updateWifiDetails();
            });
        }
    }

    function forgetNetwork(ssid: string): void {
        if (!ssid)
            return;
        const net = findWifiNetwork(ssid);
        if (net) {
            net.forget();
            loadSavedConnections();
        } else {
            executeCommand(["connection", "delete", ssid], () => {
                updateWifiDetails();
                loadSavedConnections();
            });
        }
    }

    //
    // Ethernet Actions
    //

    function findWiredDevice(ifaceName: string): var {
        if (ifaceName)
            return (Networking.devices.values.find(d => d.type === DeviceType.Wired && d.name === ifaceName) ?? root.wiredDevice);
        return root.wiredDevice;
    }

    function connectEthernet(connectionName: string, interfaceName: string): void {
        if (connectionName) {
            executeCommand(["connection", "up", connectionName], result => {
                if (!result.success && interfaceName) {
                    executeCommand(["device", "connect", interfaceName], () => {
                        updateEthDetails();
                    });
                } else {
                    updateEthDetails();
                }
            });
        } else if (interfaceName) {
            executeCommand(["device", "connect", interfaceName], () => {
                updateEthDetails();
            });
        }
    }

    function disconnectEthernet(name: string): void {
        if (!name)
            return;
        executeCommand(["connection", "down", name], result => {
            if (!result.success) {
                executeCommand(["device", "disconnect", name], () => {
                    updateEthDetails();
                });
            } else {
                updateEthDetails();
            }
        });
    }

    //
    // Advanced Configuration (IPv4, Autoconnect)
    //

    function findAnyNetwork(name: string): var {
        if (!name)
            return null;
        const target = normalizeName(name);
        const wired = Networking.devices.values.find(d => d.type === DeviceType.Wired && (normalizeName(d.network?.name) === target || normalizeName(d.name) === target));
        if (wired?.network)
            return wired.network;
        return findWifiNetwork(name);
    }

    function findSettings(name: string): var {
        const net = findAnyNetwork(name);
        return (net?.nmSettings && net.nmSettings.length > 0) ? net.nmSettings[0] : null;
    }

    function getIpv4Config(name: string): var {
        const settings = findSettings(name);
        if (!settings) {
            return null;
        }

        const data = settings.read();
        const ipv4 = data["ipv4"] ?? {};
        const conn = data["connection"] ?? {};

        let method = ipv4["method"] ?? "auto";
        if (method === "auto" && ipv4["ignore-auto-dns"]) {
            method = "auto-dns";
        }

        let address = "";
        if (ipv4["address-data"]?.[0]?.address) {
            address = `${ipv4["address-data"][0].address}/${ipv4["address-data"][0].prefix ?? 24}`;
        } else if (ipv4["addresses"]?.[0]) {
            const a = ipv4["addresses"][0];
            address = `${a[0]}/${a[1]}`;
        }

        let dnsStr = "";
        if (Array.isArray(ipv4["dns"])) {
            dnsStr = ipv4["dns"].map(d => {
                if (typeof d === "number") {
                    return [(d >> 0) & 255, (d >> 8) & 255, (d >> 16) & 255, (d >> 24) & 255].join(".");
                }
                return String(d);
            }).join(", ");
        } else if (ipv4["dns"]) {
            dnsStr = String(ipv4["dns"]);
        }

        return {
            method: method,
            address: address,
            gateway: ipv4["gateway"] ?? "",
            dns: dnsStr,
            autoconnect: conn["autoconnect"] ?? true
        };
    }

    function setIpv4Config(name: string, config: var): bool {
        const settings = findSettings(name);
        if (!settings) {
            return false;
        }

        const addrParts = (config.address || "").split("/");
        const ip = addrParts[0]?.trim() || "";
        const prefix = parseInt(addrParts[1], 10) || 24;

        const dnsNums = (config.dns || "").split(/[, ]+/)
            .map(s => s.trim())
            .filter(Boolean)
            .map(ipToUint32)
            .filter(n => n > 0);

        settings.write({
            "ipv4": {
                "method": config.method === "auto-dns" ? "auto" : (config.method || "auto"),
                "ignore-auto-dns": config.method === "auto-dns",
                "gateway": config.gateway || null,
                "address-data": (config.method === "manual" && ip) ? [{ "address": ip, "prefix": prefix }] : null,
                "dns": dnsNums.length > 0 ? dnsNums : null
            }
        });
        return true;
    }

    function setAutoconnect(name: string, enabled: bool): void {
        findSettings(name)?.write({
            "connection": {
                "autoconnect": enabled
            }
        });
    }

    //
    // Hidden Networks Fallback
    //

    function addHiddenNetwork(ssid: string, password: string, security: string, hidden: bool, callback: var): void {
        if (!ssid) {
            if (callback)
                callback({
                    success: false
                });
            return;
        }

        const args = ["dev", "wifi", "connect", ssid];
        if (password && password.length > 0) {
            args.push("password", password);
        }
        if (hidden) {
            args.push("hidden", "yes");
        }

        executeCommand(args, result => {
            if (callback)
                callback({
                    success: result.success
                });
        });
    }

    function loadSavedConnections(): void {
        executeCommand(["-t", "-f", "NAME,TYPE", "connection", "show"], result => {
            if (!result.success || !result.output)
                return;
            const ssids = [];
            for (const line of result.output.split("\n")) {
                if (!line)
                    continue;
                const idx = line.lastIndexOf(":");
                if (idx >= 0 && line.slice(idx + 1).trim() === "802-11-wireless") {
                    const name = line.slice(0, idx).trim();
                    if (name && !ssids.includes(name))
                        ssids.push(name);
                }
            }
            root.allSavedSsids = ssids;
        });
    }

    onActiveChanged: {
        if (root.active && root.pendingConnection) {
            root.pendingConnection = null;
        }
        updateWifiDetails();
    }

    onActiveEthernetChanged: {
        updateEthDetails();
    }

    Component.onCompleted: {
        updateWifiDetails();
        updateEthDetails();
        loadSavedConnections();
    }

    Timer {
        id: pendingTimeout

        interval: 15000
        running: !!root.pendingConnection
        onTriggered: {
            if (root.pendingConnection) {
                root.pendingConnection = null;
            }
        }
    }

    Connections {
        function onStateChanged() {
            if (root.wifiDevice?.state === ConnectionState.Connected) {
                root.pendingConnection = null;
                root.updateWifiDetails();
            }
        }

        function onConnectedChanged() {
            if (root.pendingConnection && root.wifiDevice?.connected) {
                root.pendingConnection = null;
            }
            root.updateWifiDetails();
        }

        target: root.wifiDevice
    }

    Connections {
        function onStateChanged() {
            if (root.wiredDevice?.state === ConnectionState.Connected) {
                root.updateEthDetails();
            }
        }

        function onConnectedChanged() {
            root.updateEthDetails();
        }

        target: root.wiredDevice
    }

    Component {
        id: commandProc

        CommandProcess {}
    }

    component CommandProcess: Process {
        id: proc

        property var callback: null
        property list<string> cmdArgs: []
        property bool callbackCalled: false
        property int exitCode: 0

        signal processFinished

        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })

        stdout: StdioCollector {
            id: stdoutCollector
        }

        stderr: StdioCollector {
            id: stderrCollector
        }

        onExited: code => { // qmllint disable signal-handler-parameters
            exitCode = code;

            Qt.callLater(() => {
                if (callbackCalled) {
                    processFinished();
                    return;
                }

                callbackCalled = true;
                if (proc.callback) {
                    const output = (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "";
                    const error = (stderrCollector && stderrCollector.text) ? stderrCollector.text : "";
                    proc.callback({
                        success: exitCode === 0,
                        output: output,
                        error: error,
                        exitCode: exitCode
                    });
                }
                processFinished();
            });
        }
    }
}
