pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.services

Singleton {
    id: root

    property var deviceStatus: null
    property var wirelessInterfaces: []
    property bool isConnected: false
    readonly property bool connecting: wirelessInterfaces.some(i => isConnectingState(i.state))
    property string activeInterface: ""
    property string activeConnection: ""
    // Wifi state lives in Wifi now, read from NetworkManager over dbus.
    // These forward it so existing consumers keep working unchanged.
    readonly property bool wifiEnabled: Wifi.enabled
    readonly property bool scanning: Wifi.scanning
    readonly property list<var> networks: Wifi.networks
    readonly property var active: Wifi.active
    // Saved profiles live in Profiles now, read from NetworkManager's Settings
    // interface. These forward them so existing consumers keep working.
    readonly property list<string> savedConnections: Profiles.names
    readonly property list<string> savedConnectionSsids: Profiles.ssids
    // Map of saved Wi-Fi SSID (lowercased) -> security type
    readonly property var savedConnectionSecurity: Profiles.securityBySsid

    property var pendingConnection: null
    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    // Wired state lives in Wired now, read from NetworkManager over dbus.
    // These forward it so existing consumers keep working unchanged.
    readonly property string ethernetDataUsage: Wired.dataUsage
    readonly property string ethernetSpeed: Wired.speed
    readonly property list<var> ethernetDevices: Wired.devices
    readonly property var activeEthernet: Wired.active
    // Whether traffic is actually leaving over a wired link, which isn't the
    // same question as whether a cable is plugged in - with both a cable and
    // wifi up, either can be carrying it. NetworkManager already tracks which
    // connection is primary, so this follows that rather than guessing.
    //
    // Falls back to activeEthernet until a full snapshot has been read, so the
    // icon doesn't flicker through a wrong state on startup or if
    // NetworkManager isn't reachable.
    readonly property bool onEthernet: NetworkRoute.ready ? NetworkRoute.primaryTransport === NetworkTransport.Ethernet : !!activeEthernet
    readonly property bool hasAvailableEthernet: Wired.available
    property list<var> activeProcesses: []

    readonly property alias connectionCheckTimer: connectionCheckTimer
    readonly property alias immediateCheckTimer: immediateCheckTimer

    // Constants
    readonly property string deviceTypeWifi: "wifi"
    readonly property string deviceTypeEthernet: "ethernet"
    readonly property string connectionTypeWireless: "802-11-wireless"
    readonly property string nmcliCommandDevice: "device"
    readonly property string nmcliCommandConnection: "connection"
    readonly property string nmcliCommandWifi: "wifi"
    readonly property string deviceStatusFields: "DEVICE,TYPE,STATE,CONNECTION"
    readonly property string networkListFields: "SSID,SIGNAL,SECURITY"
    readonly property string securityKeyMgmt: "802-11-wireless-security.key-mgmt"
    readonly property string securityPsk: "802-11-wireless-security.psk"
    readonly property string keyMgmtWpaPsk: "wpa-psk"
    readonly property string connectionParamType: "type"
    readonly property string connectionParamConName: "con-name"
    readonly property string connectionParamIfname: "ifname"
    readonly property string connectionParamSsid: "ssid"
    readonly property string connectionParamPassword: "password"
    readonly property string connectionParamBssid: "802-11-wireless.bssid"
    readonly property string connectionParamHidden: "802-11-wireless.hidden"

    signal connectionFailed(string ssid)

    function detectPasswordRequired(error: string): bool {
        if (!error || error.length === 0) {
            return false;
        }

        return (error.includes("Secrets were required") || error.includes("Secrets were required, but not provided") || error.includes("No secrets provided") || error.includes("802-11-wireless-security.psk") || error.includes("password for") || (error.includes("password") && !error.includes("Connection activated") && !error.includes("successfully")) || (error.includes("Secrets") && !error.includes("Connection activated") && !error.includes("successfully")) || (error.includes("802.11") && !error.includes("Connection activated") && !error.includes("successfully"))) && !error.includes("Connection activated") && !error.includes("successfully");
    }

    function isConnectionCommand(command: list<string>): bool {
        if (!command || command.length === 0) {
            return false;
        }

        return command.includes(root.nmcliCommandWifi) || command.includes(root.nmcliCommandConnection);
    }

    function parseDeviceStatusOutput(output: string, filterType: string): list<var> {
        if (!output || output.length === 0) {
            return [];
        }

        const interfaces = [];
        const lines = output.trim().split("\n");

        for (const line of lines) {
            const parts = line.split(":");
            if (parts.length >= 2) {
                const deviceType = parts[1];
                let shouldInclude = false;

                if (filterType === root.deviceTypeWifi && deviceType === root.deviceTypeWifi) {
                    shouldInclude = true;
                } else if (filterType === root.deviceTypeEthernet && deviceType === root.deviceTypeEthernet) {
                    shouldInclude = true;
                } else if (filterType === "both" && (deviceType === root.deviceTypeWifi || deviceType === root.deviceTypeEthernet)) {
                    shouldInclude = true;
                }

                if (shouldInclude) {
                    interfaces.push({
                        device: parts[0] || "",
                        type: parts[1] || "",
                        state: parts[2] || "",
                        connection: parts[3] || ""
                    });
                }
            }
        }

        return interfaces;
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

    function executeCommand(args: list<string>, callback: var): void {
        const proc = commandProc.createObject(root);
        proc.cmdArgs = ["nmcli", ...args];
        proc.callback = callback;

        activeProcesses.push(proc);

        proc.processFinished.connect(() => {
            const index = activeProcesses.indexOf(proc);
            if (index >= 0) {
                activeProcesses.splice(index, 1);
            }
        });

        Qt.callLater(() => {
            proc.exec(proc.cmdArgs);
        });
    }

    function getDeviceStatus(callback: var): void {
        executeCommand(["-t", "-f", root.deviceStatusFields, root.nmcliCommandDevice, "status"], result => {
            if (callback)
                callback(result.output);
        });
    }

    function getWirelessInterfaces(callback: var): void {
        executeCommand(["-t", "-f", root.deviceStatusFields, root.nmcliCommandDevice, "status"], result => {
            const interfaces = parseDeviceStatusOutput(result.output, root.deviceTypeWifi);
            root.wirelessInterfaces = interfaces;
            if (callback)
                callback(interfaces);
        });
    }

    // Kept so existing callers still get their callback; the device list is
    // a live binding on Wired now, so there is nothing to fetch.
    function getEthernetInterfaces(callback: var): void {
        if (callback)
            callback(root.ethernetDevices);
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        Wired.connect(connectionName, interfaceName, success => {
            // The device list updates itself; details still come from nmcli, and
            // NM needs a moment after activation before they are worth reading.
            if (success && interfaceName)
                Qt.callLater(() => getEthernetDeviceDetails(interfaceName, () => {}), 1000);
            if (callback)
                callback(success);
        });
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        Wired.disconnect(connectionName, success => {
            if (success)
                root.ethernetDeviceDetails = null;
            if (callback)
                callback(success);
        });
    }

    function getAllInterfaces(callback: var): void {
        executeCommand(["-t", "-f", root.deviceStatusFields, root.nmcliCommandDevice, "status"], result => {
            const interfaces = parseDeviceStatusOutput(result.output, "both");
            if (callback)
                callback(interfaces);
        });
    }

    function isInterfaceConnected(interfaceName: string, callback: var): void {
        executeCommand([root.nmcliCommandDevice, "status"], result => {
            const lines = result.output.trim().split("\n");
            for (const line of lines) {
                const parts = line.split(/\s+/);
                if (parts.length >= 3 && parts[0] === interfaceName) {
                    const connected = isConnectedState(parts[2]);
                    if (callback)
                        callback(connected);
                    return;
                }
            }
            if (callback)
                callback(false);
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
        const hasBssid = bssid !== undefined && bssid !== null && bssid.length > 0;
        const retries = retryCount !== undefined ? retryCount : 0;
        const maxRetries = 2;

        if (callback) {
            root.pendingConnection = {
                ssid: ssid,
                bssid: hasBssid ? bssid : "",
                callback: callback,
                retryCount: retries
            };
            connectionCheckTimer.start();
            immediateCheckTimer.checkCount = 0;
            immediateCheckTimer.start();
        }

        if (password && password.length > 0 && hasBssid) {
            const bssidUpper = bssid.toUpperCase();
            createConnectionWithPassword(ssid, bssidUpper, password, callback);
            return;
        }

        let cmd = [root.nmcliCommandDevice, root.nmcliCommandWifi, "connect", ssid];
        if (password && password.length > 0) {
            cmd.push(root.connectionParamPassword, password);
        }
        executeCommand(cmd, result => {
            if (result.needsPassword && callback) {
                if (callback)
                    callback(result);
                return;
            }

            if (!result.success && root.pendingConnection && retries < maxRetries) {
                console.warn(lc, "Connection failed, retrying... (attempt " + (retries + 1) + "/" + maxRetries + ")");
                Qt.callLater(() => {
                    connectWireless(ssid, password, bssid, callback, retries + 1);
                }, 1000);
            } else if (!result.success && root.pendingConnection) {} else if (result.success && callback) {} else if (!result.success && !root.pendingConnection) {
                if (callback)
                    callback(result);
            }
        });
    }

    function createConnectionWithPassword(ssid: string, bssidUpper: string, password: string, callback: var): void {
        checkAndDeleteConnection(ssid, () => {
            const cmd = [root.nmcliCommandConnection, "add", root.connectionParamType, root.deviceTypeWifi, root.connectionParamConName, ssid, root.connectionParamIfname, "*", root.connectionParamSsid, ssid, root.connectionParamBssid, bssidUpper, root.securityKeyMgmt, root.keyMgmtWpaPsk, root.securityPsk, password];

            executeCommand(cmd, result => {
                if (result.success) {
                    activateConnection(ssid, callback);
                } else {
                    const hasDuplicateWarning = result.error && (result.error.includes("another connection with the name") || result.error.includes("Reference the connection by its uuid"));

                    if (hasDuplicateWarning || (result.exitCode > 0 && result.exitCode < 10)) {
                        activateConnection(ssid, callback);
                    } else {
                        console.warn(lc, "Connection profile creation failed, trying fallback...");
                        let fallbackCmd = [root.nmcliCommandDevice, root.nmcliCommandWifi, "connect", ssid, root.connectionParamPassword, password];
                        executeCommand(fallbackCmd, fallbackResult => {
                            if (callback)
                                callback(fallbackResult);
                        });
                    }
                }
            });
        });
    }

    function checkAndDeleteConnection(ssid: string, callback: var): void {
        executeCommand([root.nmcliCommandConnection, "show", ssid], result => {
            if (result.success) {
                executeCommand([root.nmcliCommandConnection, "delete", ssid], deleteResult => {
                    Qt.callLater(() => {
                        if (callback)
                            callback();
                    }, 300);
                });
            } else {
                if (callback)
                    callback();
            }
        });
    }

    function activateConnection(connectionName: string, callback: var): void {
        executeCommand([root.nmcliCommandConnection, "up", connectionName], result => {
            if (callback)
                callback(result);
        });
    }

    // Kept so existing callers still get their callback; the saved profiles
    // are a live binding on Profiles now, so there is nothing to fetch.
    function loadSavedConnections(callback: var): void {
        if (callback)
            callback(root.savedConnectionSsids);
    }

    function securityLabel(keyMgmt: string): string {
        return Profiles.securityLabel(keyMgmt);
    }

    // Raw key management for a saved SSID, or "" if there is no profile.
    function savedSecurityFor(ssid: string): string {
        return Profiles.keyMgmtFor(ssid);
    }

    function hasSavedProfile(ssid: string): bool {
        // An active network counts as saved even before the profile lands.
        if (ssid && root.active?.ssid && root.active.ssid.toLowerCase().trim() === ssid.toLowerCase().trim())
            return true;

        return Profiles.hasName(ssid);
    }

    // Adds and connects to an SSID by name. When hidden is true the profile is
    // created with 802-11-wireless.hidden=yes so NetworkManager actively probes
    // for it.
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

        // Remove any stale profile with the same name first so we don't collide.
        checkAndDeleteConnection(ssid, () => {
            let cmd = [root.nmcliCommandConnection, "add", root.connectionParamType, root.deviceTypeWifi, root.connectionParamConName, ssid, root.connectionParamIfname, "*", root.connectionParamSsid, ssid, root.connectionParamHidden, hidden ? "yes" : "no"];

            if (isSecure) {
                cmd.push(root.securityKeyMgmt, root.keyMgmtWpaPsk, root.securityPsk, password);
            }

            executeCommand(cmd, result => {
                if (result.success) {
                    activateConnection(ssid, callback);
                } else {
                    const hasDuplicateWarning = result.error && (result.error.includes("another connection with the name") || result.error.includes("Reference the connection by its uuid"));

                    if (hasDuplicateWarning) {
                        activateConnection(ssid, callback);
                    } else if (callback) {
                        callback(result);
                    }
                }
            });
        });
    }

    // Reads whether a saved connection auto-connects.
    // Kept for existing callers; autoconnect is a live binding on Profiles now.
    function getAutoconnect(connectionName: string, callback: var): void {
        if (callback)
            callback(Profiles.autoconnectFor(connectionName));
    }

    function setAutoconnect(connectionName: string, enabled: bool, callback: var): void {
        Profiles.setAutoconnect(Profiles.nameFor(connectionName), enabled, callback);
    }

    function forgetNetwork(ssid: string, callback: var): void {
        if (!ssid) {
            if (callback)
                callback(false);
            return;
        }

        Profiles.forget(Profiles.nameFor(ssid), callback);
    }

    function disconnect(interfaceName: string, callback: var): void {
        if (interfaceName && interfaceName.length > 0) {
            executeCommand([root.nmcliCommandDevice, "disconnect", interfaceName], result => {
                if (callback)
                    callback(result.success ? result.output : "");
            });
        } else {
            executeCommand([root.nmcliCommandDevice, "disconnect", root.deviceTypeWifi], result => {
                if (callback)
                    callback(result.success ? result.output : "");
            });
        }
    }

    function disconnectFromNetwork(): void {
        Wifi.disconnect(null);
    }

    function getDeviceDetails(interfaceName: string, callback: var): void {
        executeCommand([root.nmcliCommandDevice, "show", interfaceName], result => {
            if (callback)
                callback(result.output);
        });
    }

    function refreshStatus(callback: var): void {
        getDeviceStatus(output => {
            const lines = output.trim().split("\n");
            let connected = false;
            let activeIf = "";
            let activeConn = "";

            for (const line of lines) {
                const parts = line.split(":");
                if (parts.length >= 4) {
                    const state = parts[2] || "";
                    if (isConnectedState(state)) {
                        connected = true;
                        activeIf = parts[0] || "";
                        activeConn = parts[3] || "";
                        break;
                    }
                }
            }

            root.isConnected = connected;
            root.activeInterface = activeIf;
            root.activeConnection = activeConn;

            if (callback)
                callback({
                    connected,
                    interface: activeIf,
                    connection: activeConn
                });
        });
    }

    function bringInterfaceUp(interfaceName: string, callback: var): void {
        if (interfaceName && interfaceName.length > 0) {
            executeCommand([root.nmcliCommandDevice, "connect", interfaceName], result => {
                if (callback) {
                    callback(result);
                }
            });
        } else {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No interface specified",
                    exitCode: -1
                });
        }
    }

    function bringInterfaceDown(interfaceName: string, callback: var): void {
        if (interfaceName && interfaceName.length > 0) {
            executeCommand([root.nmcliCommandDevice, "disconnect", interfaceName], result => {
                if (callback) {
                    callback(result);
                }
            });
        } else {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No interface specified",
                    exitCode: -1
                });
        }
    }

    function scanWirelessNetworks(interfaceName: string, callback: var): void {
        Wifi.scan();
        if (callback)
            callback(true);
    }

    function rescanWifi(): void {
        Wifi.scan();
    }

    function enableWifi(enabled: bool, callback: var): void {
        Wifi.setEnabled(enabled, callback);
    }

    function toggleWifi(callback: var): void {
        Wifi.toggle(callback);
    }

    // Kept for existing callers; wifiEnabled is a live binding now, so there is
    // nothing to fetch.
    function getWifiStatus(callback: var): void {
        if (callback)
            callback(root.wifiEnabled);
    }

    function findNetwork(ssid: string): var {
        return Wifi.findNetwork(ssid);
    }

    // Kept so existing callers still get their callback; the network list is
    // a live binding on Wifi now, so there is nothing to fetch.
    function getNetworks(callback: var): void {
        if (callback)
            callback(root.networks);
        checkPendingConnection();
    }

    function getWirelessSSIDs(interfaceName: string, callback: var): void {
        let cmd = ["-t", "-f", root.networkListFields, root.nmcliCommandDevice, root.nmcliCommandWifi, "list"];
        if (interfaceName && interfaceName.length > 0) {
            cmd.push(root.connectionParamIfname, interfaceName);
        }
        executeCommand(cmd, result => {
            if (!result.success) {
                if (callback)
                    callback([]);
                return;
            }

            const ssids = [];
            const lines = result.output.trim().split("\n");
            const seenSSIDs = new Set();

            for (const line of lines) {
                if (!line || line.length === 0)
                    continue;

                const parts = line.split(":");
                if (parts.length >= 1) {
                    const ssid = parts[0].trim();
                    if (ssid && ssid.length > 0 && !seenSSIDs.has(ssid)) {
                        seenSSIDs.add(ssid);
                        const signalStr = parts.length >= 2 ? parts[1].trim() : "";
                        const signal = signalStr ? parseInt(signalStr, 10) : 0;
                        const security = parts.length >= 3 ? parts[2].trim() : "";
                        ssids.push({
                            ssid: ssid,
                            signal: signalStr,
                            signalValue: isNaN(signal) ? 0 : signal,
                            security: security
                        });
                    }
                }
            }

            ssids.sort((a, b) => {
                return b.signalValue - a.signalValue;
            });

            if (callback)
                callback(ssids);
        });
    }

    function handlePasswordRequired(proc: var, error: string, output: string, exitCode: int): bool {
        if (!proc || !error || error.length === 0) {
            return false;
        }

        if (!isConnectionCommand(proc.cmdArgs) || !root.pendingConnection || !root.pendingConnection.callback) {
            return false;
        }

        const needsPassword = detectPasswordRequired(error);

        if (needsPassword && !proc.callbackCalled && root.pendingConnection) {
            connectionCheckTimer.stop();
            immediateCheckTimer.stop();
            immediateCheckTimer.checkCount = 0;
            const pending = root.pendingConnection;
            root.pendingConnection = null;
            proc.callbackCalled = true;
            const result = {
                success: false,
                output: output || "",
                error: error,
                exitCode: exitCode,
                needsPassword: true
            };
            if (pending.callback) {
                pending.callback(result);
            }
            if (proc.callback && proc.callback !== pending.callback) {
                proc.callback(result);
            }
            return true;
        }

        return false;
    }

    function checkPendingConnection(): void {
        if (root.pendingConnection) {
            Qt.callLater(() => {
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;
                if (connected) {
                    connectionCheckTimer.stop();
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                    if (root.pendingConnection.callback) {
                        root.pendingConnection.callback({
                            success: true,
                            output: "Connected",
                            error: "",
                            exitCode: 0
                        });
                    }
                    root.pendingConnection = null;
                } else {
                    if (!immediateCheckTimer.running) {
                        immediateCheckTimer.start();
                    }
                }
            });
        }
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
        if (!interfaceName || interfaceName.length === 0) {
            const activeInterface = root.wirelessInterfaces.find(iface => {
                return isConnectedState(iface.state);
            });
            if (activeInterface && activeInterface.device) {
                interfaceName = activeInterface.device;
            } else {
                if (callback)
                    callback(null);
                return;
            }
        }

        executeCommand(["device", "show", interfaceName], result => {
            if (!result.success || !result.output) {
                root.wirelessDeviceDetails = null;
                if (callback)
                    callback(null);
                return;
            }

            const details = parseDeviceDetails(result.output, false);
            root.wirelessDeviceDetails = details;
            if (callback)
                callback(details);
        });
    }

    // Reads the IPv4 configuration (method, address, gateway, DNS, autoconnect)
    // of a connection profile for the ethernet detail page.
    function getIpv4Config(connectionName: string, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback(null);
            return;
        }

        executeCommand(["-t", "-f", "ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.ignore-auto-dns,connection.autoconnect", root.nmcliCommandConnection, "show", connectionName], result => {
            if (!result.success) {
                if (callback)
                    callback(null);
                return;
            }

            const cfg = {
                method: "auto",
                address: "",
                gateway: "",
                dns: "",
                ignoreAutoDns: false,
                autoconnect: true
            };

            const lines = result.output.trim().split("\n");
            for (const line of lines) {
                const idx = line.indexOf(":");
                if (idx < 0)
                    continue;
                const key = line.slice(0, idx).trim();
                const value = line.slice(idx + 1).trim();

                if (key === "ipv4.ignore-auto-dns")
                    cfg.ignoreAutoDns = value === "yes";
                else if (key === "connection.autoconnect")
                    cfg.autoconnect = value !== "no";

                if (value === "" || value === "--")
                    continue;

                if (key === "ipv4.method")
                    cfg.method = value;
                else if (key === "ipv4.addresses")
                    cfg.address = value.split(",")[0].trim();
                else if (key === "ipv4.gateway")
                    cfg.gateway = value;
                else if (key === "ipv4.dns")
                    cfg.dns = value.replace(/;\s*$/, "").split(/[;,]/).map(d => d.trim()).filter(d => d.length > 0).join(", ");
            }

            // Distinguish "automatic + custom DNS only" from plain DHCP.
            if (cfg.method === "auto" && cfg.ignoreAutoDns)
                cfg.method = "auto-dns";

            if (callback)
                callback(cfg);
        });
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

        const dnsList = (config.dns ?? "").split(",").map(d => d.trim()).filter(d => d.length > 0).join(" ");
        let cmd = [root.nmcliCommandConnection, "modify", connectionName];

        if (config.method === "manual") {
            cmd.push("ipv4.method", "manual");
            cmd.push("ipv4.addresses", config.address ?? "");
            cmd.push("ipv4.gateway", config.gateway ?? "");
            cmd.push("ipv4.dns", dnsList);
            cmd.push("ipv4.ignore-auto-dns", "yes");
        } else if (config.method === "auto-dns") {
            // DHCP addressing, custom DNS only.
            cmd.push("ipv4.method", "auto");
            cmd.push("ipv4.addresses", "");
            cmd.push("ipv4.gateway", "");
            cmd.push("ipv4.dns", dnsList);
            cmd.push("ipv4.ignore-auto-dns", "yes");
        } else {
            // Full DHCP: clear manual fields and re-enable auto DNS.
            cmd.push("ipv4.method", "auto");
            cmd.push("ipv4.addresses", "");
            cmd.push("ipv4.gateway", "");
            cmd.push("ipv4.dns", "");
            cmd.push("ipv4.ignore-auto-dns", "no");
        }

        executeCommand(cmd, result => {
            if (!result.success) {
                if (callback)
                    callback(result);
                return;
            }
            // Reactivate so changes take effect immediately.
            executeCommand([root.nmcliCommandConnection, "up", connectionName], upResult => {
                Qt.callLater(() => {
                    refreshOnConnectionChange();
                });
                if (callback)
                    callback(upResult);
            });
        });
    }

    function getEthernetSpeed(interfaceName: string): void {
        Wired.refreshSpeed(interfaceName);
    }

    function getEthernetDataUsage(interfaceName: string): void {
        Wired.refreshDataUsage(interfaceName);
    }

    function formatBytes(bytes: var): string {
        if (!bytes || bytes <= 0)
            return "0 B";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        let v = bytes;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return `${v.toFixed(v < 10 && i > 0 ? 1 : 0)} ${units[i]}`;
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        if (!interfaceName || interfaceName.length === 0) {
            if (!root.activeEthernet) {
                if (callback)
                    callback(null);
                return;
            }
            interfaceName = root.activeEthernet.iface;
        }

        executeCommand(["device", "show", interfaceName], result => {
            if (!result.success || !result.output) {
                // Transient failure (e.g. nmcli busy during a toggle). Keep the
                // previous details so dependent UI (gateway, IP/DNS) doesn't
                // blink out and back.
                if (callback)
                    callback(root.ethernetDeviceDetails);
                return;
            }

            const details = parseDeviceDetails(result.output, true);
            root.ethernetDeviceDetails = details;
            if (callback)
                callback(details);
        });
    }

    function parseDeviceDetails(output: string, isEthernet: bool): var {
        const details = {
            ipAddress: "",
            gateway: "",
            dns: [],
            subnet: "",
            macAddress: "",
            speed: ""
        };

        if (!output || output.length === 0) {
            return details;
        }

        const lines = output.trim().split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const parts = line.split(":");
            if (parts.length >= 2) {
                const key = parts[0].trim();
                const value = parts.slice(1).join(":").trim();

                if (key.startsWith("IP4.ADDRESS")) {
                    const ipParts = value.split("/");
                    details.ipAddress = ipParts[0] || "";
                    if (ipParts[1]) {
                        details.subnet = cidrToSubnetMask(ipParts[1]);
                    } else {
                        details.subnet = "";
                    }
                } else if (key === "IP4.GATEWAY") {
                    if (value !== "--") {
                        details.gateway = value;
                    }
                } else if (key.startsWith("IP4.DNS")) {
                    if (value !== "--" && value.length > 0) {
                        details.dns.push(value);
                    }
                } else if (key === "GENERAL.HWADDR") {
                    details.macAddress = value;
                }
            }
        }

        return details;
    }

    function refreshOnConnectionChange(): void {
        if (root.active) {
            Qt.callLater(() => {
                if (root.wirelessInterfaces.length > 0) {
                    const activeWireless = root.wirelessInterfaces.find(iface => {
                        return isConnectedState(iface.state);
                    });
                    if (activeWireless && activeWireless.device) {
                        getWirelessDeviceDetails(activeWireless.device, () => {});
                    }
                }

                if (root.activeEthernet) {
                    getEthernetDeviceDetails(root.activeEthernet.iface, () => {});
                }
            }, 500);
        } else {
            root.wirelessDeviceDetails = null;
            root.ethernetDeviceDetails = null;
        }

        getWirelessInterfaces(() => {});
        if (root.activeEthernet) {
            Qt.callLater(() => {
                getEthernetDeviceDetails(root.activeEthernet.iface, () => {});
            }, 500);
        }
    }

    // Association is reported over dbus now, so a pending connect resolves the
    // moment NetworkManager says so rather than on the next poll.
    onActiveChanged: checkPendingConnection()

    Component.onCompleted: {
        Qt.callLater(() => {
            if (root.wirelessInterfaces.length > 0) {
                const activeWireless = root.wirelessInterfaces.find(iface => {
                    return isConnectedState(iface.state);
                });
                if (activeWireless && activeWireless.device) {
                    getWirelessDeviceDetails(activeWireless.device, () => {});
                }
            }

            if (root.activeEthernet) {
                getEthernetDeviceDetails(root.activeEthernet.iface, () => {});
            }
        }, 2000);
    }

    Component {
        id: commandProc

        CommandProcess {}
    }

    Timer {
        id: connectionCheckTimer

        interval: 4000
        onTriggered: {
            if (root.pendingConnection) {
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;

                if (!connected && root.pendingConnection.callback) {
                    let foundPasswordError = false;
                    for (let i = 0; i < root.activeProcesses.length; i++) {
                        const proc = root.activeProcesses[i];
                        if (proc && proc.stderr && proc.stderr.text) {
                            const error = proc.stderr.text.trim();
                            if (error && error.length > 0) {
                                if (root.isConnectionCommand(proc.cmdArgs)) {
                                    const needsPassword = root.detectPasswordRequired(error);

                                    if (needsPassword && !proc.callbackCalled && root.pendingConnection) {
                                        const pending = root.pendingConnection;
                                        root.pendingConnection = null;
                                        immediateCheckTimer.stop();
                                        immediateCheckTimer.checkCount = 0;
                                        proc.callbackCalled = true;
                                        const result = {
                                            success: false,
                                            output: (proc.stdout && proc.stdout.text) ? proc.stdout.text : "",
                                            error: error,
                                            exitCode: -1,
                                            needsPassword: true
                                        };
                                        if (pending.callback) {
                                            pending.callback(result);
                                        }
                                        if (proc.callback && proc.callback !== pending.callback) {
                                            proc.callback(result);
                                        }
                                        foundPasswordError = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    if (!foundPasswordError) {
                        const pending = root.pendingConnection;
                        const failedSsid = pending.ssid;
                        root.pendingConnection = null;
                        immediateCheckTimer.stop();
                        immediateCheckTimer.checkCount = 0;
                        root.connectionFailed(failedSsid);
                        pending.callback({
                            success: false,
                            output: "",
                            error: "Connection timeout",
                            exitCode: -1,
                            needsPassword: false
                        });
                    }
                } else if (connected) {
                    root.pendingConnection = null;
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                }
            }
        }
    }

    Timer {
        id: immediateCheckTimer

        property int checkCount: 0

        interval: 500
        repeat: true
        triggeredOnStart: false

        onTriggered: {
            if (root.pendingConnection) {
                checkCount++;
                const connected = root.active && root.active.ssid === root.pendingConnection.ssid;

                if (connected) {
                    connectionCheckTimer.stop();
                    immediateCheckTimer.stop();
                    immediateCheckTimer.checkCount = 0;
                    if (root.pendingConnection.callback) {
                        root.pendingConnection.callback({
                            success: true,
                            output: "Connected",
                            error: "",
                            exitCode: 0
                        });
                    }
                    root.pendingConnection = null;
                } else {
                    for (let i = 0; i < root.activeProcesses.length; i++) {
                        const proc = root.activeProcesses[i];
                        if (proc && proc.stderr && proc.stderr.text) {
                            const error = proc.stderr.text.trim();
                            if (error && error.length > 0) {
                                if (root.isConnectionCommand(proc.cmdArgs)) {
                                    const needsPassword = root.detectPasswordRequired(error);

                                    if (needsPassword && !proc.callbackCalled && root.pendingConnection && root.pendingConnection.callback) {
                                        connectionCheckTimer.stop();
                                        immediateCheckTimer.stop();
                                        immediateCheckTimer.checkCount = 0;
                                        const pending = root.pendingConnection;
                                        root.pendingConnection = null;
                                        proc.callbackCalled = true;
                                        const result = {
                                            success: false,
                                            output: (proc.stdout && proc.stdout.text) ? proc.stdout.text : "",
                                            error: error,
                                            exitCode: -1,
                                            needsPassword: true
                                        };
                                        if (pending.callback) {
                                            pending.callback(result);
                                        }
                                        if (proc.callback && proc.callback !== pending.callback) {
                                            proc.callback(result);
                                        }
                                        return;
                                    }
                                }
                            }
                        }
                    }

                    if (checkCount >= 6) {
                        immediateCheckTimer.stop();
                        immediateCheckTimer.checkCount = 0;
                    }
                }
            } else {
                immediateCheckTimer.stop();
                immediateCheckTimer.checkCount = 0;
            }
        }
    }

    Process {
        id: monitorProc

        running: true
        command: ["nmcli", "monitor"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: SplitParser {
            onRead: root.refreshOnConnectionChange()
        }
        onExited: monitorRestartTimer.start() // qmllint disable signal-handler-parameters
    }

    Timer {
        id: monitorRestartTimer

        interval: 2000
        onTriggered: {
            monitorProc.running = true;
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.nmcli"
        defaultLogLevel: LoggingCategory.Info
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

            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0) {
                    const output = (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "";
                    root.handlePasswordRequired(proc, error, output, -1);
                }
            }
        }

        onExited: code => { // qmllint disable signal-handler-parameters
            exitCode = code;

            Qt.callLater(() => {
                if (callbackCalled) {
                    processFinished();
                    return;
                }

                if (proc.callback) {
                    const output = (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "";
                    const error = (stderrCollector && stderrCollector.text) ? stderrCollector.text : "";
                    const success = exitCode === 0;
                    const cmdIsConnection = isConnectionCommand(proc.cmdArgs);

                    if (root.handlePasswordRequired(proc, error, output, exitCode)) {
                        processFinished();
                        return;
                    }

                    const needsPassword = cmdIsConnection && root.detectPasswordRequired(error);

                    if (!success && cmdIsConnection && root.pendingConnection) {
                        const failedSsid = root.pendingConnection.ssid;
                        root.connectionFailed(failedSsid);
                    }

                    callbackCalled = true;
                    callback({
                        success: success,
                        output: output,
                        error: error,
                        exitCode: proc.exitCode,
                        needsPassword: needsPassword || false
                    });
                    processFinished();
                } else {
                    processFinished();
                }
            });
        }
    }
}
