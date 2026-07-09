pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

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
    readonly property bool scanning: rescanProc.running
    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property list<string> savedConnections: []
    property list<string> savedConnectionSsids: []

    property var wifiConnectionQueue: []
    property int currentSsidQueryIndex: 0
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
    property list<var> activeProcesses: []

    // Constants
    readonly property string deviceTypeWifi: "wifi"
    readonly property string deviceTypeEthernet: "ethernet"
    readonly property string connectionTypeWireless: "802-11-wireless"
    readonly property string nmcliCommandDevice: "device"
    readonly property string nmcliCommandConnection: "connection"
    readonly property string nmcliCommandWifi: "wifi"
    readonly property string nmcliCommandRadio: "radio"
    readonly property string deviceStatusFields: "DEVICE,TYPE,STATE,CONNECTION"
    readonly property string connectionListFields: "NAME,TYPE"
    readonly property string wirelessSsidField: "802-11-wireless.ssid"
    readonly property string networkListFields: "SSID,SIGNAL,SECURITY"
    readonly property string networkDetailFields: "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY"
    readonly property string securityKeyMgmt: "802-11-wireless-security.key-mgmt"
    readonly property string securityPsk: "802-11-wireless-security.psk"
    readonly property string keyMgmtWpaPsk: "wpa-psk"
    readonly property string connectionParamType: "type"
    readonly property string connectionParamConName: "con-name"
    readonly property string connectionParamIfname: "ifname"
    readonly property string connectionParamSsid: "ssid"
    readonly property string connectionParamPassword: "password"
    readonly property string connectionParamAutoconnect: "connection.autoconnect"
    readonly property string securityWepKey: "802-11-wireless-security.wep-key0"
    readonly property string keyMgmtSae: "sae"
    readonly property string keyMgmtNone: "none"
    // nmcli's `connection up` blocks until activation resolves. Its default
    // timeout is 90s, and a wrong password burns the whole budget because
    // NetworkManager keeps retrying the handshake, so keep it short.
    readonly property string activationTimeout: "20"

    // Classifies a failed nmcli result so the UI can show a useful message.
    // Never used to decide control flow - the exit code alone does that.
    function failureReason(result: var): string {
        if (!result || result.success) {
            return "";
        }
        const error = result.error ?? "";
        if (error.includes("Secrets were required") || error.includes("No secrets provided")) {
            return "badPassword";
        }
        // nmcli exit codes: 3 timeout, 4 activation failed, 10 not found.
        if (result.exitCode === 3) {
            return "timeout";
        }
        if (result.exitCode === 10) {
            return "notFound";
        }
        return "unknown";
    }

    // Picks the nmcli key management mode from the security string reported by
    // `nmcli -g SECURITY`, e.g. "WPA2", "WPA1 WPA2", "WPA3", "WPA2 802.1X".
    // Returns "" for open networks.
    function keyMgmtForSecurity(security: string): string {
        const s = (security ?? "").toUpperCase();
        if (s.includes("WPA3") || s.includes("SAE")) {
            return root.keyMgmtSae;
        }
        if (s.includes("WPA")) {
            return root.keyMgmtWpaPsk;
        }
        if (s.includes("WEP")) {
            return root.keyMgmtNone;
        }
        return "";
    }

    // WPA-PSK passphrases are 8-63 characters, or exactly 64 hex digits for a
    // raw PMK. Checking here means a typo never costs a connection attempt or
    // leaves a junk profile behind.
    function isValidPsk(password: string, keyMgmt: string): bool {
        if (!password || password.length === 0) {
            return false;
        }
        if (keyMgmt === root.keyMgmtNone) {
            return true;
        }
        if (/^[0-9a-fA-F]{64}$/.test(password)) {
            return true;
        }
        return password.length >= 8 && password.length <= 63;
    }

    function parseNetworkOutput(output: string): list<var> {
        if (!output || output.length === 0) {
            return [];
        }

        const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
        const rep = new RegExp("\\\\:", "g");
        const rep2 = new RegExp(PLACEHOLDER, "g");

        const allNetworks = output.trim().split("\n").filter(line => line && line.length > 0).map(n => {
            const net = n.replace(rep, PLACEHOLDER).split(":");
            return {
                active: net[0] === "yes",
                strength: parseInt(net[1] || "0", 10) || 0,
                frequency: parseInt(net[2] || "0", 10) || 0,
                ssid: (net[3]?.replace(rep2, ":") ?? "").trim(),
                bssid: (net[4]?.replace(rep2, ":") ?? "").trim(),
                security: (net[5] ?? "").trim()
            };
        }).filter(n => n.ssid && n.ssid.length > 0);

        return allNetworks;
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

    function getEthernetInterfaces(callback: var): void {
        executeCommand(["-t", "-f", root.deviceStatusFields, root.nmcliCommandDevice, "status"], result => {
            const interfaces = parseDeviceStatusOutput(result.output, root.deviceTypeEthernet);
            const devices = interfaces.map(iface => ({
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
                    }));

            root.ethernetInterfaces = interfaces;
            syncEthernetDevices(devices);
            if (callback)
                callback(interfaces);
        });
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
        if (connectionName && connectionName.length > 0) {
            executeCommand([root.nmcliCommandConnection, "up", connectionName], result => {
                if (result.success) {
                    Qt.callLater(() => {
                        getEthernetInterfaces(() => {});
                        if (interfaceName && interfaceName.length > 0) {
                            Qt.callLater(() => {
                                getEthernetDeviceDetails(interfaceName, () => {});
                            });
                        }
                    });
                }
                if (callback)
                    callback(result);
            });
        } else if (interfaceName && interfaceName.length > 0) {
            executeCommand([root.nmcliCommandDevice, "connect", interfaceName], result => {
                if (result.success) {
                    Qt.callLater(() => {
                        getEthernetInterfaces(() => {});
                        Qt.callLater(() => {
                            getEthernetDeviceDetails(interfaceName, () => {});
                        });
                    });
                }
                if (callback)
                    callback(result);
            });
        } else {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "No connection name or interface specified",
                    exitCode: -1
                });
        }
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

        executeCommand([root.nmcliCommandConnection, "down", connectionName], result => {
            if (result.success) {
                root.ethernetDeviceDetails = null;
                Qt.callLater(() => {
                    getEthernetInterfaces(() => {});
                });
            }
            if (callback)
                callback(result);
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

    // Connects using whatever profile/secrets NetworkManager already has. Only
    // valid for open networks or ones with a saved profile - a secured network
    // without one needs connectToNetwork() with a password.
    function connectToNetwork(ssid: string, password: string, security: string, callback: var): void {
        if (password && password.length > 0) {
            createConnectionWithPassword(ssid, password, security, callback);
            return;
        }

        executeCommand(["-w", root.activationTimeout, root.nmcliCommandDevice, root.nmcliCommandWifi, "connect", ssid], result => {
            if (callback)
                callback(result);
        });
    }

    // Writes the password into a profile, then activates it. The profile is
    // created with autoconnect off and only promoted once activation actually
    // succeeds, so a wrong password can never leave behind a profile that looks
    // saved and that NetworkManager keeps retrying forever. An existing profile
    // is modified rather than recreated, preserving its static IP/DNS settings,
    // and is never deleted on failure.
    function createConnectionWithPassword(ssid: string, password: string, security: string, callback: var): void {
        const keyMgmt = keyMgmtForSecurity(security);

        if (keyMgmt.length > 0 && !isValidPsk(password, keyMgmt)) {
            if (callback)
                callback({
                    success: false,
                    output: "",
                    error: "Password must be between 8 and 63 characters",
                    exitCode: -1,
                    reason: "badPassword"
                });
            return;
        }

        const finish = result => {
            if (callback)
                callback(Object.assign({}, result, {
                    reason: failureReason(result)
                }));
        };

        const secFields = keyMgmt === root.keyMgmtNone ? [root.securityKeyMgmt, root.keyMgmtNone, root.securityWepKey, password] : [root.securityKeyMgmt, keyMgmt, root.securityPsk, password];

        executeCommand([root.nmcliCommandConnection, "show", ssid], existsResult => {
            const createdNow = !existsResult.success;

            const cmd = createdNow ? [root.nmcliCommandConnection, "add", root.connectionParamType, root.deviceTypeWifi, root.connectionParamConName, ssid, root.connectionParamIfname, "*", root.connectionParamSsid, ssid, root.connectionParamAutoconnect, "no", ...secFields] : [root.nmcliCommandConnection, "modify", ssid, ...secFields];

            executeCommand(cmd, writeResult => {
                if (!writeResult.success) {
                    finish(writeResult);
                    return;
                }

                activateConnection(ssid, upResult => {
                    if (upResult.success) {
                        executeCommand([root.nmcliCommandConnection, "modify", ssid, root.connectionParamAutoconnect, "yes"], () => {
                            loadSavedConnections(() => {});
                            finish(upResult);
                        });
                    } else if (createdNow) {
                        executeCommand([root.nmcliCommandConnection, "delete", ssid], () => {
                            loadSavedConnections(() => {});
                            finish(upResult);
                        });
                    } else {
                        finish(upResult);
                    }
                });
            });
        });
    }

    function connectEnterpriseNetwork(ssid: string, params: var, callback: var): void {
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

        executeCommand([root.nmcliCommandConnection, "show", ssid], existsResult => {
            const createdNow = !existsResult.success;

            const eapMethod = (params.eapMethod || "peap").toLowerCase();
            const fields = ["wifi-sec.key-mgmt", "wpa-eap", "802-1x.eap", eapMethod, "802-1x.identity", params.identity || ""];

            if (eapMethod !== "tls") {
                fields.push("802-1x.phase2-auth", params.phase2Method ? params.phase2Method.toLowerCase() : "mschapv2");
            }
            if (params.password) {
                fields.push("802-1x.password", params.password);
            }
            fields.push("802-1x.anonymous-identity", params.anonymousIdentity || "");
            fields.push("802-1x.domain-suffix-match", params.domainSuffixMatch || "");
            if (params.caCertPath) {
                fields.push("802-1x.ca-cert", params.caCertPath);
                fields.push("802-1x.system-ca-certs", "no");
            } else {
                fields.push("802-1x.ca-cert", "");
                fields.push("802-1x.system-ca-certs", params.verifyCert ? "yes" : "no");
            }

            const finish = result => {
                if (callback)
                    callback(Object.assign({}, result, {
                        reason: failureReason(result)
                    }));
            };

            const cmd = createdNow ? [root.nmcliCommandConnection, "add", root.connectionParamType, root.deviceTypeWifi, root.connectionParamConName, ssid, root.connectionParamIfname, "*", root.connectionParamSsid, ssid, root.connectionParamAutoconnect, "no", ...fields] : [root.nmcliCommandConnection, "modify", ssid, ...fields];

            executeCommand(cmd, writeResult => {
                if (!writeResult.success) {
                    finish(writeResult);
                    return;
                }

                activateConnection(ssid, upResult => {
                    if (upResult.success) {
                        executeCommand([root.nmcliCommandConnection, "modify", ssid, root.connectionParamAutoconnect, "yes"], () => {
                            loadSavedConnections(() => {});
                            finish(upResult);
                        });
                    } else if (createdNow) {
                        executeCommand([root.nmcliCommandConnection, "delete", ssid], () => {
                            loadSavedConnections(() => {});
                            finish(upResult);
                        });
                    } else {
                        finish(upResult);
                    }
                });
            });
        });
    }

    // nmcli blocks until the activation resolves, so the exit code here is the
    // real answer - no polling or timers needed.
    function activateConnection(connectionName: string, callback: var): void {
        executeCommand(["-w", root.activationTimeout, root.nmcliCommandConnection, "up", connectionName], result => {
            if (callback)
                callback(result);
        });
    }

    function loadSavedConnections(callback: var): void {
        executeCommand(["-t", "-f", root.connectionListFields, root.nmcliCommandConnection, "show"], result => {
            if (!result.success) {
                root.savedConnections = [];
                root.savedConnectionSsids = [];
                if (callback)
                    callback([]);
                return;
            }

            parseConnectionList(result.output, callback);
        });
    }

    function parseConnectionList(output: string, callback: var): void {
        const lines = output.trim().split("\n").filter(line => line.length > 0);
        const wifiConnections = [];
        const connections = [];

        for (const line of lines) {
            const parts = line.split(":");
            if (parts.length >= 2) {
                const name = parts[0];
                const type = parts[1];
                connections.push(name);

                if (type === root.connectionTypeWireless) {
                    wifiConnections.push(name);
                }
            }
        }

        root.savedConnections = connections;

        if (wifiConnections.length > 0) {
            root.wifiConnectionQueue = wifiConnections;
            root.currentSsidQueryIndex = 0;
            root.savedConnectionSsids = [];
            queryNextSsid(callback);
        } else {
            root.savedConnectionSsids = [];
            root.wifiConnectionQueue = [];
            if (callback)
                callback(root.savedConnectionSsids);
        }
    }

    function queryNextSsid(callback: var): void {
        if (root.currentSsidQueryIndex < root.wifiConnectionQueue.length) {
            const connectionName = root.wifiConnectionQueue[root.currentSsidQueryIndex];
            root.currentSsidQueryIndex++;

            executeCommand(["-t", "-f", root.wirelessSsidField, root.nmcliCommandConnection, "show", connectionName], result => {
                if (result.success) {
                    processSsidOutput(result.output);
                }
                queryNextSsid(callback);
            });
        } else {
            root.wifiConnectionQueue = [];
            root.currentSsidQueryIndex = 0;
            if (callback)
                callback(root.savedConnectionSsids);
        }
    }

    function processSsidOutput(output: string): void {
        const lines = output.trim().split("\n");
        for (const line of lines) {
            if (line.startsWith("802-11-wireless.ssid:")) {
                const ssid = line.substring("802-11-wireless.ssid:".length).trim();
                if (ssid && ssid.length > 0) {
                    const ssidLower = ssid.toLowerCase();
                    const exists = root.savedConnectionSsids.some(s => s && s.toLowerCase() === ssidLower);
                    if (!exists) {
                        const newList = root.savedConnectionSsids.slice();
                        newList.push(ssid);
                        root.savedConnectionSsids = newList;
                    }
                }
            }
        }
    }

    function hasSavedProfile(ssid: string): bool {
        if (!ssid || ssid.length === 0) {
            return false;
        }
        const ssidLower = ssid.toLowerCase().trim();

        const hasSsid = root.savedConnectionSsids.some(savedSsid => savedSsid && savedSsid.toLowerCase().trim() === ssidLower);

        if (hasSsid) {
            return true;
        }

        const hasConnectionName = root.savedConnections.some(connName => connName && connName.toLowerCase().trim() === ssidLower);

        return hasConnectionName;
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

        const ssidLower = ssid.toLowerCase().trim();
        const connectionName = root.savedConnections.find(conn => conn && conn.toLowerCase().trim() === ssidLower) || ssid;

        executeCommand([root.nmcliCommandConnection, "delete", connectionName], result => {
            if (result.success) {
                // Drop it locally before reloading: NetworkManager takes a moment
                // to propagate the removal, and reading back too early leaves the
                // network still showing as saved.
                root.savedConnections = root.savedConnections.filter(conn => conn !== connectionName);
                root.savedConnectionSsids = root.savedConnectionSsids.filter(s => s.toLowerCase().trim() !== ssidLower);
                loadSavedConnections(() => {});
            }
            if (callback)
                callback(result);
        });
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

    function disconnectFromNetwork(callback: var): void {
        const cmd = active && active.ssid ? [root.nmcliCommandConnection, "down", active.ssid] : [root.nmcliCommandDevice, "disconnect", root.deviceTypeWifi];

        executeCommand(cmd, result => {
            if (result.success) {
                getNetworks(() => {});
            }
            if (callback)
                callback(result);
        });
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
        let cmd = [root.nmcliCommandDevice, root.nmcliCommandWifi, "rescan"];
        if (interfaceName && interfaceName.length > 0) {
            cmd.push(root.connectionParamIfname, interfaceName);
        }
        executeCommand(cmd, result => {
            if (callback) {
                callback(result);
            }
        });
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    function enableWifi(enabled: bool, callback: var): void {
        const cmd = enabled ? "on" : "off";
        executeCommand([root.nmcliCommandRadio, root.nmcliCommandWifi, cmd], result => {
            if (result.success) {
                getWifiStatus(status => {
                    root.wifiEnabled = status;
                    if (callback)
                        callback(result);
                });
            } else {
                if (callback)
                    callback(result);
            }
        });
    }

    function toggleWifi(callback: var): void {
        const newState = !root.wifiEnabled;
        enableWifi(newState, callback);
    }

    function getWifiStatus(callback: var): void {
        executeCommand([root.nmcliCommandRadio, root.nmcliCommandWifi], result => {
            if (result.success) {
                const enabled = result.output.trim() === "enabled";
                root.wifiEnabled = enabled;
                if (callback)
                    callback(enabled);
            } else {
                if (callback)
                    callback(root.wifiEnabled);
            }
        });
    }

    function getNetworks(callback: var): void {
        executeCommand(["-g", root.networkDetailFields, "d", "w"], result => {
            if (!result.success) {
                if (callback)
                    callback([]);
                return;
            }

            const allNetworks = parseNetworkOutput(result.output);
            const networks = deduplicateNetworks(allNetworks);
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

            if (callback)
                callback(root.networks);
        });
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

    function getEnterpriseConfig(connectionName: string, callback: var): void {
        if (!connectionName || connectionName.length === 0) {
            if (callback)
                callback(null);
            return;
        }

        executeCommand(["-t", "-f", "802-1x.eap,802-1x.phase2-auth,802-1x.identity,802-1x.anonymous-identity,802-1x.domain-suffix-match,802-1x.ca-cert,802-1x.system-ca-certs", root.nmcliCommandConnection, "show", connectionName], result => {
            if (!result.success) {
                if (callback)
                    callback(null);
                return;
            }

            const cfg = {
                eapMethod: "peap",
                phase2Method: "mschapv2",
                identity: "",
                anonymousIdentity: "",
                domainSuffixMatch: "",
                caCertPath: "",
                verifyCert: true
            };

            const lines = result.output.trim().split("\n");
            for (const line of lines) {
                const idx = line.indexOf(":");
                if (idx < 0)
                    continue;
                const key = line.slice(0, idx).trim();
                const value = line.slice(idx + 1).trim();

                if (value === "" || value === "--")
                    continue;

                if (key === "802-1x.eap")
                    cfg.eapMethod = value.split(",")[0].trim();
                else if (key === "802-1x.phase2-auth")
                    cfg.phase2Method = value;
                else if (key === "802-1x.identity")
                    cfg.identity = value;
                else if (key === "802-1x.anonymous-identity")
                    cfg.anonymousIdentity = value;
                else if (key === "802-1x.domain-suffix-match")
                    cfg.domainSuffixMatch = value;
                else if (key === "802-1x.ca-cert")
                    cfg.caCertPath = value;
                else if (key === "802-1x.system-ca-certs")
                    cfg.verifyCert = value === "yes";
            }

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

    // Reads cumulative since-boot byte counters from sysfs for an interface and
    // returns a human-readable total via the callback.
    // Reads the negotiated link speed (Mbit/s) from sysfs and stores a
    // human-readable form in ethernetSpeed. nmcli `device show` doesn't expose
    // link speed, so sysfs is the root-free source.
    function getEthernetSpeed(interfaceName: string): void {
        if (!interfaceName || interfaceName.length === 0) {
            root.ethernetSpeed = "";
            return;
        }
        speedProc.command = ["sh", "-c", `cat /sys/class/net/${interfaceName}/speed 2>/dev/null`];
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
        dataUsageProc.command = ["sh", "-c", `cat /sys/class/net/${interfaceName}/statistics/rx_bytes /sys/class/net/${interfaceName}/statistics/tx_bytes 2>/dev/null`];
        dataUsageProc.running = true;
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
            const activeInterface = root.ethernetInterfaces.find(iface => {
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
        getNetworks(networks => {
            const newActive = root.active;

            if (newActive && newActive.active) {
                Qt.callLater(() => {
                    if (root.wirelessInterfaces.length > 0) {
                        const activeWireless = root.wirelessInterfaces.find(iface => {
                            return isConnectedState(iface.state);
                        });
                        if (activeWireless && activeWireless.device) {
                            getWirelessDeviceDetails(activeWireless.device, () => {});
                        }
                    }

                    if (root.ethernetInterfaces.length > 0) {
                        const activeEthernet = root.ethernetInterfaces.find(iface => {
                            return isConnectedState(iface.state);
                        });
                        if (activeEthernet && activeEthernet.device) {
                            getEthernetDeviceDetails(activeEthernet.device, () => {});
                        }
                    }
                });
            } else {
                root.wirelessDeviceDetails = null;
                root.ethernetDeviceDetails = null;
            }

            getWirelessInterfaces(() => {});
            getEthernetInterfaces(() => {
                if (root.activeEthernet && root.activeEthernet.connected) {
                    Qt.callLater(() => {
                        getEthernetDeviceDetails(root.activeEthernet.iface, () => {});
                    });
                }
            });
        });
    }

    Component.onCompleted: {
        getWifiStatus(() => {});
        getNetworks(() => {});
        loadSavedConnections(() => {});
        getWirelessInterfaces(() => {});
        getEthernetInterfaces(() => {});
        initDetailsTimer.start();
    }

    Component {
        id: commandProc

        CommandProcess {}
    }

    Component {
        id: apComp

        AccessPoint {}
    }

    Component {
        id: ethComp

        EthernetDevice {}
    }

    Timer {
        id: initDetailsTimer

        interval: 2000
        onTriggered: {
            const activeWireless = root.wirelessInterfaces.find(iface => root.isConnectedState(iface.state));
            if (activeWireless && activeWireless.device) {
                root.getWirelessDeviceDetails(activeWireless.device, () => {});
            }

            const activeEthernet = root.ethernetInterfaces.find(iface => root.isConnectedState(iface.state));
            if (activeEthernet && activeEthernet.device) {
                root.getEthernetDeviceDetails(activeEthernet.device, () => {});
            }
        }
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
                const human = root.formatBytes(nums[0] + nums[1]);
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
                    root.ethernetSpeed = `${Number.isInteger(gbps) ? gbps : gbps.toFixed(1)} Gbps`;
                } else {
                    root.ethernetSpeed = `${mbit} Mbps`;
                }
            }
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", root.nmcliCommandWifi, "list", "--rescan", "yes"]
        onExited: root.getNetworks() // qmllint disable signal-handler-parameters
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

    component CommandProcess: Process {
        id: proc

        property var callback: null
        property list<string> cmdArgs: []

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
            Qt.callLater(() => {
                if (proc.callback) {
                    proc.callback({
                        success: code === 0,
                        output: (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "",
                        error: (stderrCollector && stderrCollector.text) ? stderrCollector.text : "",
                        exitCode: code
                    });
                }
                proc.processFinished();
            });
        }
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
        readonly property bool isEnterprise: security.includes("802.1X")
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
