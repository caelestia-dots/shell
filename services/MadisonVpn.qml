pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n

Singleton {
    id: root

    readonly property string scriptsDir: `${Quickshell.env("HOME")}/.local/share/madison-vpn`

    property bool connected: false
    property string vpnIp: ""
    property string statusText: Tr.trCtx("Disconnected", "madison vpn state")
    property bool busy: false
    property bool otpOpen: false
    property string lastError: ""

    readonly property bool connecting: busy && !connected
    readonly property bool disconnecting: busy && connected

    function refreshStatus(): void {
        if (statusProc.running)
            return;
        statusProc.running = true;
    }

    function toggle(): void {
        if (root.busy)
            return;
        if (root.connected)
            root.disconnect();
        else
            root.requestOtp();
    }

    function requestOtp(): void {
        if (root.busy || root.connected)
            return;
        root.lastError = "";
        root.otpOpen = true;
    }

    function cancelOtp(): void {
        root.otpOpen = false;
        root.lastError = "";
    }

    function connectWithOtp(otp: string): void {
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
        if (root.busy || !root.connected)
            return;
        root.busy = true;
        root.statusText = Tr.trCtx("Disconnecting…", "madison vpn state");
        disconnectProc.running = true;
    }

    function applyStatus(out: string): void {
        const parts = (out || "").trim().split("|");
        const state = parts[0] || "disconnected";
        const ip = parts[1] || "";
        root.connected = state === "connected";
        root.vpnIp = ip;
        root.statusText = root.connected ? Tr.tr("Connected · %1").arg(ip) : Tr.trCtx("Disconnected", "madison vpn state");
        root.busy = false;
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
            if (GlobalConfig.utilities.toasts.vpnChanged)
                Toaster.toast(Tr.tr("Madison VPN"), Tr.tr("VPN disconnected"), "shield");
            root.refreshStatus();
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    Component.onCompleted: root.refreshStatus()
}
