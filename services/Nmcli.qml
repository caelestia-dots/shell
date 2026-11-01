pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import Caelestia.Services

Singleton {
    id: root

    property var deviceStatus: null
    property var wirelessInterfaces: []
    property var ethernetInterfaces: []
    property bool isConnected: false
    readonly property bool connecting: wirelessInterfaces.some(i => isConnectingState(i.state))
    property string activeInterface: ""
    property string activeConnection: ""
    property bool wifiEnabled: true
    property bool scanning
    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property list<string> savedConnections: []
    property list<string> savedConnectionSsids: []
    // Map of saved Wi-Fi SSID (lowercased) -> security type
    property var savedConnectionSecurity: ({})
    // Name of the saved Wi-Fi profile for each SSID (lowercased)
    property var savedProfileNames: ({})

    property var wifiConnectionQueue: []
    property int currentSsidQueryIndex: 0
    property var pendingConnection: null
    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    property string ethernetDataUsage: ""
    // Link speed of the active ethernet interface (from sysfs), e.g. "1 Gbps".
    property string ethernetSpeed: ""
    readonly property list<EthernetDevice> ethernetDevices: []
    readonly property EthernetDevice activeEthernet: ethernetDevices.find(d => d.connected) ?? null
    // True when at least one wired device has a carrier (cable plugged in).
    // nmcli reports "unavailable" for ethernet NICs with no link, so we treat
    // anything other than that as a usable connection.
    readonly property bool hasAvailableEthernet: ethernetDevices.some(d => d.state !== "unavailable")

    // Constants
    readonly property string deviceTypeWifi: "wifi"
    readonly property string deviceTypeEthernet: "ethernet"
    readonly property string connectionTypeWireless: "802-11-wireless"
    readonly property string deviceStatusFields: "DEVICE,TYPE,STATE,CONNECTION"
    readonly property string connectionListFields: "NAME,TYPE"
    readonly property string wirelessSsidField: "802-11-wireless.ssid"
    readonly property string networkListFields: "SSID,SIGNAL,SECURITY"
    readonly property string networkDetailFields: "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY"
    readonly property string securityKeyMgmt: "802-11-wireless-security.key-mgmt"
    readonly property string keyMgmtWpaPsk: "wpa-psk"
    readonly property string connectionParamIfname: "ifname"

    signal connectionFailed(string ssid)

    function detectPasswordRequired(error: string): bool {
        if (!error || error.length === 0) {
            return false;
        }

        return (error.includes("Secrets were required") || error.includes("Secrets were required, but not provided") || error.includes("No secrets provided") || error.includes("802-11-wireless-security.psk") || error.includes("password for") || (error.includes("password") && !error.includes("Connection activated") && !error.includes("successfully")) || (error.includes("Secrets") && !error.includes("Connection activated") && !error.includes("successfully")) || (error.includes("802.11") && !error.includes("Connection activated") && !error.includes("successfully"))) && !error.includes("Connection activated") && !error.includes("successfully");
    }

    function deduplicateNetworks(networks: list<var>): list<var> {
        if (!networks || networks.length === 0) {
            return [];
        }

        const networkMap = new Map();
        for (const network of networks) {
            const existing = networkMap.get(network.ssid);
            if (!existing) {
                networkMap.set(network.ssid, network);
            } else {
                if (network.active && !existing.active) {
                    networkMap.set(network.ssid, network);
                } else if (!network.active && !existing.active) {
                    if (network.strength > existing.strength) {
                        networkMap.set(network.ssid, network);
                    }
                }
            }
        }

        return Array.from(networkMap.values());
    }

    function isConnectedState(state: string): bool {
        if (!state || state.length === 0) {
            return false;
        }

        return state === "100 (connected)" || state === "connected" || state.startsWith("connected");
    }

    function isConnectingState(state: string): bool {
        return !!state && state.startsWith("connecting");
    }

    function connectingSsid(): string {
        const iface = root.wirelessInterfaces.find(i => isConnectingState(i.state));
        return iface ? iface.connection : "";
    }

    // Runs fn after ms milliseconds (Qt.callLater has no delay, its extra args go to fn)
    function delay(fn: var, ms: int): void {
        delayTimerComp.createObject(root, {
            interval: ms,
            fn
        });
    }

    function getWirelessInterfaces(callback: var): void {
        refreshAll();
        if (callback)
            callback(root.wirelessInterfaces);
    }

    function getEthernetInterfaces(callback: var): void {
        refreshAll();
        if (callback)
            callback(root.ethernetInterfaces);
    }

    // Sync a list of ethernet devices to the existing device list. Same logic as getNetworks
    function syncEthernetDevices(devices: list<var>): void {
        const rDevices = root.ethernetDevices;

        const newMap = new Map();
        for (const d of devices)
            newMap.set(d.interface, d);

        for (let i = rDevices.length - 1; i >= 0; i--) {
            if (!newMap.has(rDevices[i].iface)) {
                const removed = rDevices.splice(i, 1)[0];
                removed.destroy();
            }
        }

        const existingMap = new Map();
        for (const rd of rDevices)
            existingMap.set(rd.iface, rd);

        for (const [iface, data] of newMap) {
            const match = existingMap.get(iface);
            if (match)
                match.lastIpcObject = data;
            else
                rDevices.push(ethComp.createObject(root, {
                    lastIpcObject: data
                }));
        }
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No connection name specified",
                    exitCode: -1
                });
            return;
        }

        NetworkDbus.activate(connectionName, interfaceName ?? "", result => {
            refreshAll();
            if (callback)
                callback(result);
        });
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No connection name specified",
                    exitCode: -1
                });
            return;
        }

        NetworkDbus.deactivate(connectionName, "", result => {
            root.ethernetDeviceDetails = null;
            refreshAll();
            if (callback)
                callback(result);
        });
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        if (isSecure) {
            const hasBssid = bssid !== undefined && bssid !== null && bssid.length > 0;
            connectWireless(ssid, "", bssid, result => {
                if (result.success) {
                    if (callback)
                        callback({
                            success: true,
                            usedSavedPassword: true,
                            output: result.output,
                            error: "",
                            exitCode: 0
                        });
                } else if (result.needsPassword) {
                    if (callback)
                        callback({
                            success: false,
                            needsPassword: true,
                            output: result.output,
                            error: result.error,
                            exitCode: result.exitCode
                        });
                } else {
                    if (callback)
                        callback(result);
                }
            });
        } else {
            connectWireless(ssid, "", bssid, callback);
        }
    }

    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        connectWireless(ssid, password, bssid, callback);
    }

    function connectWireless(ssid: string, password: string, bssid: string, callback: var, retryCount: int): void {
        const retries = retryCount ?? 0;
        const pending = {
            ssid: ssid,
            bssid: bssid ?? "",
            callback: callback,
            retryCount: retries
        };
        root.pendingConnection = pending;

        const finish = result => {
            // A newer attempt replaced this one
            if (root.pendingConnection !== pending)
                return;
            if (!result.success && !result.needsPassword && retries < 2) {
                console.warn(lc, "Connection failed, retrying... (attempt " + (retries + 1) + "/2)");
                root.delay(() => {
                    root.pendingConnection = null;
                    connectWireless(ssid, password, bssid, callback, retries + 1);
                }, 1000);
                return;
            }
            root.pendingConnection = null;
            refreshAll();
            if (callback)
                callback(result);
        };

        // A saved profile keeps its stored password, so it is simply brought up
        const savedName = root.savedProfileNames[ssid.toLowerCase()];
        if (!password && savedName)
            NetworkDbus.activate(savedName, "", finish);
        else
            NetworkDbus.connectWifi(ssid, bssid ?? "", password ?? "", false, keyMgmtFor(ssid), finish);
    }

    // WPA3-only networks need SAE; anything that also offers WPA2/WPA1 works with a PSK
    function keyMgmtFor(ssid: string): string {
        const security = root.networks.find(n => n.ssid === ssid)?.security ?? "";
        return security.includes("WPA3") && !/WPA[12]/.test(security) ? "sae" : root.keyMgmtWpaPsk;
    }

    function loadSavedConnections(callback: var): void {
        refreshAll();
        if (callback)
            callback(root.savedConnectionSsids);
    }

    function securityLabel(keyMgmt: string): string {
        switch ((keyMgmt || "").trim().toLowerCase()) {
        case "":
        case "none":
            return Tr.trCtx("Open", "wifi security type");
        case "sae":
            return "WPA3";
        case "wpa-psk":
            return "WPA2";
        case "wpa-eap":
        case "wpa-eap-suite-b-192":
            return Tr.tr("Enterprise");
        case "owe":
            return Tr.tr("Enhanced Open");
        case "ieee8021x":
            return "802.1X";
        default:
            return keyMgmt.trim();
        }
    }

    // Cached security label for a saved SSID, or "" if unknown (e.g. not loaded).
    function savedSecurityFor(ssid: string): string {
        if (!ssid || ssid.length === 0)
            return "";
        return root.savedConnectionSecurity[ssid.toLowerCase().trim()] || "";
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid || ssid.length === 0) {
            return false;
        }
        const ssidLower = ssid.toLowerCase().trim();

        if (root.active && root.active.ssid) {
            const activeSsidLower = root.active.ssid.toLowerCase().trim();
            if (activeSsidLower === ssidLower) {
                return true;
            }
        }

        const hasSsid = root.savedConnectionSsids.some(savedSsid => savedSsid && savedSsid.toLowerCase().trim() === ssidLower);

        if (hasSsid) {
            return true;
        }

        const hasConnectionName = root.savedConnections.some(connName => connName && connName.toLowerCase().trim() === ssidLower);

        return hasConnectionName;
    }

    // Adds and connects to an SSID by name. When hidden is true the profile is
    // created with 802-11-wireless.hidden=yes so NetworkManager actively probes
    // for it.
    // Adds and connects to an SSID by name. When hidden is true the profile is created with
    // 802-11-wireless.hidden=yes so NetworkManager actively probes for it.
    function addHiddenNetwork(ssid: string, password: string, security: string, hidden: bool, callback: var): void {
        if (!ssid || ssid.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No SSID specified",
                    exitCode: -1
                });
            return;
        }

        const isSecure = security && security !== "none";
        NetworkDbus.connectWifi(ssid, "", isSecure ? password : "", hidden, "wpa-psk", result => {
            refreshAll();
            if (callback)
                callback(result);
        });
    }

    // Reads whether a saved connection auto-connects.
    function getAutoconnect(connectionName: string, callback: var): void {
        if (callback)
            callback(connectionName ? NetworkDbus.autoconnect(connectionName) : true);
    }

    // Toggles auto-connect for a saved connection. When turned OFF, also makes
    // NetworkManager ask for the password on the next manual connect instead of
    // silently reusing the stored one (psk-flags 2 = "not saved, always ask");
    // turning it back ON restores psk-flags 0 so the next password is saved.
    function setAutoconnect(connectionName: string, enabled: bool, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No connection specified",
                    exitCode: -1
                });
            return;
        }

        const ok = NetworkDbus.setAutoconnect(connectionName, enabled);
        refreshAll();
        if (callback)
            callback({
                success: ok,
                output: "",
                error: ok ? "" : "Could not change autoconnect for " + connectionName,
                exitCode: ok ? 0 : 1,
                needsPassword: false
            });
    }

    function forgetNetwork(ssid: string, callback: var): void {
        if (!ssid || ssid.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No SSID specified",
                    exitCode: -1
                });
            return;
        }

        const connectionName = root.savedProfileNames[ssid.toLowerCase().trim()] ?? ssid;
        NetworkDbus.forget(connectionName, result => {
            refreshAll();
            if (callback)
                callback(result);
        });
    }

    function disconnect(interfaceName: string, callback: var): void {
        NetworkDbus.deactivate("", interfaceName ?? "", result => {
            if (callback)
                callback(result.success ? result.output : "");
        });
    }

    function disconnectFromNetwork(): void {
        const iface = root.wirelessInterfaces.find(i => isConnectedState(i.state))?.device ?? "";
        NetworkDbus.deactivate("", iface, () => refreshAll());
    }

    function refreshStatus(callback: var): void {
        refreshAll();
        if (callback)
            callback({
                connected: root.isConnected,
                interface: root.activeInterface,
                connection: root.activeConnection
            });
    }

    function bringInterfaceUp(interfaceName: string, callback: var): void {
        if (!interfaceName || interfaceName.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No interface specified",
                    exitCode: -1
                });
            return;
        }
        NetworkDbus.connectDevice(interfaceName, result => {
            refreshAll();
            if (callback)
                callback(result);
        });
    }

    function bringInterfaceDown(interfaceName: string, callback: var): void {
        if (!interfaceName || interfaceName.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No interface specified",
                    exitCode: -1
                });
            return;
        }
        NetworkDbus.deactivate("", interfaceName, result => {
            refreshAll();
            if (callback)
                callback(result);
        });
    }

    // Re-reads the whole network state from NetworkManager over D-Bus and applies it
    function refreshAll(): void {
        const snap = NetworkDbus.snapshot();
        if (snap.available)
            applySnapshot(snap);
    }

    function applySnapshot(snap: var): void {
        root.wifiEnabled = snap.wifiEnabled ?? root.wifiEnabled;

        const wireless = (snap.wifiDevices ?? []).map(d => ({
                    device: d.iface,
                    type: root.deviceTypeWifi,
                    state: d.state,
                    connection: d.connection
                }));
        const ethernet = (snap.ethernetDevices ?? []).map(d => ({
                    device: d.iface,
                    type: root.deviceTypeEthernet,
                    state: d.state,
                    connection: d.connection
                }));
        root.wirelessInterfaces = wireless;
        root.ethernetInterfaces = ethernet;
        syncEthernetDevices(ethernet.map(iface => ({
                    interface: iface.device,
                    type: iface.type,
                    state: iface.state,
                    connection: iface.connection,
                    connected: isConnectedState(iface.state),
                    ipAddress: "",
                    gateway: "",
                    dns: [],
                    subnet: "",
                    macAddress: "",
                    speed: ""
                })));

        const active = [...wireless, ...ethernet].find(i => isConnectedState(i.state));
        root.isConnected = !!active;
        root.activeInterface = active?.device ?? "";
        root.activeConnection = active?.connection ?? "";

        // Saved profiles: names of all, and the SSIDs and key management of Wi-Fi ones
        const saved = snap.savedConnections ?? [];
        root.savedConnections = saved.map(c => c.id);
        const ssids = [];
        const security = {};
        for (const c of saved) {
            if (c.type !== root.connectionTypeWireless || !c.ssid)
                continue;
            if (!ssids.some(x => x.toLowerCase() === c.ssid.toLowerCase()))
                ssids.push(c.ssid);
            security[c.ssid.toLowerCase()] = c.keyMgmt;
        }
        root.savedConnectionSsids = ssids;
        root.savedConnectionSecurity = security;
        const profileNames = {};
        for (const c of saved)
            if (c.type === root.connectionTypeWireless && c.ssid)
                profileNames[c.ssid.toLowerCase().trim()] = c.id;
        root.savedProfileNames = profileNames;

        const aps = [];
        for (const d of snap.wifiDevices ?? [])
            for (const ap of d.aps ?? [])
                aps.push({
                    active: ap.active,
                    strength: ap.strength,
                    frequency: ap.frequency,
                    ssid: ap.ssid,
                    bssid: ap.bssid,
                    security: ap.security
                });
        applyNetworks(deduplicateNetworks(aps));

        refreshDetailsFor(wireless, ethernet);
    }

    // Reconciles the live Wi-Fi list with the new one, keeping existing objects so bindings and
    // animations on unchanged networks don't restart
    function applyNetworks(networks: list<var>): void {
        const rNetworks = root.networks;
        const newMap = new Map();
        for (const n of networks)
            newMap.set(`${n.frequency}:${n.ssid}:${n.bssid}`, n);

        for (let i = rNetworks.length - 1; i >= 0; i--) {
            const rn = rNetworks[i];
            const key = `${rn.frequency}:${rn.ssid}:${rn.bssid}`;
            if (!newMap.has(key)) {
                rNetworks.splice(i, 1);
                rn.destroy();
            }
        }

        const existingMap = new Map();
        for (const rn of rNetworks)
            existingMap.set(`${rn.frequency}:${rn.ssid}:${rn.bssid}`, rn);

        for (const [key, network] of newMap) {
            const match = existingMap.get(key);
            if (match) {
                match.lastIpcObject = network;
            } else {
                rNetworks.push(apComp.createObject(root, {
                    lastIpcObject: network
                }));
            }
        }
    }

    // Address details of one device, in the shape the detail pages use
    function detailsFor(iface: string): var {
        const d = NetworkDbus.deviceDetails(iface);
        return {
            ipAddress: d.ip ?? "",
            gateway: d.gateway ?? "",
            dns: d.dns ?? [],
            subnet: d.prefix !== undefined ? cidrToSubnetMask(String(d.prefix)) : "",
            macAddress: d.mac ?? "",
            speed: ""
        };
    }

    function refreshDetailsFor(wireless: list<var>, ethernet: list<var>): void {
        const w = wireless.find(i => isConnectedState(i.state));
        root.wirelessDeviceDetails = w ? detailsFor(w.device) : null;
        const e = ethernet.find(i => isConnectedState(i.state));
        root.ethernetDeviceDetails = e ? detailsFor(e.device) : null;
    }

    function refreshDetails(): void {
        refreshDetailsFor(root.wirelessInterfaces, root.ethernetInterfaces);
    }

    function scanWirelessNetworks(interfaceName: string, callback: var): void {
        NetworkDbus.requestScan(interfaceName || (root.wirelessInterfaces[0]?.device ?? ""));
        if (callback)
            callback({
                success: true,
                output: "",
                error: "",
                exitCode: 0,
                needsPassword: false
            });
    }

    function rescanWifi(): void {
        for (const iface of root.wirelessInterfaces)
            NetworkDbus.requestScan(iface.device);
        root.scanning = true;
        scanDoneTimer.restart();
    }

    function enableWifi(enabled: bool, callback: var): void {
        NetworkDbus.setWifiEnabled(enabled);
        refreshAll();
        if (callback)
            callback({
                success: true,
                output: "",
                error: "",
                exitCode: 0,
                needsPassword: false
            });
    }

    function toggleWifi(callback: var): void {
        const newState = !root.wifiEnabled;
        enableWifi(newState, callback);
    }

    function getWifiStatus(callback: var): void {
        refreshAll();
        if (callback)
            callback(root.wifiEnabled);
    }

    function findNetwork(ssid: string): var {
        return networks.find(n => n.ssid === ssid) ?? null;
    }

    function getNetworks(callback: var): void {
        refreshAll();
        if (callback)
            callback(root.networks);
    }

    function cidrToSubnetMask(cidr: string): string {
        const cidrNum = parseInt(cidr, 10);
        if (isNaN(cidrNum) || cidrNum < 0 || cidrNum > 32) {
            return "";
        }

        const mask = (0xffffffff << (32 - cidrNum)) >>> 0;
        const octet1 = (mask >>> 24) & 0xff;
        const octet2 = (mask >>> 16) & 0xff;
        const octet3 = (mask >>> 8) & 0xff;
        const octet4 = mask & 0xff;

        return `${octet1}.${octet2}.${octet3}.${octet4}`;
    }

    function getWirelessDeviceDetails(interfaceName: string, callback: var): void {
        const iface = interfaceName || (root.wirelessInterfaces.find(i => isConnectedState(i.state))?.device ?? "");
        const details = iface ? detailsFor(iface) : null;
        root.wirelessDeviceDetails = details;
        if (callback)
            callback(details);
    }

    // Reads the IPv4 configuration (method, address, gateway, DNS, autoconnect)
    // of a connection profile for the ethernet detail page.
    function getIpv4Config(connectionName: string, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback(null);
            return;
        }
        const cfg = NetworkDbus.ipv4Config(connectionName);
        if (callback)
            callback(Object.keys(cfg).length > 0 ? cfg : null);
    }

    // Writes an IPv4 configuration to a connection profile and reactivates it so
    // the change takes effect immediately.
    function setIpv4Config(connectionName: string, config: var, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No connection specified",
                    exitCode: -1
                });
            return;
        }

        if (!NetworkDbus.setIpv4Config(connectionName, config)) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "Could not change the IPv4 settings of " + connectionName,
                    exitCode: 1
                });
            return;
        }

        // Reactivate so the change takes effect now
        NetworkDbus.activate(connectionName, "", upResult => {
            refreshAll();
            if (callback)
                callback(upResult);
        });
    }

    // Reads cumulative since-boot byte counters from sysfs for an interface and
    // returns a human-readable total via the callback.
    // Reads the negotiated link speed (Mbit/s) from sysfs and stores a
    // human-readable form in ethernetSpeed
    function getEthernetSpeed(interfaceName: string): void {
        if (!interfaceName || interfaceName.length === 0) {
            root.ethernetSpeed = "";
            return;
        }
        speedProc.command = ["sh", "-c", 'cat "/sys/class/net/$1/speed" 2>/dev/null', "sh", interfaceName];
        speedProc.running = true;
    }

    function getEthernetDataUsage(interfaceName: string, callback: var): void {
        if (!interfaceName || interfaceName.length === 0) {
            if (callback)
                callback("");
            return;
        }
        dataUsageProc.iface = interfaceName;
        dataUsageProc.cb = callback;
        dataUsageProc.command = ["sh", "-c", 'cat "/sys/class/net/$1/statistics/rx_bytes" "/sys/class/net/$1/statistics/tx_bytes" 2>/dev/null', "sh", interfaceName];
        dataUsageProc.running = true;
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        const iface = interfaceName || (root.ethernetInterfaces.find(i => isConnectedState(i.state))?.device ?? "");
        if (!iface) {
            root.ethernetDeviceDetails = null;
            if (callback)
                callback(null);
            return;
        }
        const details = detailsFor(iface);
        root.ethernetDeviceDetails = details;
        if (callback)
            callback(details);
    }

    function refreshOnConnectionChange(): void {
        refreshAll();
        refreshDetails();
    }

    Component.onCompleted: root.refreshAll()

    Component {
        id: delayTimerComp

        Timer {
            id: delayTimer

            property var fn

            running: true
            onTriggered: {
                fn();
                delayTimer.destroy();
            }
        }
    }

    Component {
        id: apComp

        AccessPoint {}
    }

    Component {
        id: ethComp

        EthernetDevice {}
    }

    Process {
        id: dataUsageProc

        property string iface
        property var cb

        stdout: StdioCollector {
            onStreamFinished: {
                const nums = text.trim().split("\n").map(n => parseInt(n.trim(), 10)).filter(n => !isNaN(n));
                if (nums.length < 2) {
                    if (dataUsageProc.cb)
                        dataUsageProc.cb("");
                    return;
                }
                const human = Units.formatBytes(nums[0] + nums[1]);
                root.ethernetDataUsage = human;
                if (dataUsageProc.cb)
                    dataUsageProc.cb(human);
            }
        }
    }

    Process {
        id: speedProc

        stdout: StdioCollector {
            onStreamFinished: {
                const mbit = parseInt(text.trim(), 10);
                // Disconnected/virtual interfaces report -1 or nothing.
                if (isNaN(mbit) || mbit <= 0) {
                    root.ethernetSpeed = "";
                } else if (mbit >= 1000) {
                    const gbps = mbit / 1000;
                    // TRANSLATORS: %1 = a number
                    root.ethernetSpeed = Tr.tr("%1 Gbps").arg(Number.isInteger(gbps) ? gbps : gbps.toFixed(1));
                } else {
                    // TRANSLATORS: %1 = a number
                    root.ethernetSpeed = Tr.tr("%1 Mbps").arg(mbit);
                }
            }
        }
    }

    Connections {
        function onChanged(): void {
            root.refreshOnConnectionChange();
        }

        target: NetworkDbus
    }

    Timer {
        id: scanDoneTimer

        interval: 3000
        onTriggered: {
            root.scanning = false;
            root.refreshAll();
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.nmcli"
        defaultLogLevel: LoggingCategory.Info
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    component EthernetDevice: QtObject {
        required property var lastIpcObject
        readonly property string iface: lastIpcObject.interface
        readonly property string type: lastIpcObject.type
        readonly property string state: lastIpcObject.state
        readonly property string connection: lastIpcObject.connection
        readonly property bool connected: lastIpcObject.connected
        readonly property string ipAddress: lastIpcObject.ipAddress ?? ""
        readonly property string gateway: lastIpcObject.gateway ?? ""
        readonly property var dns: lastIpcObject.dns ?? []
        readonly property string subnet: lastIpcObject.subnet ?? ""
        readonly property string macAddress: lastIpcObject.macAddress ?? ""
        readonly property string speed: lastIpcObject.speed ?? ""
    }
}
