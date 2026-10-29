pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services

Singleton {
    id: root

    readonly property string scriptsDir: `${Quickshell.env("HOME")}/.local/share/madison-vpn`
    readonly property string configPath: `${Quickshell.env("HOME")}/.config/openfortivpn/config`

    readonly property bool enabled: GlobalConfig.addons.madisonVpn.enabled

    property bool connected: false
    property string vpnIp: ""
    property string statusText: Tr.trCtx("Disconnected", "madison vpn state")
    property bool busy: false
    property bool otpOpen: false
    property string lastError: ""
    property bool wasConnected: false
    property bool tearingDown: false

    // Editable openfortivpn connection fields (rest of the file is preserved on save)
    property string cfgHost: ""
    property string cfgPort: "10443"
    property string cfgUsername: ""
    property string cfgPassword: ""
    property string cfgRealm: ""
    property bool configLoaded: false
    property string configError: ""

    readonly property bool connecting: busy && !connected
    readonly property bool disconnecting: busy && connected

    function setEnabled(on: bool): void {
        if (GlobalConfig.addons.madisonVpn.enabled === on)
            return;
        GlobalConfig.addons.madisonVpn.enabled = on;
    }

    function refreshStatus(): void {
        // While connect/disconnect is in flight the piped status is stale by
        // definition; the process onExited handler refreshes at the end.
        // Previously poll here reset `busy` mid-connect (UI flicker + a second
        // connectWithOtp could kill the first tunnel attempt).
        if (connectProc.running || disconnectProc.running)
            return;
        if (!root.enabled || statusProc.running)
            return;
        statusProc.running = true;
    }

    function onResumed(): void {
        if (!root.enabled)
            return;
        // After sleep the SSL tunnel is usually dead while ppp0 still looks up.
        // Heal tears down zombies + clears hosts/DNS; then burst-poll status.
        if (!healProc.running)
            healProc.running = true;
        resumeBurst.ticks = 0;
        resumeBurst.restart();
    }

    function toggle(): void {
        if (!root.enabled || root.busy)
            return;
        if (root.connected)
            root.disconnect();
        else
            root.requestOtp();
    }

    function requestOtp(): void {
        if (!root.enabled || root.busy || root.connected)
            return;
        root.lastError = "";
        root.otpOpen = true;
    }

    function cancelOtp(): void {
        root.otpOpen = false;
        root.lastError = "";
    }

    function connectWithOtp(otp: string): void {
        if (!root.enabled)
            return;
        const token = (otp || "").replace(/\s+/g, "");
        if (token.length === 0 || root.busy)
            return;

        root.otpOpen = false;
        root.busy = true;
        root.lastError = "";
        root.statusText = Tr.trCtx("Connecting…", "madison vpn state");
        connectProc.command = [`${root.scriptsDir}/connect_vpn.sh`, token];
        connectProc.running = true;
    }

    function disconnect(): void {
        if (!root.enabled || root.busy || !root.connected)
            return;
        root.busy = true;
        root.statusText = Tr.trCtx("Disconnecting…", "madison vpn state");
        disconnectProc.running = true;
    }

    // Kill tunnel / openfortivpn even if status already looks disconnected
    function teardown(): void {
        root.cancelOtp();
        root.tearingDown = true;
        root.busy = true;
        root.lastError = "";
        root.statusText = Tr.trCtx("Disconnected", "madison vpn state");
        resumeBurst.stop();
        if (connectProc.running)
            connectProc.running = false;
        if (statusProc.running)
            statusProc.running = false;
        if (disconnectProc.running) {
            // Already stopping; heal will run on exit
            return;
        }
        disconnectProc.running = true;
    }

    function clearRuntimeState(): void {
        root.connected = false;
        root.vpnIp = "";
        root.busy = false;
        root.wasConnected = false;
        root.otpOpen = false;
        root.tearingDown = false;
        root.statusText = Tr.trCtx("Disconnected", "madison vpn state");
    }

    function reloadConfig(): void {
        root.configError = "";
        configFile.reload();
    }

    function applyConfigText(text: string): void {
        let host = "";
        let port = "10443";
        let username = "";
        let password = "";
        let realm = "";
        for (const raw of (text || "").split("\n")) {
            const line = raw.trim();
            if (!line || line.startsWith("#"))
                continue;
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            const key = line.slice(0, eq).trim();
            const value = line.slice(eq + 1).trim();
            switch (key) {
            case "host":
                host = value;
                break;
            case "port":
                port = value || "10443";
                break;
            case "username":
                username = value;
                break;
            case "password":
                password = value;
                break;
            case "realm":
                realm = value;
                break;
            }
        }
        root.cfgHost = host;
        root.cfgPort = port;
        root.cfgUsername = username;
        root.cfgPassword = password;
        root.cfgRealm = realm;
        root.configLoaded = true;
    }

    function saveConfig(): bool {
        if (!root.cfgHost.trim()) {
            root.configError = Tr.tr("Host is required");
            return false;
        }
        const port = (root.cfgPort || "").trim() || "10443";
        if (!/^\d+$/.test(port)) {
            root.configError = Tr.tr("Port must be a number");
            return false;
        }

        const updates = {
            host: root.cfgHost.trim(),
            port: port,
            username: root.cfgUsername.trim(),
            password: root.cfgPassword,
            realm: root.cfgRealm.trim()
        };
        const seen = {};
        const src = configFile.text() || "";
        const lines = src.length ? src.split("\n") : [];
        const out = lines.map(raw => {
            const m = raw.match(/^(\s*)([\w-]+)(\s*=\s*)(.*)$/);
            if (!m)
                return raw;
            const key = m[2];
            if (!(key in updates))
                return raw;
            seen[key] = true;
            return `${m[1]}${key}${m[3]}${updates[key]}`;
        });
        for (const key of Object.keys(updates)) {
            if (!seen[key])
                out.push(`${key} = ${updates[key]}`);
        }
        try {
            configFile.setText(out.join("\n").replace(/\n+$/, "") + "\n");
            root.configError = "";
            root.cfgPort = port;
            return true;
        } catch (e) {
            root.configError = Tr.tr("Could not write VPN config");
            return false;
        }
    }

    function applyStatus(out: string): void {
        if (!root.enabled) {
            root.clearRuntimeState();
            return;
        }
        const parts = (out || "").trim().split("|");
        const state = parts[0] || "disconnected";
        const ip = parts[1] || "";
        const nowConnected = state === "connected";
        // A transition is owned by its process; ignore piped status that raced
        // with it (would stamp "Disconnected" over "Connecting…" and clear busy).
        if (connectProc.running || disconnectProc.running)
            return;
        const dropped = root.wasConnected && !nowConnected && !root.busy;

        root.connected = nowConnected;
        root.vpnIp = ip;
        root.statusText = root.connected ? Tr.tr("Connected · %1").arg(ip) : Tr.trCtx("Disconnected", "madison vpn state");
        root.busy = false;
        root.wasConnected = nowConnected;

        if (dropped && GlobalConfig.utilities.toasts.vpnChanged)
            Toaster.toast(Tr.tr("Madison VPN"), Tr.tr("VPN dropped (reconnect after sleep)"), "gpp_bad");
    }

    Process {
        id: statusProc

        command: [`${root.scriptsDir}/status_vpn.sh`]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text)
        }
    }

    Process {
        id: healProc

        command: [`${root.scriptsDir}/heal_vpn.sh`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.tearingDown || !root.enabled)
                    root.clearRuntimeState();
                else
                    root.applyStatus(text);
            }
        }
        onExited: () => {
            if (root.tearingDown || !root.enabled) {
                root.clearRuntimeState();
                return;
            }
            root.refreshStatus();
        }
    }

    Process {
        id: connectProc

        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.lastError = text.trim();
            }
        }
        onExited: code => {
            if (!root.enabled) {
                root.clearRuntimeState();
                return;
            }
            if (code === 0) {
                if (GlobalConfig.utilities.toasts.vpnChanged)
                    Toaster.toast(Tr.tr("Madison VPN"), Tr.tr("VPN connected"), "vpn_lock");
            } else if (code === 3) {
                root.lastError = Tr.tr("Login failed (user / password / OTP / certificate).");
                if (GlobalConfig.utilities.toasts.vpnChanged)
                    Toaster.toast(Tr.tr("Madison VPN"), root.lastError, "gpp_bad");
            } else if (code !== 0) {
                const detail = root.lastError || Tr.tr("Could not start the VPN tunnel (code %1).").arg(code);
                if (GlobalConfig.utilities.toasts.vpnChanged)
                    Toaster.toast(Tr.tr("Madison VPN"), detail, "gpp_bad");
            }
            root.refreshStatus();
        }
    }

    Process {
        id: disconnectProc

        command: [`${root.scriptsDir}/disconnect_vpn.sh`]
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: () => {
            if (root.tearingDown || !root.enabled) {
                // After forced stop, heal to clear DNS/hosts/zombies
                if (!healProc.running)
                    healProc.running = true;
                else
                    root.clearRuntimeState();
                if (GlobalConfig.utilities.toasts.vpnChanged)
                    Toaster.toast(Tr.tr("Madison VPN"), Tr.tr("Complement disabled"), "shield");
                return;
            }
            if (GlobalConfig.utilities.toasts.vpnChanged)
                Toaster.toast(Tr.tr("Madison VPN"), Tr.tr("VPN disconnected"), "shield");
            root.refreshStatus();
        }
    }

    Timer {
        id: poll

        // Connected/busy: catch drops quickly; idle disconnect: cheap heartbeat
        interval: root.connected || root.busy || root.tearingDown ? 8000 : 30000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    Timer {
        id: resumeBurst

        property int ticks: 0
        interval: 1500
        repeat: true
        onTriggered: {
            if (!root.enabled) {
                resumeBurst.stop();
                return;
            }
            root.refreshStatus();
            resumeBurst.ticks++;
            if (resumeBurst.ticks >= 6)
                resumeBurst.stop();
        }
    }

    Connections {
        target: SessionManager

        function onResumed(): void {
            root.onResumed();
        }
    }

    Connections {
        target: GlobalConfig.addons.madisonVpn

        function onEnabledChanged(): void {
            if (root.enabled) {
                root.tearingDown = false;
                root.refreshStatus();
            } else {
                root.teardown();
            }
        }
    }

    FileView {
        id: configFile

        path: root.configPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyConfigText(text())
        onLoadFailed: err => {
            root.configLoaded = true;
            if (err !== FileViewError.FileNotFound)
                root.configError = Tr.tr("Could not read VPN config");
        }
    }

    Component.onCompleted: {
        if (root.enabled)
            root.refreshStatus();
    }
}
