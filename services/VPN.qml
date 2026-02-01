pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import Caelestia

Singleton {
    id: root

    property bool connected: false
    property var status: ({
        connected: false,
        state: "disconnected",
        reason: "",
        authUrl: ""
    })

    readonly property bool connecting: connectProc.running || disconnectProc.running
    readonly property bool enabled: Config.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false)
    readonly property var providerInput: {
        const enabledProvider = Config.utilities.vpn.provider.find(p => typeof p === "object" ? (p.enabled === true) : false);
        return enabledProvider || "wireguard";
    }
    readonly property bool isCustomProvider: typeof providerInput === "object"
    readonly property string providerName: isCustomProvider ? (providerInput.name || "custom") : String(providerInput)
    readonly property string interfaceName: isCustomProvider ? (providerInput.interface || "") : ""
    readonly property var currentConfig: {
        const name = providerName;
        const iface = interfaceName;
        const defaults = getBuiltinDefaults(name, iface);

        if (isCustomProvider) {
            const custom = providerInput;
            return {
                connectCmd: custom.connectCmd || defaults.connectCmd,
                disconnectCmd: custom.disconnectCmd || defaults.disconnectCmd,
                interface: custom.interface || defaults.interface,
                displayName: custom.displayName || defaults.displayName
            };
        }

        return defaults;
    }

    function getBuiltinDefaults(name, iface) {
        const builtins = {
            "wireguard": {
                connectCmd: ["pkexec", "wg-quick", "up", iface],
                disconnectCmd: ["pkexec", "wg-quick", "down", iface],
                interface: iface,
                displayName: iface
            },
            "warp": {
                connectCmd: ["warp-cli", "connect"],
                disconnectCmd: ["warp-cli", "disconnect"],
                interface: "CloudflareWARP",
                displayName: "Warp"
            },
            "netbird": {
                connectCmd: ["netbird", "up", "--no-browser"],
                disconnectCmd: ["netbird", "down"],
                interface: "wt0",
                displayName: "NetBird"
            },
            "tailscale": {
                connectCmd: ["tailscale", "up"],
                disconnectCmd: ["tailscale", "down"],
                interface: "tailscale0",
                displayName: "Tailscale"
            }
        };

        return builtins[name] || {
            connectCmd: [name, "up"],
            disconnectCmd: [name, "down"],
            interface: iface || name,
            displayName: name
        };
    }

    function connect(): void {
        if (status.state === "needs-auth") {
            emitStatusToast(status);
            return;
        }
        if (!connected && !connecting && root.currentConfig && root.currentConfig.connectCmd) {
            connectProc.exec(root.currentConfig.connectCmd);
        }
    }

    function disconnect(): void {
        if (connected && !connecting && root.currentConfig && root.currentConfig.disconnectCmd) {
            disconnectProc.exec(root.currentConfig.disconnectCmd);
        }
    }

    function toggle(): void {
        connected ? disconnect() : connect();
    }

    function checkStatus(): void {
        if (root.enabled) {
            statusProc.running = true;
        }
    }

    function getStatusCommand(): var {
        switch (providerName) {
            case "tailscale":
                return ["tailscale", "status", "--json"];
            case "netbird":
                return ["netbird", "status", "--json"];
            case "warp":
                return ["warp-cli", "status"];
            case "wireguard":
                return ["ip", "link", "show"];
            default:
                return ["ip", "link", "show"];
        }
    }

    function parseTailscaleStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        try {
            const data = JSON.parse(output);
            const backendState = data.BackendState || "";
            
            if (backendState === "Running") {
                status.connected = true;
                status.state = "connected";
            } else if (backendState === "Starting") {
                status.state = "connecting";
            } else if (backendState === "NeedsLogin" || backendState === "NeedsMachineAuth") {
                status.state = "needs-auth";
                status.reason = backendState === "NeedsLogin" ? "Login required" : "Machine authorization required";
                status.authUrl = data.AuthURL || "";
            }
        } catch (e) {
            status.state = "error";
            status.reason = "Failed to parse status";
        }
        return status;
    }

    function parseNetBirdStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        try {
            const data = JSON.parse(output);
            const mgmtConnected = data.management?.connected;
            const signalConnected = data.signal?.connected;
            
            if (mgmtConnected && signalConnected) {
                status.connected = true;
                status.state = "connected";
            } else if (data.management?.error) {
                const error = data.management.error;
                if (error.includes("auth") || error.includes("login")) {
                    status.state = "needs-auth";
                    status.reason = "Authentication required";
                } else {
                    status.reason = error;
                }
            }
        } catch (e) {
            status.state = "error";
            status.reason = "Failed to parse status";
        }
        return status;
    }

    function parseWarpStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        
        if (output.includes("Connected")) {
            status.connected = true;
            status.state = "connected";
        } else if (output.includes("Connecting")) {
            status.state = "connecting";
        } else if (output.includes("Unable") || output.includes("Registration Missing") || 
                   output.includes("registration") || output.includes("register")) {
            status.state = "needs-auth";
            status.reason = "WARP registration required";
        } else if (!output.includes("Disconnected")) {
            status.state = "error";
            status.reason = "Unknown WARP status";
        }
        return status;
    }

    function parseWireGuardStatus(output: string): var {
        const status = { connected: false, state: "disconnected", reason: "", authUrl: "" };
        const iface = root.currentConfig?.interface || "";
        
        if (iface && output.includes(iface + ":")) {
            status.connected = true;
            status.state = "connected";
        }
        return status;
    }

    function parseStatusOutput(output: string): var {
        switch (providerName) {
            case "tailscale": return parseTailscaleStatus(output);
            case "netbird": return parseNetBirdStatus(output);
            case "warp": return parseWarpStatus(output);
            case "wireguard":
            default: return parseWireGuardStatus(output);
        }
    }

    function extractAuthUrl(text: string): string {
        const urlMatch = text.match(/(https?:\/\/[^\s]+)/);
        return urlMatch ? urlMatch[1] : "";
    }

    function createAuthStatus(authUrl: string): var {
        return {
            connected: false,
            state: "needs-auth",
            reason: "Authentication required",
            authUrl: authUrl
        };
    }

    function updateStatus(newStatus: var): void {
        const oldState = status.state;
        status = newStatus;
        root.connected = newStatus.connected;

        if (oldState !== newStatus.state) {
            emitStatusToast(newStatus);
        }
    }

    function emitStatusToast(statusObj: var): void {
        if (!Config.utilities.toasts.vpnChanged)
            return;

        const displayName = root.currentConfig ? (root.currentConfig.displayName || "VPN") : "VPN";

        switch (statusObj.state) {
            case "connected":
                Toaster.toast(qsTr("VPN connected"), qsTr("Connected to %1").arg(displayName), "vpn_key");
                break;
            case "disconnected":
                if (status.connected) {
                    Toaster.toast(qsTr("VPN disconnected"), qsTr("Disconnected from %1").arg(displayName), "vpn_key_off");
                }
                break;
            case "needs-auth":
                const authMsg = statusObj.reason || "Authentication required";
                Toaster.toast(qsTr("VPN authentication required"), qsTr("%1: %2").arg(displayName).arg(authMsg), "vpn_lock");
                break;
            case "error":
                if (status.state === "connected" || status.state === "connecting" || status.state === "needs-auth") {
                    const errMsg = statusObj.reason || "Unknown error";
                    Toaster.toast(qsTr("VPN error"), qsTr("%1: %2").arg(displayName).arg(errMsg), "error");
                }
                break;
        }
    }

    Component.onCompleted: root.enabled && statusCheckTimer.start()

    Process {
        id: nmMonitor

        running: root.enabled
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: statusCheckTimer.restart()
        }
    }

    Process {
        id: statusProc

        command: getStatusCommand()
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const newStatus = parseStatusOutput(text);
                updateStatus(newStatus);
            }
        }
    }

    Process {
        id: connectProc

        onExited: (exitCode) => {
            if (status.state !== "needs-auth") {
                statusCheckTimer.start();
            }
        }
        stdout: SplitParser {
            onRead: (data) => {
                const authUrl = extractAuthUrl(data);
                if (authUrl) {
                    updateStatus(createAuthStatus(authUrl));
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                const authUrl = extractAuthUrl(error);

                if (authUrl) {
                    updateStatus(createAuthStatus(authUrl));
                } else if (error.includes("already exists")) {
                    root.connected = true;
                }
            }
        }
    }

    Process {
        id: disconnectProc

        onExited: statusCheckTimer.start()
    }

    Process {
        id: warpRegisterProc

        onExited: (exitCode) => {
            if (exitCode === 0) {
                statusCheckTimer.start();
            }
        }
    }

    Timer {
        id: statusCheckTimer

        interval: 500
        onTriggered: root.checkStatus()
    }

    onStatusChanged: {
        if (providerName === "warp" && status.state === "needs-auth" && 
            status.reason.includes("registration")) {
            warpRegisterProc.exec(["warp-cli", "registration", "new"]);
        }
    }

    onProviderNameChanged: {
        status = {
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: ""
        };
        root.connected = false;
        statusCheckTimer.start();
    }
}
