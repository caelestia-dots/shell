pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool probeDone: false
    property bool debugEnabled: false
    property string wirelessInterface: ""
    property bool wifiEnabled: true
    property bool scanning: false

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null

    property var pendingConnection: null
    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    property list<var> ethernetDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null

    property list<string> savedConnections: []
    property list<string> savedConnectionSsids: []

    property list<var> activeProcesses: []

    signal connectionFailed(string ssid)

    function dbg(message: string): void {
        if (debugEnabled) {
            console.log(`[IWD-DEBUG] ${message}`);
        }
    }

    function stripAnsi(text: string): string {
        if (!text)
            return "";
        return text.replace(/\x1b\[[0-9;]*m/g, "");
    }

    function normalizeLines(text: string): list<string> {
        return stripAnsi(text).split("\n").map(line => line.replace(/\r/g, "").replace(/\s+$/, ""));
    }

    function executeCommand(args: list<string>, callback: var): void {
        const proc = commandProc.createObject(root);
        proc.cmdArgs = args;
        proc.callback = callback;

        activeProcesses.push(proc);
        proc.processFinished.connect(() => {
            const idx = activeProcesses.indexOf(proc);
            if (idx >= 0) {
                activeProcesses.splice(idx, 1);
            }
        });

        Qt.callLater(() => {
            proc.exec(proc.cmdArgs);
        });
    }

    function executeShell(script: string, callback: var): void {
        executeCommand(["sh", "-lc", script], callback);
    }

    function detectPasswordRequired(errorText: string): bool {
        if (!errorText || errorText.length === 0)
            return false;

        const err = errorText.toLowerCase();
        return err.includes("passphrase") || err.includes("invalid") || err.includes("authentication") || err.includes("not configured") || err.includes("psk");
    }

    function parseDeviceList(output: string): list<var> {
        const devices = [];
        const lines = normalizeLines(output);

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;
            if (line.startsWith("Devices") || line.startsWith("Name") || line.startsWith("Settable") || line.startsWith("---"))
                continue;

            const match = line.match(/^([\w.:-]+)\s+([0-9a-fA-F:]{17})\s+(on|off)\s+([\w.:-]+)\s+([\w-]+)$/);
            if (!match)
                continue;

            devices.push({
                name: match[1],
                address: match[2],
                powered: match[3] === "on",
                adapter: match[4],
                mode: match[5]
            });
        }

        return devices;
    }

    function detectWirelessInterface(callback: var): void {
        executeCommand(["iwctl", "device", "list"], result => {
            if (!result.success) {
                root.wirelessInterface = "";
                dbg(`detectWirelessInterface failed: exit=${result.exitCode} err='${stripAnsi(result.error).trim()}'`);
                if (callback)
                    callback("");
                return;
            }

            const devices = parseDeviceList(result.output);
            const station = devices.find(d => d.mode === "station");
            const chosen = station ? station.name : ((devices.length > 0) ? devices[0].name : "");
            root.wirelessInterface = chosen || "";
            dbg(`detectWirelessInterface -> '${root.wirelessInterface}' (devices=${devices.length})`);

            if (callback)
                callback(root.wirelessInterface);
        });
    }

    function ensureWirelessInterface(callback: var): void {
        if (root.wirelessInterface && root.wirelessInterface.length > 0) {
            if (callback)
                callback(root.wirelessInterface);
            return;
        }

        detectWirelessInterface(callback);
    }

    function parseKnownNetworks(output: string): list<string> {
        const names = [];
        const lines = normalizeLines(output);

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;
            if (line.startsWith("Known Networks") || line.startsWith("Name") || line.startsWith("Settable") || line.startsWith("---"))
                continue;

            const m = rawLine.match(/^\s*(.+?)\s{2,}(open|none|wep|psk|8021x|sae|wpa\S*)\s{2,}.*$/i);
            if (m && m[1]) {
                const ssid = m[1].trim();
                if (ssid.length > 0)
                    names.push(ssid);
            }
        }

        return names;
    }

    function loadSavedConnections(callback: var): void {
        executeCommand(["iwctl", "known-networks", "list"], result => {
            if (!result.success) {
                root.savedConnections = [];
                root.savedConnectionSsids = [];
                if (callback)
                    callback([]);
                return;
            }

            const known = parseKnownNetworks(result.output);
            root.savedConnections = known.slice();
            root.savedConnectionSsids = known.slice();

            if (callback)
                callback(root.savedConnectionSsids);
        });
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid || ssid.length === 0)
            return false;

        const target = ssid.toLowerCase().trim();

        if (root.active && root.active.ssid && root.active.ssid.toLowerCase().trim() === target)
            return true;

        return root.savedConnectionSsids.some(s => s && s.toLowerCase().trim() === target) || root.savedConnections.some(s => s && s.toLowerCase().trim() === target);
    }

    function parseStationInfo(output: string): var {
        const info = {
            scanning: false,
            state: "",
            ssid: "",
            bssid: "",
            frequency: 0,
            security: "",
            rssiDbm: -100
        };

        const lines = normalizeLines(output);
        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;
            if (line.startsWith("Station:") || line.startsWith("Settable") || line.startsWith("---"))
                continue;

            const m = rawLine.match(/^\s*(?:\*\s*)?([A-Za-z0-9 ]+?)\s{2,}(.*?)\s*$/);
            if (!m)
                continue;

            const key = m[1].trim();
            const value = (m[2] || "").trim();

            if (key === "Scanning") {
                info.scanning = value === "yes";
            } else if (key === "State") {
                info.state = value;
            } else if (key === "Connected network") {
                info.ssid = value;
            } else if (key === "ConnectedBss") {
                info.bssid = value.toLowerCase();
            } else if (key === "Frequency") {
                info.frequency = parseInt(value, 10) || 0;
            } else if (key === "Security") {
                info.security = value;
            } else if (key === "RSSI") {
                const rm = value.match(/(-?\d+)/);
                if (rm)
                    info.rssiDbm = parseInt(rm[1], 10) || -100;
            }
        }

        return info;
    }

    function dbmToStrength(dbm: int): int {
        const clamped = Math.max(-100, Math.min(-50, dbm));
        return Math.round(((clamped + 100) / 50) * 100);
    }

    function parseNetworkList(output: string): list<var> {
        const parsed = [];
        const lines = normalizeLines(output);

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;
            if (line.startsWith("Available networks") || line.startsWith("Network name") || line.startsWith("Settable") || line.startsWith("---"))
                continue;

            const m = rawLine.match(/^\s*(>)?\s*(.+?)\s{2,}(open|none|wep|psk|8021x|sae|wpa\S*)\s{2,}(-?\d+)\s*$/i);
            if (!m)
                continue;

            const ssid = (m[2] || "").trim();
            const securityRaw = (m[3] || "").trim();
            let dbm = parseInt(m[4], 10) || -100;
            if (Math.abs(dbm) > 200)
                dbm = Math.round(dbm / 100);

            const security = securityRaw.toLowerCase();
            const isOpen = security === "open" || security === "none";

            parsed.push({
                active: m[1] === ">",
                strength: dbmToStrength(dbm),
                frequency: 0,
                ssid: ssid,
                bssid: "",
                security: isOpen ? "" : securityRaw
            });
        }

        return parsed;
    }

    function deduplicateNetworks(networkList: list<var>): list<var> {
        const map = new Map();

        for (const n of networkList) {
            const existing = map.get(n.ssid);
            if (!existing) {
                map.set(n.ssid, n);
                continue;
            }

            if (n.active && !existing.active) {
                map.set(n.ssid, n);
                continue;
            }

            if (!n.active && !existing.active && n.strength > existing.strength) {
                map.set(n.ssid, n);
            }
        }

        return Array.from(map.values());
    }

    function replaceNetworks(networkList: list<var>): void {
        const current = root.networks;

        for (let i = current.length - 1; i >= 0; i--) {
            const n = current[i];
            current.splice(i, 1);
            n.destroy();
        }

        for (const n of networkList) {
            current.push(apComp.createObject(root, {
                lastIpcObject: n
            }));
        }
    }

    function getNetworks(callback: var): void {
        ensureWirelessInterface(iface => {
            if (!iface || iface.length === 0) {
                replaceNetworks([]);
                if (callback)
                    callback(root.networks);
                return;
            }

            executeCommand(["iwctl", "station", iface, "get-networks", "rssi-dbms"], result => {
                if (!result.success) {
                    replaceNetworks([]);
                    if (callback)
                        callback([]);
                    return;
                }

                const parsed = deduplicateNetworks(parseNetworkList(result.output));

                executeCommand(["iwctl", "station", iface, "show"], stationResult => {
                    if (stationResult.success) {
                        const station = parseStationInfo(stationResult.output);
                        root.scanning = station.scanning;

                        if (station.ssid && station.ssid.length > 0) {
                            for (const n of parsed) {
                                if (n.ssid === station.ssid) {
                                    n.active = true;
                                    n.bssid = station.bssid || n.bssid;
                                    n.frequency = station.frequency || n.frequency;
                                    if (station.security && station.security.length > 0)
                                        n.security = station.security;
                                } else {
                                    n.active = false;
                                }
                            }

                            const hasActiveInList = parsed.some(n => n.ssid === station.ssid);
                            if (!hasActiveInList) {
                                parsed.push({
                                    active: true,
                                    strength: dbmToStrength(station.rssiDbm),
                                    frequency: station.frequency || 0,
                                    ssid: station.ssid,
                                    bssid: station.bssid || "",
                                    security: station.security || ""
                                });
                            }
                        }
                    }

                    parsed.sort((a, b) => {
                        if (a.active !== b.active)
                            return b.active - a.active;
                        return b.strength - a.strength;
                    });

                    replaceNetworks(parsed);
                    checkPendingConnection();

                    if (callback)
                        callback(root.networks);
                });
            });
        });
    }

    function getWifiStatus(callback: var): void {
        ensureWirelessInterface(iface => {
            if (!iface || iface.length === 0) {
                dbg("getWifiStatus: no interface, keeping previous wifiEnabled=" + root.wifiEnabled);
                if (callback)
                    callback(root.wifiEnabled);
                return;
            }

            executeCommand(["iwctl", "device", "list"], listResult => {
                let enabled = root.wifiEnabled;
                let parsedFromList = false;

                if (listResult.success) {
                    const devices = parseDeviceList(listResult.output);
                    const dev = devices.find(d => d.name === iface);
                    if (dev) {
                        enabled = !!dev.powered;
                        parsedFromList = true;
                    }
                }

                if (parsedFromList) {
                    root.wifiEnabled = enabled;
                    dbg(`getWifiStatus(list) iface=${iface} enabled=${enabled}`);
                    if (callback)
                        callback(enabled);
                    return;
                }

                executeCommand(["iwctl", "device", iface, "show"], result => {
                    if (!result.success) {
                        dbg(`getWifiStatus(show) failed iface=${iface} exit=${result.exitCode} err='${stripAnsi(result.error).trim()}'`);
                        if (callback)
                            callback(root.wifiEnabled);
                        return;
                    }

                    const lines = normalizeLines(result.output);
                    let found = false;

                    for (const rawLine of lines) {
                        const m = rawLine.match(/^\s*(?:\*\s*)?Powered\s{2,}(on|off)\s*$/i);
                        if (m) {
                            enabled = m[1].toLowerCase() === "on";
                            found = true;
                            break;
                        }
                    }

                    if (!found) {
                        dbg(`getWifiStatus(show) could not parse Powered row; keeping previous=${root.wifiEnabled}`);
                        if (callback)
                            callback(root.wifiEnabled);
                        return;
                    }

                    root.wifiEnabled = enabled;
                    dbg(`getWifiStatus(show) iface=${iface} enabled=${enabled}`);
                    if (callback)
                        callback(enabled);
                });
            });
        });
    }

    function enableWifi(enabled: bool, callback: var): void {
        ensureWirelessInterface(iface => {
            if (!iface || iface.length === 0) {
                dbg("enableWifi: no interface");
                if (callback) {
                    callback({
                        success: false,
                        output: "",
                        error: "No wireless interface found",
                        exitCode: -1
                    });
                }
                return;
            }

            dbg(`enableWifi request iface=${iface} enabled=${enabled}`);
            executeCommand(["iwctl", "device", iface, "set-property", "Powered", enabled ? "on" : "off"], result => {
                dbg(`enableWifi result success=${result.success} exit=${result.exitCode} err='${stripAnsi(result.error).trim()}'`);
                getWifiStatus(() => {
                    if (!enabled)
                        replaceNetworks([]);
                    else
                        getNetworks(() => {});

                    if (callback)
                        callback(result);
                });
            });
        });
    }

    function toggleWifi(callback: var): void {
        enableWifi(!root.wifiEnabled, callback);
    }

    function rescanWifi(): void {
        if (root.scanning)
            return;

        root.scanning = true;
        ensureWirelessInterface(iface => {
            if (!iface || iface.length === 0) {
                root.scanning = false;
                return;
            }

            executeCommand(["iwctl", "station", iface, "scan"], result => {
                Qt.callLater(() => {
                    getNetworks(() => {
                        root.scanning = false;
                    });
                }, 900);
            });
        });
    }

    function connectToNetworkWithPasswordCheck(ssid: string, isSecure: bool, callback: var, bssid: string): void {
        if (isSecure && !hasSavedProfile(ssid)) {
            if (callback) {
                callback({
                    success: false,
                    needsPassword: true,
                    output: "",
                    error: "Passphrase required",
                    exitCode: 1
                });
            }
            return;
        }

        connectToNetwork(ssid, "", bssid, callback);
    }

    function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
        ensureWirelessInterface(iface => {
            if (!iface || iface.length === 0) {
                if (callback) {
                    callback({
                        success: false,
                        output: "",
                        error: "No wireless interface found",
                        exitCode: -1,
                        needsPassword: false
                    });
                }
                return;
            }

            if (callback) {
                root.pendingConnection = {
                    ssid: ssid,
                    bssid: bssid || "",
                    callback: callback
                };
            }

            const cmd = (password && password.length > 0) ? ["iwctl", "--passphrase", password, "station", iface, "connect", ssid] : ["iwctl", "station", iface, "connect", ssid];

            executeCommand(cmd, result => {
                const needsPassword = !result.success && detectPasswordRequired(result.error || "");

                if (!result.success) {
                    root.pendingConnection = null;
                    root.connectionFailed(ssid);
                    if (callback) {
                        callback({
                            success: false,
                            output: result.output,
                            error: result.error,
                            exitCode: result.exitCode,
                            needsPassword: needsPassword
                        });
                    }
                    return;
                }

                Qt.callLater(() => {
                    getNetworks(() => {
                        const connected = root.active && root.active.ssid && root.active.ssid.toLowerCase().trim() === ssid.toLowerCase().trim();
                        root.pendingConnection = null;
                        if (callback) {
                            callback({
                                success: connected,
                                output: result.output,
                                error: connected ? "" : "Connection did not become active",
                                exitCode: connected ? 0 : 1,
                                needsPassword: false
                            });
                        }
                        if (!connected)
                            root.connectionFailed(ssid);
                    });
                }, 700);
            });
        });
    }

    function disconnectFromNetwork(): void {
        ensureWirelessInterface(iface => {
            if (!iface || iface.length === 0)
                return;

            executeCommand(["iwctl", "station", iface, "disconnect"], result => {
                Qt.callLater(() => {
                    getNetworks(() => {});
                    getWirelessDeviceDetails(iface, () => {});
                }, 300);
            });
        });
    }

    function forgetNetwork(ssid: string, callback: var): void {
        if (!ssid || ssid.length === 0) {
            if (callback) {
                callback({
                    success: false,
                    output: "",
                    error: "No SSID specified",
                    exitCode: -1
                });
            }
            return;
        }

        executeCommand(["iwctl", "known-networks", ssid, "forget"], result => {
            if (result.success) {
                Qt.callLater(() => {
                    loadSavedConnections(() => {});
                    getNetworks(() => {});
                }, 200);
            }

            if (callback)
                callback(result);
        });
    }

    function parseNetworkctlList(output: string): list<var> {
        const devices = [];
        const lines = normalizeLines(output);

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;

            const m = line.match(/^\d+\s+([\w.:-]+)\s+(\w+)\s+([\w-]+)\s+([\w-]+)$/);
            if (!m)
                continue;

            const iface = m[1];
            const type = m[2];
            const operState = m[3];
            const setupState = m[4];
            const connected = operState === "routable" || operState === "degraded" || operState === "carrier";

            devices.push({
                interface: iface,
                type: type,
                state: `${operState} (${setupState})`,
                connection: iface,
                connected: connected,
                ipAddress: "",
                gateway: "",
                dns: [],
                subnet: "",
                macAddress: "",
                speed: ""
            });
        }

        return devices;
    }

    function getEthernetInterfaces(callback: var): void {
        executeCommand(["networkctl", "--no-legend", "--no-pager", "list"], result => {
            if (!result.success) {
                root.ethernetDevices = [];
                if (callback)
                    callback([]);
                return;
            }

            const all = parseNetworkctlList(result.output);
            root.ethernetDevices = all.filter(d => d.type === "ether");

            if (callback)
                callback(root.ethernetDevices);
        });
    }

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        const iface = (interfaceName && interfaceName.length > 0) ? interfaceName : connectionName;
        if (!iface || iface.length === 0) {
            if (callback) {
                callback({
                    success: false,
                    output: "",
                    error: "No ethernet interface specified",
                    exitCode: -1
                });
            }
            return;
        }

        executeCommand(["ip", "link", "set", "dev", iface, "up"], result => {
            Qt.callLater(() => {
                getEthernetInterfaces(() => {});
                getEthernetDeviceDetails(iface, () => {});
            }, 300);

            if (callback)
                callback(result);
        });
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        const iface = (connectionName && connectionName.length > 0) ? connectionName : (root.activeEthernet ? root.activeEthernet.interface : "");

        if (!iface || iface.length === 0) {
            if (callback) {
                callback({
                    success: false,
                    output: "",
                    error: "No ethernet interface specified",
                    exitCode: -1
                });
            }
            return;
        }

        executeCommand(["ip", "link", "set", "dev", iface, "down"], result => {
            Qt.callLater(() => {
                getEthernetInterfaces(() => {});
                root.ethernetDeviceDetails = null;
            }, 300);

            if (callback)
                callback(result);
        });
    }

    function cidrToSubnetMask(cidr: string): string {
        const cidrNum = parseInt(cidr, 10);
        if (isNaN(cidrNum) || cidrNum < 0 || cidrNum > 32)
            return "";

        const mask = (0xffffffff << (32 - cidrNum)) >>> 0;
        const octet1 = (mask >>> 24) & 0xff;
        const octet2 = (mask >>> 16) & 0xff;
        const octet3 = (mask >>> 8) & 0xff;
        const octet4 = mask & 0xff;

        return `${octet1}.${octet2}.${octet3}.${octet4}`;
    }

    function parseNetworkctlStatus(output: string): var {
        const details = {
            ipAddress: "",
            gateway: "",
            dns: [],
            subnet: "",
            macAddress: "",
            speed: ""
        };

        const lines = normalizeLines(output);
        let readingDns = false;

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;

            if (line.startsWith("Address:")) {
                const value = line.substring("Address:".length).trim();
                const ipv4 = value.match(/\b(\d+\.\d+\.\d+\.\d+)\b/);
                if (ipv4)
                    details.ipAddress = ipv4[1];
                readingDns = false;
            } else if (line.startsWith("Gateway:")) {
                const value = line.substring("Gateway:".length).trim();
                const gw = value.match(/\b(\d+\.\d+\.\d+\.\d+)\b/);
                if (gw)
                    details.gateway = gw[1];
                readingDns = false;
            } else if (line.startsWith("DNS:")) {
                const value = line.substring("DNS:".length).trim();
                const dns = value.match(/\b(\d+\.\d+\.\d+\.\d+)\b/g);
                if (dns)
                    details.dns = details.dns.concat(dns);
                readingDns = true;
            } else if (line.startsWith("Hardware Address:")) {
                const mac = line.substring("Hardware Address:".length).trim().match(/[0-9a-fA-F:]{17}/);
                if (mac)
                    details.macAddress = mac[0];
                readingDns = false;
            } else if (readingDns && !line.includes(":")) {
                const dns = line.match(/\b(\d+\.\d+\.\d+\.\d+)\b/g);
                if (dns)
                    details.dns = details.dns.concat(dns);
            } else {
                readingDns = false;
            }
        }

        details.dns = Array.from(new Set(details.dns));
        return details;
    }

    function fillSubnetFromIpCommand(interfaceName: string, details: var, callback: var): void {
        executeCommand(["ip", "-o", "-4", "addr", "show", "dev", interfaceName], result => {
            if (result.success && result.output) {
                const m = result.output.match(/\binet\s+\d+\.\d+\.\d+\.\d+\/(\d+)\b/);
                if (m)
                    details.subnet = cidrToSubnetMask(m[1]);
            }

            if (callback)
                callback(details);
        });
    }

    function getWirelessDeviceDetails(interfaceName: string, callback: var): void {
        const iface = (interfaceName && interfaceName.length > 0) ? interfaceName : root.wirelessInterface;

        if (!iface || iface.length === 0) {
            root.wirelessDeviceDetails = null;
            if (callback)
                callback(null);
            return;
        }

        executeCommand(["networkctl", "--no-pager", "status", iface], result => {
            if (!result.success) {
                root.wirelessDeviceDetails = null;
                if (callback)
                    callback(null);
                return;
            }

            const details = parseNetworkctlStatus(result.output);
            fillSubnetFromIpCommand(iface, details, finalDetails => {
                root.wirelessDeviceDetails = finalDetails;
                if (callback)
                    callback(finalDetails);
            });
        });
    }

    function getEthernetDeviceDetails(interfaceName: string, callback: var): void {
        let iface = interfaceName;
        if (!iface || iface.length === 0) {
            iface = root.activeEthernet ? root.activeEthernet.interface : "";
        }

        if (!iface || iface.length === 0) {
            root.ethernetDeviceDetails = null;
            if (callback)
                callback(null);
            return;
        }

        executeCommand(["networkctl", "--no-pager", "status", iface], result => {
            if (!result.success) {
                root.ethernetDeviceDetails = null;
                if (callback)
                    callback(null);
                return;
            }

            const details = parseNetworkctlStatus(result.output);
            fillSubnetFromIpCommand(iface, details, finalDetails => {
                root.ethernetDeviceDetails = finalDetails;
                if (callback)
                    callback(finalDetails);
            });
        });
    }

    function checkPendingConnection(): void {
        if (!root.pendingConnection)
            return;

        const pending = root.pendingConnection;
        const connected = root.active && root.active.ssid && pending.ssid && root.active.ssid.toLowerCase().trim() === pending.ssid.toLowerCase().trim();
        if (!connected)
            return;

        root.pendingConnection = null;
        if (pending.callback) {
            pending.callback({
                success: true,
                output: "Connected",
                error: "",
                exitCode: 0,
                needsPassword: false
            });
        }
    }

    onWifiEnabledChanged: dbg(`wifiEnabled changed -> ${wifiEnabled}`)

    function refreshAll(): void {
        loadSavedConnections(() => {});
        getWifiStatus(() => {});
        getNetworks(() => {});
        getEthernetInterfaces(() => {});
    }

    Component.onCompleted: {
        dbg("onCompleted: probing iwctl availability");
        executeShell("command -v iwctl >/dev/null 2>&1", result => {
            root.available = result.success;
            root.probeDone = true;
            dbg(`iwctl available=${root.available}`);
            if (!root.available)
                return;

            detectWirelessInterface(() => {
                dbg("initial refreshAll");
                refreshAll();
            });
        });
    }

    Timer {
        id: pollTimer

        interval: 4000
        repeat: true
        running: root.available
        onTriggered: {
            root.getWifiStatus(() => {});
            root.getNetworks(() => {});
            root.getEthernetInterfaces(() => {});
        }
    }

    Component {
        id: commandProc

        CommandProcess {}
    }

    component CommandProcess: Process {
        id: proc

        property var callback: null
        property list<string> cmdArgs: []
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
                if (callback) {
                    callback({
                        success: code === 0,
                        output: (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "",
                        error: (stderrCollector && stderrCollector.text) ? stderrCollector.text : "",
                        exitCode: code
                    });
                }
                processFinished();
            });
        }
    }

    Component {
        id: apComp

        AccessPoint {}
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
}
