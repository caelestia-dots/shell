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

    readonly property bool connecting: Wifi.connecting
    // Wifi state lives in Wifi now, read from NetworkManager over dbus.
    // These forward it so existing consumers keep working unchanged.
    readonly property bool wifiEnabled: Wifi.enabled
    readonly property bool scanning: Wifi.scanning
    readonly property list<var> networks: Wifi.networks
    readonly property var active: Wifi.active
    // Saved profiles live in Profiles now, read from NetworkManager's Settings
    // interface. These forward them so existing consumers keep working.
    readonly property list<string> savedConnectionSsids: Profiles.ssids
    // Map of saved Wi-Fi SSID (lowercased) -> security type

    property var pendingConnection: null
    // Device details come from NetworkManager's IP4Config over dbus now.
    // These forward them so existing consumers keep working unchanged.
    readonly property var wirelessDeviceDetails: Wifi.details
    readonly property var ethernetDeviceDetails: Wired.details
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

    // Constants
    readonly property string deviceTypeWifi: "wifi"
    readonly property string nmcliCommandDevice: "device"
    readonly property string nmcliCommandConnection: "connection"
    readonly property string nmcliCommandWifi: "wifi"
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

    function connectingSsid(): string {
        return Wifi.connectingSsid;
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

    function connectEthernet(connectionName: string, interfaceName: string, callback: var): void {
        Wired.connect(connectionName, interfaceName, callback);
    }

    function disconnectEthernet(connectionName: string, callback: var): void {
        Wired.disconnect(connectionName, callback);
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

    function disconnectFromNetwork(): void {
        Wifi.disconnect(null);
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
                    if (root.pendingConnection.callback) {
                        root.pendingConnection.callback({
                            success: true,
                            output: "Connected",
                            error: "",
                            exitCode: 0
                        });
                    }
                    root.pendingConnection = null;
                }
            });
        }
    }

    // Reads the IPv4 configuration (method, address, gateway, DNS, autoconnect)
    // of a connection profile for the ethernet detail page.
    // Kept for existing callers; the saved configuration is a live binding on
    // Profiles now, so there is nothing to fetch.
    function getIpv4Config(connectionName: string, callback: var): void {
        if (callback)
            callback(Profiles.ipv4ConfigFor(connectionName));
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
            // Reactivate so changes take effect immediately. Nothing to
            // refresh afterwards; the new addresses arrive over dbus.
            executeCommand([root.nmcliCommandConnection, "up", connectionName], upResult => {
                if (callback)
                    callback(upResult);
            });
        });
    }

    function getEthernetDataUsage(interfaceName: string): void {
        Wired.refreshDataUsage(interfaceName);
    }

    // Association is reported over dbus now, so a pending connect resolves the
    // moment NetworkManager says so rather than on the next poll.
    onActiveChanged: checkPendingConnection()

    Component {
        id: commandProc

        CommandProcess {}
    }

    // Nothing reports a connect that simply never happens, so this stays as the
    // backstop. Success arrives on onActiveChanged and a rejected password on
    // the process's own stderr, both immediately, so neither needs polling.
    Timer {
        id: connectionCheckTimer

        interval: 4000
        onTriggered: {
            if (!root.pendingConnection)
                return;

            const pending = root.pendingConnection;
            root.pendingConnection = null;

            if (root.active?.ssid === pending.ssid)
                return;

            root.connectionFailed(pending.ssid);
            pending.callback?.({
                success: false,
                output: "",
                error: "Connection timeout",
                exitCode: -1,
                needsPassword: false
            });
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
