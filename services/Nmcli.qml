pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var deviceStatus: null
    property var wirelessInterfaces: []
    property var ethernetInterfaces: []
    property bool isConnected: false
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
    property var pendingConnection: null
    signal connectionFailed(string ssid)
    property var wirelessDeviceDetails: null
    property var ethernetDeviceDetails: null
    property list<var> ethernetDevices: []
    readonly property var activeEthernet: ethernetDevices.find(d => d.connected) ?? null

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
    readonly property string connectionParamBssid: "802-11-wireless.bssid"

    function detectPasswordRequired(error: string): bool {
        if (!error || error.length === 0) {
            return false;
        }

        return (error.includes("Secrets were required") || error.includes("Secrets were required, but not provided") || error.includes("No secrets provided") || error.includes("802-11-wireless-security.psk") || error.includes("password for") || (error.includes("password") && !error.includes("Connection activated") && !error.includes("successfully")) || (error.includes("Secrets") && !error.includes("Connection activated") && !error.includes("successfully")) || (error.includes("802.11") && !error.includes("Connection activated") && !error.includes("successfully"))) && !error.includes("Connection activated") && !error.includes("successfully");
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

    function executeCommand(args: list<string>, callback: var): void {
        const proc = commandProc.createObject(root);
        proc.command = ["nmcli", ...args];
        proc.callback = callback;

        activeProcesses.push(proc);

        proc.processFinished.connect(() => {
            const index = activeProcesses.indexOf(proc);
            if (index >= 0) {
                activeProcesses.splice(index, 1);
            }
        });

        Qt.callLater(() => {
            proc.exec(proc.command);
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
            const devices = [];

            for (const iface of interfaces) {
                const connected = isConnectedState(iface.state);

                devices.push({
                    interface: iface.device,
                    type: iface.type,
                    state: iface.state,
                    connection: iface.connection,
                    connected: connected,
                    ipAddress: "",
                    gateway: "",
                    dns: [],
                    subnet: "",
                    macAddress: "",
                    speed: ""
                });
            }

            root.ethernetInterfaces = interfaces;
            root.ethernetDevices = devices;
            if (callback)
                callback(interfaces);
        });
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
                            }, 1000);
                        }
                    }, 500);
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
                        }, 1000);
                    }, 500);
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
                }, 500);
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
                console.warn("[NMCLI] Connection failed, retrying... (attempt " + (retries + 1) + "/" + maxRetries + ")");
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
                    loadSavedConnections(() => {});
                    activateConnection(ssid, callback);
                } else {
                    const hasDuplicateWarning = result.error && (result.error.includes("another connection with the name") || result.error.includes("Reference the connection by its uuid"));

                    if (hasDuplicateWarning || (result.exitCode > 0 && result.exitCode < 10)) {
                        loadSavedConnections(() => {});
                        activateConnection(ssid, callback);
                    } else {
                        console.warn("[NMCLI] Connection profile creation failed, trying fallback...");
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

        const connectionName = root.savedConnections.find(conn => conn && conn.toLowerCase().trim() === ssid.toLowerCase().trim()) || ssid;

        executeCommand([root.nmcliCommandConnection, "delete", connectionName], result => {
            if (result.success) {
                Qt.callLater(() => {
                    loadSavedConnections(() => {});
                }, 500);
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

    function disconnectFromNetwork(): void {
        if (active && active.ssid) {
            executeCommand([root.nmcliCommandConnection, "down", active.ssid], result => {
                if (result.success) {
                    getNetworks(() => {});
                }
            });
        } else {
            executeCommand([root.nmcliCommandDevice, "disconnect", root.deviceTypeWifi], result => {
                if (result.success) {
                    getNetworks(() => {});
                }
            });
        }
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

            const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
            for (const network of destroyed) {
                const index = rNetworks.indexOf(network);
                if (index >= 0) {
                    rNetworks.splice(index, 1);
                    network.destroy();
                }
            }

            for (const network of networks) {
                const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
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
            checkPendingConnection();
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

    function handlePasswordRequired(proc: var, error: string, output: string, exitCode: int): bool {
        if (!proc || !error || error.length === 0) {
            return false;
        }

        if (!isConnectionCommand(proc.command) || !root.pendingConnection || !root.pendingConnection.callback) {
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

    component CommandProcess: Process {
        id: proc

        property var callback: null
        property list<string> command: []
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

        onExited: code => {
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
                    const cmdIsConnection = isConnectionCommand(proc.command);

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

    Component {
        id: commandProc

        CommandProcess {}
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

    Component {
        id: apComp

        AccessPoint {}
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
                                if (root.isConnectionCommand(proc.command)) {
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
                                if (root.isConnectionCommand(proc.command)) {
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
                root.ethernetDeviceDetails = null;
                if (callback)
                    callback(null);
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
                } else if (isEthernet && key === "WIRED-PROPERTIES.MAC") {
                    details.macAddress = value;
                } else if (isEthernet && key === "WIRED-PROPERTIES.SPEED") {
                    details.speed = value;
                } else if (!isEthernet && key === "GENERAL.HWADDR") {
                    details.macAddress = value;
                }
            }
        }

        return details;
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", root.nmcliCommandWifi, "list", "--rescan", "yes"]
        onExited: root.getNetworks()
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
        onExited: monitorRestartTimer.start()
    }

    Timer {
        id: monitorRestartTimer
        interval: 2000
        onTriggered: {
            monitorProc.running = true;
        }
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
                }, 500);
            } else {
                root.wirelessDeviceDetails = null;
                root.ethernetDeviceDetails = null;
            }

            getWirelessInterfaces(() => {});
            getEthernetInterfaces(() => {
                if (root.activeEthernet && root.activeEthernet.connected) {
                    Qt.callLater(() => {
                        getEthernetDeviceDetails(root.activeEthernet.interface, () => {});
                    }, 500);
                }
            });
        });
    }

    Component.onCompleted: {
        getWifiStatus(() => {});
        getNetworks(() => {});
        loadSavedConnections(() => {});
        getEthernetInterfaces(() => {});

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
        }, 2000);
    }
}
