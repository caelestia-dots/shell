pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

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
    readonly property bool enabled: GlobalConfig.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false)
    readonly property var providerInput: {
        const enabledProvider = GlobalConfig.utilities.vpn.provider.find(p => typeof p === "object" ? (p.enabled === true) : false);
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

    // Tracks an in-flight provider switch that must wait for disconnect.
    property int pendingSwitchIndex: -1
    // Tracks whether the previous status read was empty, so we tolerate a single
    // starved read but still report persistent empties (e.g. no connectivity).
    property bool _sawEmptyStatus: false
    // Epoch ms when the VPN connection was established (0 = not connected).
    property double connectedSince: 0
    // Live counters for the active VPN interface (cumulative bytes since the
    // interface came up). "In" = received, "Out" = transmitted.
    property string bytesIn: ""
    property string bytesOut: ""
    // Round-trip latency over the VPN tunnel, in ms (-1 = unknown/not measured).
    property int pingMs: -1
    // Best-effort server/exit location (currently only resolvable for WARP).
    property string serverLocation: ""

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
        if (status.state === "needs-auth" && status.authUrl) {
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

    // ---- Provider management -------------------------------------------------
    // Normalised view of the configured providers, one entry per provider with
    // a stable index. Used by the VPN management UI.
    function providers(): var {
        const list = GlobalConfig.utilities.vpn.provider;
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            const isObject = typeof p === "object";
            out.push({
                index: i,
                name: isObject ? (p.name || "custom") : String(p),
                displayName: isObject ? (p.displayName || p.name || String(p)) : String(p),
                interface: isObject ? (p.interface || "") : "",
                connectCmd: isObject && p.connectCmd ? p.connectCmd : [],
                disconnectCmd: isObject && p.disconnectCmd ? p.disconnectCmd : [],
                enabled: isObject ? (p.enabled === true) : false,
                isObject: isObject
            });
        }
        return out;
    }

    // Rebuild a provider object for persistence, preserving optional commands.
    function buildProviderObject(data: var, enabled: bool): var {
        const obj = {
            name: data.name,
            displayName: data.displayName,
            interface: data.interface,
            enabled: enabled
        };
        if (data.connectCmd && data.connectCmd.length > 0)
            obj.connectCmd = data.connectCmd;
        if (data.disconnectCmd && data.disconnectCmd.length > 0)
            obj.disconnectCmd = data.disconnectCmd;
        return obj;
    }

    // Persist the whole provider list back to config (file-backed).
    function writeProviders(providers: var): void {
        GlobalConfig.utilities.vpn.provider = providers;
    }

    // Add a new provider. data: { name, displayName, interface, connectCmd[],
    // disconnectCmd[] }. Newly added providers are disabled by default.
    function addProvider(data: var): void {
        const current = GlobalConfig.utilities.vpn.provider.slice();
        current.push(buildProviderObject(data, false));
        writeProviders(current);
    }

    // Update an existing provider (by index), keeping its enabled state.
    function updateProvider(index: int, data: var): void {
        const current = GlobalConfig.utilities.vpn.provider;
        const result = [];
        for (let i = 0; i < current.length; i++) {
            const p = current[i];
            if (i === index) {
                const wasEnabled = typeof p === "object" ? (p.enabled === true) : false;
                result.push(buildProviderObject(data, wasEnabled));
            } else {
                result.push(p);
            }
        }
        writeProviders(result);
    }

    // Delete a provider by index.
    function deleteProvider(index: int): void {
        const current = GlobalConfig.utilities.vpn.provider;
        const result = [];
        for (let i = 0; i < current.length; i++)
            if (i !== index)
                result.push(current[i]);
        writeProviders(result);
    }

    // Make the provider at `index` the active (enabled) one, disabling others.
    // If a VPN is currently connected, disconnect first, switch, then reconnect.
    function setActiveProvider(index: int): void {
        const apply = () => {
            const current = GlobalConfig.utilities.vpn.provider;
            const result = [];
            for (let i = 0; i < current.length; i++) {
                const p = current[i];
                if (typeof p === "object")
                    result.push(buildProviderObject(p, i === index));
                else
                    result.push(p);
            }
            writeProviders(result);
        };

        if (root.connected) {
            root.pendingSwitchIndex = index;
            root.disconnect();
        } else {
            apply();
        }
    }

    function checkStatus(): void {
        if (root.enabled) {
            statusProc.running = true;
        }
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

    // Refresh live In/Out byte counters and (for WARP) the server location.
    function refreshStats(): void {
        if (!connected)
            return;
        const iface = root.currentConfig?.interface || "";
        if (iface.length > 0) {
            statsProc.command = ["sh", "-c", `cat /sys/class/net/${iface}/statistics/rx_bytes /sys/class/net/${iface}/statistics/tx_bytes 2>/dev/null`];
            statsProc.running = true;
            // Measure latency over the tunnel by binding the ping to the VPN
            // interface (-I), so the result reflects the VPN path, not the LAN.
            if (!pingProc.running) {
                pingProc.command = ["sh", "-c", `ping -c1 -W2 -I ${iface} 1.1.1.1 2>/dev/null || ping -c1 -W2 1.1.1.1 2>/dev/null`];
                pingProc.running = true;
            }
        }
        if (providerName === "warp" && serverLocation.length === 0)
            warpServerProc.running = true;
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
        const status = {
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: "",
            server: ""
        };

        // Handle empty or whitespace-only output
        if (!output || output.trim().length === 0) {
            return status;
        }

        // Check for common non-JSON states first
        if (output.includes("Logged out") || output.includes("Stopped") || output.includes("not running") || output.includes("Tailscale is not running")) {
            status.state = "disconnected";
            return status;
        }

        // Try to parse as JSON
        try {
            const data = JSON.parse(output);
            const backendState = data.BackendState || "";

            if (backendState === "Running") {
                status.connected = true;
                status.state = "connected";

                // Exit node, if one is in use, is the most meaningful "server".
                try {
                    const peers = data.Peer || {};
                    for (const key in peers) {
                        const p = peers[key];
                        if (p && p.ExitNode) {
                            status.server = (p.DNSName || p.HostName || "").replace(/\.$/, "");
                            break;
                        }
                    }
                } catch (e2) {}
            } else if (backendState === "Starting") {
                status.state = "connecting";
            } else if (backendState === "NeedsLogin" || backendState === "NeedsMachineAuth") {
                status.state = "needs-auth";
                status.reason = backendState === "NeedsLogin" ? "Login required" : "Machine authorization required";
                status.authUrl = data.AuthURL || "";
            }
        } catch (e) {
            // JSON parsing failed - treat as disconnected unless it looks like an error
            if (output.includes("error") || output.includes("Error") || output.includes("failed")) {
                status.state = "disconnected";
                status.reason = "Tailscale may not be running";
            } else {
                status.state = "disconnected";
            }
        }
        return status;
    }

    function parseNetBirdStatus(output: string): var {
        const status = {
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: "",
            server: ""
        };
        try {
            const data = JSON.parse(output);
            const mgmtConnected = data.management?.connected;
            const signalConnected = data.signal?.connected;

            if (mgmtConnected && signalConnected) {
                status.connected = true;
                status.state = "connected";
                // The management server URL is the most stable "server" value.
                const url = data.management?.url || data.management?.URL || "";
                if (url)
                    status.server = url.replace(/^https?:\/\//, "").replace(/:\d+$/, "");
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
        const status = {
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: "",
            server: ""
        };

        // Order matters: "Disconnected" contains the substring "Connected",
        // so the disconnected/registration cases must be checked first. Recent
        // warp-cli prints lines like "Status update: Connected" /
        // "Status update: Disconnected\nReason: ...".
        if (output.includes("Registration Missing") || output.includes("registration") || output.includes("register") || output.includes("Unable to connect")) {
            status.state = "needs-auth";
            status.reason = "WARP registration required";
        } else if (output.includes("Disconnected")) {
            status.state = "disconnected";
        } else if (output.includes("Connecting")) {
            status.state = "connecting";
        } else if (output.includes("Connected")) {
            status.connected = true;
            status.state = "connected";
        } else {
            status.state = "error";
            status.reason = "Unknown WARP status";
        }
        return status;
    }

    function parseWireGuardStatus(output: string): var {
        const status = {
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: "",
            server: ""
        };
        const iface = root.currentConfig?.interface || "";

        if (iface && output.includes(iface + ":")) {
            status.connected = true;
            status.state = "connected";
        }
        return status;
    }

    function parseStatusOutput(output: string): var {
        switch (providerName) {
        case "tailscale":
            return parseTailscaleStatus(output);
        case "netbird":
            return parseNetBirdStatus(output);
        case "warp":
            return parseWarpStatus(output);
        case "wireguard":
        default:
            return parseWireGuardStatus(output);
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
        if (newStatus.state === "needs-auth" && !newStatus.authUrl && status.authUrl) {
            newStatus.authUrl = status.authUrl;
        }

        status = newStatus;
        root.connected = newStatus.connected;

        // Surface a parsed server/exit-node (Tailscale, NetBird, WireGuard).
        // WARP is handled separately via warpServerProc.
        if (newStatus.connected && providerName !== "warp" && newStatus.server)
            root.serverLocation = newStatus.server;

        if (oldState !== newStatus.state) {
            emitStatusToast(newStatus);
        }
    }

    function emitStatusToast(statusObj: var): void {
        if (!GlobalConfig.utilities.toasts.vpnChanged)
            return;

        const displayName = root.currentConfig ? (root.currentConfig.displayName || "VPN") : "VPN";

        switch (statusObj.state) {
        case "connected":
            Toaster.toast(qsTr("VPN connected"), qsTr("Connected to %1").arg(displayName), "vpn_key");
            break;
        case "disconnected":
            Toaster.toast(qsTr("VPN disconnected"), qsTr("Disconnected from %1").arg(displayName), "vpn_key_off");
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

    onConnectedChanged: {
        // Stamp / clear the connection start time.
        if (connected) {
            if (connectedSince === 0)
                connectedSince = Date.now();
        } else {
            connectedSince = 0;
            bytesIn = "";
            bytesOut = "";
            serverLocation = "";
            pingMs = -1;
        }

        if (!connected && pendingSwitchIndex >= 0) {
            const idx = pendingSwitchIndex;
            pendingSwitchIndex = -1;

            const current = GlobalConfig.utilities.vpn.provider;
            const result = [];
            for (let i = 0; i < current.length; i++) {
                const p = current[i];
                if (typeof p === "object")
                    result.push(buildProviderObject(p, i === idx));
                else
                    result.push(p);
            }
            GlobalConfig.utilities.vpn.provider = result;

            Qt.callLater(() => root.connect());
        }
    }

    onStatusChanged: {
        if (providerName === "warp" && status.state === "needs-auth" && status.reason.includes("registration")) {
            warpRegisterProc.exec(["warp-cli", "registration", "new"]);
        }
    }

    onProviderNameChanged: {
        status = {
            connected: false,
            state: "disconnected",
            reason: "",
            authUrl: "",
            server: ""
        };
        root.connected = false;
        root.serverLocation = "";
        root.bytesIn = "";
        root.bytesOut = "";
        root.pingMs = -1;
        statusCheckTimer.start();
    }

    Component.onCompleted: root.enabled && statusCheckTimer.start()

    // Reads cumulative rx/tx bytes for the active VPN interface from sysfs.
    Process {
        id: statsProc

        stdout: StdioCollector {
            onStreamFinished: {
                const nums = text.trim().split("\n").map(n => parseInt(n.trim(), 10)).filter(n => !isNaN(n));
                if (nums.length >= 2) {
                    root.bytesIn = root.formatBytes(nums[0]);
                    root.bytesOut = root.formatBytes(nums[1]);
                }
            }
        }
    }

    // Measures tunnel latency. Parses "time=21.3 ms" from ping output.
    Process {
        id: pingProc

        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/time[=<]\s*([\d.]+)\s*ms/i);
                if (m) {
                    root.pingMs = Math.round(parseFloat(m[1]));
                } else if (root.connected) {
                    // Reachable interface but no reply parsed → mark unknown.
                    root.pingMs = -1;
                }
            }
        }
        stderr: StdioCollector {}
    }

    // Best-effort WARP server/endpoint location from warp-cli.
    Process {
        id: warpServerProc

        command: ["warp-cli", "tunnel", "stats"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Look for an endpoint/colo hint in the stats output. WARP shows
                // an "Endpoint" line with an IP; some versions include a colo.
                const lines = text.split("\n");
                for (const line of lines) {
                    const m = line.match(/Endpoint[^\d]*([\d.]+)/i);
                    if (m) {
                        root.serverLocation = m[1];
                        break;
                    }
                }
            }
        }
        stderr: StdioCollector {}
    }

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

        command: root.getStatusCommand()
        // qmllint disable incompatible-type
        environment: ({
                // qmllint enable incompatible-type
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                // A single empty read can mean the status command was briefly
                // starved (e.g. by a concurrent ping sweep). Ignore one, but if
                // empties persist it's a real condition (e.g. no connectivity),
                // so fall through and let the parser report it.
                if (text.trim().length === 0) {
                    if (!root._sawEmptyStatus) {
                        root._sawEmptyStatus = true;
                        return;
                    }
                } else {
                    root._sawEmptyStatus = false;
                }
                const newStatus = root.parseStatusOutput(text);
                root.updateStatus(newStatus);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    if (text.includes("doesn't appear to be running") || text.includes("failed to connect to local tailscaled") || text.includes("daemon is not running") || text.includes("not running") && (text.includes("netbird") || text.includes("warp"))) {
                        let cmd = "sudo systemctl start ";
                        switch (root.providerName) {
                        case "tailscale":
                            cmd += "tailscaled";
                            break;
                        case "netbird":
                            cmd += "netbird";
                            break;
                        case "warp":
                            cmd += "warp-svc";
                            break;
                        default:
                            cmd += root.providerName + "d";
                            break;
                        }
                        const errorStatus = {
                            connected: false,
                            state: "disconnected",
                            reason: `Service not running (run: ${cmd})`,
                            authUrl: ""
                        };
                        root.updateStatus(errorStatus);
                    }
                }
            }
        }
    }

    Process {
        id: connectProc

        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (exitCode !== 0) {
                return;
            }

            if (root.providerName === "tailscale") {
                Qt.callLater(() => {
                    if (root.status.state !== "needs-auth") {
                        statusCheckTimer.start();
                    }
                });
            } else if (root.status.state !== "needs-auth") {
                statusCheckTimer.start();
            }
        }
        stdout: SplitParser {
            onRead: data => {
                const authUrl = root.extractAuthUrl(data);
                if (authUrl) {
                    root.updateStatus(root.createAuthStatus(authUrl));
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();

                if (error.includes("Access denied") || error.includes("checkprefs access denied")) {
                    const errorStatus = {
                        connected: false,
                        state: "disconnected",
                        reason: "Permission denied. Run in terminal: sudo tailscale set --operator=$USER",
                        authUrl: ""
                    };
                    root.updateStatus(errorStatus);
                    return;
                }

                if (error.includes("Unknown device type") || error.includes("Protocol not supported")) {
                    const errorStatus = {
                        connected: false,
                        state: "disconnected",
                        reason: "WireGuard module not loaded. Run: sudo modprobe wireguard",
                        authUrl: ""
                    };
                    root.updateStatus(errorStatus);
                    return;
                }

                const authUrl = root.extractAuthUrl(error);

                if (authUrl) {
                    root.updateStatus(root.createAuthStatus(authUrl));
                } else if (error.includes("already exists")) {
                    root.connected = true;
                }
            }
        }
    }

    Process {
        id: disconnectProc

        onExited: statusCheckTimer.start() // qmllint disable signal-handler-parameters
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]")) {
                    console.warn(lc, "Disconnection error:", error);
                }
            }
        }
    }

    Process {
        id: warpRegisterProc

        onExited: exitCode => { // qmllint disable signal-handler-parameters
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

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.vpn"
        defaultLogLevel: LoggingCategory.Info
    }
}
