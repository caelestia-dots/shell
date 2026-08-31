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
                frequency: n.frequency,
                bssid: n.bssid,
                maxBitrate: n.maxBitrate,
                bandwidth: n.bandwidth,
                lastSeen: n.lastSeen,
                known: n.known,
                raw: n
            }))

    readonly property var active: networks.find(n => n.connected) ?? null

    readonly property list<var> savedNetworks: networks.filter(n => n.known)
    readonly property list<string> savedConnectionSsids: savedNetworks.map(n => n.ssid)
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
            dns: ""
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
                connection: d.name,
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

    readonly property string ethernetDataUsage: activeEthernet ? NetworkUsage.formatBytesTotal((NetworkUsage.downloadTotal ?? 0) + (NetworkUsage.uploadTotal ?? 0)) : ""

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
        return root.savedNetworks.some(n => normalizeName(n.ssid) === target);
    }

    function securityLabel(security: string): string {
        if (!security || security === "None" || security === "Open")
            return qsTr("Open");
        return security;
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
                if (result.success && result.output) {
                    let ip = "";
                    let gw = "";
                    let dnsList = [];
                    let mac = root.wifiDevice?.address ?? "";
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
                    root.wirelessDeviceDetails = {
                        macAddress: mac,
                        ipAddress: ip,
                        gateway: gw,
                        dns: dnsList.join(", ")
                    };
                }
            });
        } else {
            root.wirelessDeviceDetails = {
                macAddress: root.wifiDevice?.address ?? "",
                ipAddress: "",
                gateway: "",
                dns: ""
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
        } else {
            executeCommand(["connection", "delete", ssid], () => {
                updateWifiDetails();
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
                updateEthDetails();
            });
        } else if (interfaceName) {
            executeCommand(["device", "connect", interfaceName], result => {
                updateEthDetails();
            });
        }
    }

    function disconnectEthernet(interfaceName: string): void {
        if (interfaceName) {
            executeCommand(["device", "disconnect", interfaceName], result => {
                updateEthDetails();
            });
        }
    }

    //
    // Advanced Configuration (IPv4, Autoconnect)
    //

    function findAnyNetwork(name: string): var {
        if (!name)
            return null;
        return findWifiNetwork(name) ?? (root.wiredDevice?.networks?.values ?? []).find(n => n.name === name) ?? null;
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

        return {
            method: method,
            address: ipv4["addresses"]?.[0] ? `${ipv4["addresses"][0][0]}/${ipv4["addresses"][0][1]}` : "",
            gateway: ipv4["gateway"] ?? "",
            dns: Array.isArray(ipv4["dns"]) ? ipv4["dns"].join(", ") : (ipv4["dns"] ?? ""),
            autoconnect: conn["autoconnect"] ?? true
        };
    }

    function setIpv4Config(name: string, config: var): bool {
        const settings = findSettings(name);
        if (!settings) {
            return false;
        }

        settings.write({
            "ipv4": {
                "method": config.method === "auto-dns" ? "auto" : (config.method || "auto"),
                "ignore-auto-dns": config.method === "auto-dns",
                "gateway": config.gateway || null,
                "dns": config.dns ? config.dns.split(/[, ]+/).filter(Boolean) : null
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

        onExited: code => {
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
