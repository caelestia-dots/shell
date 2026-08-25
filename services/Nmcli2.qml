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
    readonly property bool connecting: wifiDevice?.state === ConnectionState.Connecting
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

    //
    // Hardware and Connection Details
    //

    readonly property var wirelessDeviceDetails: ({
            macAddress: wifiDevice?.address ?? "",
            ipAddress: active?.raw?.nmSettings?.[0]?.read()?.["ipv4"]?.["addresses"]?.[0]?.[0] ?? "",
            gateway: active?.raw?.nmSettings?.[0]?.read()?.["ipv4"]?.["gateway"] ?? "",
            dns: active?.raw?.nmSettings?.[0]?.read()?.["ipv4"]?.["dns"] ?? ""
        })

    readonly property var ethernetDeviceDetails: ({
            macAddress: wiredDevice?.address ?? "",
            ipAddress: activeEthernet?.device?.nmSettings?.[0]?.read()?.["ipv4"]?.["addresses"]?.[0]?.[0] ?? "",
            gateway: activeEthernet?.device?.nmSettings?.[0]?.read()?.["ipv4"]?.["gateway"] ?? "",
            dns: activeEthernet?.device?.nmSettings?.[0]?.read()?.["ipv4"]?.["dns"] ?? ""
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

    // returns mapped network object
    function findNetwork(ssid: string): var {
        if (!ssid)
            return null;
        return root.networks.find(n => n.ssid === ssid || n.name === ssid) ?? null;
    }

    // returns raw native WifiNetwork object
    function findWifiNetwork(ssid: string): var {
        if (!ssid)
            return null;
        return (wifiDevice?.networks.values ?? []).find(n => n.name === ssid) ?? null;
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid)
            return false;
        const target = normalizeName(ssid);
        return root.savedNetworks.some(n => normalizeName(n.ssid) === target);
    }

    // since Quickshell already maps the security type to a string, we just need to handle the "None" case and return "Open" instead
    function securityLabel(security: string): string {
        if (!security || security === "None" || security === "Open")
            return qsTr("Open");
        return security;
    }

    Connections {
        target: root.wifiDevice

        function onConnectedChanged() {
            if (root.wifiDevice?.connected && root.pendingConnection) {
                root.pendingConnection = null;
            }
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

    function rescanWifi(): void {
        if (root.wifiDevice) {
            root.wifiDevice.scannerEnabled = true;
        }
    }

    function connectingSsid(): string {
        const connectingNet = (root.wifiDevice?.networks.values ?? []).find(n => n.state === ConnectionState.Connecting);
        return connectingNet?.name ?? root.pendingConnection?.ssid ?? "";
    }

    function connectToNetwork(ssid: string, password: string, bssid: string): void {
        const network = findWifiNetwork(ssid);
        if (!network)
            return;

        root.pendingConnection = {
            ssid: ssid
        };

        const onFailed = () => {
            network.connectionFailed.disconnect(onFailed);
            root.connectionFailed(ssid);
            if (root.pendingConnection?.ssid === ssid) {
                root.pendingConnection = null;
            }
        };
        network.connectionFailed.connect(onFailed);

        if (password && password.length > 0) {
            network.connectWithPsk(password);
        } else {
            network.connect();
        }
    }

    function disconnectFromNetwork(): void {
        wifiDevice?.disconnect();
    }

    function forgetNetwork(ssid: string): void {
        const network = findWifiNetwork(ssid);
        if (!network) {
            return;
        }
        network.forget();
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
        const device = findWiredDevice(interfaceName);
        if (!device) {
            return;
        }

        if (connectionName) {
            const targetNet = (device.networks?.values ?? []).find(n => n.name === connectionName);
            if (targetNet) {
                targetNet.connect();
                return;
            }
        }

        const primaryNet = device.networks?.values?.[0];
        if (primaryNet) {
            primaryNet.connect();
        } else {
            device.autoconnect = true;
        }
    }

    function disconnectEthernet(interfaceName: string): void {
        const device = findWiredDevice(interfaceName);
        if (!device) {
            return;
        }
        device.disconnect();
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

    Process {
        id: hiddenNetworkProc
        property var cb: null

        onExited: (code, status) => {
            if (cb) {
                cb({
                    success: code === 0
                });
                cb = null;
            }
        }
    }

    function addHiddenNetwork(ssid: string, password: string, security: string, hidden: bool, callback: var): void {
        if (!ssid) {
            if (callback)
                callback({
                    success: false
                });
            return;
        }

        const args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password && password.length > 0) {
            args.push("password", password);
        }
        if (hidden) {
            args.push("hidden", "yes");
        }

        hiddenNetworkProc.cb = callback;
        hiddenNetworkProc.command = args;
        hiddenNetworkProc.running = true;
    }
}
